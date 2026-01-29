-- Caso 1 - 
-- Bloque PL/SQL anónimo --
DECLARE
    -- Variables para parámetros del año
    v_año_anterior NUMBER := EXTRACT(YEAR FROM SYSDATE) - 1;
    v_fecha_inicio DATE := TO_DATE('01/01/' || v_año_anterior, 'DD/MM/YYYY');
    v_fecha_fin DATE := TO_DATE('31/12/' || v_año_anterior, 'DD/MM/YYYY');
    
    -- Variables --
    v_puntos_normales NUMBER;
    v_puntos_totales NUMBER;
    v_monto_anual_cliente NUMBER;
    
    v_tipo_transaccion VARCHAR2(40);
    v_cod_tipo_cliente NUMBER;
    v_nombre_tipo_cliente VARCHAR2(30);
    
    v_mes_anno VARCHAR2(6);
    v_monto_total_compras NUMBER := 0;
    v_total_puntos_compras NUMBER := 0;
    v_monto_total_avances NUMBER := 0;
    v_total_puntos_avances NUMBER := 0;
    v_monto_total_savances NUMBER := 0;
    v_total_puntos_savances NUMBER := 0;
    v_mes_actual VARCHAR2(6);
    
    TYPE t_puntos_extras IS VARRAY(4) OF NUMBER;
    v_puntos_extras t_puntos_extras := t_puntos_extras(300, 550, 700, 250);
    
    v_tramo1_inf NUMBER := 500000;
    v_tramo1_sup NUMBER := 700000;
    v_tramo2_inf NUMBER := 700001;
    v_tramo2_sup NUMBER := 900000;
    v_tramo3_inf NUMBER := 900001;
    v_tramo3_sup NUMBER := 999999999;
    
    -- Registro PL/SQL para detalle de transacciones --
    TYPE r_detalle_transaccion IS RECORD (
        numrun CLIENTE.numrun%TYPE,
        dvrun CLIENTE.dvrun%TYPE,
        nro_tarjeta TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_transaccion TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        monto_transaccion TRANSACCION_TARJETA_CLIENTE.monto_transaccion%TYPE,
        cod_tptran_tarjeta TRANSACCION_TARJETA_CLIENTE.cod_tptran_tarjeta%TYPE,
        cod_tipo_cliente CLIENTE.cod_tipo_cliente%TYPE
    );
    
    v_detalle r_detalle_transaccion;
    
    -- Variable de cursor --
    CURSOR c_tipos_transaccion IS
        SELECT cod_tptran_tarjeta, nombre_tptran_tarjeta
        FROM TIPO_TRANSACCION_TARJETA;
    
    CURSOR c_transacciones_año(p_fecha_inicio DATE, p_fecha_fin DATE) IS
        SELECT c.numrun, c.dvrun, tc.nro_tarjeta, ttc.nro_transaccion,
               ttc.fecha_transaccion, ttc.monto_transaccion,
               ttc.cod_tptran_tarjeta, c.cod_tipo_cliente
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc ON tc.nro_tarjeta = ttc.nro_tarjeta
        WHERE ttc.fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;
    
    CURSOR c_monto_anual_cliente(p_numrun CLIENTE.numrun%TYPE, 
                                 p_cod_tipo_cliente CLIENTE.cod_tipo_cliente%TYPE) IS
        SELECT SUM(ttc.monto_transaccion) as monto_anual
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc ON tc.nro_tarjeta = ttc.nro_tarjeta
        WHERE c.numrun = p_numrun
          AND c.cod_tipo_cliente = p_cod_tipo_cliente
          AND EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_año_anterior;
    
    v_contador_transacciones NUMBER := 0;
    
