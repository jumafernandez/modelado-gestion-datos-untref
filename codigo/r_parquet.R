# =====================================================================
# Parquet desde R: guardar, leer y consultar archivos con arrow
# Modelado y Gestión de Datos - UNTREF - 2026
#
# Qué hace este script:
#   1. Descarga los hogares de la EPH en JSON, el mismo archivo que
#      importamos en MongoDB, y los guarda en Parquet.
#   2. Compara el tamaño de los dos archivos.
#   3. Lee del Parquet solo las columnas que necesita.
#   4. Consulta el archivo con dplyr sin cargarlo entero en memoria.
#   5. Separa las personas de cada hogar y calcula la tasa de desocupación.
#   6. Guarda un dataset particionado: una carpeta por región.
#
# Usa solo el paquete arrow, con dplyr y tidyr: no hace falta DuckDB ni
# ningún servidor. Los paquetes se instalan una sola vez:
#   install.packages(c("arrow", "dplyr", "tidyr"))
#
# Los archivos se guardan en la carpeta de trabajo, que se ve con getwd().
# Se corre de a una línea: Ctrl + Enter (Cmd + Enter en Mac).
# =====================================================================

library(arrow)
library(dplyr)
library(tidyr)


# 1. Del JSON a Parquet ------------------------------------------------
# Un hogar por línea, con la lista de sus personas adentro
url <- "https://raw.githubusercontent.com/jumafernandez/modelado-gestion-datos-untref/main/data/eph_hogares_2026t1.json"
download.file(url, "eph_hogares_2026t1.json", mode = "wb")

hogares <- read_json_arrow("eph_hogares_2026t1.json")
hogares                     # la columna personas guarda las personas de cada hogar

write_parquet(hogares, "eph_hogares_2026t1.parquet")


# 2. Los mismos datos, en mucho menos espacio --------------------------
file.size("eph_hogares_2026t1.json") / 1e6       # MB
file.size("eph_hogares_2026t1.parquet") / 1e6    # MB


# 3. Leer solo algunas columnas ----------------------------------------
# Parquet guarda cada columna por separado: se leen solo las pedidas
ingresos <- read_parquet("eph_hogares_2026t1.parquet",
                         col_select = c(region, aglomerado, itf))
ingresos


# 4. Consultar sin cargar todo el archivo ------------------------------
eph <- open_dataset("eph_hogares_2026t1.parquet")
eph                         # muestra las columnas y sus tipos, sin leer los datos

# dplyr arma la consulta, arrow la ejecuta y collect() trae el resultado
eph |>
  group_by(region) |>
  summarise(hogares = n(), aglomerados = n_distinct(aglomerado)) |>
  arrange(desc(hogares)) |>
  collect()


# 5. Las personas de cada hogar ----------------------------------------
# Parquet conserva la estructura anidada del JSON; unnest() separa las
# personas de cada hogar, como $unwind en MongoDB
personas <- read_parquet("eph_hogares_2026t1.parquet") |>
  select(region, pondera, personas) |>
  unnest(personas)
personas

tasas <- personas |>
  group_by(region) |>
  summarise(ocupados    = sum(pondera[estado == "Ocupado"]),
            desocupados = sum(pondera[estado == "Desocupado"])) |>
  mutate(tasa_desocupacion = round(100 * desocupados / (ocupados + desocupados), 1)) |>
  arrange(desc(tasa_desocupacion))
tasas                       # Gran Buenos Aires: 8,7%, igual que con SQL y con MongoDB


# 6. Un dataset particionado por región --------------------------------
# Una carpeta por región, cada una con su archivo Parquet: así se
# organizan los archivos en un data lake. En los nombres de las carpetas,
# los espacios aparecen como %20.
write_dataset(hogares, "eph_por_region", partitioning = "region")
list.files("eph_por_region", recursive = TRUE)

# Al filtrar por región, arrow lee solo la carpeta de esa región
open_dataset("eph_por_region") |>
  filter(region == "Patagonia") |>
  count(aglomerado, sort = TRUE) |>
  collect()
