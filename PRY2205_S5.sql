--Caso 1

SELECT 
    c.numrun AS "Rut Cliente",
    c.dvrun AS "Dv",
    c.pnombre || ' ' || 
    NVL(c.snombre, '') || ' ' || 
    c.appaterno || ' ' || 
    NVL(c.apmaterno, '') AS "Nombre Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD/MM/YYYY') AS "Fecha Inscripcion",
    tc.nombre_tipo_cliente AS "Tipo Cliente",
    po.nombre_prof_ofic AS "Profesion Oficio"
FROM cliente c
INNER JOIN tipo_cliente tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente
INNER JOIN profesion_oficio po ON c.cod_prof_ofic = po.cod_prof_ofic
WHERE tc.nombre_tipo_cliente = 'Trabajadores dependientes'
    AND po.nombre_prof_ofic IN ('Contador', 'Vendedor')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) > (
        SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
        FROM cliente
    )
ORDER BY c.numrun ASC;

--Caso 2

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT 
    c.numrun AS "Rut Cliente",
    c.dvrun AS "Dv",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento) AS "Edad",
    tc.cupo_disp_compra AS "Cupo Disp. Compra"
FROM cliente c
INNER JOIN tarjeta_cliente tc ON c.numrun = tc.numrun
WHERE 1 = 0;

INSERT INTO CLIENTES_CUPOS_COMPRA
SELECT 
    c.numrun AS "Rut Cliente",
    c.dvrun AS "Dv",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento) AS "Edad",
    tc.cupo_disp_compra AS "Cupo Disp. Compra"
FROM cliente c
INNER JOIN tarjeta_cliente tc ON c.numrun = tc.numrun
WHERE tc.cupo_disp_compra >= (
    SELECT MAX(tc2.cupo_disp_compra)
    FROM tarjeta_cliente tc2
    INNER JOIN cliente c2 ON tc2.numrun = c2.numrun
    WHERE EXTRACT(YEAR FROM c2.fecha_inscripcion) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY "Edad" ASC;

SELECT 
    "Rut Cliente",
    "Dv",
    "Edad",
    "Cupo Disp. Compra"
FROM CLIENTES_CUPOS_COMPRA
ORDER BY "Edad" ASC;
