-- Consultas sobre la EPH en BigQuery
-- Usan la tabla eph.hogares de la Guía de Laboratorio II: un hogar por fila,
-- con la lista de sus personas adentro.
-- pondera expande los casos a la población; pondih es el ponderador de los ingresos.


-- 1. Hogares según la cantidad de integrantes
-- Las personas están adentro de cada hogar: alcanza con medir el largo de la lista, sin JOIN.
SELECT LEAST(ARRAY_LENGTH(personas.list), 6) AS integrantes,  -- 6 incluye a los hogares de 6 o más
  COUNT(*) AS hogares_encuestados,
  ROUND(100 * SUM(pondera) / SUM(SUM(pondera)) OVER (), 1) AS porcentaje
FROM eph.hogares
GROUP BY integrantes
ORDER BY integrantes;


-- 2. Pirámide de población, en millones de personas
-- Para verla como gráfico, abrir la pestaña Visualización de los resultados.
SELECT LEAST(DIV(p.element.edad, 10) * 10, 80) AS edad_desde,  -- 80 incluye a las personas de 80 o más
  ROUND(SUM(IF(p.element.sexo = 'Varón', pondera, 0)) / 1e6, 2) AS varones,
  ROUND(SUM(IF(p.element.sexo = 'Mujer', pondera, 0)) / 1e6, 2) AS mujeres
FROM eph.hogares, UNNEST(personas.list) AS p
GROUP BY edad_desde
ORDER BY edad_desde;


-- 3. Tasa de desocupación de jóvenes y adultos, por sexo
SELECT IF(p.element.edad < 30, '15 a 29', '30 o más') AS edad,
  p.element.sexo AS sexo,
  ROUND(100 * SUM(IF(p.element.estado = 'Desocupado', pondera, 0))
    / SUM(IF(p.element.estado IN ('Ocupado', 'Desocupado'), pondera, 0)), 1) AS tasa_desocupacion
FROM eph.hogares, UNNEST(personas.list) AS p
WHERE p.element.edad >= 15
GROUP BY edad, sexo
ORDER BY edad, sexo;


-- 4. Ingreso total familiar promedio por región, en pesos
-- Se pondera con pondih, que compensa a los hogares que no declararon sus ingresos.
SELECT region,
  CAST(SUM(itf * pondih) / SUM(pondih) AS INT64) AS ingreso_promedio
FROM eph.hogares
GROUP BY region
ORDER BY ingreso_promedio DESC;
