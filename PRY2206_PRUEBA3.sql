
-- CASO 1: TRIGGER

CREATE OR REPLACE TRIGGER trg_actualiza_total_consumos
AFTER INSERT OR UPDATE OR DELETE ON CONSUMO
FOR EACH ROW
DECLARE
    v_id_huesped NUMBER(6);
    v_monto_ajuste NUMBER(10);
    v_operacion VARCHAR2(10);
BEGIN
    -- Determinamos la operación y el monto de ajuste --
    IF INSERTING THEN
        v_id_huesped := :NEW.id_huesped;
        v_monto_ajuste := :NEW.monto;
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN

        IF :OLD.monto != :NEW.monto THEN
            v_id_huesped := :NEW.id_huesped;
            v_monto_ajuste := :NEW.monto - :OLD.monto;
            v_operacion := 'UPDATE';
        ELSE
        
            RETURN;
        END IF;
    ELSIF DELETING THEN
        v_id_huesped := :OLD.id_huesped;
        v_monto_ajuste := -:OLD.monto; 
        v_operacion := 'DELETE';
    END IF;


    MERGE INTO total_consumos tc
    USING (SELECT v_id_huesped AS id_huesped FROM DUAL) src
    ON (tc.id_huesped = src.id_huesped)
    WHEN MATCHED THEN
        UPDATE SET tc.monto_consumos = NVL(tc.monto_consumos, 0) + v_monto_ajuste
    WHEN NOT MATCHED THEN
    
        INSERT (id_huesped, monto_consumos) VALUES (v_id_huesped, v_monto_ajuste);

EXCEPTION
    WHEN OTHERS THEN
        -- Registro de posibles errores --
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'trg_actualiza_total_consumos', SQLERRM);
   
        RAISE;
END trg_actualiza_total_consumos;
/


-- CASO 2:Package para la gestion de los huespedes --

CREATE OR REPLACE PACKAGE pkg_gestion_huespedes AS
    FUNCTION fnc_total_tours (p_id_huesped IN NUMBER)
    RETURN NUMBER;

    gv_monto_tours_dolares NUMBER; 

END pkg_gestion_huespedes;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestion_huespedes AS

    FUNCTION fnc_total_tours (p_id_huesped IN NUMBER)
    RETURN NUMBER
    IS
        v_total NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(t.valor_tour * ht.num_personas), 0)
        INTO v_total
        FROM huesped_tour ht
        JOIN tour t ON ht.id_tour = t.id_tour
        WHERE ht.id_huesped = p_id_huesped;

        v_total := ROUND(v_total);
        gv_monto_tours_dolares := v_total;
        RETURN v_total;

    EXCEPTION
        WHEN OTHERS THEN
            INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
            VALUES (sq_error.NEXTVAL, 'pkg_gestion_huespedes.fnc_total_tours', SQLERRM);
            gv_monto_tours_dolares := 0;
            RETURN 0;
    END fnc_total_tours;

END pkg_gestion_huespedes;
/

CREATE OR REPLACE FUNCTION fnc_nombre_agencia (p_id_huesped IN NUMBER)
RETURN VARCHAR2
IS
    v_nom_agencia agencia.nom_agencia%TYPE;
    v_id_agencia huesped.id_agencia%TYPE;
BEGIN

    BEGIN
        SELECT id_agencia INTO v_id_agencia
        FROM huesped
        WHERE id_huesped = p_id_huesped;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
            VALUES (sq_error.NEXTVAL, 'fnc_nombre_agencia', SQLERRM);
        
            RETURN 'NO REGISTRA AGENCIA';
    END;

    IF v_id_agencia IS NULL THEN
        RETURN 'NO REGISTRA AGENCIA';
    END IF;

    BEGIN
        SELECT nom_agencia INTO v_nom_agencia
        FROM agencia
        WHERE id_agencia = v_id_agencia;
        RETURN v_nom_agencia;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
            VALUES (sq_error.NEXTVAL, 'fnc_nombre_agencia', SQLERRM);
    
            RETURN 'NO REGISTRA AGENCIA';
    END;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'fnc_nombre_agencia', SQLERRM);
        RETURN 'NO REGISTRA AGENCIA';
END fnc_nombre_agencia;
/


CREATE OR REPLACE FUNCTION fnc_total_consumos (p_id_huesped IN NUMBER)
RETURN NUMBER
IS
    v_total_consumos NUMBER;
BEGIN
    SELECT NVL(monto_consumos, 0)
    INTO v_total_consumos
    FROM total_consumos
    WHERE id_huesped = p_id_huesped;

    RETURN v_total_consumos;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'fnc_total_consumos', SQLERRM);
        RETURN 0;
END fnc_total_consumos;
/