BEGIN
   
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('INICIO PROCESO CALCULO PUNTOS CATB');
    DBMS_OUTPUT.PUT_LINE('Año procesado: ' || v_año_anterior);
    DBMS_OUTPUT.PUT_LINE('Fecha inicio: ' || TO_CHAR(v_fecha_inicio, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Fecha fin: ' || TO_CHAR(v_fecha_fin, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    
    DBMS_OUTPUT.PUT_LINE('TRUNCANDO tablas de resultados...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_PUNTOS_TARJETA_CATB';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_PUNTOS_TARJETA_CATB';
    DBMS_OUTPUT.PUT_LINE('Tablas truncadas exitosamente.');
    
  
    v_mes_actual := NULL;
    
   
    DBMS_OUTPUT.PUT_LINE('Procesando transacciones del año ' || v_año_anterior || '...');
    
  
    OPEN c_transacciones_año(v_fecha_inicio, v_fecha_fin);
    
    LOOP
        FETCH c_transacciones_año INTO v_detalle;
        EXIT WHEN c_transacciones_año%NOTFOUND;
        
        v_contador_transacciones := v_contador_transacciones + 1;
        
       
        BEGIN
            SELECT nombre_tptran_tarjeta INTO v_tipo_transaccion
            FROM TIPO_TRANSACCION_TARJETA
            WHERE cod_tptran_tarjeta = v_detalle.cod_tptran_tarjeta;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tipo_transaccion := 'DESCONOCIDO';
        END;
        
       
        v_cod_tipo_cliente := v_detalle.cod_tipo_cliente;
        
        
        v_monto_anual_cliente := 0;
        IF v_cod_tipo_cliente IN (30, 40) THEN -- 30: Dueña de Casa, 40: Pensionados/Tercera Edad
            OPEN c_monto_anual_cliente(v_detalle.numrun, v_cod_tipo_cliente);
            FETCH c_monto_anual_cliente INTO v_monto_anual_cliente;
            CLOSE c_monto_anual_cliente;
            
          
            IF v_monto_anual_cliente IS NULL THEN
                v_monto_anual_cliente := 0;
            END IF;
        END IF;
        
        
        v_puntos_normales := 0;
        IF v_detalle.monto_transaccion > 0 THEN
            v_puntos_normales := FLOOR(v_detalle.monto_transaccion / 100000) * v_puntos_extras(4);
        END IF;
        
        -- Inicializar puntos totales --
        v_puntos_totales := v_puntos_normales;
        

        IF v_cod_tipo_cliente IN (30, 40) THEN
            IF v_monto_anual_cliente BETWEEN v_tramo1_inf AND v_tramo1_sup THEN
            
                v_puntos_totales := v_puntos_totales + 
                    (FLOOR(v_detalle.monto_transaccion / 100000) * v_puntos_extras(1));
            ELSIF v_monto_anual_cliente BETWEEN v_tramo2_inf AND v_tramo2_sup THEN
           
                v_puntos_totales := v_puntos_totales + 
                    (FLOOR(v_detalle.monto_transaccion / 100000) * v_puntos_extras(2));
            ELSIF v_monto_anual_cliente >= v_tramo3_inf THEN
            
                v_puntos_totales := v_puntos_totales + 
                    (FLOOR(v_detalle.monto_transaccion / 100000) * v_puntos_extras(3));
            END IF;
        END IF;
        

        INSERT INTO DETALLE_PUNTOS_TARJETA_CATB (
            numrun, dvrun, nro_tarjeta, nro_transaccion,
            fecha_transaccion, tipo_transaccion,
            monto_transaccion, puntos_allthebest
        ) VALUES (
            v_detalle.numrun, v_detalle.dvrun, v_detalle.nro_tarjeta, 
            v_detalle.nro_transaccion, v_detalle.fecha_transaccion,
            v_tipo_transaccion, v_detalle.monto_transaccion,
            v_puntos_totales
        );
        

        v_mes_anno := TO_CHAR(v_detalle.fecha_transaccion, 'MM') || 
                     TO_CHAR(v_detalle.fecha_transaccion, 'YYYY');
        

        IF v_mes_actual IS NULL THEN
            v_mes_actual := v_mes_anno;
        ELSIF v_mes_actual != v_mes_anno THEN
        
            INSERT INTO RESUMEN_PUNTOS_TARJETA_CATB (
                mes_anno, monto_total_compras, total_puntos_compras,
                monto_total_avances, total_puntos_avances,
                monto_total_savances, total_puntos_savances
            ) VALUES (
                v_mes_actual, v_monto_total_compras, v_total_puntos_compras,
                v_monto_total_avances, v_total_puntos_avances,
                v_monto_total_savances, v_total_puntos_savances
            );
            
   
            v_mes_actual := v_mes_anno;
            v_monto_total_compras := 0;
            v_total_puntos_compras := 0;
            v_monto_total_avances := 0;
            v_total_puntos_avances := 0;
            v_monto_total_savances := 0;
            v_total_puntos_savances := 0;
        END IF;
        
    
        CASE v_detalle.cod_tptran_tarjeta
            WHEN 101 THEN 
                v_monto_total_compras := v_monto_total_compras + v_detalle.monto_transaccion;
                v_total_puntos_compras := v_total_puntos_compras + v_puntos_totales;
            WHEN 102 THEN 
                v_monto_total_avances := v_monto_total_avances + v_detalle.monto_transaccion;
                v_total_puntos_avances := v_total_puntos_avances + v_puntos_totales;
            WHEN 103 THEN 
                v_monto_total_savances := v_monto_total_savances + v_detalle.monto_transaccion;
                v_total_puntos_savances := v_total_puntos_savances + v_puntos_totales;
            ELSE
                DBMS_OUTPUT.PUT_LINE('Tipo de transacción no reconocido: ' || v_detalle.cod_tptran_tarjeta);
        END CASE;
        
     
        IF MOD(v_contador_transacciones, 1000) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Procesadas ' || v_contador_transacciones || ' transacciones...');
        END IF;
        
    END LOOP;
    
    CLOSE c_transacciones_año;
    
  
    IF v_mes_actual IS NOT NULL THEN
        INSERT INTO RESUMEN_PUNTOS_TARJETA_CATB (
            mes_anno, monto_total_compras, total_puntos_compras,
            monto_total_avances, total_puntos_avances,
            monto_total_savances, total_puntos_savances
        ) VALUES (
            v_mes_actual, v_monto_total_compras, v_total_puntos_compras,
            v_monto_total_avances, v_total_puntos_avances,
            v_monto_total_savances, v_total_puntos_savances
        );
    END IF;
    
   
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('PROCESO COMPLETADO EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('Total transacciones procesadas: ' || v_contador_transacciones);
    DBMS_OUTPUT.PUT_LINE('Último mes procesado: ' || NVL(v_mes_actual, 'N/A'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('ERROR EN EL PROCESO');
        DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Transacciones procesadas: ' || v_contador_transacciones);
        DBMS_OUTPUT.PUT_LINE('========================================');
        ROLLBACK;
        RAISE;
END;
/

-- Caso 2 --
-- Bloque PL/SQL anónimo para procesar transacciones del año actual --
DECLARE
    -- Variables --
    v_año_actual NUMBER := EXTRACT(YEAR FROM SYSDATE);
    v_fecha_inicio DATE := TO_DATE('01/01/' || v_año_actual, 'DD/MM/YYYY');
    v_fecha_fin DATE := TO_DATE('31/12/' || v_año_actual, 'DD/MM/YYYY');
    
    v_monto_total_transaccion NUMBER;
    v_aporte_sbif NUMBER;
    v_porcentaje_aporte NUMBER;
    
    v_tipo_transaccion VARCHAR2(40);
    v_nombre_tipo_cliente VARCHAR2(30);
    
    v_mes_anno VARCHAR2(6);
    
    TYPE r_detalle_transaccion IS RECORD (
        numrun CLIENTE.numrun%TYPE,
        dvrun CLIENTE.dvrun%TYPE,
        nro_tarjeta TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_transaccion TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        monto_transaccion TRANSACCION_TARJETA_CLIENTE.monto_transaccion%TYPE,
        monto_total_transaccion TRANSACCION_TARJETA_CLIENTE.monto_total_transaccion%TYPE,
        cod_tptran_tarjeta TRANSACCION_TARJETA_CLIENTE.cod_tptran_tarjeta%TYPE
    );
    
    v_detalle r_detalle_transaccion;
    
    -- Cursor explícito --
    CURSOR c_transacciones_avances(p_fecha_inicio DATE, p_fecha_fin DATE) IS
        SELECT c.numrun, c.dvrun, tc.nro_tarjeta, ttc.nro_transaccion,
               ttc.fecha_transaccion, ttc.monto_transaccion,
               ttc.monto_total_transaccion, ttc.cod_tptran_tarjeta
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc ON tc.nro_tarjeta = ttc.nro_tarjeta
        WHERE ttc.fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin
          AND ttc.cod_tptran_tarjeta IN (102, 103) 
        ORDER BY ttc.fecha_transaccion, c.numrun;
    

    CURSOR c_porcentaje_aporte(p_monto_total NUMBER) IS
        SELECT porc_aporte_sbif
        FROM TRAMO_APORTE_SBIF
        WHERE p_monto_total BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;
    

    TYPE t_resumen IS TABLE OF RESUMEN_APORTE_SBIF%ROWTYPE INDEX BY VARCHAR2(50);
    v_resumenes t_resumen;
    v_clave_resumen VARCHAR2(50);
    

    v_contador_transacciones NUMBER := 0;
    
BEGIN

    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('INICIO PROCESO CALCULO APORTE SBIF');
    DBMS_OUTPUT.PUT_LINE('Año procesado: ' || v_año_actual);
    DBMS_OUTPUT.PUT_LINE('Fecha inicio: ' || TO_CHAR(v_fecha_inicio, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Fecha fin: ' || TO_CHAR(v_fecha_fin, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    

    DBMS_OUTPUT.PUT_LINE('TRUNCANDO tablas de resultados...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';
    DBMS_OUTPUT.PUT_LINE('Tablas truncadas exitosamente.');
    
 
    v_resumenes.DELETE;
    
   
    DBMS_OUTPUT.PUT_LINE('Procesando avances y súper avances del año ' || v_año_actual || '...');
    
 
    OPEN c_transacciones_avances(v_fecha_inicio, v_fecha_fin);
    
    LOOP
        FETCH c_transacciones_avances INTO v_detalle;
        EXIT WHEN c_transacciones_avances%NOTFOUND;
        
        v_contador_transacciones := v_contador_transacciones + 1;
        
      
        BEGIN
            SELECT nombre_tptran_tarjeta INTO v_tipo_transaccion
            FROM TIPO_TRANSACCION_TARJETA
            WHERE cod_tptran_tarjeta = v_detalle.cod_tptran_tarjeta;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tipo_transaccion := 'DESCONOCIDO';
        END;
        
    
        v_monto_total_transaccion := v_detalle.monto_total_transaccion;
        
      
        v_porcentaje_aporte := 0;
        OPEN c_porcentaje_aporte(v_monto_total_transaccion);
        FETCH c_porcentaje_aporte INTO v_porcentaje_aporte;
        IF c_porcentaje_aporte%NOTFOUND THEN
         
            v_porcentaje_aporte := 0;
        END IF;
        CLOSE c_porcentaje_aporte;
        
      
        v_aporte_sbif := ROUND(v_monto_total_transaccion * (v_porcentaje_aporte / 100));
        
     
        INSERT INTO DETALLE_APORTE_SBIF (
            numrun, dvrun, nro_tarjeta, nro_transaccion,
            fecha_transaccion, tipo_transaccion,
            monto_transaccion, aporte_sbif
        ) VALUES (
            v_detalle.numrun, v_detalle.dvrun, v_detalle.nro_tarjeta, 
            v_detalle.nro_transaccion, v_detalle.fecha_transaccion,
            v_tipo_transaccion, v_monto_total_transaccion,
            v_aporte_sbif
        );
        
    
        v_mes_anno := TO_CHAR(v_detalle.fecha_transaccion, 'MM') || 
                     TO_CHAR(v_detalle.fecha_transaccion, 'YYYY');
        v_clave_resumen := v_mes_anno || '|' || v_tipo_transaccion;
        
       
        IF NOT v_resumenes.EXISTS(v_clave_resumen) THEN
            -- Inicializar nuevo resumen
            v_resumenes(v_clave_resumen).mes_anno := v_mes_anno;
            v_resumenes(v_clave_resumen).tipo_transaccion := v_tipo_transaccion;
            v_resumenes(v_clave_resumen).monto_total_transacciones := v_monto_total_transaccion;
            v_resumenes(v_clave_resumen).aporte_total_abif := v_aporte_sbif;
        ELSE
           
            v_resumenes(v_clave_resumen).monto_total_transacciones := 
                v_resumenes(v_clave_resumen).monto_total_transacciones + v_monto_total_transaccion;
            v_resumenes(v_clave_resumen).aporte_total_abif := 
                v_resumenes(v_clave_resumen).aporte_total_abif + v_aporte_sbif;
        END IF;
        
       
        IF MOD(v_contador_transacciones, 500) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Procesadas ' || v_contador_transacciones || ' transacciones...');
        END IF;
        
    END LOOP;
    
    CLOSE c_transacciones_avances;
    
   
    DBMS_OUTPUT.PUT_LINE('Insertando ' || v_resumenes.COUNT || ' registros de resumen...');
    
    v_clave_resumen := v_resumenes.FIRST;
    WHILE v_clave_resumen IS NOT NULL LOOP
        INSERT INTO RESUMEN_APORTE_SBIF (
            mes_anno, tipo_transaccion,
            monto_total_transacciones, aporte_total_abif
        ) VALUES (
            v_resumenes(v_clave_resumen).mes_anno,
            v_resumenes(v_clave_resumen).tipo_transaccion,
            v_resumenes(v_clave_resumen).monto_total_transacciones,
            v_resumenes(v_clave_resumen).aporte_total_abif
        );
        
        v_clave_resumen := v_resumenes.NEXT(v_clave_resumen);
    END LOOP;
    

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('PROCESO COMPLETADO EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('Total transacciones procesadas: ' || v_contador_transacciones);
    DBMS_OUTPUT.PUT_LINE('Total registros de resumen: ' || v_resumenes.COUNT);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('ERROR EN EL PROCESO');
        DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Transacciones procesadas: ' || v_contador_transacciones);
        DBMS_OUTPUT.PUT_LINE('========================================');
        ROLLBACK;
        RAISE;
END;
/