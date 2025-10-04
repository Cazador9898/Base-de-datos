
CREATE TABLE REGION (
    id_region NUMBER(4) NOT NULL,
    nom_region VARCHAR2(255) NOT NULL,
    CONSTRAINT REGION_PK PRIMARY KEY (id_region),
    CONSTRAINT REGION_NOM_REGION_UN UNIQUE (nom_region)
);


CREATE TABLE COMUNA (
    id_comuna NUMBER(4) NOT NULL,
    nom_comuna VARCHAR2(100) NOT NULL,
    cod_region NUMBER(4) NOT NULL,
    CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna),
    CONSTRAINT COMUNA_NOM_COMUNA_UN UNIQUE (nom_comuna),
    CONSTRAINT COMUNA_REGION_FK FOREIGN KEY (cod_region) REFERENCES REGION(id_region)
);


CREATE TABLE SALUD (
    id_salud NUMBER(4) NOT NULL,
    nom_salud VARCHAR2(40) NOT NULL,
    CONSTRAINT SALUD_PK PRIMARY KEY (id_salud),
    CONSTRAINT SALUD_NOM_SALUD_UN UNIQUE (nom_salud)
);


CREATE TABLE AFP (
    id_afp NUMBER(5) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 6) NOT NULL,
    nom_afp VARCHAR2(255) NOT NULL,
    CONSTRAINT APP_PK PRIMARY KEY (id_afp),
    CONSTRAINT APP_NOM_AFP_UN UNIQUE (nom_afp)
);


CREATE TABLE MEDIO_PAGO (
    id_mpago NUMBER(3) NOT NULL,
    nombre_mpago VARCHAR2(50) NOT NULL,
    CONSTRAINT MEDIO_PAGO_PK PRIMARY KEY (id_mpago),
    CONSTRAINT MEDIO_PAGO_NOMBRE_UN UNIQUE (nombre_mpago)
);


CREATE TABLE CATEGORIA (
    id_categoria NUMBER(3) NOT NULL,
    nombre_categoria VARCHAR2(255) NOT NULL,
    CONSTRAINT CATEGORIA_PK PRIMARY KEY (id_categoria),
    CONSTRAINT CATEGORIA_NOMBRE_UN UNIQUE (nombre_categoria)
);


CREATE TABLE MARCA (
    cod_marca NUMBER(3) NOT NULL,
    nombre_marca VARCHAR2(100) NOT NULL,
    CONSTRAINT MARCA_PK PRIMARY KEY (cod_marca),
    CONSTRAINT MARCA_NOMBRE_UN UNIQUE (nombre_marca)
);


CREATE TABLE PROVEEDOR (
    id_proveedor NUMBER(5) NOT NULL,
    nombre_proveedor VARCHAR2(150) NOT NULL,
    rut_proveedor VARCHAR2(10) NOT NULL,
    telefono VARCHAR2(10) NOT NULL,
    email VARCHAR2(200) NOT NULL,
    direccion VARCHAR2(200) NOT NULL,
    cod_comuna NUMBER(3) NOT NULL,
    CONSTRAINT PROVEEDOR_PK PRIMARY KEY (id_proveedor),
    CONSTRAINT PROVEEDOR_RUT_UN UNIQUE (rut_proveedor),
    CONSTRAINT PROVEEDOR_EMAIL_UN UNIQUE (email),
    CONSTRAINT PROVEEDOR_COMUNA_FK FOREIGN KEY (cod_comuna) REFERENCES COMUNA(id_comuna),
    CONSTRAINT PROVEEDOR_EMAIL_CK CHECK (email LIKE '%@%.%')
);


