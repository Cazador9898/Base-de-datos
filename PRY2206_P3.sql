
-- Casp 1 --
--PL/SQL--
DECLARE

    -- Variables necesarias--
    v_id_atencion atenciones.id_atencion%TYPE;
    v_fecha_venc_pago atenciones.fecha_venc_pago%TYPE;
    v_fecha_pago_real atenciones.fecha_pago_real%TYPE;
    v_id_paciente pacientes.id_paciente%TYPE;
    
   
    v_dias_atraso NUMBER;
    v_edad_paciente NUMBER;
    v_multa_diaria NUMBER;
    v_multa_total NUMBER;
    v_descuento NUMBER := 0;
    v_valor_final NUMBER;
    

    v_nombre_paciente VARCHAR2(200);
    v_especialidad especialidades.nombre%TYPE;
    

    TYPE multa_especialidad_type IS VARRAY(7) OF NUMBER;
    multas_especialidad multa_especialidad_type;
    

    -- Cursor --
    CURSOR cur_atenciones_morosas IS
        SELECT 
            a.id_atencion,
            a.fecha_venc_pago,
            a.fecha_pago_real,
            -- Calcular días de atraso (mínimo 0 para evitar valores negativos)
            GREATEST(0, TRUNC(a.fecha_pago_real) - TRUNC(a.fecha_venc_pago)) AS dias_atraso,
            p.id_paciente,
            p.nombre || ' ' || p.apellido_paterno AS nombre_paciente,
            e.nombre AS especialidad,
            -- Calcular edad del paciente en años completos
            TRUNC(MONTHS_BETWEEN(SYSDATE, p.fecha_nacimiento) / 12) AS edad_paciente
        FROM atenciones a
        JOIN pacientes p ON a.id_paciente = p.id_paciente
        JOIN especialidades e ON a.id_especialidad = e.id_especialidad
        WHERE EXTRACT(YEAR FROM a.fecha_pago_real) = EXTRACT(YEAR FROM SYSDATE) - 1
          AND a.fecha_pago_real > a.fecha_venc_pago  -- Solo pagos con atraso
        ORDER BY a.fecha_venc_pago, p.apellido_paterno;
    
    v_contador_registros NUMBER := 0;

