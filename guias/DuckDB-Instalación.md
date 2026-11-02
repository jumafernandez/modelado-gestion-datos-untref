# Guía de instalación de DuckDB

DuckDB es un motor de bases de datos relacional pensado para el análisis: guarda y procesa los datos por columnas y lee directamente archivos CSV, JSON y Parquet. A diferencia de PostgreSQL y MongoDB, no tiene un servidor que haya que instalar y dejar corriendo: es un programa que se abre cuando lo usamos y guarda toda la base en un único archivo.

En esta guía instalamos la consola de DuckDB, cargamos los hogares de la EPH desde el mismo archivo JSON que usamos con MongoDB, hacemos una consulta mínima y guardamos los datos en Parquet.

> **¿Qué versión instalar?** Se recomienda **DuckDB 2.0**, la versión con soporte extendido (LTS). Cualquier versión desde la 1.4 sirve para el curso.

## Windows

1. Abrir la terminal (PowerShell o Símbolo del sistema) y ejecutar:

```
winget install DuckDB.cli
```

2. Cerrar la terminal y abrir una nueva, para que reconozca el comando `duckdb`.

Si `winget` no está disponible, en la [página de instalación de DuckDB](https://duckdb.org/install/) se descarga la consola para Windows como un archivo comprimido. Al descomprimirlo queda `duckdb.exe`, que se ejecuta desde esa carpeta.

Si al ejecutar `duckdb` aparece un error por un archivo `.dll` que falta, hay que instalar el [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/es-es/cpp/windows/latest-supported-vc-redist), que DuckDB necesita en Windows.

## macOS y Ubuntu

En la terminal:

```bash
curl https://install.duckdb.org | bash
```

El script instala DuckDB en la carpeta `~/.duckdb/cli/latest`, pero no la agrega al `PATH`. Para poder usar el comando `duckdb` desde cualquier carpeta, hay que agregar esa carpeta al archivo de configuración de la terminal y después abrir una terminal nueva.

En macOS:

```bash
echo 'export PATH="$HOME/.duckdb/cli/latest:$PATH"' >> ~/.zshrc
```

En Ubuntu:

```bash
echo 'export PATH="$HOME/.duckdb/cli/latest:$PATH"' >> ~/.bashrc
```

En macOS, si ya está instalado [Homebrew](https://brew.sh) (lo usamos en la guía de MongoDB), también se puede instalar con `brew install duckdb`.

## Verificar la instalación

```
duckdb --version
```

La respuesta es la versión instalada, por ejemplo `v2.0.0`.

## Cargar los datos de la EPH

1. Crear una carpeta para trabajar, por ejemplo `duckdb-eph`, y descargar ahí el archivo [eph_hogares_2026t1.json](https://github.com/jumafernandez/modelado-gestion-datos-untref/raw/main/data/eph_hogares_2026t1.json) del repositorio. Es el mismo que importamos en MongoDB: un hogar por línea, con la lista de sus personas adentro.
2. Abrir una terminal en esa carpeta y ejecutar:

```
duckdb curso.duckdb
```

DuckDB crea el archivo `curso.duckdb`, donde guarda la base, y abre su consola, que muestra el indicador `D`. Ahí se escriben las sentencias SQL, terminadas en punto y coma.

3. Crear la tabla `hogares` a partir del JSON. `read_json` reconoce solo los nombres y los tipos de las columnas:

```sql
CREATE TABLE hogares AS
SELECT * FROM read_json('eph_hogares_2026t1.json');
```

4. Ver la estructura de la tabla:

```sql
DESCRIBE hogares;
```

La columna `personas` es de tipo `STRUCT(componente BIGINT, parentesco VARCHAR, sexo VARCHAR, edad BIGINT, nivel_educativo VARCHAR, estado VARCHAR)[]`: una lista con una estructura por persona. Las personas quedan adentro de cada hogar, como en MongoDB, sin una tabla aparte.

## Una consulta mínima

Cuántos hogares de la encuesta hay en cada región:

```sql
SELECT region, COUNT(*) AS hogares
FROM hogares
GROUP BY region
ORDER BY hogares DESC;
```

```
┌───────────────────┬─────────┐
│      region       │ hogares │
│      varchar      │  int64  │
├───────────────────┼─────────┤
│ Pampeana          │    5084 │
│ Noroeste          │    2986 │
│ Gran Buenos Aires │    2415 │
│ Patagonia         │    2042 │
│ Noreste           │    1508 │
│ Cuyo              │    1412 │
└───────────────────┴─────────┘
```

## Las personas de cada hogar

`UNNEST` separa la lista de personas de cada hogar en filas, como `$unwind` en MongoDB. Con eso se calcula la tasa de desocupación por región, sumando el ponderador:

```sql
SELECT region,
       SUM(pondera) FILTER (WHERE persona.estado = 'Ocupado')    AS ocupados,
       SUM(pondera) FILTER (WHERE persona.estado = 'Desocupado') AS desocupados,
       ROUND(100 * desocupados / (ocupados + desocupados), 1)    AS tasa_desocupacion
FROM (SELECT region, pondera, UNNEST(personas) AS persona FROM hogares)
GROUP BY region
ORDER BY tasa_desocupacion DESC;
```

`FILTER` suma solo las filas que cumplen la condición, y DuckDB permite usar en la misma consulta los nombres `ocupados` y `desocupados` que se acaban de definir. Para Gran Buenos Aires da 7.269.425 ocupados y 691.244 desocupados: una tasa de desocupación de 8,7%, la misma que se obtiene con MongoDB y con SQL en PostgreSQL.

## Guardar en Parquet

```sql
COPY hogares TO 'eph_hogares_2026t1.parquet' (FORMAT parquet);
```

El JSON ocupa 10,5 MB y el Parquet, menos de 0,5 MB. Un archivo Parquet se consulta directamente, sin crear una tabla:

```sql
SELECT region, COUNT(*) AS hogares
FROM 'eph_hogares_2026t1.parquet'
GROUP BY region;
```

El script [r_parquet.R](../codigo/r_parquet.R) hace el mismo recorrido desde R sin DuckDB: guarda la EPH en Parquet con el paquete `arrow` y la consulta con `dplyr`.

## Salir de la consola

Con `.exit`, o con Ctrl + D (Ctrl + C en Windows). DuckDB guarda los cambios en `curso.duckdb`: al volver a abrir la base con `duckdb curso.duckdb`, la tabla `hogares` sigue ahí.

## La interfaz web de DuckDB

DuckDB también tiene una interfaz en el navegador, con un cuaderno para escribir consultas y ver los resultados y la estructura de las tablas. Con la base abierta en la consola, se inicia con:

```sql
CALL start_ui();
```

Se abre en el navegador, en la dirección `http://localhost:4213`, y trabaja sobre la base abierta. Las consultas y los datos no salen de la computadora, pero la interfaz se descarga de internet, así que hace falta conexión. No está disponible para Windows en procesadores ARM ni para Mac con procesador Intel.

_Última actualización: noviembre de 2026._
