-- =====================================================================
-- De la EPH a PostgreSQL · 01: tablas de códigos
-- Regiones, aglomerados y catálogos, con sus datos.
-- No usa archivos: se puede correr en el Query Tool de pgAdmin o en psql.
-- =====================================================================

-- Para empezar de cero (si se vuelve a correr, hay que correr también 02, 03 y 04)
DROP TABLE IF EXISTS regiones, aglomerados, tenencias, parentescos,
                     niveles_educativos, condiciones_actividad CASCADE;

-- Regiones -------------------------------------------------------------

CREATE TABLE regiones (
    id      smallint     PRIMARY KEY,
    nombre  varchar(40)  NOT NULL UNIQUE
);

COMMENT ON TABLE regiones     IS 'Regiones estadísticas de la EPH (variable REGION).';
COMMENT ON COLUMN regiones.id IS 'REGION: código de la región.';

INSERT INTO regiones (id, nombre) VALUES
    (1,  'Gran Buenos Aires'),
    (40, 'Noroeste'),
    (41, 'Noreste'),
    (42, 'Cuyo'),
    (43, 'Pampeana'),
    (44, 'Patagonia');

-- Aglomerados ------------------------------------------------------------

CREATE TABLE aglomerados (
    id         smallint     PRIMARY KEY,
    nombre     varchar(60)  NOT NULL UNIQUE,
    id_region  smallint     NOT NULL REFERENCES regiones (id)
);

COMMENT ON TABLE aglomerados     IS 'Aglomerados urbanos relevados por la EPH (variable AGLOMERADO).';
COMMENT ON COLUMN aglomerados.id IS 'AGLOMERADO: código del aglomerado.';

INSERT INTO aglomerados (id, nombre, id_region) VALUES
    (2,  'Gran La Plata', 43),
    (3,  'Bahía Blanca-Cerri', 43),
    (4,  'Gran Rosario', 43),
    (5,  'Gran Santa Fe', 43),
    (6,  'Gran Paraná', 43),
    (7,  'Posadas', 41),
    (8,  'Gran Resistencia', 41),
    (9,  'Comodoro Rivadavia-Rada Tilly', 44),
    (10, 'Gran Mendoza', 42),
    (12, 'Corrientes', 41),
    (13, 'Gran Córdoba', 43),
    (14, 'Concordia', 43),
    (15, 'Formosa', 41),
    (17, 'Neuquén-Plottier', 44),
    (18, 'Santiago del Estero-La Banda', 40),
    (19, 'Jujuy-Palpalá', 40),
    (20, 'Río Gallegos', 44),
    (22, 'Gran Catamarca', 40),
    (23, 'Gran Salta', 40),
    (25, 'La Rioja', 40),
    (26, 'Gran San Luis', 42),
    (27, 'Gran San Juan', 42),
    (29, 'Gran Tucumán-Tafí Viejo', 40),
    (30, 'Santa Rosa-Toay', 43),
    (31, 'Ushuaia-Río Grande', 44),
    (32, 'Ciudad Autónoma de Buenos Aires', 1),
    (33, 'Partidos del Gran Buenos Aires', 1),
    (34, 'Mar del Plata', 43),
    (36, 'Río Cuarto', 43),
    (38, 'San Nicolás-Villa Constitución', 43),
    (91, 'Rawson-Trelew', 44),
    (93, 'Viedma-Carmen de Patagones', 44);

-- Catálogos ----------------------------------------------------------------

CREATE TABLE tenencias (
    id           smallint     PRIMARY KEY,
    descripcion  varchar(60)  NOT NULL
);

COMMENT ON TABLE tenencias IS 'Códigos de II7: régimen de tenencia de la vivienda.';

INSERT INTO tenencias (id, descripcion) VALUES
    (1, 'Propietario de la vivienda y el terreno'),
    (2, 'Propietario de la vivienda solamente'),
    (3, 'Inquilino/arrendatario'),
    (4, 'Ocupante por pago de impuestos/expensas'),
    (5, 'Ocupante en relación de dependencia'),
    (6, 'Ocupante gratuito (con permiso)'),
    (7, 'Ocupante de hecho (sin permiso)'),
    (8, 'Está en sucesión'),
    (9, 'Otra situación');

CREATE TABLE parentescos (
    id           smallint     PRIMARY KEY,
    descripcion  varchar(40)  NOT NULL
);

COMMENT ON TABLE parentescos IS 'Códigos de CH03: relación de parentesco con el jefe/a del hogar.';

INSERT INTO parentescos (id, descripcion) VALUES
    (1,  'Jefe/a'),
    (2,  'Cónyuge/Pareja'),
    (3,  'Hijo/Hijastro/a'),
    (4,  'Yerno/Nuera'),
    (5,  'Nieto/a'),
    (6,  'Madre/Padre'),
    (7,  'Suegro/a'),
    (8,  'Hermano/a'),
    (9,  'Otros familiares'),
    (10, 'No familiares');

CREATE TABLE niveles_educativos (
    id           smallint     PRIMARY KEY,
    descripcion  varchar(60)  NOT NULL,
    orden        smallint     NOT NULL UNIQUE
);

COMMENT ON TABLE niveles_educativos IS 'Códigos de NIVEL_ED. La columna orden sirve para ordenar de menor a mayor nivel.';

INSERT INTO niveles_educativos (id, descripcion, orden) VALUES
    (7, 'Sin instrucción', 1),
    (1, 'Primario incompleto (incluye educación especial)', 2),
    (2, 'Primario completo', 3),
    (3, 'Secundario incompleto', 4),
    (4, 'Secundario completo', 5),
    (5, 'Superior universitario incompleto', 6),
    (6, 'Superior universitario completo', 7),
    (9, 'Ns/Nr', 9);

CREATE TABLE condiciones_actividad (
    id           smallint     PRIMARY KEY,
    descripcion  varchar(60)  NOT NULL
);

COMMENT ON TABLE condiciones_actividad IS 'Códigos de ESTADO: condición de actividad.';

INSERT INTO condiciones_actividad (id, descripcion) VALUES
    (0, 'Entrevista individual no realizada'),
    (1, 'Ocupado'),
    (2, 'Desocupado'),
    (3, 'Inactivo'),
    (4, 'Menor de 10 años');
