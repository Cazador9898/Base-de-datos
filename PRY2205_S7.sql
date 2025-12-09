--Caso 1

CREATE SYNONYM trabajador_syn FOR trabajador;
CREATE SYNONYM bono_antiguedad_syn FOR bono_antiguedad;
CREATE SYNONYM tickets_concierto_syn FOR tickets_concierto;

INSERT INTO DETALLE_BONIFICACIONES_TRABAJADOR (num, rut, nombre_trabajador, sueldo_base, num_ticket, direccion, sistema_salud, monto, bonif_x_ticket, simulacion_x_ticket, simulacion_antiguedad)
SELECT 
    seq_det_bonif.NEXTVAL AS num,
    datos.*
FROM (
    SELECT 
        t.numrut || '-' || t.dvrut AS rut,
        t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno AS nombre_trabajador,
        TO_CHAR(t.sueldo_base, '999,999,999') AS sueldo_base,
        NVL(TO_CHAR(MIN(tc.nro_ticket)), 'Sin ticket') AS num_ticket,
        t.direccion AS direccion,
        i.nombre_isapre AS sistema_salud,
        NVL(TO_CHAR(SUM(tc.monto_ticket), '999,999,999'), 'No hay info') AS monto,
        NVL(
            CASE 
                WHEN SUM(tc.monto_ticket) <= 50000 THEN '0%'
                WHEN SUM(tc.monto_ticket) > 50000 AND SUM(tc.monto_ticket) <= 100000 THEN '5%'
                WHEN SUM(tc.monto_ticket) > 100000 THEN '7%'
            END, 'No hay info'
        ) AS bonif_x_ticket,
        TO_CHAR(
            t.sueldo_base + 
            NVL(
                CASE 
                    WHEN SUM(tc.monto_ticket) <= 50000 THEN 0
                    WHEN SUM(tc.monto_ticket) > 50000 AND SUM(tc.monto_ticket) <= 100000 THEN t.sueldo_base * 0.05
                    WHEN SUM(tc.monto_ticket) > 100000 THEN t.sueldo_base * 0.07
                END, 0
            ), '999,999,999'
        ) AS simulacion_x_ticket,
        TO_CHAR(
            t.sueldo_base * (1 + NVL(ba.porcentaje, 0)), '999,999,999'
        ) AS simulacion_antiguedad
    FROM 
        trabajador_syn t
        JOIN isapre i ON t.cod_isapre = i.cod_isapre
        LEFT JOIN tickets_concierto_syn tc ON t.numrut = tc.numrut_t
        LEFT JOIN bono_antiguedad_syn ba ON 
            FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) BETWEEN ba.limite_inferior AND ba.limite_superior
    WHERE 
        i.porc_descto_isapre > 4
        AND (MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50
        AND t.fecnac IS NOT NULL
    GROUP BY 
        t.numrut, t.dvrut, t.nombre, t.appaterno, t.apmaterno, 
        t.sueldo_base, t.direccion, i.nombre_isapre, ba.porcentaje
    HAVING 
        SUM(NVL(tc.monto_ticket, 0)) >= 0
    ORDER BY 
        NVL(SUM(tc.monto_ticket), 0) DESC,
        t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno ASC
) datos;
COMMIT;


SELECT * FROM DETALLE_BONIFICACIONES_TRABAJADOR ORDER BY num;




--Caso 2

CREATE OR REPLACE SYNONYM sin_trab FOR trabajador;
CREATE OR REPLACE SYNONYM sin_af FOR asignacion_familiar;

CREATE OR REPLACE VIEW V_AUMENTOS_ESTUDIOS AS
SELECT 
    TO_CHAR(t.numrut, 'FM099G999G999', 'NLS_NUMERIC_CHARACTERS=,.') || '-' || t.dvrut AS RUT,
    
    INITCAP(t.appaterno) || ' ' || INITCAP(t.apmaterno) || ' ' || INITCAP(t.nombre) AS "NOMBRE COMPLETO",
    
    INITCAP(be.descrip) AS "NIVEL EDUCACIÓN",
    
    LPAD(be.porc_bono, 6, '0') || '%' AS "% BONO ESTUDIO",
    
    TO_CHAR(t.sueldo_base, 'FM999G999G999', 'NLS_NUMERIC_CHARACTERS=,.') AS "SUELDO ACTUAL",
    
    TO_CHAR(
        ROUND(t.sueldo_base * (be.porc_bono / 100)), 
        'FM999G999G999', 
        'NLS_NUMERIC_CHARACTERS=,.'
    ) AS "AUMENTO ESTUDIO",
    
    TO_CHAR(
        t.sueldo_base + ROUND(t.sueldo_base * (be.porc_bono / 100)), 
        'FM999G999G999', 
        'NLS_NUMERIC_CHARACTERS=,.'
    ) AS "SUELDO SIMULADO",
    
    NVL(
        (SELECT COUNT(*) 
         FROM sin_af af 
         WHERE af.numrut_t = t.numrut), 
        0
    ) AS "CARGAS FAMILIARES"

FROM sin_trab t
INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
INNER JOIN bono_escolar be ON t.id_escolaridad_t = be.id_escolar

WHERE UPPER(tt.desc_categoria) = 'CAJERO'

OR t.numrut IN (
    SELECT numrut_t
    FROM sin_af
    GROUP BY numrut_t
    HAVING COUNT(*) BETWEEN 1 AND 2
)

ORDER BY be.porc_bono ASC, 
         t.appaterno ASC, 
         t.apmaterno ASC, 
         t.nombre ASC;
         
SELECT * FROM V_AUMENTOS_ESTUDIOS;         

--etapa 2

CREATE INDEX idx_trabajador_apmaterno ON trabajador(apmaterno);

CREATE INDEX idx_trabajador_apmaterno_upper ON trabajador(UPPER(apmaterno));

SELECT index_name, index_type, uniqueness 
FROM user_indexes 
WHERE table_name = 'TRABAJADOR'
ORDER BY index_name;

SELECT index_name, column_name, column_position
FROM user_ind_columns
WHERE table_name = 'TRABAJADOR'
ORDER BY index_name, column_position;

SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno
FROM trabajador t 
JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE t.apmaterno = 'CASTILLO'
ORDER BY 3;

SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno
FROM trabajador t 
JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE UPPER(t.apmaterno) = 'CASTILLO'
ORDER BY 3;

EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'TRABAJADOR', cascade => TRUE);