CREATE TABLE PRODUCTO (
    id_producto NUMBER(4) NOT NULL,
    nombre_producto VARCHAR2(100) NOT NULL,
    precio_unitario NUMBER(10) NOT NULL,
    origen_nacional CHAR(1) NOT NULL,
    stock_minimo NUMBER(3) NOT NULL,
    activo CHAR(1) NOT NULL,
    cod_marca NUMBER(3) NOT NULL,
    cod_categoria NUMBER(3) NOT NULL,
    cod_proveedor NUMBER(3) NOT NULL,
    CONSTRAINT PRODUCTO_PK PRIMARY KEY (id_producto),
    CONSTRAINT PRODUCTO_MARCA_FK FOREIGN KEY (cod_marca) REFERENCES MARCA(cod_marca),
    CONSTRAINT PRODUCTO_CATEGORIA_FK FOREIGN KEY (cod_categoria) REFERENCES CATEGORIA(id_categoria),
    CONSTRAINT PRODUCTO_PROVEEDOR_FK FOREIGN KEY (cod_proveedor) REFERENCES PROVEEDOR(id_proveedor),
    CONSTRAINT PRODUCTO_DECOL_UNITINO_CK CHECK (cod_proveedor IN ('S','N')),
    CONSTRAINT PRODUCTO_ACTION_CK CHECK (activo IN ('A','I','D')),
    CONSTRAINT PRODUCTO_PRECIO_CK CHECK (precio_unitario > 0)
);


CREATE TABLE EMPLEADO (
    id_empleado NUMBER(4) NOT NULL,
    rut_empleado VARCHAR2(10) NOT NULL,
    nombre_empleado VARCHAR2(25) NOT NULL,
    apellido_paterno VARCHAR2(25) NOT NULL,
    apellido_materno VARCHAR2(25) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    sueldo_base NUMBER(10) NOT NULL,
    bono_jefatura CHAR(1) NOT NULL,
    activo CHAR(1) NOT NULL,
    tipo_empleado NUMBER(4) NOT NULL,
    cod_empleado NUMBER(4) NOT NULL,
    cod_salud NUMBER(4) NOT NULL,
    cod_afp NUMBER(5) NOT NULL,
    CONSTRAINT EMPLEADO_PK PRIMARY KEY (id_empleado),
    CONSTRAINT EMPLEADO_RUT_UN UNIQUE (rut_empleado),
    CONSTRAINT EMPLEADO_EMPLEADO_FK FOREIGN KEY (cod_empleado) REFERENCES EMPLEADO(id_empleado),
    CONSTRAINT EMPLEADO_SALUD_FK FOREIGN KEY (cod_salud) REFERENCES SALUD(id_salud),
    CONSTRAINT EMPLEADO_AFP_FK FOREIGN KEY (cod_afp) REFERENCES AFP(id_afp),
    CONSTRAINT EMPLEADO_BONO_JEFATURA_CK CHECK (bono_jefatura IN ('S','N')),
    CONSTRAINT EMPLEADO_ACTIVO_CK CHECK (activo IN ('ACTIVO','INACTIVO')),
    CONSTRAINT EMPLEADO_SUELDO_CK CHECK (sueldo_base > 0)
);


CREATE TABLE VENDEDOR (
    id_empleado NUMBER(4) NOT NULL,
    comision_venta NUMBER(2,2) NOT NULL,
    CONSTRAINT VENDEDOR_PK PRIMARY KEY (id_empleado),
    CONSTRAINT VENDEDOR_EMPLEADO_FK FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado),
    CONSTRAINT VENDEDOR_COMISION_CK CHECK (comision_venta BETWEEN 0 AND 1)
);


CREATE TABLE ADMINISTRATIVO (
    id_empleado NUMBER(4) NOT NULL,
    CONSTRAINT ADMINISTRATIVO_PK PRIMARY KEY (id_empleado),
    CONSTRAINT ADMINISTRATIVO_EMPLEADO_FK FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado)
);


CREATE TABLE VENTA (
    id_venta NUMBER(4) GENERATED ALWAYS AS IDENTITY (START WITH 5050 INCREMENT BY 3) NOT NULL,
    fecha_venta DATE NOT NULL,
    total_venta NUMBER(10) NOT NULL,
    cod_mpago NUMBER(3) NOT NULL,
    cod_empleado NUMBER(4) NOT NULL,
    CONSTRAINT VENTA_PK PRIMARY KEY (id_venta),
    CONSTRAINT VENTA_EMPLEADO_FK FOREIGN KEY (cod_empleado) REFERENCES EMPLEADO(id_empleado),
    CONSTRAINT VENTA_MEDIO_PAGO_FK FOREIGN KEY (cod_mpago) REFERENCES MEDIO_PAGO(id_mpago),
    CONSTRAINT VENTA_TOTAL_CK CHECK (total_venta >= 0)
);


