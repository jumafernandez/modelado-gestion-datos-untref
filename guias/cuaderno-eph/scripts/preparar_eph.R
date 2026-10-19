# Descarga y preparación de la EPH (INDEC), del 1.er trimestre de 2018 al 1.er trimestre de 2026.
# Genera dos archivos listos para importar en PostgreSQL: eph/hogares.csv y eph/personas.csv
#
# Todo se guarda en la carpeta "eph", dentro del directorio de trabajo de R.
# Para ver cuál es: getwd(). Para cambiarlo: setwd(), o en RStudio
# Session > Set Working Directory > Choose Directory...
#
# Si ya bajaste los .zip del Drive del curso, copialos a la carpeta "eph":
# el script no vuelve a descargar los que ya están.

carpeta <- "eph"
dir.create(carpeta, showWarnings = FALSE)
options(timeout = 600)

# 1. Descargar y descomprimir los 33 trimestres
base_url <- "https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/"
periodos <- expand.grid(trimestre = 1:4, anio = 2018:2026)
periodos <- subset(periodos, anio < 2026 | trimestre == 1)   # último publicado: 1T 2026

for (i in seq_len(nrow(periodos))) {
  zip <- sprintf("EPH_usu_%d_Trim_%d_txt.zip", periodos$trimestre[i], periodos$anio[i])
  destino <- file.path(carpeta, zip)
  if (!file.exists(destino)) download.file(paste0(base_url, zip), destino, mode = "wb")
  unzip(destino, exdir = carpeta, junkpaths = TRUE)
}

# 2. Quedarse con las columnas que usamos y juntar los trimestres
col_hogar   <- c("CODUSU", "ANO4", "TRIMESTRE", "NRO_HOGAR", "REGION", "AGLOMERADO",
                 "PONDERA", "II7", "IX_TOT", "ITF", "IPCF", "PONDIH")
col_persona <- c("CODUSU", "ANO4", "TRIMESTRE", "NRO_HOGAR", "COMPONENTE", "REGION",
                 "AGLOMERADO", "PONDERA", "CH03", "CH04", "CH06", "NIVEL_ED", "ESTADO",
                 "P21", "P47T", "ITF", "IPCF")

# Se lee todo como texto: la limpieza se hace después, en SQL
leer <- function(archivo, columnas) {
  datos <- read.csv2(archivo, colClasses = "character", na.strings = c("", "NA"))
  names(datos) <- toupper(names(datos))
  datos[as.integer(datos$ANO4) >= 2018, columnas]
}

# Los nombres de los archivos cambian de un trimestre a otro: se buscan por patrón
txt <- list.files(carpeta, pattern = "\\.txt$", full.names = TRUE)
hogares  <- do.call(rbind, lapply(grep("hogar", txt, ignore.case = TRUE, value = TRUE),
                                  leer, columnas = col_hogar))
personas <- do.call(rbind, lapply(grep("individual|personas", txt, ignore.case = TRUE, value = TRUE),
                                  leer, columnas = col_persona))
names(hogares)  <- tolower(names(hogares))
names(personas) <- tolower(names(personas))

# 3. Guardar los CSV
write.csv(hogares,  file.path(carpeta, "hogares.csv"),  row.names = FALSE, na = "")
write.csv(personas, file.path(carpeta, "personas.csv"), row.names = FALSE, na = "")

cat("Hogares:", nrow(hogares), "filas\nPersonas:", nrow(personas), "filas\n")
cat("Rutas completas, para usar en \\copy:\n")
cat(normalizePath(file.path(carpeta, c("hogares.csv", "personas.csv")), winslash = "/"), sep = "\n")
