CREATE TABLE region (
    region_id     NUMBER PRIMARY KEY,
    nombre_region VARCHAR2(50) NOT NULL
);


CREATE TABLE comuna (
    comuna_id      NUMBER PRIMARY KEY,
    nombre_comuna  VARCHAR2(50) NOT NULL,
    region_id      NUMBER NOT NULL,
    CONSTRAINT fk_comuna_region FOREIGN KEY (region_id) REFERENCES region(region_id)
);


CREATE TABLE tipo_empleado (
    tipo_empleado_id NUMBER PRIMARY KEY,
    descripcion      VARCHAR2(20) NOT NULL
);



CREATE TABLE planta (
    planta_id     NUMBER PRIMARY KEY,
    nombre_planta VARCHAR2(100) NOT NULL,
    direccion     VARCHAR2(200) NOT NULL,
    comuna_id     NUMBER NOT NULL,
    CONSTRAINT fk_planta_comuna FOREIGN KEY (comuna_id) REFERENCES comuna(comuna_id)
);


CREATE TABLE tipo_maquina (
    tipo_maquina_id NUMBER PRIMARY KEY,
    nombre_tipo     VARCHAR2(100) NOT NULL,
    descripcion     VARCHAR2(200)
);



CREATE TABLE turno (
    turno_id      NUMBER PRIMARY KEY,
    nombre_turno  VARCHAR2(20) NOT NULL,
    hora_inicio   CHAR(5) NOT NULL,
    hora_termino  CHAR(5) NOT NULL,
    CONSTRAINT chek_hora_inicio CHECK (hora_inicio LIKE '__:__'),
    CONSTRAINT chek_hora_termino CHECK (hora_termino LIKE '__:__')
);



CREATE TABLE empleado (
    empleado_id         NUMBER PRIMARY KEY,
    codigo_empleado     NUMBER(8) NOT NULL UNIQUE,
    rut                 VARCHAR2(12) NOT NULL UNIQUE,
    nombres             VARCHAR2(100) NOT NULL,
    apellidos           VARCHAR2(100) NOT NULL,
    fecha_contratacion  DATE NOT NULL,
    sueldo_base         NUMBER(10,2) NOT NULL,
    estado_activo       CHAR(1) DEFAULT 'S' NOT NULL,
    planta_id           NUMBER NOT NULL,
    afp                 VARCHAR2(50) NOT NULL,
    sistema_salud       VARCHAR2(50) NOT NULL,
    tipo_empleado_id    NUMBER NOT NULL,
    jefe_directo_id     NUMBER NULL,
    CONSTRAINT fk_empleado_planta FOREIGN KEY (planta_id) REFERENCES planta(planta_id),
    CONSTRAINT fk_empleado_tipo FOREIGN KEY (tipo_empleado_id) REFERENCES tipo_empleado(tipo_empleado_id),
    CONSTRAINT fk_empleado_jefe FOREIGN KEY (jefe_directo_id) REFERENCES empleado(empleado_id),
    CONSTRAINT chk_estado_activo CHECK (estado_activo IN ('S','N'))
);



CREATE TABLE maquina (
    maquina_id      NUMBER PRIMARY KEY,
    numero_maquina  VARCHAR2(20) NOT NULL,
    nombre_maquina  VARCHAR2(100) NOT NULL,
    estado_activo   CHAR(1) NOT NULL,
    planta_id       NUMBER NOT NULL,
    tipo_maquina_id NUMBER NOT NULL,
    CONSTRAINT fk_maquina_planta FOREIGN KEY (planta_id) REFERENCES planta(planta_id),
    CONSTRAINT fk_maquina_tipo FOREIGN KEY (tipo_maquina_id) REFERENCES tipo_maquina(tipo_maquina_id),
    CONSTRAINT chk_maquina_activo CHECK (estado_activo IN ('S','N')),
    CONSTRAINT uk_maquina_planta UNIQUE (numero_maquina, planta_id)
);



CREATE TABLE jefe_turno (
    empleado_id           NUMBER PRIMARY KEY,
    area_responsabilidad  VARCHAR2(100) NOT NULL,
    max_operarios_turno   NUMBER(3) NOT NULL,
    CONSTRAINT fk_jefe_empleado FOREIGN KEY (empleado_id) REFERENCES empleado(empleado_id)
);




CREATE TABLE operario (
    empleado_id           NUMBER PRIMARY KEY,
    categoria_proceso     VARCHAR2(50) NOT NULL,
    certificacion         VARCHAR2(100),
    horas_estandar_turno  NUMBER(3,1) DEFAULT 8.0 NOT NULL,
    CONSTRAINT fk_operario_empleado FOREIGN KEY (empleado_id) REFERENCES empleado(empleado_id)
);



