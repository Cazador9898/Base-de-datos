CREATE SEQUENCE SEQ_CONTROL_STOCK
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

INSERT INTO CONTROL_STOCK_LIBROS
SELECT
    ROW_NUMBER() OVER (ORDER BY libroid) AS correlativo,
    fecha_proceso,
    libroid,
    nombre_libro,
    total_ejemplares,
    ejemplares_prestados,
    ejemplares_disponibles,
    porcentaje_prestamo,
    stock_critico
FROM (
    SELECT
        TO_CHAR(ADD_MONTHS(SYSDATE, -24), 'MM/YYYY') AS fecha_proceso,
        l.libroid,
        l.nombre_libro,
        COUNT(DISTINCT e.ejemplarid) AS total_ejemplares,
        COUNT(DISTINCT p.ejemplarid) AS ejemplares_prestados,
        COUNT(DISTINCT e.ejemplarid) - COUNT(DISTINCT p.ejemplarid) AS ejemplares_disponibles,
        ROUND((COUNT(DISTINCT p.ejemplarid) / NULLIF(COUNT(DISTINCT e.ejemplarid), 0)) * 100, 2) AS porcentaje_prestamo,
        CASE
            WHEN COUNT(DISTINCT e.ejemplarid) - COUNT(DISTINCT p.ejemplarid) > 2 THEN 'S'
            ELSE 'N'
        END AS stock_critico
    FROM libro l
    JOIN ejemplar e ON l.libroid = e.libroid
    LEFT JOIN prestamo p ON e.libroid = p.libroid 
        AND e.ejemplarid = p.ejemplarid
        AND EXTRACT(YEAR FROM p.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
        AND p.empleadoid IN (190, 180, 150)
        AND p.fecha_inicio >= TRUNC(ADD_MONTHS(SYSDATE, -24), 'YEAR')
        AND p.fecha_inicio < TRUNC(ADD_MONTHS(SYSDATE, -12), 'YEAR')
    GROUP BY l.libroid, l.nombre_libro
);

COMMIT;