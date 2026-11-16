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
# Para leer el código:
#   - x <- valor     guarda el valor en un objeto llamado x
#   - c(a, b)        junta varios valores en un vector
#   - a |> f()       pasa el resultado de a a la función f (se lee "y después")
#   - # texto        es un comentario: R no lo ejecuta
#
# Los archivos se guardan en la carpeta de trabajo, que se ve con getwd().
# Se corre de a una línea: Ctrl + Enter (Cmd + Enter en Mac).
# =====================================================================


# 1. Paquetes ----------------------------------------------------------

# Vector con los nombres de los paquetes que usa el script
paquetes <- c("arrow", "duckdb", "dplyr", "tidyr")

# installed.packages() lista los paquetes instalados en la computadora;
# rownames() se queda con sus nombres, y setdiff(a, b) devuelve los
# elementos de a que no están en b: los paquetes que faltan
faltan <- setdiff(paquetes, rownames(installed.packages()))

# length() cuenta cuántos faltan. Si falta alguno, install.packages()
# lo baja de CRAN y lo instala. La primera vez tarda unos minutos;
# las siguientes no hace nada
if (length(faltan) > 0) install.packages(faltan)

# library() carga cada paquete para poder usar sus funciones
library(arrow)    # lee y escribe archivos Parquet
library(duckdb)   # motor SQL analítico que corre dentro de R (carga también DBI)
library(dplyr)    # filter(), group_by(), summarise(), arrange()...
library(tidyr)    # unnest(), para separar las personas de cada hogar


# 2. Bajar el JSON -----------------------------------------------------

# Dirección del archivo en el repositorio de la materia en GitHub
url <- "https://raw.githubusercontent.com/jumafernandez/modelado-gestion-datos-untref/main/data/eph_hogares_2026t1.json"

# download.file(origen, destino) baja el archivo de internet y lo guarda
# en la carpeta de trabajo con el nombre "eph_hogares.json".
# mode = "wb" (binario) copia el archivo tal cual: en Windows, sin esto,
# R puede cambiar los saltos de línea
download.file(url, "eph_hogares.json", mode = "wb")

# readLines() lee un archivo de texto línea por línea.
# n = 1 indica cuántas líneas leer: solo la primera (sin n, lee todo).
# Cada línea es un documento JSON: un hogar con la lista de sus personas
readLines("eph_hogares.json", n = 1)


# 3. Del JSON a Parquet ------------------------------------------------

# read_json_arrow() lee el JSON y lo convierte en una tabla:
# cada clave del JSON pasa a ser una columna y cada hogar, una fila
hogares <- read_json_arrow("eph_hogares.json")

# Escribir el nombre de un objeto lo muestra en la consola.
# La columna personas es una lista: en cada fila están las personas del hogar
hogares

# write_parquet(datos, archivo) guarda la tabla en un archivo Parquet:
# los datos quedan ordenados por columnas, comprimidos y con el tipo de
# cada columna (texto, número, lista), así no hay que adivinarlo al leer
write_parquet(hogares, "eph_hogares.parquet")

# file.size() devuelve el tamaño de un archivo en bytes;
# al dividir por 1e6 (un millón) queda en megabytes (MB)
file.size("eph_hogares.json") / 1e6
file.size("eph_hogares.parquet") / 1e6


# 4. Volver a leer el Parquet y consultarlo con dplyr -----------------

# open_dataset() abre el archivo sin cargar los datos en memoria:
# solo lee el esquema, es decir, los nombres y los tipos de las columnas
eph <- open_dataset("eph_hogares.parquet")
eph

# Hogares e ingreso promedio por región. arrow arma la consulta paso a
# paso y recién la ejecuta cuando llega a collect()
eph |>                                  # parte del Parquet abierto
  group_by(region) |>                   # agrupa los hogares por región
  summarise(hogares = n(),              # n() cuenta los hogares de cada grupo
            itf_promedio = mean(itf, na.rm = TRUE)) |>  # mean() promedia el ingreso total familiar;
                                        # na.rm = TRUE ignora los hogares sin dato (NA)
  arrange(desc(hogares)) |>             # ordena por hogares; desc() lo hace de mayor a menor
  collect()                             # ejecuta la consulta y trae el resultado a R