CREATE TABLE tecnico_mantencion (
    empleado_id               NUMBER PRIMARY KEY,
    especialidad              VARCHAR2(50) NOT NULL,
    nivel_certificacion       VARCHAR2(50),
    tiempo_respuesta_estandar NUMBER(4) NOT NULL,
    CONSTRAINT fk_tecnico_empleado FOREIGN KEY (empleado_id) REFERENCES empleado(empleado_id)
);




CREATE TABLE orden_mantencion (
    orden_id             NUMBER PRIMARY KEY,
    maquina_id           NUMBER NOT NULL,
    tecnico_id           NUMBER NOT NULL,
    fecha_programada     DATE NOT NULL,
    fecha_ejecucion      DATE,
    descripcion_trabajo  VARCHAR2(500) NOT NULL,
    estado               VARCHAR2(20) DEFAULT 'Programada' NOT NULL,
    CONSTRAINT fk_orden_maquina FOREIGN KEY (maquina_id) REFERENCES maquina(maquina_id),
    CONSTRAINT fk_orden_tecnico FOREIGN KEY (tecnico_id) REFERENCES tecnico_mantencion(empleado_id),
    CONSTRAINT chk_estado_orden CHECK (estado IN ('Programada','En_Proceso','Completada','Cancelada'))
);




CREATE TABLE asignacion_turno (
    asignacion_id     NUMBER PRIMARY KEY,
    fecha             DATE NOT NULL,
    empleado_id       NUMBER NOT NULL,
    turno_id          NUMBER NOT NULL,
    maquina_id        NUMBER NOT NULL,
    rol_desempenado   VARCHAR2(50),
    CONSTRAINT fk_asignacion_empleado FOREIGN KEY (empleado_id) REFERENCES empleado(empleado_id),
    CONSTRAINT fk_asignacion_turno FOREIGN KEY (turno_id) REFERENCES turno(turno_id),
    CONSTRAINT fk_asignacion_maquina FOREIGN KEY (maquina_id) REFERENCES maquina(maquina_id),
    CONSTRAINT uk_empleado_fecha UNIQUE (fecha, empleado_id)
);


CREATE SEQUENCE seq_region START WITH 21 INCREMENT BY 1;
CREATE SEQUENCE seq_comuna START WITH 1050 INCREMENT BY 5;
CREATE SEQUENCE seq_tipo_empleado START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_planta START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_tipo_maquina START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_turno START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_empleado START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_maquina START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orden_mantencion START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_asignacion_turno START WITH 1 INCREMENT BY 1;


INSERT INTO region (region_id, nombre_region) VALUES (seq_region.NEXTVAL, 'Región de Valparaíso');
INSERT INTO region (region_id, nombre_region) VALUES (seq_region.NEXTVAL, 'Región Metropolitana');


INSERT INTO comuna (comuna_id, nombre_comuna, region_id) VALUES (seq_comuna.NEXTVAL, 'Quilpué', 21);
INSERT INTO comuna (comuna_id, nombre_comuna, region_id) VALUES (seq_comuna.NEXTVAL, 'Maipú', 22);


INSERT INTO planta (planta_id, nombre_planta, direccion, comuna_id) VALUES (seq_planta.NEXTVAL, 'Planta Oriente', 'Camino Industrial 1234', 1050);
INSERT INTO planta (planta_id, nombre_planta, direccion, comuna_id) VALUES (seq_planta.NEXTVAL, 'Planta Vidrieras', 'Av. Vidrieras 890', 1055);


INSERT INTO turno (turno_id, nombre_turno, hora_inicio, hora_termino) VALUES (seq_turno.NEXTVAL, 'Mañana', '07:00', '15:00');
INSERT INTO turno (turno_id, nombre_turno, hora_inicio, hora_termino) VALUES (seq_turno.NEXTVAL, 'Tarde', '15:00', '23:00');
INSERT INTO turno (turno_id, nombre_turno, hora_inicio, hora_termino) VALUES (seq_turno.NEXTVAL, 'Noche', '23:00', '07:00');

SELECT 
    turno_id AS "ID_TURNO",
    nombre_turno AS "TURNO",
    hora_inicio AS "ENTRADA",
    hora_termino AS "SALIDA"
FROM turno
WHERE hora_inicio > '20:00'
ORDER BY hora_inicio DESC;

SELECT 
    nombre_turno AS "TURNO",
    hora_inicio AS "ENTRADA",
    hora_termino AS "SALIDA"
FROM turno
WHERE hora_inicio BETWEEN '06:00' AND '14:59'
ORDER BY hora_inicio ASC;

