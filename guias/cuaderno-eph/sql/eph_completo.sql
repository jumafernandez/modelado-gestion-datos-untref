-- =====================================================================
-- De la EPH a PostgreSQL · script completo
-- Corre los cuatro scripts en orden. Desde psql (o el PSQL Tool de pgAdmin),
-- conectado a la base eph y parado en la carpeta de los CSV y los scripts:
--
--   \cd C:/Users/ana/Downloads/eph       (en Mac: \cd /Users/ana/Downloads/eph)
--   \i eph_completo.sql
-- =====================================================================

\ir 01_codigos.sql
\ir 02_hogares.sql
\ir 03_personas.sql
\ir 04_vistas.sql
