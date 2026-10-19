-- =====================================================================
-- De la EPH a PostgreSQL · 02: viviendas y hogares
-- Carga hogares.csv y arma las tablas viviendas y hogares.
-- Necesita 01_codigos.sql. Usa \copy: se corre desde psql (o el PSQL Tool
-- de pgAdmin), parado en la carpeta donde está hogares.csv.
-- =====================================================================

-- Para empezar de cero (si se vuelve a correr, hay que correr también 03 y 04)
DROP TABLE IF EXISTS stg_hogares, hogares, viviendas CASCADE;

-- Staging: las mismas columnas que el CSV, todas de texto -----------------

CREATE TABLE stg_hogares (
    codusu text, ano4 text, trimestre text, nro_hogar text,
    region text, aglomerado text, pondera text, ii7 text,
    ix_tot text, itf text, ipcf text, pondih text
);

\copy stg_hogares FROM 'hogares.csv' DELIMITER ',' CSV HEADER

-- Viviendas -----------------------------------------------------------------

CREATE TABLE viviendas (
    codusu         char(29)  PRIMARY KEY,
    id_aglomerado  smallint  NOT NULL REFERENCES aglomerados (id)
);

COMMENT ON TABLE viviendas                IS 'Viviendas de la muestra. Una misma vivienda se visita en varios trimestres.';
COMMENT ON COLUMN viviendas.codusu        IS 'CODUSU: código que identifica la vivienda y permite seguirla entre trimestres.';
COMMENT ON COLUMN viviendas.id_aglomerado IS 'AGLOMERADO: aglomerado donde está la vivienda.';

INSERT INTO viviendas (codusu, id_aglomerado)
SELECT DISTINCT codusu,
       aglomerado::smallint
FROM stg_hogares;

-- Hogares -------------------------------------------------------------------

CREATE TABLE hogares (
    codusu                  char(29)       NOT NULL REFERENCES viviendas (codusu),
    anio                    smallint       NOT NULL CHECK (anio >= 2003),
    trimestre               smallint       NOT NULL,
    nro_hogar               smallint       NOT NULL,
    id_tenencia             smallint       REFERENCES tenencias (id),
    ingreso_total_familiar  numeric(14,2)  CHECK (ingreso_total_familiar >= 0),
    pondera                 integer        NOT NULL CHECK (pondera > 0),
    pondih                  integer        NOT NULL CHECK (pondih >= 0),
    CONSTRAINT trimestre_valido CHECK (trimestre BETWEEN 1 AND 4),
    PRIMARY KEY (codusu, anio, trimestre, nro_hogar)
);

COMMENT ON TABLE hogares                         IS 'Hogares relevados en cada trimestre (base usu_hogar).';
COMMENT ON COLUMN hogares.anio                   IS 'ANO4: año del relevamiento.';
COMMENT ON COLUMN hogares.trimestre              IS 'TRIMESTRE: trimestre del relevamiento.';
COMMENT ON COLUMN hogares.nro_hogar              IS 'NRO_HOGAR: número de hogar dentro de la vivienda.';
COMMENT ON COLUMN hogares.id_tenencia            IS 'II7: régimen de tenencia. NULL si no hay dato.';
COMMENT ON COLUMN hogares.ingreso_total_familiar IS 'ITF: ingreso total familiar, en pesos corrientes. NULL si el hogar no respondió ingresos.';
COMMENT ON COLUMN hogares.pondera                IS 'PONDERA: ponderador del hogar (factor de expansión).';
COMMENT ON COLUMN hogares.pondih                 IS 'PONDIH: ponderador para los ingresos del hogar, corregido por no respuesta.';

INSERT INTO hogares (codusu, anio, trimestre, nro_hogar, id_tenencia,
                     ingreso_total_familiar, pondera, pondih)
SELECT codusu,
       ano4::smallint,
       trimestre::smallint,
       nro_hogar::smallint,
       NULLIF(ii7, '0')::smallint,
       CASE WHEN REPLACE(itf, ',', '.')::numeric = 0 AND pondih = '0' THEN NULL
            ELSE REPLACE(itf, ',', '.')::numeric
       END,
       pondera::integer,
       pondih::integer
FROM stg_hogares;

-- El staging ya cumplió su función --------------------------------------------

DROP TABLE stg_hogares;
ANALYZE viviendas, hogares;
