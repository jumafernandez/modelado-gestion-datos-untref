# =====================================================================
# De PostgreSQL a R: la EPH en un data frame
# Modelado y Gestión de Datos - UNTREF - 2026
#
# Qué hace este script:
#   1. Se conecta a la base eph con DBI y RPostgres.
#   2. Trae a un data frame las personas de un trimestre con una consulta SQL.
#   3. Calcula las tasas del mercado de trabajo por región.
#   4. Arma la serie de la tasa de desocupación con dplyr sobre la base.
#   5. Explora la estructura por edad y sexo y el ingreso per cápita familiar.
#
# Requisitos:
#   - La base eph del cuaderno "De la EPH a PostgreSQL", con las vistas del
#     script 04_vistas.sql:
#     https://jumafernandez.github.io/modelado-gestion-datos-untref/guias/cuaderno-eph/
#   - Los paquetes (se instalan una sola vez):
#     install.packages(c("DBI", "RPostgres", "dplyr", "dbplyr", "ggplot2"))
#
# La contraseña no se escribe en el script. Se guarda una sola vez en el
# archivo .Renviron de tu usuario, que se abre con usethis::edit_r_environ()
# o con file.edit("~/.Renviron"), agregando estas líneas:
#
#   PGHOST=localhost
#   PGPORT=5432
#   PGUSER=postgres
#   PGPASSWORD=tu_contraseña
#
# Después de guardarlo hay que reiniciar R: RPostgres toma esos valores solo.
#
# Conviene correr el script de a una línea (en RStudio, Ctrl + Enter o
# Cmd + Enter en Mac) para ver el resultado de cada paso.
# =====================================================================

library(DBI)
library(dplyr)
library(ggplot2)


# 1. Conexión -----------------------------------------------------------

# bigint = "numeric": COUNT() y SUM() devuelven enteros de 64 bits en
# PostgreSQL; con esta opción llegan a R como números comunes.
con <- dbConnect(RPostgres::Postgres(), dbname = "eph", bigint = "numeric")

dbListTables(con)                # tablas y vistas de la base
dbListFields(con, "personas")    # columnas de una tabla


# 2. Una consulta SQL, un data frame ------------------------------------

# Una tabla chica se puede traer entera.
regiones <- dbReadTable(con, "regiones")
regiones

# De una tabla grande conviene pedir solo lo que se va a usar: personas
# tiene más de un millón y medio de filas. La consulta une cada persona con
# su hogar (para el ponderador) y llega hasta la región. El año y el
# trimestre van como parámetros ($1 y $2): los valores viajan aparte del SQL.
# Para analizar otro trimestre alcanza con cambiar estas dos líneas.
anio_elegido      <- 2026
trimestre_elegido <- 1
texto_periodo <- paste0("trimestre ", trimestre_elegido, " de ", anio_elegido)

consulta_personas <- "
SELECT p.sexo,
       p.edad,
       p.id_condicion_actividad,
       r.nombre AS region,
       h.pondera
FROM personas p
INNER JOIN hogares h     ON p.codusu = h.codusu AND p.anio = h.anio
                        AND p.trimestre = h.trimestre AND p.nro_hogar = h.nro_hogar
INNER JOIN viviendas v   ON h.codusu = v.codusu
INNER JOIN aglomerados a ON v.id_aglomerado = a.id
INNER JOIN regiones r    ON a.id_region = r.id
WHERE p.anio = $1 AND p.trimestre = $2"

personas <- dbGetQuery(con, consulta_personas,
                       params = list(anio_elegido, trimestre_elegido))

glimpse(personas)
nrow(personas)            # personas encuestadas
sum(personas$pondera)     # población que representan


# 3. Tasas del mercado de trabajo por región ----------------------------

# Condición de actividad: 1 ocupado, 2 desocupado, 3 inactivo,
# 4 menor de 10 años. Las tasas suman el ponderador, como las de INDEC:
#   actividad    = (ocupados + desocupados) / población
#   empleo       = ocupados / población
#   desocupación = desocupados / (ocupados + desocupados)
tasas_region <- personas |>
  group_by(region) |>
  summarise(
    poblacion   = sum(pondera),
    ocupados    = sum(pondera[id_condicion_actividad == 1]),
    desocupados = sum(pondera[id_condicion_actividad == 2])
  ) |>
  mutate(
    tasa_actividad    = round(100 * (ocupados + desocupados) / poblacion, 1),
    tasa_empleo       = round(100 * ocupados / poblacion, 1),
    tasa_desocupacion = round(100 * desocupados / (ocupados + desocupados), 1)
  ) |>
  select(region, tasa_actividad, tasa_empleo, tasa_desocupacion) |>
  arrange(desc(tasa_desocupacion))

tasas_region


# 4. dplyr sobre la base: dbplyr ----------------------------------------

# tbl() no trae datos: crea una referencia a la tabla. Los verbos de dplyr
# se traducen a SQL y se ejecutan en PostgreSQL. Así se recorren todos los
# trimestres sin bajar el millón y medio de filas a R.
personas_db <- tbl(con, "personas")
hogares_db  <- tbl(con, "hogares")