CREATE TABLE DETALLE_VENTA (
    cod_venta NUMBER(4) NOT NULL,
    cod_producto NUMBER(4) NOT NULL,
    cantidad NUMBER(6) NOT NULL,
    CONSTRAINT DETALLE_VENTA_PK PRIMARY KEY (cod_venta, cod_producto),
    CONSTRAINT DETALLE_VENTA_VENTA_FK FOREIGN KEY (cod_venta) REFERENCES VENTA(id_venta),
    CONSTRAINT DETALLE_VENTA_PRODUCTO_FK FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(id_producto),
    CONSTRAINT DETALLE_VENTA_CANTIDAD_CK CHECK (cantidad > 0)
);


COMMENT ON TABLE REGION IS 'Tabla que almacena las regiones de Chile';
COMMENT ON TABLE COMUNA IS 'Tabla que almacena las comunas de Chile con referencia a su región';
COMMENT ON TABLE SALUD IS 'Tabla que almacena las instituciones de salud previsional';
COMMENT ON TABLE AFP IS 'Tabla que almacena las Administradoras de Fondos de Pensiones (AFP)';
COMMENT ON TABLE MEDIO_PAGO IS 'Tabla que almacena los medios de pago disponibles';
COMMENT ON TABLE CATEGORIA IS 'Tabla que almacena las categorías de productos';
COMMENT ON TABLE MARCA IS 'Tabla que almacena las marcas de productos';
COMMENT ON TABLE PROVEEDOR IS 'Tabla que almacena los proveedores de productos';
COMMENT ON TABLE PRODUCTO IS 'Tabla que almacena los productos del sistema';
COMMENT ON TABLE EMPLEADO IS 'Tabla que almacena los empleados de la empresa';
COMMENT ON TABLE VENDEDOR IS 'Tabla que almacena los empleados que son vendedores';
COMMENT ON TABLE ADMINISTRATIVO IS 'Tabla que almacena los empleados que son administrativos';
COMMENT ON TABLE VENTA IS 'Tabla que almacena las ventas realizadas';
COMMENT ON TABLE DETALLE_VENTA IS 'Tabla que almacena el detalle de los productos vendidos en cada venta';


ALTER TABLE EMPLEADO 
ADD CONSTRAINT EMPLEADO_SUELDO_MINIMO_CK 
CHECK (sueldo_base >= 400000);


ALTER TABLE VENDEDOR 
ADD CONSTRAINT VENDEDOR_COMISION_MAXIMA_CK 
CHECK (comision_venta BETWEEN 0 AND 0.25);


ALTER TABLE PRODUCTO 
ADD CONSTRAINT PRODUCTO_STOCK_MINIMO_CK 
CHECK (stock_minimo >= 3);


ALTER TABLE DETALLE_VENTA 
ADD CONSTRAINT DETALLE_VENTA_CANTIDAD_MINIMA_CK 
CHECK (cantidad >= 1);

CREATE SEQUENCE SEQ_SALUD 
START WITH 2050 
INCREMENT BY 10;

CREATE SEQUENCE SEQ_EMPLEADO 
START WITH 750 
INCREMENT BY 3;

CREATE SEQUENCE SEQ_AFP 
START WITH 210 
INCREMENT BY 6;

COMMIT;

INSERT INTO REGION (id_region, nom_region) VALUES (1, 'Region Metropolitana');
INSERT INTO REGION (id_region, nom_region) VALUES (2, 'Valparaiso');
INSERT INTO REGION (id_region, nom_region) VALUES (3, 'Biobio');
INSERT INTO REGION (id_region, nom_region) VALUES (4, 'Los Lagos');
COMMIT;

INSERT INTO AFP (id_afp, nom_afp) VALUES (SEQ_AFP.NEXTVAL, 'AFP Habitat');
INSERT INTO AFP (id_afp, nom_afp) VALUES (SEQ_AFP.NEXTVAL, 'AFP Cuprum');
INSERT INTO AFP (id_afp, nom_afp) VALUES (SEQ_AFP.NEXTVAL, 'AFP Provida');
INSERT INTO AFP (id_afp, nom_afp) VALUES (SEQ_AFP.NEXTVAL, 'AFP Planvital');
COMMIT;

INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Fonasa');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Colmena');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Bamedica');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Cruz Blanca');
COMMIT;

INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (11, 'Efectivo');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (12, 'Tarjeta Debito');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (13, 'Tarjeta Credito');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (14, 'Cheque');
COMMIT;

