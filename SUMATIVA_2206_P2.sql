--Actividad sumativa 2 bloque aninimo complejo--
DECLARE
    -- Variables BIND --
    v_anio_ejecucion NUMBER := :p_anio_ejecucion;
    
    -- Variables de control --
    v_anio_procesar NUMBER;
    v_total_registros NUMBER := 0;
    v_contador_iteraciones NUMBER := 0;
    
    -- Variables para cálculos --
    v_monto_total_transaccion NUMBER;
    v_aporte_sbif NUMBER;
    v_porcentaje_aporte NUMBER;
    
    -- Registro PL/SQL  --
    TYPE t_registro_detalle IS RECORD (
        numrun CLIENTE.numrun%TYPE,
        dvrun CLIENTE.dvrun%TYPE,
        pnombre CLIENTE.pnombre%TYPE,
        appaterno CLIENTE.appaterno%TYPE,
        apmaterno CLIENTE.apmaterno%TYPE,
        nro_tarjeta TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_transaccion TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        tipo_transaccion VARCHAR2(40),
        monto_transaccion TRANSACCION_TARJETA_CLIENTE.monto_transaccion%TYPE,
        monto_total_transaccion TRANSACCION_TARJETA_CLIENTE.monto_total_transaccion%TYPE
    );
    
    TYPE t_tipos_transaccion IS VARRAY(2) OF VARCHAR2(40);
    v_tipos_transaccion t_tipos_transaccion := t_tipos_transaccion('Avance en Efectivo', 'Súper Avance en Efectivo');
    
    e_anio_invalido EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_anio_invalido, -20001);
    
    e_sin_tramo EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_sin_tramo, -20002);
    
    CURSOR c_detalle_transacciones(p_anio NUMBER) IS
        SELECT 
            c.numrun,
            c.dvrun,
            c.pnombre,
            c.appaterno,
            c.apmaterno,
            tc.nro_tarjeta,
            ttc.nro_transaccion,
            ttc.fecha_transaccion,
            CASE 
                WHEN ttt.cod_tptran_tarjeta = 102 THEN 'Avance en Efectivo'
                WHEN ttt.cod_tptran_tarjeta = 103 THEN 'Súper Avance en Efectivo'
            END AS tipo_transaccion,
            ttc.monto_transaccion,
            ttc.monto_total_transaccion
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc ON tc.nro_tarjeta = ttc.nro_tarjeta
        JOIN TIPO_TRANSACCION_TARJETA ttt ON ttc.cod_tptran_tarjeta = ttt.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = p_anio
          AND ttt.cod_tptran_tarjeta IN (102, 103) -- Avance (102) y Súper Avance (103)
        ORDER BY ttc.fecha_transaccion, c.numrun;
    
    CURSOR c_resumen_transacciones(p_anio NUMBER) IS
        SELECT 
            EXTRACT(MONTH FROM ttc.fecha_transaccion) AS mes,
            EXTRACT(YEAR FROM ttc.fecha_transaccion) AS anio,
            CASE 
                WHEN ttt.cod_tptran_tarjeta = 102 THEN 'Avance en Efectivo'
                WHEN ttt.cod_tptran_tarjeta = 103 THEN 'Súper Avance en Efectivo'
            END AS tipo_transaccion,
            SUM(ttc.monto_transaccion) AS monto_transaccion,
            SUM(ttc.monto_total_transaccion) AS monto_total_transaccion
        FROM TRANSACCION_TARJETA_CLIENTE ttc
        JOIN TIPO_TRANSACCION_TARJETA ttt ON ttc.cod_tptran_tarjeta = ttt.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = p_anio
          AND ttt.cod_tptran_tarjeta IN (102, 103)
        GROUP BY 
            EXTRACT(MONTH FROM ttc.fecha_transaccion),
            EXTRACT(YEAR FROM ttc.fecha_transaccion),
            ttt.cod_tptran_tarjeta
        ORDER BY 
            EXTRACT(YEAR FROM ttc.fecha_transaccion),
            EXTRACT(MONTH FROM ttc.fecha_transaccion),
            ttt.cod_tptran_tarjeta;
    
    -- Variables de registro --
    v_reg_detalle t_registro_detalle;
    v_mes_resumen NUMBER;
    v_anio_resumen NUMBER;
    v_tipo_resumen VARCHAR2(40);
    v_monto_trans_resumen NUMBER;
    v_monto_total_resumen NUMBER;
    