CREATE OR REPLACE PROCEDURE prc_pago_diario_huespedes (
    p_fecha_referencia IN DATE,
    p_valor_dolar IN NUMBER
)
IS
    CURSOR c_huespedes_salida IS
        SELECT
            r.id_huesped,
            r.id_reserva,
            r.estadia,
            SUM(h.valor_habitacion + h.valor_minibar) AS valor_total_diario_habitaciones_dolares
        FROM reserva r
        JOIN detalle_reserva dr ON r.id_reserva = dr.id_reserva
        JOIN habitacion h ON dr.id_habitacion = h.id_habitacion
        WHERE r.ingreso + r.estadia - 1 = p_fecha_referencia
        GROUP BY r.id_huesped, r.id_reserva, r.estadia;

    v_nom_huesped_completo VARCHAR2(200);
    v_nom_agencia VARCHAR2(100);
    v_id_agencia_huesped huesped.id_agencia%TYPE;

    -- Variables en dolares --
    v_alojamiento_dolares NUMBER := 0;
    v_consumos_dolares NUMBER := 0;
    v_tours_dolares NUMBER := 0;
    v_valor_personas_dolares NUMBER := 0;
    v_monto_acumulado_dolares NUMBER := 0; 
    v_subtotal_dolares NUMBER := 0;         
    v_descuento_consumos_dolares NUMBER := 0;
    v_descuento_agencia_dolares NUMBER := 0;
    v_total_dolares NUMBER := 0;

    -- Variables en pesos --
    v_alojamiento_pesos NUMBER := 0;
    v_consumos_pesos NUMBER := 0;
    v_tours_pesos NUMBER := 0;
    v_monto_acumulado_pesos NUMBER := 0;
    v_subtotal_pesos NUMBER := 0;
    v_descuento_consumos_pesos NUMBER := 0;
    v_descuento_agencia_pesos NUMBER := 0;
    v_total_pesos NUMBER := 0;

    v_pct_descuento_consumos NUMBER := 0;
    

    c_valor_personas_clp CONSTANT NUMBER := 35000;
    c_id_agencia_alberti CONSTANT agencia.id_agencia%TYPE := 4;

BEGIN
    DELETE FROM detalle_diario_huespedes;
    DELETE FROM reg_errores;

    DBMS_OUTPUT.PUT_LINE('Iniciando proceso para fecha de salida: ' ||
                         TO_CHAR(p_fecha_referencia, 'DD/MM/YYYY'));

    FOR r_huesped IN c_huespedes_salida LOOP
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Procesando huésped: ' || r_huesped.id_huesped);

            --  Obtener nombre completo --
            BEGIN
                SELECT TRIM(appat_huesped || ' ' || apmat_huesped || ' ' || nom_huesped)
                INTO v_nom_huesped_completo
                FROM huesped
                WHERE id_huesped = r_huesped.id_huesped;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_nom_huesped_completo := 'NOMBRE NO ENCONTRADO';
                    INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
                    VALUES (sq_error.NEXTVAL, 'prc_pago_diario_huespedes',
                            'Huésped ID ' || r_huesped.id_huesped || ' no encontrado.');
            END;


            v_nom_agencia := fnc_nombre_agencia(r_huesped.id_huesped);

            -- Obtener el ID de agencia --
            BEGIN
                SELECT id_agencia INTO v_id_agencia_huesped
                FROM huesped 
                WHERE id_huesped = r_huesped.id_huesped;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_id_agencia_huesped := NULL;
            END;

            -- Calculos --
            v_alojamiento_dolares := r_huesped.valor_total_diario_habitaciones_dolares * r_huesped.estadia;
            v_alojamiento_dolares := ROUND(v_alojamiento_dolares);

       
            v_consumos_dolares := fnc_total_consumos(r_huesped.id_huesped);

            v_tours_dolares := pkg_gestion_huespedes.fnc_total_tours(r_huesped.id_huesped);

            v_valor_personas_dolares := ROUND(c_valor_personas_clp / p_valor_dolar);

            v_monto_acumulado_dolares := v_alojamiento_dolares + v_consumos_dolares + v_valor_personas_dolares;

            v_subtotal_dolares := v_monto_acumulado_dolares + v_tours_dolares;


            BEGIN
                SELECT NVL(pct, 0) INTO v_pct_descuento_consumos
                FROM tramos_consumos
                WHERE v_consumos_dolares BETWEEN vmin_tramo AND vmax_tramo;

                v_descuento_consumos_dolares := ROUND(v_consumos_dolares * v_pct_descuento_consumos);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_descuento_consumos_dolares := 0;
            END;

            v_descuento_agencia_dolares := 0;
            IF v_id_agencia_huesped = c_id_agencia_alberti THEN
                v_descuento_agencia_dolares := ROUND(v_monto_acumulado_dolares * 0.12);
            END IF;

            v_total_dolares := v_subtotal_dolares - v_descuento_consumos_dolares - v_descuento_agencia_dolares;

            v_alojamiento_pesos        := ROUND(v_alojamiento_dolares * p_valor_dolar);
            v_consumos_pesos           := ROUND(v_consumos_dolares * p_valor_dolar);
            v_tours_pesos              := ROUND(v_tours_dolares * p_valor_dolar);
            v_monto_acumulado_pesos    := ROUND(v_monto_acumulado_dolares * p_valor_dolar);
            v_subtotal_pesos           := ROUND(v_subtotal_dolares * p_valor_dolar);
            v_descuento_consumos_pesos := ROUND(v_descuento_consumos_dolares * p_valor_dolar);
            v_descuento_agencia_pesos  := ROUND(v_descuento_agencia_dolares * p_valor_dolar);
            v_total_pesos              := ROUND(v_total_dolares * p_valor_dolar);
            -- ======================================

            -- Insertar en la tabla de resultados --
            INSERT INTO detalle_diario_huespedes (
                id_huesped, nombre, agencia, alojamiento, consumos, tours,
                subtotal_pago, descuento_consumos, descuentos_agencia, total
            ) VALUES (
                r_huesped.id_huesped, 
                v_nom_huesped_completo, 
                v_nom_agencia,
                v_alojamiento_pesos, 
                v_consumos_pesos, 
                v_tours_pesos,
                v_subtotal_pesos, 
                v_descuento_consumos_pesos, 
                v_descuento_agencia_pesos, 
                v_total_pesos
            );
            
            DBMS_OUTPUT.PUT_LINE('  -> Insertado correctamente. Total CLP: $' || v_total_pesos);

        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
                VALUES (sq_error.NEXTVAL, 'prc_pago_diario_huespedes',
                        'Error huésped ' || r_huesped.id_huesped || ': ' || SQLERRM);
                DBMS_OUTPUT.PUT_LINE('  -> ERROR: ' || SQLERRM);
        END;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso completado.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error crítico: ' || SQLERRM);
        RAISE;