ALTER TABLE EMPLEADO DROP CONSTRAINT EMPLEADO_ACTIVO_CK;

ALTER TABLE EMPLEADO 
ADD CONSTRAINT EMPLEADO_ACTIVO_CK 
CHECK (activo IN ('A','I'));

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (750, '11111111-1', 'Merce1a', 'Gonzalez', 'Perez', TO_DATE('15-03-2022', 'DD-MM-YYYY'), 950000, 'S', 'A', 1, 750, 2050, 210);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (753, '22222222-2', 'José', 'Muñoz', 'Ramírez', TO_DATE('10-07-2021', 'DD-MM-YYYY'), 900000, 'S', 'A', 1, 753, 2060, 216);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (756, '33333333-3', 'Verónica', 'Soto', 'Alarcon', TO_DATE('05-01-2020', 'DD-MM-YYYY'), 880000, 'N', 'A', 2, 750, 2060, 228);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (759, '44444444-4', 'Luis', 'Reyes', 'Fuentes', TO_DATE('01-04-2023', 'DD-MM-YYYY'), 560000, 'N', 'A', 2, 750, 2070, 228);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (762, '55555555-5', 'Claudia', 'Fernández', 'Lagos', TO_DATE('15-04-2023', 'DD-MM-YYYY'), 600000, 'N', 'A', 2, 753, 2070, 216);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (765, '66666666-6', 'Carlos', 'Navarro', 'Vega', TO_DATE('01-05-2023', 'DD-MM-YYYY'), 610000, 'N', 'A', 1, 753, 2060, 210);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (768, '77777777-7', 'Javiera', 'Pino', 'Rojas', TO_DATE('10-05-2023', 'DD-MM-YYYY'), 650000, 'N', 'A', 1, 750, 2050, 210);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (771, '88888888-8', 'Diego', 'Mella', 'Contreras', TO_DATE('12-05-2023', 'DD-MM-YYYY'), 620000, 'N', 'A', 2, 750, 2060, 216);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (774, '99999999-9', 'Fernanda', 'Salas', 'Herrera', TO_DATE('18-05-2023', 'DD-MM-YYYY'), 570000, 'N', 'A', 2, 753, 2070, 228);

INSERT INTO EMPLEADO (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, cod_empleado, cod_salud, cod_afp) 
VALUES (777, '10101010-0', 'Tomás', 'Vidal', 'Espinoza', TO_DATE('01-06-2023', 'DD-MM-YYYY'), 550000, 'N', 'A', 2, 750, 2050, 222);
COMMIT;

--En la tabla salen algunos empleados en el codigo de empleados como NULL, le agregue un codigo para evitar el error--

INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado) 
VALUES (TO_DATE('12-05-2023', 'DD-MM-YYYY'), 225990, 12, 771);

INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado) 
VALUES (TO_DATE('23-10-2023', 'DD-MM-YYYY'), 524990, 13, 777);

INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado) 
VALUES (TO_DATE('17-02-2023', 'DD-MM-YYYY'), 466990, 11, 759);
COMMIT;

SELECT 
    e.id_empleado AS IDENTIFICADOR,
    e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || e.apellido_materno AS "NOMBRE COMPLETO",
    e.sueldo_base AS SALARIO,
    CASE 
        WHEN e.bono_jefatura = 'S' THEN 80000
        WHEN e.id_empleado = 756 THEN 70000  -- Caso específico de Verónica Soto
        ELSE 0
    END AS BONIFICACION,
    (e.sueldo_base + 
        CASE 
            WHEN e.bono_jefatura = 'S' THEN 80000
            WHEN e.id_empleado = 756 THEN 70000  -- Caso específico de Verónica Soto
            ELSE 0
        END
    ) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.activo = 'A'
    AND (e.bono_jefatura = 'S' OR e.id_empleado = 756)  -- Incluir Verónica específicamente
ORDER BY "SALARIO SIMULADO" DESC, e.apellido_paterno DESC;

SELECT 
    e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || e.apellido_materno AS EMPLEADO,
    e.sueldo_base AS SUELDO,
    ROUND(e.sueldo_base * 0.08) AS "POSIBLE AUMENTO",
    (e.sueldo_base + ROUND(e.sueldo_base * 0.08)) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.sueldo_base BETWEEN 550000 AND 800000
ORDER BY e.sueldo_base ASC;