BEGIN

    IF v_anio_ejecucion IS NULL OR v_anio_ejecucion < 2015 THEN
        RAISE e_anio_invalido;
    END IF;
    

    v_anio_procesar := v_anio_ejecucion - 1;
    
    DBMS_OUTPUT.PUT_LINE('=== INICIO PROCESO ===');
    DBMS_OUTPUT.PUT_LINE('Año de ejecución: ' || v_anio_ejecucion);
    DBMS_OUTPUT.PUT_LINE('Año a procesar: ' || v_anio_procesar);
    

    DBMS_OUTPUT.PUT_LINE('Truncando tablas de destino...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';
    DBMS_OUTPUT.PUT_LINE('Tablas truncadas exitosamente.');
    

    DBMS_OUTPUT.PUT_LINE('Iniciando procesamiento de detalles...');
    
    OPEN c_detalle_transacciones(v_anio_procesar);
    
    LOOP
        FETCH c_detalle_transacciones INTO 
            v_reg_detalle.numrun,
            v_reg_detalle.dvrun,
            v_reg_detalle.pnombre,
            v_reg_detalle.appaterno,
            v_reg_detalle.apmaterno,
            v_reg_detalle.nro_tarjeta,
            v_reg_detalle.nro_transaccion,
            v_reg_detalle.fecha_transaccion,
            v_reg_detalle.tipo_transaccion,
            v_reg_detalle.monto_transaccion,
            v_reg_detalle.monto_total_transaccion;
        
        EXIT WHEN c_detalle_transacciones%NOTFOUND;
        
        v_contador_iteraciones := v_contador_iteraciones + 1;
        
       
        v_monto_total_transaccion := v_reg_detalle.monto_total_transaccion;
        

        BEGIN
            SELECT porc_aporte_sbif 
            INTO v_porcentaje_aporte
            FROM TRAMO_APORTE_SBIF
            WHERE v_monto_total_transaccion BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;
     
            v_aporte_sbif := ROUND(v_monto_total_transaccion * v_porcentaje_aporte / 100);
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              
                RAISE e_sin_tramo;
        END;
        
       
        INSERT INTO DETALLE_APORTE_SBIF (
            numrun, 
            dvrun, 
            nro_tarjeta, 
            nro_transaccion,
            fecha_transaccion, 
            tipo_transaccion, 
            monto_transaccion, 
            aporte_sbif
        ) VALUES (
            v_reg_detalle.numrun,
            v_reg_detalle.dvrun,
            v_reg_detalle.nro_tarjeta,
            v_reg_detalle.nro_transaccion,
            v_reg_detalle.fecha_transaccion,
            v_reg_detalle.tipo_transaccion,
            v_reg_detalle.monto_transaccion,
            v_aporte_sbif
        );
        
       
        IF MOD(v_contador_iteraciones, 100) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Procesados ' || v_contador_iteraciones || ' registros...');
        END IF;
        
    END LOOP;
    
    CLOSE c_detalle_transacciones;
    
    DBMS_OUTPUT.PUT_LINE('Total registros procesados en detalle: ' || v_contador_iteraciones);
    

    DBMS_OUTPUT.PUT_LINE('Iniciando procesamiento de resumen...');
    
    OPEN c_resumen_transacciones(v_anio_procesar);
    
    LOOP
        FETCH c_resumen_transacciones INTO 
            v_mes_resumen,
            v_anio_resumen,
            v_tipo_resumen,
            v_monto_trans_resumen,
            v_monto_total_resumen;
        
        EXIT WHEN c_resumen_transacciones%NOTFOUND;
        

        v_aporte_sbif := 0;
        

        SELECT NVL(SUM(aporte_sbif), 0)
        INTO v_aporte_sbif
        FROM DETALLE_APORTE_SBIF
        WHERE EXTRACT(MONTH FROM fecha_transaccion) = v_mes_resumen
          AND EXTRACT(YEAR FROM fecha_transaccion) = v_anio_resumen
          AND tipo_transaccion = v_tipo_resumen;
        
        
        INSERT INTO RESUMEN_APORTE_SBIF (
            mes_anno,
            tipo_transaccion,
            monto_total_transacciones,
            aporte_total_abif
        ) VALUES (
            LPAD(v_mes_resumen, 2, '0') || v_anio_resumen,
            v_tipo_resumen,
            v_monto_total_resumen,
            v_aporte_sbif
        );
        
    END LOOP;
    
    CLOSE c_resumen_transacciones;
    
    DBMS_OUTPUT.PUT_LINE('Resumen procesado exitosamente.');
    

    SELECT COUNT(*) INTO v_total_registros
    FROM DETALLE_APORTE_SBIF;
    
    DBMS_OUTPUT.PUT_LINE('=== VERIFICACIÓN FINAL ===');
    DBMS_OUTPUT.PUT_LINE('Registros en DETALLE_APORTE_SBIF: ' || v_total_registros);
    DBMS_OUTPUT.PUT_LINE('Iteraciones realizadas: ' || v_contador_iteraciones);
    

    v_contador_iteraciones := c_resumen_transacciones%ROWCOUNT;
    
   
    IF v_contador_iteraciones = v_total_registros AND v_contador_iteraciones > 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Transacción confirmada exitosamente.');
        DBMS_OUTPUT.PUT_LINE('Registros en RESUMEN_APORTE_SBIF: ' || v_contador_iteraciones);
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Validación fallida.');
        DBMS_OUTPUT.PUT_LINE('Iteraciones: ' || v_contador_iteraciones || ' vs Registros: ' || v_total_registros);
        DBMS_OUTPUT.PUT_LINE('Transacción revertida.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('=== FIN DEL PROCESO ===');
    
EXCEPTION

    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontraron datos para procesar.');
        DBMS_OUTPUT.PUT_LINE('Año procesado: ' || v_anio_procesar);
        ROLLBACK;
    
    
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: Se encontraron múltiples tramos para el mismo monto.');
        DBMS_OUTPUT.PUT_LINE('Verificar la tabla TRAMO_APORTE_SBIF.');
        ROLLBACK;
    

    WHEN e_anio_invalido THEN
        DBMS_OUTPUT.PUT_LINE('Error: Año de ejecución inválido.');
        DBMS_OUTPUT.PUT_LINE('El año debe ser mayor o igual a 2015 (año de creación de la empresa).');
        DBMS_OUTPUT.PUT_LINE('Año ingresado: ' || NVL(TO_CHAR(v_anio_ejecucion), 'NULL'));
        ROLLBACK;
    

    WHEN e_sin_tramo THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró tramo para el monto: ' || v_monto_total_transaccion);
        DBMS_OUTPUT.PUT_LINE('Verificar rangos en tabla TRAMO_APORTE_SBIF.');
        ROLLBACK;
    
    -- Excepcion --
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Código de error: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('En el registro: ' || v_contador_iteraciones);
        ROLLBACK;
        
END;
/