BEGIN

    
    DBMS_OUTPUT.PUT_LINE('INICIANDO PROCESO DE CÁLCULO DE MULTAS...');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    multas_especialidad := multa_especialidad_type(1200, 1300, 1700, 1900, 1100, 2000, 2300);
    
 
    DBMS_OUTPUT.PUT_LINE('Limpiando tabla PAGO_MOROSO...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PAGO_MOROSO';
    DBMS_OUTPUT.PUT_LINE('Tabla limpiada correctamente.');
    

    DBMS_OUTPUT.PUT_LINE('Procesando atenciones morosas...');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    

    FOR rec IN cur_atenciones_morosas LOOP
    
        -- Asignar valores a variables locales --
        v_id_atencion := rec.id_atencion;
        v_fecha_venc_pago := rec.fecha_venc_pago;
        v_fecha_pago_real := rec.fecha_pago_real;
        v_dias_atraso := rec.dias_atraso;
        v_id_paciente := rec.id_paciente;
        v_nombre_paciente := rec.nombre_paciente;
        v_especialidad := rec.especialidad;
        v_edad_paciente := rec.edad_paciente;
        
        
        IF v_especialidad IN ('Cirugía General', 'Dermatología') THEN
            v_multa_diaria := multas_especialidad(1);  
        ELSIF v_especialidad IN ('Ortopedia', 'Traumatología') THEN
            v_multa_diaria := multas_especialidad(2); 
        ELSIF v_especialidad IN ('Inmunología', 'Otorrinolaringología') THEN
            v_multa_diaria := multas_especialidad(3);  
        ELSIF v_especialidad IN ('Fisiatría', 'Medicina Interna') THEN
            v_multa_diaria := multas_especialidad(4); 
        ELSIF v_especialidad = 'Medicina General' THEN
            v_multa_diaria := multas_especialidad(5); 
        ELSIF v_especialidad = 'Psiquiatría Adultos' THEN
            v_multa_diaria := multas_especialidad(6);  
        ELSIF v_especialidad IN ('Cirugía Digestiva', 'Reumatología') THEN
            v_multa_diaria := multas_especialidad(7);  
        ELSE
            v_multa_diaria := 0;  
            DBMS_OUTPUT.PUT_LINE('Advertencia: Especialidad ' || v_especialidad || 
                               ' no tiene multa asignada. ID Atención: ' || v_id_atencion);
        END IF;
        

        
        v_multa_total := v_dias_atraso * v_multa_diaria;
        
  
        IF v_edad_paciente >= 65 THEN
        
            BEGIN
                SELECT porc_descto INTO v_descuento 
                FROM PORC_DESCTO_3RA_EDAD 
                WHERE v_edad_paciente BETWEEN edad_min AND edad_max;
                
                DBMS_OUTPUT.PUT_LINE('  Paciente ' || v_nombre_paciente || 
                                   ' (edad: ' || v_edad_paciente || 
                                   ') recibe ' || v_descuento || '% de descuento');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_descuento := 0;
                    DBMS_OUTPUT.PUT_LINE('Advertencia: No se encontró descuento para edad ' || 
                                       v_edad_paciente || '. ID Paciente: ' || v_id_paciente);
                WHEN TOO_MANY_ROWS THEN
                    v_descuento := 0;
                    DBMS_OUTPUT.PUT_LINE('Error: Múltiples descuentos para edad ' || 
                                       v_edad_paciente || '. ID Paciente: ' || v_id_paciente);
            END;
        ELSE
            v_descuento := 0; 
        END IF;
        

        
        v_valor_final := v_multa_total * (1 - v_descuento / 100);
        
        
        INSERT INTO PAGO_MOROSO (
            id_atencion,
            fecha_venc_pago,
            fecha_pago_real,
            dias_atraso,
            valor_final,
            id_paciente,
            nombre_paciente,
            especialidad
        ) VALUES (
            v_id_atencion,
            v_fecha_venc_pago,
            v_fecha_pago_real,
            v_dias_atraso,
            v_valor_final,
            v_id_paciente,
            v_nombre_paciente,
            v_especialidad
        );
        
   
        v_contador_registros := v_contador_registros + 1;
        
    
        IF MOD(v_contador_registros, 100) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Procesados ' || v_contador_registros || ' registros...');
        END IF;
    END LOOP;
    

    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PROCESO FINALIZADO CORRECTAMENTE.');
    DBMS_OUTPUT.PUT_LINE('Total de registros procesados: ' || v_contador_registros);
    DBMS_OUTPUT.PUT_LINE('Realizando COMMIT de la transacción...');
    

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('COMMIT realizado exitosamente.');
    DBMS_OUTPUT.PUT_LINE('========================================');

EXCEPTION

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('ERROR EN EL PROCESO:');
        DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Realizando ROLLBACK...');
        
     
        ROLLBACK;
        
        DBMS_OUTPUT.PUT_LINE('ROLLBACK completado.');
        DBMS_OUTPUT.PUT_LINE('========================================');
        

        RAISE;
END;
/




--CASO 2--
--PL/SQL--

DECLARE

    
    -- Variables necesarias --
    v_id_medico medicos.id_medico%TYPE;
    v_nombre_completo VARCHAR2(200);
    v_apellido_paterno medicos.apellido_paterno%TYPE;
    v_unidad_trabajo unidades.nombre%TYPE;
    

    v_total_atenciones NUMBER;
    v_max_atenciones NUMBER;
    v_destinacion_asignada VARCHAR2(100);
    v_correo_institucional VARCHAR2(100);
    
 
    v_unidad_abreviada VARCHAR2(2);
    v_letras_apellido VARCHAR2(2);
    v_id_digitos VARCHAR2(3);
    
    -- Año de referencia --
    v_año_anterior NUMBER;
    

    TYPE destinaciones_type IS VARRAY(7) OF VARCHAR2(100);
    destinaciones destinaciones_type;
    

    CURSOR cur_medicos IS
        SELECT 
            m.id_medico,
      
            m.nombre || ' ' || m.apellido_paterno || ' ' || 
            COALESCE(m.apellido_materno, '') AS nombre_completo,
            m.apellido_paterno,
            u.nombre AS unidad_trabajo,
          
            COUNT(a.id_atencion) AS total_atenciones
        FROM medicos m
        JOIN unidades u ON m.id_unidad = u.id_unidad
        LEFT JOIN atenciones a ON m.id_medico = a.id_medico
           AND EXTRACT(YEAR FROM a.fecha_atencion) = EXTRACT(YEAR FROM SYSDATE) - 1
        GROUP BY m.id_medico, m.nombre, m.apellido_paterno, m.apellido_materno, u.nombre
        ORDER BY u.nombre, m.apellido_paterno
        FOR UPDATE; 
    
  
    v_contador_procesados NUMBER := 0;
    v_contador_asignados NUMBER := 0;
    v_contador_excluidos NUMBER := 0;

BEGIN

    
    DBMS_OUTPUT.PUT_LINE('INICIANDO PROCESO DE ASIGNACIÓN DE SERVICIO COMUNITARIO...');
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    

    v_año_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;
    DBMS_OUTPUT.PUT_LINE('Año de referencia: ' || v_año_anterior);
    

    destinaciones := destinaciones_type(
        'Servicio de Atención Primaria de Urgencia (SAPU)',       
        'Servicio de Atención Primaria de Urgencia (SAPU)',        
        'Hospitales del área de la Salud Pública',                 
        'Hospitales del área de la Salud Pública',                 
        'Hospitales del área de la Salud Pública',                 
        'Centros de Salud Familiar (CESFAM)',                     
        'Servicio de Atención Primaria de Urgencia (SAPU)'        
    );
    

    
    DBMS_OUTPUT.PUT_LINE('Calculando máximo de atenciones del año ' || v_año_anterior || '...');
    
    SELECT MAX(total_atenciones) INTO v_max_atenciones
    FROM (
        SELECT m.id_medico, COUNT(a.id_atencion) AS total_atenciones
        FROM medicos m
        LEFT JOIN atenciones a ON m.id_medico = a.id_medico
           AND EXTRACT(YEAR FROM a.fecha_atencion) = v_año_anterior
        GROUP BY m.id_medico
    );
    
    DBMS_OUTPUT.PUT_LINE('Máximo de atenciones encontrado: ' || v_max_atenciones);
    DBMS_OUTPUT.PUT_LINE('(Médicos con menos atenciones serán asignados a servicio comunitario)');
    
    DBMS_OUTPUT.PUT_LINE('Limpiando tabla MEDICO_SERVICIO_COMUNIDAD...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE MEDICO_SERVICIO_COMUNIDAD';
    DBMS_OUTPUT.PUT_LINE('Tabla limpiada correctamente.');
    
    
    DBMS_OUTPUT.PUT_LINE('Procesando médicos...');
    DBMS_OUTPUT.PUT_LINE('-----------------');

    OPEN cur_medicos;
    
    LOOP

        FETCH cur_medicos INTO 
            v_id_medico,
            v_nombre_completo,
            v_apellido_paterno,
            v_unidad_trabajo,
            v_total_atenciones;
        
 
        EXIT WHEN cur_medicos%NOTFOUND;
        
      
        v_contador_procesados := v_contador_procesados + 1;
        
   
        IF MOD(v_contador_procesados, 50) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Procesados ' || v_contador_procesados || ' médicos...');
        END IF;
        
        IF v_total_atenciones < v_max_atenciones THEN
      
            
            IF v_unidad_trabajo IN ('Atención Adulto', 'Atención Ambulatoria') THEN
               
                v_destinacion_asignada := destinaciones(1);
                
            ELSIF v_unidad_trabajo = 'Atención Urgencia' THEN
            
                IF v_total_atenciones BETWEEN 0 AND 3 THEN
                    v_destinacion_asignada := destinaciones(2);  
                ELSE
                    v_destinacion_asignada := destinaciones(3);  
                END IF;
                
            ELSIF v_unidad_trabajo IN ('Cardiología', 'Oncología') THEN
            
                v_destinacion_asignada := destinaciones(4);
                
            ELSIF v_unidad_trabajo IN ('Cirugía', 'Cirugía Plástica') THEN
               
                IF v_total_atenciones BETWEEN 0 AND 3 THEN
                    v_destinacion_asignada := destinaciones(5); 
                ELSE
                    v_destinacion_asignada := destinaciones(3);  
                END IF;
                
            ELSIF v_unidad_trabajo = 'Paciente Crítico' THEN
            
                v_destinacion_asignada := destinaciones(3);
                
            ELSIF v_unidad_trabajo IN ('Psiquiatría', 'Salus Mental') THEN
               
                v_destinacion_asignada := destinaciones(6);
                
            ELSIF v_unidad_trabajo = 'Traumatología Adulto' THEN
          
                IF v_total_atenciones BETWEEN 0 AND 3 THEN
                    v_destinacion_asignada := destinaciones(7); )
                ELSE
                    v_destinacion_asignada := destinaciones(3);  
                END IF;
                
            ELSE
              
                v_destinacion_asignada := 'Sin destinación asignada - Unidad no catalogada';
                DBMS_OUTPUT.PUT_LINE('Advertencia: Unidad ' || v_unidad_trabajo || 
                                   ' no está en las reglas. Médico: ' || v_nombre_completo);
            END IF;
            
        
            
            BEGIN
             
                v_unidad_abreviada := UPPER(SUBSTR(v_unidad_trabajo, 1, 2));
            
                IF LENGTH(v_apellido_paterno) >= 2 THEN
                    v_letras_apellido := UPPER(SUBSTR(v_apellido_paterno, -2));
                ELSIF LENGTH(v_apellido_paterno) = 1 THEN
                    v_letras_apellido := UPPER(v_apellido_paterno || 'X');
                ELSE
                    v_letras_apellido := 'XX';  
                END IF;
                
       
                v_id_digitos := LPAD(MOD(v_id_medico, 1000), 3, '0');
                
          
                v_correo_institucional := v_unidad_abreviada || v_letras_apellido || 
                                        v_id_digitos || '@clinicaketekura.cl';
                
            EXCEPTION
                WHEN OTHERS THEN
            
                    v_correo_institucional := 'error.correo@clinicaketekura.cl';
                    DBMS_OUTPUT.PUT_LINE('Error generando correo para médico ' || 
                                       v_id_medico || ': ' || SQLERRM);
            END;
            
  
            
            INSERT INTO MEDICO_SERVICIO_COMUNIDAD (
                id_medico,
                nombre_completo,
                unidad_trabajo,
                total_atenciones,
                destinacion_asignada,
                correo_institucional
            ) VALUES (
                v_id_medico,
                v_nombre_completo,
                v_unidad_trabajo,
                v_total_atenciones,
                v_destinacion_asignada,
                v_correo_institucional
            );
            
      
            v_contador_asignados := v_contador_asignados + 1;
            
        
            IF MOD(v_contador_asignados, 10) = 0 THEN
                DBMS_OUTPUT.PUT_LINE('  Asignados ' || v_contador_asignados || ' médicos...');
            END IF;
            
        ELSE
   
            v_contador_excluidos := v_contador_excluidos + 1;
            
        END IF;
        
    END LOOP;
    

    CLOSE cur_medicos;

    DBMS_OUTPUT.PUT_LINE('---------------');
    DBMS_OUTPUT.PUT_LINE('PROCESO FINALIZADO CORRECTAMENTE.');
    DBMS_OUTPUT.PUT_LINE('================');
    DBMS_OUTPUT.PUT_LINE('ESTADÍSTICAS:');
    DBMS_OUTPUT.PUT_LINE('  Total de médicos procesados: ' || v_contador_procesados);
    DBMS_OUTPUT.PUT_LINE('  Médicos asignados a servicio: ' || v_contador_asignados);
    DBMS_OUTPUT.PUT_LINE('  Médicos excluidos (alta productividad): ' || v_contador_excluidos);
    DBMS_OUTPUT.PUT_LINE('  Máximo de atenciones referencia: ' || v_max_atenciones);
    DBMS_OUTPUT.PUT_LINE('----------------');
    DBMS_OUTPUT.PUT_LINE('Realizando COMMIT de la transacción...');
    
    -- Confirmar todas las inserciones
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('COMMIT realizado exitosamente.');
    DBMS_OUTPUT.PUT_LINE('=================');

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: No se encontraron datos necesarios para el procesamiento.');
        DBMS_OUTPUT.PUT_LINE('Realizando ROLLBACK...');
        ROLLBACK;
        
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Múltiples registros encontrados donde se esperaba uno.');
        DBMS_OUTPUT.PUT_LINE('Realizando ROLLBACK...');
        ROLLBACK;
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('=============');
        DBMS_OUTPUT.PUT_LINE('ERROR EN EL PROCESO:');
        DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('--------------');
        DBMS_OUTPUT.PUT_LINE('Realizando ROLLBACK...');
        

        ROLLBACK;
        
        DBMS_OUTPUT.PUT_LINE('ROLLBACK completado.');
        DBMS_OUTPUT.PUT_LINE('====================');
        
        RAISE;
END;
/