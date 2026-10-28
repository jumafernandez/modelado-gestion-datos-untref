# =====================================================================
# MongoDB desde RStudio: la EPH en formato documento
# Modelado y Gestión de Datos - UNTREF - 2026
#
# Antes de empezar: MongoDB corriendo en tu computadora y la colección
# hogares de la base eph importada con Compass (guía "Primeros pasos
# con MongoDB Compass").
#
# Se corre de a una línea: Ctrl + Enter (Cmd + Enter en Mac).
# =====================================================================

install.packages("mongolite")   # una sola vez
library(mongolite)


# 1. Conexión con la colección hogares de la base eph
hogares <- mongo(collection = "hogares", db = "eph", url = "mongodb://localhost:27017")
hogares$count()                  # cantidad de hogares


# 2. find(): el mismo filtro y la misma proyección que en Compass
cuyo <- hogares$find(query  = '{"region": "Cuyo"}',
                     fields = '{"_id": 0, "codusu": 1, "aglomerado": 1, "itf": 1}')
head(cuyo)
summary(cuyo$itf)                # ingreso total familiar de los hogares de Cuyo


# 3. Una consulta dentro del array de personas
hogares$count('{"personas": {"$elemMatch": {"sexo": "Mujer", "estado": "Desocupado"}}}')


# 4. Agregación: población por región y condición de actividad
por_estado <- hogares$aggregate('[
  {"$unwind": "$personas"},
  {"$group": {"_id": {"region": "$region", "estado": "$personas.estado"},
              "poblacion": {"$sum": "$pondera"}}},
  {"$project": {"_id": 0, "region": "$_id.region", "estado": "$_id.estado", "poblacion": 1}}
]')

tabla <- xtabs(poblacion ~ region + estado, data = por_estado)
tabla

# Tasa de desocupación por región: desocupados / (ocupados + desocupados)
round(100 * tabla[, "Desocupado"] / (tabla[, "Ocupado"] + tabla[, "Desocupado"]), 1)


# 5. Cierre
hogares$disconnect()
