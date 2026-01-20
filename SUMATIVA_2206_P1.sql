
--Caso 1--
--Tabla de resultados--

CREATE TABLE USUARIO_CLAVE (
    id_emp NUMBER,
    numrun_emp VARCHAR2(20),
    nombre_empleado VARCHAR2(100),
    nombre_usuario VARCHAR2(50),
    clave_usuario VARCHAR2(100)
);

-- Bloque PL/SQL anonimo--
DECLARE
 
 -- Variables --
    v_fecha_proceso DATE := SYSDATE;
    
    v_estado_civil empleados.estado_civil%TYPE;
    v_nombre empleados.first_name%TYPE;
    v_sueldo empleados.salary%TYPE;
    v_run empleados.numrun_emp%TYPE;
    v_dv_run empleados.dvrun_emp%TYPE;
    v_fecha_contrato empleados.hire_date%TYPE;
    v_fecha_nacimiento empleados.birth_date%TYPE;
    v_apellido_paterno empleados.last_name%TYPE;
    v_id_emp empleados.employee_id%TYPE;
    
    v_primera_letra_estado CHAR(1);
    v_tres_primeras_nombre VARCHAR2(3);
    v_largo_nombre NUMBER;
    v_ultimo_digito_sueldo CHAR(1);
    v_años_trabajando NUMBER;
    v_tercer_digito_run CHAR(1);
    v_año_nacimiento_mas_dos NUMBER;
    v_ultimos_tres_sueldo VARCHAR2(3);
    v_letras_apellido VARCHAR2(2);
    v_mes_años_num VARCHAR2(6);
    
    v_nombre_usuario VARCHAR2(50);
    v_clave_usuario VARCHAR2(100);
    
    v_contador NUMBER := 0;
    v_total_empleados NUMBER;
    
    CURSOR c_empleados IS
        SELECT employee_id, numrun_emp, dvrun_emp, 
               first_name, last_name, salary, 
               hire_date, birth_date, estado_civil
        FROM empleados
        WHERE employee_id BETWEEN 100 AND 320
        ORDER BY employee_id;
    
BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE USUARIO_CLAVE';
    
    SELECT COUNT(*) INTO v_total_empleados 
    FROM empleados 
    WHERE employee_id BETWEEN 100 AND 320;
    
  
    

    FOR reg_emp IN c_empleados LOOP
    
        v_id_emp := reg_emp.employee_id;
        v_run := reg_emp.numrun_emp;
        v_dv_run := reg_emp.dvrun_emp;
        v_nombre := reg_emp.first_name;
        v_apellido_paterno := reg_emp.last_name;
        v_sueldo := ROUND(reg_emp.salary);
        v_fecha_contrato := reg_emp.hire_date;
        v_fecha_nacimiento := reg_emp.birth_date;
        v_estado_civil := reg_emp.estado_civil;
        
      --Construccion nombre de usuario--  
        

        v_primera_letra_estado := LOWER(SUBSTR(v_estado_civil, 1, 1));
        
        v_tres_primeras_nombre := UPPER(SUBSTR(v_nombre, 1, 3));
        
        v_largo_nombre := LENGTH(v_nombre);
        
        v_ultimo_digito_sueldo := SUBSTR(TO_CHAR(v_sueldo), -1, 1);
        
        v_años_trabajando := ROUND(MONTHS_BETWEEN(v_fecha_proceso, v_fecha_contrato) / 12);
        
        v_nombre_usuario := v_primera_letra_estado || 
                           v_tres_primeras_nombre || 
                           v_largo_nombre || 
                           '*' || 
                           v_ultimo_digito_sueldo || 
                           v_dv_run || 
                           v_años_trabajando;
        
        IF v_años_trabajando < 10 THEN
            v_nombre_usuario := v_nombre_usuario || 'X';
        END IF;

        v_tercer_digito_run := SUBSTR(v_run, 3, 1);
        
        v_año_nacimiento_mas_dos := EXTRACT(YEAR FROM v_fecha_nacimiento) + 2;
        
        v_ultimos_tres_sueldo := LPAD(MOD(v_sueldo - 1, 1000), 3, '0');
        
        v_estado_civil := UPPER(v_estado_civil);
        
        IF v_estado_civil IN ('CASADO', 'UNION CIVIL') THEN
            v_letras_apellido := LOWER(SUBSTR(v_apellido_paterno, 1, 2));
        ELSIF v_estado_civil IN ('DIVORCIADO', 'SOLTERO') THEN
            v_letras_apellido := LOWER(
                SUBSTR(v_apellido_paterno, 1, 1) || 
                SUBSTR(v_apellido_paterno, -1, 1)
            );
        ELSIF v_estado_civil = 'VIUDO' THEN
            v_letras_apellido := LOWER(
                SUBSTR(v_apellido_paterno, -3, 1) || 
                SUBSTR(v_apellido_paterno, -2, 1)
            );
        ELSIF v_estado_civil = 'SEPARADO' THEN
            v_letras_apellido := LOWER(SUBSTR(v_apellido_paterno, -2, 2));
        ELSE
            v_letras_apellido := 'xx';
        END IF;
        
        v_mes_años_num := TO_CHAR(v_fecha_proceso, 'MMYYYY');
        
        v_clave_usuario := v_tercer_digito_run || 
                          v_año_nacimiento_mas_dos || 
                          v_ultimos_tres_sueldo || 
                          v_letras_apellido || 
                          v_id_emp || 
                          v_mes_años_num;
        
        INSERT INTO USUARIO_CLAVE (
            id_emp, 
            numrun_emp, 
            nombre_empleado, 
            nombre_usuario, 
            clave_usuario
        ) VALUES (
            v_id_emp,
            v_run || ' ' || v_dv_run,
            v_nombre || ' ' || v_apellido_paterno,
            v_nombre_usuario,
            v_clave_usuario
        );
        
        
        v_contador := v_contador + 1;
        
    END LOOP;
    
    --Verificacion de empleados--
    
    IF v_contador = v_total_empleados THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Proceso completado exitosamente.');
        DBMS_OUTPUT.PUT_LINE('Empleados procesados: ' || v_contador);
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No se procesaron todos los empleados.');
        DBMS_OUTPUT.PUT_LINE('Procesados: ' || v_contador || ' de ' || v_total_empleados);
    END IF;
    
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/