-- Resolucion Caso 1
VARIABLE v_numrun_cliente NUMBER
VARIABLE v_dvrun_cliente CHAR(1)
VARIABLE v_tramo1_max NUMBER
VARIABLE v_tramo2_min NUMBER
VARIABLE v_tramo2_max NUMBER
VARIABLE v_tramo3_min NUMBER
VARIABLE v_pesos_normales_por_100k NUMBER
VARIABLE v_pesos_extras_tramo1 NUMBER
VARIABLE v_pesos_extras_tramo2 NUMBER
VARIABLE v_pesos_extras_tramo3 NUMBER


EXEC :v_numrun_cliente := 12345678;
EXEC :v_dvrun_cliente := 'K';
EXEC :v_tramo1_max := 1000000;
EXEC :v_tramo2_min := 1000001;
EXEC :v_tramo2_max := 3000000;
EXEC :v_tramo3_min := 3000001;
EXEC :v_pesos_normales_por_100k := 1200;
EXEC :v_pesos_extras_tramo1 := 100;
EXEC :v_pesos_extras_tramo2 := 300;
EXEC :v_pesos_extras_tramo3 := 550;

DECLARE
    
    v_nro_cliente           CLIENTE.nro_cliente%TYPE;
    v_nombre_completo       VARCHAR2(150);
    v_tipo_cliente_desc     VARCHAR2(30);
    v_cod_tipo_cliente      CLIENTE.cod_tipo_cliente%TYPE;
    v_monto_total_creditos  NUMBER := 0;
    v_pesos_base            NUMBER := 0;
    v_pesos_extras          NUMBER := 0;
    v_pesos_totales         NUMBER := 0;
    v_anio_anterior         NUMBER;
    v_run_formateado        VARCHAR2(15);
    