# read_parquet() lee el archivo y lo carga en memoria.
# col_select indica qué columnas leer: como Parquet guarda cada columna
# por separado, las demás ni siquiera se leen del disco
read_parquet("eph_hogares.parquet", col_select = c(region, aglomerado, itf))

# Una fila por persona
personas <- read_parquet("eph_hogares.parquet") |>  # lee el archivo completo
  select(region, pondera, personas) |>               # se queda con tres columnas
  unnest(personas)                                   # separa las personas de cada hogar, como $unwind en MongoDB
personas                                             # muestra el resultado: una columna por dato de la persona


# 5. SQL con DuckDB, directo sobre el archivo --------------------------

# dbConnect() abre una conexión a una base de datos (es del paquete DBI).
# duckdb() indica que la base es DuckDB, que corre dentro de R, en
# memoria: no hay servidor, usuario ni contraseña
con <- dbConnect(duckdb())

# dbGetQuery(conexión, consulta) ejecuta una consulta SQL y devuelve el
# resultado como data frame. En el FROM va el nombre del archivo entre
# comillas simples: DuckDB lo lee directamente, sin importarlo a una tabla
dbGetQuery(con, "
  SELECT region, COUNT(*) AS hogares, ROUND(AVG(itf)) AS itf_promedio
  FROM 'eph_hogares.parquet'
  GROUP BY region
  ORDER BY hogares DESC")

# DESCRIBE muestra las columnas del archivo y sus tipos:
# personas es una lista (los corchetes []) de estructuras (STRUCT)
dbGetQuery(con, "DESCRIBE SELECT * FROM 'eph_hogares.parquet'")

# Tasa de desocupación por región, ponderada:
#   - UNNEST(personas) separa las personas de cada hogar, como en BigQuery;
#     cada persona queda en la columna p, y sus datos se leen como p.estado
#   - SUM(pondera) FILTER (WHERE ...) suma el ponderador solo en las filas
#     que cumplen la condición
#   - ROUND(valor, 1) redondea a un decimal
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

# dbExecute() ejecuta una instrucción que no devuelve una tabla.
# COPY (consulta) TO 'archivo' (FORMAT parquet) guarda el resultado de
# la consulta en un archivo Parquet nuevo
dbExecute(con, "
  COPY (SELECT aglomerado, COUNT(*) AS hogares
        FROM 'eph_hogares.parquet'
        GROUP BY aglomerado)
  TO 'hogares_por_aglomerado.parquet' (FORMAT parquet)")

# Se lee el archivo nuevo para ver qué quedó guardado
read_parquet("hogares_por_aglomerado.parquet")

# dbDisconnect() cierra la conexión con DuckDB
dbDisconnect(con)


# 6. ¿Cuánto más rápido es Parquet? -----------------------------------

# La misma consulta, el ingreso promedio por región, sobre los dos archivos.
# system.time() mide cuánto tarda lo que tiene adentro, y ["elapsed"] se
# queda con el tiempo transcurrido, en segundos.
# for (i in 1:10) repite la consulta 10 veces, para que el tiempo se note.

# Con el JSON hay que leer y convertir el archivo entero,
# aunque la consulta use solo dos columnas
t_json <- system.time(
  for (i in 1:10) read_json_arrow("eph_hogares.json") |>
    group_by(region) |>
    summarise(itf_promedio = mean(itf, na.rm = TRUE))
)["elapsed"]

# Con el Parquet, arrow lee solo las dos columnas que usa: region e itf
t_parquet <- system.time(
  for (i in 1:10) open_dataset("eph_hogares.parquet") |>
    group_by(region) |>
    summarise(itf_promedio = mean(itf, na.rm = TRUE)) |>
    collect()
)["elapsed"]

t_json                     # segundos con el JSON
t_parquet                  # segundos con el Parquet
round(t_json / t_parquet)  # cuántas veces más rápido es el Parquet; round() redondea al entero