serie_db <- personas_db |>
  inner_join(hogares_db, by = join_by(codusu, anio, trimestre, nro_hogar)) |>
  group_by(anio, trimestre) |>
  summarise(
    ocupados    = sum(if_else(id_condicion_actividad == 1, pondera, 0), na.rm = TRUE),
    desocupados = sum(if_else(id_condicion_actividad == 2, pondera, 0), na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(tasa_desocupacion = 100 * desocupados / (ocupados + desocupados)) |>
  arrange(anio, trimestre)

show_query(serie_db)             # el SQL que escribió dbplyr

serie <- collect(serie_db)       # recién acá viajan los datos: una fila por trimestre
serie <- serie |>
  mutate(periodo = anio + (trimestre - 1) / 4)

ggplot(serie, aes(x = periodo, y = tasa_desocupacion)) +
  geom_line(colour = "#E08A1E", linewidth = 1) +
  geom_point(colour = "#1C1A3A", size = 1.5) +
  scale_x_continuous(breaks = 2018:2026) +
  labs(title = "Tasa de desocupación por trimestre",
       x = NULL, y = "% de la población económicamente activa",
       caption = "Fuente: EPH (INDEC), 31 aglomerados urbanos.") +
  theme_minimal()


# 5. Exploración ---------------------------------------------------------

# 5.1 Estructura por edad y sexo, con el data frame del paso 2.
etiquetas_edad <- c(paste(seq(0, 75, by = 5), seq(4, 79, by = 5), sep = "-"), "80 y más")

piramide <- personas |>
  mutate(
    grupo_edad = cut(edad, breaks = c(seq(0, 80, by = 5), Inf),
                     right = FALSE, labels = etiquetas_edad),
    sexo = if_else(sexo == 1, "Varones", "Mujeres")
  ) |>
  group_by(grupo_edad, sexo) |>
  summarise(poblacion = sum(pondera), .groups = "drop") |>
  mutate(porcentaje = 100 * poblacion / sum(poblacion),
         porcentaje = if_else(sexo == "Varones", -porcentaje, porcentaje))

ggplot(piramide, aes(x = porcentaje, y = grupo_edad, fill = sexo)) +
  geom_col(width = 0.9) +
  scale_x_continuous(labels = abs) +
  scale_fill_manual(values = c(Mujeres = "#E08A1E", Varones = "#1C1A3A")) +
  labs(title = paste("Estructura por edad y sexo,", texto_periodo),
       x = "% de la población", y = NULL, fill = NULL,
       caption = "Fuente: EPH (INDEC), 31 aglomerados urbanos.") +
  theme_minimal()

# 5.2 Ingreso per cápita familiar por región. La vista ingresos_hogares
# del cuaderno ya lo calcula. Para los ingresos INDEC usa el ponderador
# PONDIH; los hogares que no respondieron tienen PONDIH = 0 y quedan afuera.
consulta_ingresos <- "
SELECT r.nombre AS region,
       i.ingreso_per_capita,
       i.pondih
FROM ingresos_hogares i
INNER JOIN viviendas v   ON i.codusu = v.codusu
INNER JOIN aglomerados a ON v.id_aglomerado = a.id
INNER JOIN regiones r    ON a.id_region = r.id
WHERE i.anio = $1 AND i.trimestre = $2 AND i.pondih > 0"

ingresos <- dbGetQuery(con, consulta_ingresos,
                       params = list(anio_elegido, trimestre_elegido))

# Mediana ponderada: el primer valor en el que el peso acumulado llega a la mitad.
mediana_ponderada <- function(x, w) {
  orden <- order(x)
  peso_acumulado <- cumsum(w[orden])
  x[orden][which(peso_acumulado >= sum(w) / 2)[1]]
}

ingresos |>
  group_by(region) |>
  summarise(
    hogares_encuestados = n(),
    media   = round(weighted.mean(ingreso_per_capita, pondih)),
    mediana = round(mediana_ponderada(ingreso_per_capita, pondih))
  ) |>
  arrange(desc(mediana))

# La distribución es muy asimétrica: el eje va en escala logarítmica.
# Los hogares con ingreso cero no tienen logaritmo y no se grafican.
ingresos |>
  filter(ingreso_per_capita > 0) |>
  ggplot(aes(x = ingreso_per_capita, weight = pondih)) +
  geom_density(fill = "#F3C98B", colour = "#A3540A") +
  scale_x_log10(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  facet_wrap(vars(region), ncol = 2) +
  labs(title = paste("Ingreso per cápita familiar,", texto_periodo),
       x = "Pesos por mes (escala logarítmica)", y = NULL,
       caption = "Fuente: EPH (INDEC), ponderado con PONDIH.") +
  theme_minimal() +
  theme(axis.text.y = element_blank())


# 6. Cierre ---------------------------------------------------------------

dbDisconnect(con)