END prc_pago_diario_huespedes;
/

-- Bloque anonimo para pruebas del casi 1--

SET SERVEROUTPUT ON;

DECLARE
    v_new_id_consumo consumo.id_consumo%TYPE;

    PROCEDURE mostrar_estado (p_mensaje IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- ' || p_mensaje || ' ---');
        DBMS_OUTPUT.PUT_LINE('Consumos (ID, Huésped, Monto):');
        FOR r IN (SELECT id_consumo, id_huesped, monto FROM consumo WHERE id_huesped IN (340006, 340008, 340004) ORDER BY id_huesped, id_consumo) LOOP
            DBMS_OUTPUT.PUT_LINE('  ID: ' || r.id_consumo || ', Huésped: ' || r.id_huesped || ', Monto: ' || r.monto);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Totales (Huésped, Total):');
        FOR r IN (SELECT id_huesped, monto_consumos FROM total_consumos WHERE id_huesped IN (340006, 340008, 340004) ORDER BY id_huesped) LOOP
            DBMS_OUTPUT.PUT_LINE('  Huésped: ' || r.id_huesped || ', Total: ' || r.monto_consumos);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END mostrar_estado;

BEGIN
 
    SELECT NVL(MAX(id_consumo), 0) + 1 INTO v_new_id_consumo FROM consumo;

    mostrar_estado('ESTADO INICIAL');

    DBMS_OUTPUT.PUT_LINE('OPERACIÓN 1: INSERT consumo ID ' || v_new_id_consumo || ' para huésped 340006 (Monto 150)');
    INSERT INTO consumo (id_consumo, id_reserva, id_huesped, monto)
    VALUES (v_new_id_consumo, 1587, 340006, 150);
    mostrar_estado('DESPUÉS DE INSERT');

    DBMS_OUTPUT.PUT_LINE('OPERACIÓN 2: DELETE consumo ID 11473');
    DELETE FROM consumo WHERE id_consumo = 11473;
    mostrar_estado('DESPUÉS DE DELETE');

    DBMS_OUTPUT.PUT_LINE('OPERACIÓN 3: UPDATE consumo ID 10688 a monto 95');
    UPDATE consumo SET monto = 95 WHERE id_consumo = 10688;
    mostrar_estado('DESPUÉS DE UPDATE');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- TRANSACCIÓN CONFIRMADA ---');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/


-- Ejecucion del procedimiento para el caso 2 --

BEGIN
    prc_pago_diario_huespedes(
        p_fecha_referencia => TO_DATE('18/08/2021', 'DD/MM/YYYY'),
        p_valor_dolar => 915
    );
END;
/


SELECT * FROM detalle_diario_huespedes;
SELECT * FROM reg_errores;