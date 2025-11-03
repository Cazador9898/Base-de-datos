--Caso 1

SELECT 
    NUMFACTURA AS "N° Factura",
    TO_CHAR(FECHA, 'dd "de" Month YYYY') AS "Fecha Emisión",
    LPAD(RUTCLIENTE, 10, '0') AS "RUT Cliente",
    TO_CHAR(NETO, 'L999G999G999') AS "Monto Neto",
    TO_CHAR(IVA, 'L999G999G999') AS "Monto IVA",
    TO_CHAR(TOTAL, 'L999G999G999') AS "Total Factura",
    CASE 
        WHEN TOTAL <= 50000 THEN 'Bajo'
        WHEN TOTAL BETWEEN 50001 AND 100000 THEN 'Medio'
        ELSE 'Alto'
    END AS "Categoría Monto",
    CASE CODPAGO
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DEBITO'
        WHEN 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END AS "Forma de pago"
FROM FACTURA
WHERE EXTRACT(YEAR FROM FECHA) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY 
    FECHA DESC,
    NETO DESC;
    
    --Caso 2
    
    SELECT 
    RPAD(REVERSE(RUTCLIENTE), 10, '*') AS "RUT Cliente",
    
    NOMBRE AS "Nombre",
    DIRECCION AS "Dirección",
    

    NVL(TO_CHAR(TELEFONO), 'Sin teléfono') AS "Teléfono",
    NVL(TO_CHAR(CODCOMUNA), 'Sin comuna') AS "Comuna",
    NVL(MAIL, 'Correo no registrado') AS "Correo",
    

    CASE 
        WHEN MAIL IS NOT NULL THEN 
            SUBSTR(MAIL, INSTR(MAIL, '@') + 1)
        ELSE 'No aplica'
    END AS "Dominio Correo",
    
 
    TO_CHAR(CREDITO, 'L999G999G999') AS "Crédito",
    TO_CHAR(SALDO, 'L999G999G999') AS "Saldo",
    
 
    CASE 
        WHEN (SALDO / CREDITO) < 0.5 THEN 
            'Bueno - Diferencia: ' || TO_CHAR(CREDITO - SALDO, 'L999G999G999')
        WHEN (SALDO / CREDITO) BETWEEN 0.5 AND 0.8 THEN 
            'Regular - Saldo: ' || TO_CHAR(SALDO, 'L999G999G999')
        ELSE 
            'Crítico - Saldo: ' || TO_CHAR(SALDO, 'L999G999G999')
    END AS "Categoría Crédito",
    
 
    ROUND((SALDO / CREDITO) * 100, 2) || '%' AS "Porcentaje Uso"

FROM CLIENTE
WHERE ESTADO = 'A' 
  AND CREDITO > 0
ORDER BY RUTCLIENTE;


ACCEPT p_tipo_cambio NUMBER PROMPT 'Ingrese el tipo de cambio CLP: ';
ACCEPT p_umbral_bajo NUMBER PROMPT 'Ingrese el umbral bajo de stock: ';
ACCEPT p_umbral_alto NUMBER PROMPT 'Ingrese el umbral alto de stock: ';
--Caso 3

SELECT 
    CODPRODUCTO AS "Código Producto",
    DESCRIPCION AS "Descripción",
    CODUNIDAD AS "Unidad",
    CODCATEGORIA AS "Categoría",
    
 
    TO_CHAR(VUNITARIO, 'L999G999G999') AS "Valor Unitario",
    
 
    CASE 
        WHEN VALORCOMPRADOLAR IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(VALORCOMPRADOLAR, 'L999G999G990D00') || ' USD'
    END AS "Valor Compra USD",
    
 
    CASE 
        WHEN VALORCOMPRADOLAR IS NOT NULL THEN
            TO_CHAR(VALORCOMPRADOLAR * &p_tipo_cambio, 'L999G999G999') || ' CLP'
        ELSE 'No convertible'
    END AS "Valor Compra CLP",
    
   
    NVL(TO_CHAR(TOTALSTOCK), 'Nulo') AS "Stock Total",
    
  
    CASE 
        WHEN TOTALSTOCK IS NULL THEN 'Sin datos'
        WHEN TOTALSTOCK < &p_umbral_bajo THEN '¡ALERTA stock muy bajo!'
        WHEN TOTALSTOCK BETWEEN &p_umbral_bajo AND &p_umbral_alto THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS "Alerta Stock",
    
 
    CASE 
        WHEN TOTALSTOCK > 80 THEN 
            TO_CHAR(VUNITARIO * 0.10, 'L999G999G999') || ' (10%)'
        ELSE 'Sin descuento'
    END AS "Descuento Aplicable",
    
    
    CASE 
        WHEN TOTALSTOCK > 80 THEN 
            TO_CHAR(VUNITARIO * 0.90, 'L999G999G999')
        ELSE TO_CHAR(VUNITARIO, 'L999G999G999')
    END AS "Valor con Descuento",
    
    PROCEDENCIA AS "Procedencia",
    CODPAIS AS "País"

FROM PRODUCTO
WHERE UPPER(DESCRIPCION) LIKE '%ZAPATO%'
  AND UPPER(PROCEDENCIA) = 'I'
ORDER BY CODPRODUCTO;

