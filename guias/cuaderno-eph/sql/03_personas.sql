-- =====================================================================
-- De la EPH a PostgreSQL · 03: personas
-- Carga personas.csv y arma la tabla personas.
-- Necesita 01_codigos.sql y 02_hogares.sql. Usa \copy: se corre desde psql
-- (o el PSQL Tool de pgAdmin), parado en la carpeta donde está personas.csv.
-- =====================================================================

-- Para empezar de cero (si se vuelve a correr, hay que correr también 04)
DROP TABLE IF EXISTS stg_personas, personas CASCADE;

-- Staging: las mismas columnas que el CSV, todas de texto -----------------

CREATE TABLE stg_personas (
    codusu text, ano4 text, trimestre text, nro_hogar text, componente text,
    region text, aglomerado text, pondera text,
    ch03 text, ch04 text, ch06 text, nivel_ed text, estado text,
    p21 text, p47t text, itf text, ipcf text
);

\copy stg_personas FROM 'personas.csv' DELIMITER ',' CSV HEADER

-- Personas ------------------------------------------------------------------

CREATE TABLE personas (
    codusu                       char(29)       NOT NULL,
    anio                         smallint       NOT NULL,
    trimestre                    smallint       NOT NULL,
    nro_hogar                    smallint       NOT NULL,
    componente                   smallint       NOT NULL,
    id_parentesco                smallint       NOT NULL REFERENCES parentescos (id),
    sexo                         smallint       NOT NULL CHECK (sexo IN (1, 2)),
    edad                         smallint       NOT NULL CHECK (edad >= 0),
    id_nivel_educativo           smallint       NOT NULL REFERENCES niveles_educativos (id),
    id_condicion_actividad       smallint       NOT NULL REFERENCES condiciones_actividad (id),
    ingreso_ocupacion_principal  numeric(14,2)  CHECK (ingreso_ocupacion_principal >= 0),
    ingreso_total_individual     numeric(14,2)  CHECK (ingreso_total_individual >= 0),
    PRIMARY KEY (codusu, anio, trimestre, nro_hogar, componente),
    FOREIGN KEY (codusu, anio, trimestre, nro_hogar)
        REFERENCES hogares (codusu, anio, trimestre, nro_hogar)
);

COMMENT ON TABLE personas                         IS 'Personas de cada hogar relevado (base usu_individual).';
COMMENT ON COLUMN personas.componente             IS 'COMPONENTE: número de orden de la persona dentro del hogar.';
COMMENT ON COLUMN personas.id_parentesco          IS 'CH03: parentesco con el jefe/a del hogar.';
COMMENT ON COLUMN personas.sexo                   IS 'CH04: sexo (1 = varón, 2 = mujer).';
COMMENT ON COLUMN personas.edad                   IS 'CH06: años cumplidos (0 = menos de un año).';
COMMENT ON COLUMN personas.id_nivel_educativo     IS 'NIVEL_ED: nivel educativo.';
COMMENT ON COLUMN personas.id_condicion_actividad IS 'ESTADO: condición de actividad.';
COMMENT ON COLUMN personas.ingreso_ocupacion_principal IS 'P21: ingreso de la ocupación principal, en pesos corrientes. NULL = no sabe o no responde.';
COMMENT ON COLUMN personas.ingreso_total_individual    IS 'P47T: ingreso total individual, en pesos corrientes. NULL = no sabe, no responde o sin dato.';

INSERT INTO personas (codusu, anio, trimestre, nro_hogar, componente,
                      id_parentesco, sexo, edad, id_nivel_educativo,
                      id_condicion_actividad, ingreso_ocupacion_principal,
                      ingreso_total_individual)
SELECT codusu,
       ano4::smallint,
       trimestre::smallint,
       nro_hogar::smallint,
       componente::smallint,
       ch03::smallint,
       ch04::smallint,
       GREATEST(ch06::smallint, 0),
       nivel_ed::smallint,
       estado::smallint,
       NULLIF(REPLACE(p21, ',', '.')::numeric, -9),
       NULLIF(REPLACE(p47t, ',', '.')::numeric, -9)
FROM stg_personas;

-- El staging ya cumplió su función --------------------------------------------

DROP TABLE stg_personas;
ANALYZE personas;
