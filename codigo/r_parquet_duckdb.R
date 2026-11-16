# =====================================================================
# Laboratorio: del JSON a Parquet, con arrow y DuckDB
# Modelado y Gestión de Datos - UNTREF - 2026
#
# Qué hace este script:
#   1. Instala los paquetes que falten y los carga.
#   2. Descarga los hogares de la EPH en JSON, el mismo archivo que
#      importamos en MongoDB.
#   3. Lo guarda en Parquet y compara el tamaño de los dos archivos.
#   4. Vuelve a leer el Parquet y lo consulta con dplyr (arrow).
#   5. Consulta el mismo archivo con SQL en DuckDB, sin importarlo.
#   6. Mide cuánto tarda la misma consulta sobre el JSON y sobre el Parquet.
#
# Los archivos se guardan en la carpeta de trabajo, que se ve con getwd().
# Se corre de a una línea: Ctrl + Enter (Cmd + Enter en Mac).
# =====================================================================


# 1. Paquetes ----------------------------------------------------------
# Instala solo los que falten (la primera vez tarda unos minutos)
paquetes <- c("arrow", "duckdb", "dplyr", "tidyr")
faltan <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltan) > 0) install.packages(faltan)

library(arrow)    # lee y escribe archivos Parquet
library(duckdb)   # motor SQL analítico que corre dentro de R (trae DBI)
library(dplyr)    # filter(), group_by(), summarise(), arrange()...
library(tidyr)    # unnest(), para separar las personas de cada hogar


# 2. Bajar el JSON -----------------------------------------------------
# Un hogar por línea, con la lista de sus personas adentro
url <- "https://raw.githubusercontent.com/jumafernandez/modelado-gestion-datos-untref/main/data/eph_hogares_2026t1.json"
download.file(url, "eph_hogares.json", mode = "wb")

# La primera línea: un documento JSON por hogar
readLines("eph_hogares.json", n = 1)


# 3. Del JSON a Parquet ------------------------------------------------
hogares <- read_json_arrow("eph_hogares.json")
hogares                   # la columna personas guarda las personas de cada hogar

write_parquet(hogares, "eph_hogares.parquet")

# Los mismos datos, en mucho menos espacio (en MB)
file.size("eph_hogares.json") / 1e6
file.size("eph_hogares.parquet") / 1e6


# 4. Volver a leer el Parquet y consultarlo con dplyr -----------------
# open_dataset() no carga los datos: solo mira las columnas y sus tipos
eph <- open_dataset("eph_hogares.parquet")
eph

# dplyr arma la consulta, arrow la ejecuta y collect() trae el resultado
eph |>
  group_by(region) |>
  summarise(hogares = n(), itf_promedio = mean(itf, na.rm = TRUE)) |>
  arrange(desc(hogares)) |>
  collect()

# Leer solo algunas columnas: Parquet guarda cada columna por separado
read_parquet("eph_hogares.parquet", col_select = c(region, aglomerado, itf))

# Las personas de cada hogar: unnest() las separa, como $unwind en MongoDB
personas <- read_parquet("eph_hogares.parquet") |>
  select(region, pondera, personas) |>
  unnest(personas)
personas


# 5. SQL con DuckDB, directo sobre el archivo --------------------------
# DuckDB corre dentro de R: no hay servidor, usuario ni contraseña
con <- dbConnect(duckdb())

# El archivo se consulta por su nombre, sin importarlo a una tabla
dbGetQuery(con, "
  SELECT region, COUNT(*) AS hogares, ROUND(AVG(itf)) AS itf_promedio
  FROM 'eph_hogares.parquet'
  GROUP BY region
  ORDER BY hogares DESC")

# Las columnas y sus tipos: personas es una lista de estructuras
dbGetQuery(con, "DESCRIBE SELECT * FROM 'eph_hogares.parquet'")

# UNNEST separa las personas de cada hogar, igual que en BigQuery
dbGetQuery(con, "
  SELECT region,
         ROUND(100 * SUM(pondera) FILTER (WHERE p.estado = 'Desocupado')
             / SUM(pondera) FILTER (WHERE p.estado IN ('Ocupado', 'Desocupado')), 1)
           AS tasa_desocupacion
  FROM (SELECT region, pondera, UNNEST(personas) AS p
        FROM 'eph_hogares.parquet')
  GROUP BY region
  ORDER BY tasa_desocupacion DESC")
# Gran Buenos Aires: 8,7%, igual que con PostgreSQL y con MongoDB

# DuckDB también escribe Parquet: guarda el resultado de una consulta
dbExecute(con, "
  COPY (SELECT aglomerado, COUNT(*) AS hogares
        FROM 'eph_hogares.parquet'
        GROUP BY aglomerado)
  TO 'hogares_por_aglomerado.parquet' (FORMAT parquet)")
read_parquet("hogares_por_aglomerado.parquet")


# 6. ¿Cuánto más rápido es Parquet? -----------------------------------
# La misma consulta, 20 veces seguidas, sobre el JSON y sobre el Parquet
t_json <- system.time(
  for (i in 1:20) dbGetQuery(con, "SELECT region, AVG(itf) FROM read_json_auto('eph_hogares.json') GROUP BY region")
)["elapsed"]

t_parquet <- system.time(
  for (i in 1:20) dbGetQuery(con, "SELECT region, AVG(itf) FROM 'eph_hogares.parquet' GROUP BY region")
)["elapsed"]

t_json                     # segundos con el JSON
t_parquet                  # segundos con el Parquet
round(t_json / t_parquet)  # cuántas veces más rápido es el Parquet

dbDisconnect(con)
