
CREATE OR REPLACE PACKAGE pkg_gestion_multas AS
  
    v_valor_multa NUMBER(8) := 0;
    v_valor_descuento NUMBER(4) := 0;
    
   
    FUNCTION fn_obtener_descueto_3ra_edad(p_edad NUMBER) RETURN NUMBER;
    
END pkg_gestion_multas;
/


CREATE OR REPLACE PACKAGE BODY pkg_gestion_multas AS
    

    FUNCTION fn_obtener_descueto_3ra_edad(p_edad NUMBER) RETURN NUMBER IS
        v_porcentaje_descuento NUMBER(4) := 0;
    BEGIN
      
        BEGIN
            SELECT porcentaje_descto
            INTO v_porcentaje_descuento
            FROM PORC_DESCTO_3RA_EDAD
            WHERE p_edad BETWEEN anno_ini AND anno_ter;
            
          
            v_valor_descuento := v_porcentaje_descuento;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_porcentaje_descuento := 0;
                v_valor_descuento := 0;
        END;
        
        RETURN v_porcentaje_descuento;
    END fn_obtener_descueto_3ra_edad;
    
END pkg_gestion_multas;
/

CREATE OR REPLACE FUNCTION fn_obtener_especialidad(p_ate_id NUMBER) 
RETURN VARCHAR2 IS
    v_nombre_especialidad ESPECIALIDAD.nombre%TYPE;
BEGIN
    SELECT e.nombre
    INTO v_nombre_especialidad
    FROM ATENCION a
    INNER JOIN MEDICO m ON a.med_run = m.med_run
    INNER JOIN ESPECIALIDAD e ON m.esp_id = e.esp_id
    WHERE a.ate_id = p_ate_id;
    
    RETURN v_nombre_especialidad;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ESPECIALIDAD NO ENCONTRADA';
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END fn_obtener_especialidad;
/


CREATE OR REPLACE PROCEDURE sp_generar_info_morosidad IS
  
    TYPE multas_especialidades IS VARRAY(7) OF NUMBER(4);
    v_multas_especialidades multas_especialidades := multas_especialidades(1200, 1300, 1700, 1900, 1100, 2000, 2300);
    

    CURSOR c_atenciones_morosas IS
        SELECT 
            p.pac_run,
            p.dv_run,
            p.pnombre,
            p.snombre,
            p.apaterno,
            p.amaterno,
            p.fecha_nacimiento,
            a.ate_id,
            pa.fecha_venc_pago,
            pa.fecha_pago,
            a.costo AS costo_atencion,
            a.fecha_atencion
        FROM PACIENTE p
        INNER JOIN ATENCION a ON p.pac_run = a.pac_run
        INNER JOIN PAGO_ATENCION pa ON a.ate_id = pa.ate_id
        WHERE EXTRACT(YEAR FROM pa.fecha_venc_pago) = EXTRACT(YEAR FROM SYSDATE) - 1
        AND pa.fecha_pago > pa.fecha_venc_pago; 
    
 
    v_nombre_completo VARCHAR2(100);
    v_dias_morosidad NUMBER(3);
    v_valor_multa NUMBER(8);
    v_especialidad VARCHAR2(100);
    v_edad NUMBER(3);
    v_porc_descuento NUMBER(4);
    v_valor_descuento NUMBER(8);
    v_multa_final NUMBER(8);
    v_observacion VARCHAR2(100);
    
BEGIN
  
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PAGO_MOROSO';
    
 
    FOR reg_atencion IN c_atenciones_morosas LOOP
        
       
        v_nombre_completo := reg_atencion.pnombre || ' ' || 
                             NVL(reg_atencion.snombre, '') || ' ' || 
                             reg_atencion.apaterno || ' ' || 
                             NVL(reg_atencion.amaterno, '');
        
   
        v_dias_morosidad := reg_atencion.fecha_pago - reg_atencion.fecha_venc_pago;
        
      
        v_especialidad := fn_obtener_especialidad(reg_atencion.ate_id);
        
  
        v_edad := EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM reg_atencion.fecha_nacimiento);
        

        IF v_especialidad = 'Medicina General' THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(1);
        ELSIF v_especialidad = 'Traumatologia' THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(2);
        ELSIF v_especialidad IN ('Neurologia', 'Pediatria') THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(3);
        ELSIF v_especialidad = 'Oftalmologia' THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(4);
        ELSIF v_especialidad = 'Geriatria' THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(5);
        ELSIF v_especialidad IN ('Ginecologia', 'Gastroenterologia') THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(6);
        ELSIF v_especialidad = 'Dermatologia' THEN
            pkg_gestion_multas.v_valor_multa := v_multas_especialidades(7);
        ELSE
            pkg_gestion_multas.v_valor_multa := 1000;
        END IF;
        

        v_valor_multa := pkg_gestion_multas.v_valor_multa * v_dias_morosidad;
        
    
        IF v_edad > 70 THEN
            v_porc_descuento := pkg_gestion_multas.fn_obtener_descueto_3ra_edad(v_edad);
            v_valor_descuento := v_valor_multa * v_porc_descuento / 100;
            v_multa_final := v_valor_multa - v_valor_descuento;
            v_observacion := 'Se aplicó descuento del ' || v_porc_descuento || '% por tercera edad';
        ELSE
            v_multa_final := v_valor_multa;
            v_observacion := 'No aplica descuento por edad';
        END IF;
        
     
        INSERT INTO PAGO_MOROSO (
            pac_run,
            pac_dv_run,
            pac_nombre,
            ate_id,
            fecha_venc_pago,
            fecha_pago,
            dias_morosidad,
            especialidad_atencion,
            costo_atencion,
            monto_multa,
            observacion
        ) VALUES (
            reg_atencion.pac_run,
            reg_atencion.dv_run,
            v_nombre_completo,
            reg_atencion.ate_id,
            reg_atencion.fecha_venc_pago,
            reg_atencion.fecha_pago,
            v_dias_morosidad,
            v_especialidad,
            reg_atencion.costo_atencion,
            v_multa_final,
            v_observacion
        );
        
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso completado exitosamente. Se generaron ' || SQL%ROWCOUNT || ' registros.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en el proceso: ' || SQLERRM);
        -- Registrar error en tabla ERRORES_PROCESO
        INSERT INTO ERRORES_PROCESO VALUES(
            SEQ_ERRORES.NEXTVAL,
            'sp_generar_info_morosidad',
            SQLERRM
        );
        COMMIT;
END sp_generar_info_morosidad;
/


CREATE SEQUENCE SEQ_ERRORES
START WITH 1
INCREMENT BY 1
NOMAXVALUE
NOCACHE;


SET SERVEROUTPUT ON;


BEGIN
    sp_generar_info_morosidad;
END;
/

SELECT * FROM PAGO_MOROSO 
ORDER BY fecha_venc_pago ASC, pac_nombre ASC;

SELECT COUNT(*) AS total_registros FROM PAGO_MOROSO;