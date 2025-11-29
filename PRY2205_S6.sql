
--Caso 1
SELECT 
p.id_profesional AS "Id Profesional",
TRIM(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS "Nombre Profesional",
NVL((SELECT COUNT(*) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector = 3), 0) AS "Nro Asesorías Banca",
NVL((SELECT SUM(a.honorario) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector = 3), 0) AS "Monto Honorarios Banca",
NVL((SELECT COUNT(*) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector = 4), 0) AS "Nro Asesorías Retail",
NVL((SELECT SUM(a.honorario) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector = 4), 0) AS "Monto Honorarios Retail",
NVL((SELECT COUNT(*) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector IN (3, 4)), 0) AS "Total Asesorías",
NVL((SELECT SUM(a.honorario) FROM asesoria a 
JOIN empresa e ON a.cod_empresa = e.cod_empresa 
WHERE a.id_profesional = p.id_profesional AND e.cod_sector IN (3, 4)), 0) AS "Total Honorarios"
FROM profesional p
WHERE p.id_profesional IN (
    SELECT DISTINCT a1.id_profesional
    FROM asesoria a1
    JOIN empresa e1 ON a1.cod_empresa = e1.cod_empresa
    WHERE e1.cod_sector = 3
    INTERSECT
    SELECT DISTINCT a2.id_profesional
    FROM asesoria a2
    JOIN empresa e2 ON a2.cod_empresa = e2.cod_empresa
    WHERE e2.cod_sector = 4
)
ORDER BY p.id_profesional ASC;

--Caso 2

CREATE TABLE REPORTE_MES (
    id_profesional NUMBER(10) NOT NULL,
    nombre_completo VARCHAR2(60) NOT NULL,
    profesion VARCHAR2(25) NOT NULL,
    comuna_residencia VARCHAR2(20) NOT NULL,
    nro_asesorias NUMBER(3) NOT NULL,
    total_honorarios NUMBER(12) NOT NULL,
    honorario_promedio NUMBER(12) NOT NULL,
    honorario_minimo NUMBER(12) NOT NULL,
    honorario_maximo NUMBER(12) NOT NULL
);

SELECT 
    p.id_profesional AS id_profesional,
    RTRIM(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS nombre_completo,
    pr.nombre_profesion AS profesion,
    c.nom_comuna AS comuna_residencia,
    COUNT(a.id_profesional) AS nro_asesorias,
    NVL(ROUND(SUM(a.honorario)), 0) AS total_honorarios,
    NVL(ROUND(AVG(a.honorario)), 0) AS honorario_promedio,
    NVL(ROUND(MIN(a.honorario)), 0) AS honorario_minimo,
    NVL(ROUND(MAX(a.honorario)), 0) AS honorario_maximo
FROM 
    profesional p
    INNER JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
    INNER JOIN comuna c ON p.cod_comuna = c.cod_comuna
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
    AND EXTRACT(MONTH FROM a.fin_asesoria) = 4
GROUP BY 
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna
ORDER BY 
    p.id_profesional ASC;


SELECT * FROM REPORTE_MES;

--Caso 3

CREATE TABLE REPORTE_ANTES_ACTUALIZACION AS
SELECT 
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    pr.nombre_profesion AS profesion,
    NVL(ROUND(SUM(
        CASE 
            WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                 AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
            THEN a.honorario 
            ELSE 0 
        END
    )), 0) AS total_honorarios_marzo,
    p.sueldo AS sueldo_actual,
    CASE 
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) < 1000000 THEN '10%'
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) >= 1000000 THEN '15%'
        ELSE '0%'
    END AS porcentaje_incremento,
    CASE 
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) < 1000000 THEN ROUND(p.sueldo * 1.10)
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) >= 1000000 THEN ROUND(p.sueldo * 1.15)
        ELSE p.sueldo
    END AS sueldo_proyectado
FROM 
    profesional p
    INNER JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
    LEFT JOIN asesoria a ON p.id_profesional = a.id_profesional
GROUP BY 
    p.id_profesional, 
    p.appaterno, 
    p.apmaterno, 
    p.nombre, 
    pr.nombre_profesion, 
    p.sueldo
ORDER BY 
    p.id_profesional;

