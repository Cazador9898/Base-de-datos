--Caso 1
SELECT

 tr.numrut || '-' || tr.dvrut            AS "RUT TRABAJADOR",

 INITCAP(tr.nombre || ' ' || tr.appaterno || ' ' ||

     tr.apmaterno)               AS "NOMBRE TRABAJADOR",

 INITCAP(tr.direccion)               AS "DIRECCION",

 INITCAP(NVL(ci.nombre_ciudad,'SIN CIUDAD'))    AS "CIUDAD",

 '$' || TO_CHAR(tr.sueldo_base, '999G999G999')   AS "SUELDO BASE",

 INITCAP(tt.desc_categoria)             AS "TIPO TRABAJADOR",

 INITCAP(isap.nombre_isapre)            AS "SISTEMA SALUD",

 INITCAP(afp.nombre_afp)              AS "AFP"

FROM trabajador    tr

JOIN comuna_ciudad  ci  ON tr.id_ciudad   = ci.id_ciudad

JOIN tipo_trabajador tt  ON tr.id_categoria_t = tt.id_categoria

JOIN isapre      isap ON tr.cod_isapre   = isap.cod_isapre

JOIN afp       afp ON tr.cod_afp    = afp.cod_afp

WHERE tr.sueldo_base BETWEEN 650000 AND 3000000

ORDER BY

 ci.nombre_ciudad DESC,

 tr.sueldo_base  ASC;


--Caso 2
SELECT

 INITCAP(tr.nombre || ' ' || tr.appaterno || ' ' ||

     tr.apmaterno)               AS "NOMBRE TRABAJADOR",

 INITCAP(ci.nombre_ciudad)             AS "COMUNA TRABAJADOR",

 COUNT(tk.nro_ticket)               AS "CANTIDAD TICKETS",

 '$' || TO_CHAR(ROUND(SUM(tk.monto_ticket)),

         '999G999G999')           AS "TOTAL VENDIDO",

 '$' || TO_CHAR(ROUND(SUM(ct.valor_comision)),

         '999G999G999')           AS "COMISION TOTAL"

FROM trabajador    tr

JOIN tipo_trabajador tt ON tr.id_categoria_t = tt.id_categoria

JOIN comuna_ciudad  ci ON tr.id_ciudad   = ci.id_ciudad

JOIN tickets_concierto tk ON tr.numrut    = tk.numrut_t

JOIN comisiones_ticket ct ON tk.nro_ticket  = ct.nro_ticket

WHERE UPPER(tt.desc_categoria) = 'CAJERO'

GROUP BY

 tr.numrut,

 tr.nombre,

 tr.appaterno,

 tr.apmaterno,

 ci.nombre_ciudad

HAVING SUM(tk.monto_ticket) > 50000

ORDER BY

 SUM(tk.monto_ticket) DESC;

--Caso 3

SELECT

 tr.numrut || '-' || tr.dvrut            AS "RUT TRABAJADOR",

 INITCAP(tr.nombre || ' ' || tr.appaterno || ' ' ||

     tr.apmaterno)               AS "NOMBRE TRABAJADOR",

 TO_CHAR(tr.fecing, 'YYYY')            AS "ANIO INGRESO",

 TRUNC(MONTHS_BETWEEN(SYSDATE, tr.fecing) / 12)  AS "ANTIGUEDAD_ANOS",

 CASE

  WHEN COUNT(af.numrut_carga) > 0 THEN 'SI'

  ELSE 'NO'

 END                        AS "TIENE_ASIGNACION_FAM",

 INITCAP(isap.nombre_isapre)            AS "SISTEMA_SALUD",

 ROUND(

  CASE

   WHEN UPPER(isap.nombre_isapre) = 'FONASA'

   THEN tr.sueldo_base * 0.01

   ELSE 0

  END

 )                         AS "BONO_SALUD",

 ROUND(

  CASE

   WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, tr.fecing) / 12) <= 10

   THEN tr.sueldo_base * 0.10

   ELSE tr.sueldo_base * 0.15

  END

 )                         AS "BONO_ANTIGUEDAD",

 ROUND(

  CASE

   WHEN UPPER(isap.nombre_isapre) = 'FONASA'

   THEN tr.sueldo_base * 0.01

   ELSE 0

  END

 ) +

 ROUND(

  CASE

   WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, tr.fecing) / 12) <= 10

   THEN tr.sueldo_base * 0.10

   ELSE tr.sueldo_base * 0.15

  END

 )                         AS "BONO_TOTAL"

FROM trabajador  tr

JOIN isapre    isap ON tr.cod_isapre = isap.cod_isapre

LEFT JOIN asignacion_familiar af

    ON tr.numrut = af.numrut_t

JOIN est_civil  ec

    ON tr.numrut = ec.numrut_t

WHERE ec.fecini_estcivil <= SYSDATE

 AND (ec.fecter_estcivil IS NULL

    OR ec.fecter_estcivil > SYSDATE)

GROUP BY

 tr.numrut,

 tr.dvrut,

 tr.nombre,

 tr.appaterno,

 tr.apmaterno,

 tr.fecing,

 tr.sueldo_base,

 isap.nombre_isapre

ORDER BY

 tr.numrut ASC;