BEGIN
   
    v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;
    
    DBMS_OUTPUT.PUT_LINE('=== PROCESANDO AÑO: ' || v_anio_anterior || ' ===');
    
   
    SELECT 
        c.nro_cliente,
        c.pnombre || ' ' || NVL(c.snombre, '') || ' ' || c.appaterno || ' ' || c.apmaterno,
        tc.nombre_tipo_cliente,
        c.cod_tipo_cliente,
        c.numrun || '-' || c.dvrun
    INTO 
        v_nro_cliente,
        v_nombre_completo,
        v_tipo_cliente_desc,
        v_cod_tipo_cliente,
        v_run_formateado
    FROM CLIENTE c
    INNER JOIN TIPO_CLIENTE tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente
    WHERE c.numrun = :v_numrun_cliente 
      AND c.dvrun = :v_dvrun_cliente;
    
   
    SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_creditos
    FROM CREDITO_CLIENTE cc
    WHERE cc.nro_cliente = v_nro_cliente
      AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;
    
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('RUN: ' || v_run_formateado);
    DBMS_OUTPUT.PUT_LINE('Tipo cliente: ' || v_tipo_cliente_desc);
    DBMS_OUTPUT.PUT_LINE('Monto total créditos ' || v_anio_anterior || ': $' || TO_CHAR(v_monto_total_creditos, 'FM999,999,999'));
    
  
    IF v_monto_total_creditos >= 100000 THEN
        v_pesos_base := TRUNC(v_monto_total_creditos / 100000) * :v_pesos_normales_por_100k;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Pesos base: ' || TO_CHAR(v_pesos_base, 'FM999,999,999'));
    
    
    IF v_tipo_cliente_desc = 'Trabajadores independientes' THEN
        DBMS_OUTPUT.PUT_LINE('Cliente es independiente, calculando pesos extras...');
        
        IF v_monto_total_creditos < :v_tramo1_max THEN
          
            v_pesos_extras := TRUNC(v_monto_total_creditos / 100000) * :v_pesos_extras_tramo1;
            DBMS_OUTPUT.PUT_LINE('Tramo 1 - Pesos extras: ' || TO_CHAR(v_pesos_extras, 'FM999,999,999'));
            
        ELSIF v_monto_total_creditos BETWEEN :v_tramo2_min AND :v_tramo2_max THEN
           
            v_pesos_extras := TRUNC(v_monto_total_creditos / 100000) * :v_pesos_extras_tramo2;
            DBMS_OUTPUT.PUT_LINE('Tramo 2 - Pesos extras: ' || TO_CHAR(v_pesos_extras, 'FM999,999,999'));
            
        ELSIF v_monto_total_creditos >= :v_tramo3_min THEN
            
            v_pesos_extras := TRUNC(v_monto_total_creditos / 100000) * :v_pesos_extras_tramo3;
            DBMS_OUTPUT.PUT_LINE('Tramo 3 - Pesos extras: ' || TO_CHAR(v_pesos_extras, 'FM999,999,999'));
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Cliente NO es independiente, sin pesos extras.');
    END IF;
    
 
    v_pesos_totales := v_pesos_base + v_pesos_extras;
    DBMS_OUTPUT.PUT_LINE('Pesos totales TODOSUMA: ' || TO_CHAR(v_pesos_totales, 'FM999,999,999'));
    
   
    DELETE FROM CLIENTE_TODOSUMA 
    WHERE NRO_CLIENTE = v_nro_cliente;
    
   
    INSERT INTO CLIENTE_TODOSUMA (
        NRO_CLIENTE,
        RUN_CLIENTE,
        NOMBRE_CLIENTE,
        TIPO_CLIENTE,
        MONTO_SOLIC_CREDITOS,
        MONTO_PESOS_TODOSUMA
    ) VALUES (
        v_nro_cliente,
        v_run_formateado,
        v_nombre_completo,
        v_tipo_cliente_desc,
        v_monto_total_creditos,
        v_pesos_totales
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✅ Registro insertado en CLIENTE_TODOSUMA para ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ Cliente con RUN ' || :v_numrun_cliente || '-' || :v_dvrun_cliente || ' no encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
        ROLLBACK;
END;
/
-- Resolucion Caso 2

VARIABLE v_nro_cliente_param NUMBER
VARIABLE v_nro_solic_credito_param NUMBER
VARIABLE v_cant_cuotas_postergar NUMBER


EXEC :v_nro_cliente_param := 1001; 
EXEC :v_nro_solic_credito_param := 2001;
EXEC :v_cant_cuotas_postergar := 2;

DECLARE
   
    v_tipo_credito_desc      CREDITO.nombre_credito%TYPE;
    v_cod_credito            CREDITO_CLIENTE.cod_credito%TYPE;
    v_total_cuotas_original  CREDITO_CLIENTE.total_cuotas_credito%TYPE;
    v_ultimo_nro_cuota       NUMBER;
    v_ultima_fecha_venc      DATE;
    v_ultimo_valor_cuota     NUMBER;
    v_nueva_fecha_venc       DATE;
    v_nuevo_valor_cuota      NUMBER;
    v_tasa_interes           NUMBER := 0;
    v_cuotas_permitidas      NUMBER := 0;
    v_cant_creditos_anio_ant NUMBER := 0;
    v_anio_anterior          NUMBER;
    v_i                      NUMBER := 1;
    
BEGIN

    v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;
    
    DBMS_OUTPUT.PUT_LINE('=== INICIO PROCESO POSTERGACIÓN ===');
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || :v_nro_cliente_param || ', Crédito: ' || :v_nro_solic_credito_param);
    DBMS_OUTPUT.PUT_LINE('Cuotas a postergar: ' || :v_cant_cuotas_postergar);
    DBMS_OUTPUT.PUT_LINE('Año anterior para verificación: ' || v_anio_anterior);
    
  
    SELECT COUNT(DISTINCT cc.nro_solic_credito)
    INTO v_cant_creditos_anio_ant
    FROM CREDITO_CLIENTE cc
    WHERE cc.nro_cliente = :v_nro_cliente_param
      AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;
    
    DBMS_OUTPUT.PUT_LINE('Créditos del cliente en ' || v_anio_anterior || ': ' || v_cant_creditos_anio_ant);
    
   
    SELECT 
        c.nombre_credito,
        cc.cod_credito,
        cc.total_cuotas_credito
    INTO 
        v_tipo_credito_desc,
        v_cod_credito,
        v_total_cuotas_original
    FROM CREDITO_CLIENTE cc
    INNER JOIN CREDITO c ON cc.cod_credito = c.cod_credito
    WHERE cc.nro_solic_credito = :v_nro_solic_credito_param
      AND cc.nro_cliente = :v_nro_cliente_param;
    
    DBMS_OUTPUT.PUT_LINE('Tipo de crédito: ' || v_tipo_credito_desc);
    DBMS_OUTPUT.PUT_LINE('Total cuotas originales: ' || v_total_cuotas_original);
    
 
    IF v_tipo_credito_desc = 'Crédito Hipotecario' THEN
        IF :v_cant_cuotas_postergar = 1 THEN
            v_tasa_interes := 0;
            v_cuotas_permitidas := 1;
        ELSIF :v_cant_cuotas_postergar = 2 THEN
            v_tasa_interes := 0.5;
            v_cuotas_permitidas := 2;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Crédito hipotecario solo permite 1 o 2 cuotas de postergación');
        END IF;
    ELSIF v_tipo_credito_desc = 'Crédito de Consumo' THEN
        IF :v_cant_cuotas_postergar = 1 THEN
            v_tasa_interes := 1;
            v_cuotas_permitidas := 1;
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 'Crédito de consumo solo permite 1 cuota de postergación');
        END IF;
    ELSIF v_tipo_credito_desc = 'Crédito Automotriz' THEN
        IF :v_cant_cuotas_postergar = 1 THEN
            v_tasa_interes := 2;
            v_cuotas_permitidas := 1;
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Crédito automotriz solo permite 1 cuota de postergación');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Tipo de crédito no válido para postergación: ' || v_tipo_credito_desc);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Tasa de interés aplicada: ' || v_tasa_interes || '%');
    
    
    SELECT 
        MAX(cu.nro_cuota),
        MAX(cu.fecha_venc_cuota),
        MAX(cu.valor_cuota)
    INTO 
        v_ultimo_nro_cuota,
        v_ultima_fecha_venc,
        v_ultimo_valor_cuota
    FROM CUOTA_CREDITO_CLIENTE cu
    WHERE cu.nro_solic_credito = :v_nro_solic_credito_param;
    
    DBMS_OUTPUT.PUT_LINE('Última cuota: N°' || v_ultimo_nro_cuota || ', Valor: $' || v_ultimo_valor_cuota || ', Vence: ' || TO_CHAR(v_ultima_fecha_venc, 'DD/MM/YYYY'));
    
    
    IF v_cant_creditos_anio_ant > 1 THEN
        DBMS_OUTPUT.PUT_LINE('Cliente con múltiples créditos - Condonando última cuota...');
        
        UPDATE CUOTA_CREDITO_CLIENTE
        SET fecha_pago_cuota = fecha_venc_cuota,
            monto_pagado = valor_cuota,
            saldo_por_pagar = 0
        WHERE nro_solic_credito = :v_nro_solic_credito_param
          AND nro_cuota = v_ultimo_nro_cuota;
        
        DBMS_OUTPUT.PUT_LINE('✅ Última cuota condonada exitosamente');
    END IF;
    
   
    v_nueva_fecha_venc := v_ultima_fecha_venc;
    
    FOR v_i IN 1..:v_cant_cuotas_postergar LOOP
        -- Nueva fecha: un mes después
        v_nueva_fecha_venc := ADD_MONTHS(v_nueva_fecha_venc, 1);
        
        
        IF v_tasa_interes = 0 THEN
            v_nuevo_valor_cuota := v_ultimo_valor_cuota;
        ELSE
            v_nuevo_valor_cuota := v_ultimo_valor_cuota + (v_ultimo_valor_cuota * (v_tasa_interes / 100));
        END IF;
        
       
        v_ultimo_nro_cuota := v_ultimo_nro_cuota + 1;
        
        DBMS_OUTPUT.PUT_LINE('Generando cuota ' || v_i || ':');
        DBMS_OUTPUT.PUT_LINE('  - N° Cuota: ' || v_ultimo_nro_cuota);
        DBMS_OUTPUT.PUT_LINE('  - Fecha vencimiento: ' || TO_CHAR(v_nueva_fecha_venc, 'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('  - Valor cuota: $' || ROUND(v_nuevo_valor_cuota));
        
       
        INSERT INTO CUOTA_CREDITO_CLIENTE (
            nro_solic_credito,
            nro_cuota,
            fecha_venc_cuota,
            valor_cuota,
            fecha_pago_cuota,
            monto_pagado,
            saldo_por_pagar,
            cod_forma_pago
        ) VALUES (
            :v_nro_solic_credito_param,
            v_ultimo_nro_cuota,
            v_nueva_fecha_venc,
            ROUND(v_nuevo_valor_cuota),
            NULL,  
            NULL,  
            NULL,  
            NULL   
        );
    END LOOP;
    
    
    UPDATE CREDITO_CLIENTE
    SET total_cuotas_credito = total_cuotas_credito + :v_cant_cuotas_postergar
    WHERE nro_solic_credito = :v_nro_solic_credito_param;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('=== PROCESO COMPLETADO EXITOSAMENTE ===');
    DBMS_OUTPUT.PUT_LINE('Se agregaron ' || :v_cant_cuotas_postergar || ' cuota(s) postergada(s)');
    DBMS_OUTPUT.PUT_LINE('Total cuotas actualizado: ' || (v_total_cuotas_original + :v_cant_cuotas_postergar));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERROR: No se encontró el crédito especificado');
        ROLLBACK;
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERROR: Múltiples créditos encontrados');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/