MERGE INTO RESUMEN_COMPRA_AVANCE_PUNTOS rcap
USING (
    SELECT 
        p.id_profesional,
        CASE 
            WHEN NVL(SUM(
                CASE 
                    WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                         AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                    THEN a.honorario 
                    ELSE 0 
                END
            ), 0) < 1000000 THEN ROUND(p.sueldo * 1.10)
            WHEN NVL(SUM(
                CASE 
                    WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                         AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                    THEN a.honorario 
                    ELSE 0 
                END
            ), 0) >= 1000000 THEN ROUND(p.sueldo * 1.15)
            ELSE p.sueldo
        END AS nuevos_puntos
    FROM 
        profesional p
        LEFT JOIN asesoria a ON p.id_profesional = a.id_profesional
    GROUP BY 
        p.id_profesional, 
        p.sueldo
) datos_actualizados
ON (rcap.id_profesional = datos_actualizados.id_profesional)
WHEN MATCHED THEN
    UPDATE SET rcap.puntos = datos_actualizados.nuevos_puntos;

-- Si no existe la tabla RESUMEN_COMPRA_AVANCE_PUNTOS, crearla e insertar datos
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE RESUMEN_COMPRA_AVANCE_PUNTOS (
        id_profesional NUMBER(10) PRIMARY KEY,
        puntos NUMBER(10)
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END;

INSERT INTO RESUMEN_COMPRA_AVANCE_PUNTOS (id_profesional, puntos)
SELECT 
    p.id_profesional,
    CASE 
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) < 1000000 THEN ROUND(p.sueldo * 1.10)
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) >= 1000000 THEN ROUND(p.sueldo * 1.15)
        ELSE p.sueldo
    END AS puntos
FROM 
    profesional p
    LEFT JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM RESUMEN_COMPRA_AVANCE_PUNTOS rcap 
        WHERE rcap.id_profesional = p.id_profesional
    )
GROUP BY 
    p.id_profesional, 
    p.sueldo;

CREATE TABLE REPORTE_DESPUES_ACTUALIZACION AS
SELECT 
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    pr.nombre_profesion AS profesion,
    NVL(ROUND(SUM(
        CASE 
            WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                 AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
            THEN a.honorario 
            ELSE 0 
        END
    )), 0) AS total_honorarios_marzo,
    p.sueldo AS sueldo_original,
    rcap.puntos AS sueldo_actualizado,
    CASE 
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) < 1000000 THEN '10%'
        WHEN NVL(SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 
                     AND EXTRACT(MONTH FROM a.fin_asesoria) = 3 
                THEN a.honorario 
                ELSE 0 
            END
        ), 0) >= 1000000 THEN '15%'
        ELSE '0%'
    END AS porcentaje_aplicado,
    ROUND(rcap.puntos - p.sueldo) AS incremento_aplicado
FROM 
    profesional p
    INNER JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
    LEFT JOIN asesoria a ON p.id_profesional = a.id_profesional
    INNER JOIN RESUMEN_COMPRA_AVANCE_PUNTOS rcap ON p.id_profesional = rcap.id_profesional
GROUP BY 
    p.id_profesional, 
    p.appaterno, 
    p.apmaterno, 
    p.nombre, 
    pr.nombre_profesion, 
    p.sueldo, 
    rcap.puntos
ORDER BY 
    p.id_profesional;


SELECT 
    'ANTES' AS periodo,
    COUNT(*) AS total_profesionales,
    SUM(a.sueldo_actual) AS total_sueldos,
    ROUND(AVG(a.sueldo_actual)) AS promedio_sueldo
FROM REPORTE_ANTES_ACTUALIZACION a
UNION ALL
SELECT 
    'DESPUES' AS periodo,
    COUNT(*) AS total_profesionales,
    SUM(d.sueldo_actualizado) AS total_sueldos,
    ROUND(AVG(d.sueldo_actualizado)) AS promedio_sueldo
FROM REPORTE_DESPUES_ACTUALIZACION d;

/* ---- VER DETALLE DE LOS CAMBIOS ---- */
SELECT * FROM REPORTE_ANTES_ACTUALIZACION;
SELECT * FROM REPORTE_DESPUES_ACTUALIZACION;