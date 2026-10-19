-- =====================================================================
-- De la EPH a PostgreSQL · 04: vistas
-- La vista con los atributos derivados y la vista materializada del capítulo 6.
-- Necesita 01, 02 y 03. Se puede correr en el Query Tool de pgAdmin o en psql.
-- =====================================================================

DROP MATERIALIZED VIEW IF EXISTS resumen_trimestral;
DROP VIEW IF EXISTS ingresos_hogares;

-- Atributos derivados: cantidad de miembros e ingreso per cápita familiar
CREATE VIEW ingresos_hogares AS
SELECT h.codusu,
       h.anio,
       h.trimestre,
       h.nro_hogar,
       COUNT(*) AS miembros,
       h.ingreso_total_familiar,
       ROUND(h.ingreso_total_familiar / COUNT(*), 2) AS ingreso_per_capita,
       h.pondih
FROM hogares h
INNER JOIN personas p ON h.codusu = p.codusu AND h.anio = p.anio
                     AND h.trimestre = p.trimestre AND h.nro_hogar = p.nro_hogar
GROUP BY h.codusu, h.anio, h.trimestre, h.nro_hogar;

-- Resumen por región y trimestre, calculado una vez y guardado
CREATE MATERIALIZED VIEW resumen_trimestral AS
SELECT r.nombre AS region,
       h.anio,
       h.trimestre,
       SUM(h.pondera) AS hogares,
       ROUND(100.0 * SUM(CASE WHEN h.id_tenencia = 3 THEN h.pondera ELSE 0 END)
             / SUM(h.pondera), 1) AS pct_inquilinos,
       ROUND(SUM(i.ingreso_per_capita * i.pondih) / SUM(i.pondih)) AS ipcf_promedio
FROM hogares h
INNER JOIN ingresos_hogares i ON h.codusu = i.codusu AND h.anio = i.anio
                             AND h.trimestre = i.trimestre AND h.nro_hogar = i.nro_hogar
INNER JOIN viviendas v   ON h.codusu = v.codusu
INNER JOIN aglomerados a ON v.id_aglomerado = a.id
INNER JOIN regiones r    ON a.id_region = r.id
GROUP BY r.nombre, h.anio, h.trimestre;
