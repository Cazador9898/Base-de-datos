-- CASO 1
SELECT 

    SUBSTR(TO_CHAR("NUMRUT_CLI"), 1, 2) || '.' || 
    SUBSTR(TO_CHAR("NUMRUT_CLI"), 3, 3) || '.' || 
    SUBSTR(TO_CHAR("NUMRUT_CLI"), 6, 3) || '-' || 
    SUBSTR(TO_CHAR("NUMRUT_CLI"), 9, 1) AS "RUT_CLIENTE",
    
    TRIM("APPATERNO_CLI") || ' ' || TRIM("APMATERNO_CLI") || ' ' || TRIM("NOMBRE_CLI") AS "NOMBRE_COMPLETO",
    
    TRIM("DIRECCION_CLI") AS "DIRECCION",
    
    TO_CHAR("CELULAR_CLI") AS "CELULAR",
    
    TO_CHAR("RENTA_CLI", 'FM999,999,999') AS "RENTA",
    
    CASE 
        WHEN "RENTA_CLI" > 500000 THEN 'TRAMO 1'
        WHEN "RENTA_CLI" BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN "RENTA_CLI" BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "TRAMO_RENTABILIDAD"

FROM CLIENTE
WHERE 
    "RENTA_CLI" BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    
    AND "CELULAR_CLI" IS NOT NULL
    AND "CELULAR_CLI" != 0
    
ORDER BY TRIM("APPATERNO_CLI") || ' ' || TRIM("APMATERNO_CLI") || ' ' || TRIM("NOMBRE_CLI") ASC;

-- CASO 2

SELECT 
    s.id_sucursal AS "Código Sucursal",
    s.desc_sucursal AS "Sucursal",
    ce.desc_categoria_emp AS "Categoría Empleado",
    COUNT(e.numrut_emp) AS "Cantidad Empleados",
    TO_CHAR(ROUND(AVG(e.sueldo_emp)), 'FML999,999,999') AS "Sueldo Promedio"
FROM 
    empleado e
    JOIN sucursal s ON e.id_sucursal = s.id_sucursal
    JOIN categoria_empleado ce ON e.id_categoria_emp = ce.id_categoria_emp
GROUP BY 
    s.id_sucursal, 
    s.desc_sucursal, 
    ce.id_categoria_emp, 
    ce.desc_categoria_emp
HAVING 
    AVG(e.sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY 
    AVG(e.sueldo_emp) DESC;
    
-- Caso 3

SELECT 
    tp.desc_tipo_propiedad AS "Tipo Propiedad",
    COUNT(p.nro_propiedad) AS "Total Propiedades",
    ROUND(AVG(p.valor_arriendo), 0) AS "Promedio Arriendo",
    ROUND(AVG(p.superficie), 2) AS "Promedio Superficie",
    ROUND(AVG(p.valor_arriendo / p.superficie), 2) AS "Arriendo m2",
    CASE 
        WHEN AVG(p.valor_arriendo / p.superficie) < 5000 THEN 'Económico'
        WHEN AVG(p.valor_arriendo / p.superficie) BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END AS "Clasificación"
FROM 
    propiedad p
    JOIN tipo_propiedad tp ON p.id_tipo_propiedad = tp.id_tipo_propiedad
GROUP BY 
    tp.id_tipo_propiedad, 
    tp.desc_tipo_propiedad
HAVING 
    AVG(p.valor_arriendo / p.superficie) > 1000
ORDER BY 
    AVG(p.valor_arriendo / p.superficie) DESC;