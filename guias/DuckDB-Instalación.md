# Guía de instalación de DuckDB

DuckDB es un motor de bases de datos pensado para el análisis: guarda y procesa los datos por columnas y lee directamente archivos CSV, JSON y Parquet. A diferencia de PostgreSQL y MongoDB, no tiene un servidor que haya que dejar corriendo: se abre cuando lo usamos.

En esta guía instalamos DuckDB y trabajamos con su **interfaz web**, un cuaderno en el navegador parecido a Colab: se escribe una consulta en una celda, se ejecuta y el resultado aparece abajo. La terminal se usa solo para dos comandos, uno para instalar y otro para abrir la interfaz.

> **¿Qué versión instalar?** Se recomienda **DuckDB 2.0**, la versión con soporte extendido (LTS). Cualquier versión desde la 1.4 sirve para el curso.

## 1. Instalar DuckDB

### Windows

Abrir **PowerShell** desde el menú Inicio y ejecutar:

```
winget install DuckDB.cli
```

Al terminar, cerrar PowerShell y volver a abrirlo.

Si `winget` no está disponible, en la [página de instalación de DuckDB](https://duckdb.org/install/) se descarga DuckDB para Windows como un archivo comprimido. Si al abrir DuckDB aparece un error por un archivo `.dll` que falta, hay que instalar el [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/es-es/cpp/windows/latest-supported-vc-redist).

### macOS y Ubuntu

Abrir la **Terminal** (en macOS está en *Aplicaciones > Utilidades*) y ejecutar:

```bash
curl https://install.duckdb.org | bash
```

## 2. Abrir la interfaz

En Windows, en PowerShell:

```
duckdb -ui
```

En macOS y Ubuntu, en la Terminal:

```bash
~/.duckdb/cli/latest/duckdb -ui
```

Se abre el navegador, en la dirección `http://localhost:4213`, con un cuaderno de DuckDB. La primera vez necesita conexión a internet, porque descarga la interfaz. Mientras se usa, la terminal tiene que quedar abierta: si se cierra, la interfaz deja de funcionar.

<p align="center">
<img src="https://duckdb.org/images/blog/ui/basics.png" width="750px" />
</p>

<p align="center"><em>La interfaz de DuckDB. Fuente: <a href="https://duckdb.org/2025/03/12/duckdb-ui">blog oficial de DuckDB</a>.</em></p>

A la izquierda están las bases de datos y sus tablas. En el centro, las celdas del cuaderno, cada una con su botón **Run**. A la derecha, un resumen de las columnas del resultado. La base se llama `memory` porque sus tablas se guardan en la memoria mientras la interfaz está abierta.

## 3. Cargar los datos de la EPH

En una celda, escribir esta sentencia y hacer clic en **Run**:

```sql
CREATE OR REPLACE TABLE hogares AS
SELECT * FROM read_json('https://raw.githubusercontent.com/jumafernandez/modelado-gestion-datos-untref/main/data/eph_hogares_2026t1.json');
```

DuckDB lee el archivo directamente del repositorio del curso, sin descargarlo, y crea la tabla `hogares`, con un hogar por fila. Es el mismo archivo JSON que importamos en MongoDB.

La tabla aparece a la izquierda, dentro de `memory` y `main`. Al hacer clic en ella se ven la cantidad de filas (15.447 hogares), las columnas con su tipo y un resumen de cada una, y el botón **Preview data** muestra las primeras filas. La columna `personas` guarda la lista de personas de cada hogar, como en MongoDB.

Al cerrar la interfaz, la tabla se pierde. La próxima vez alcanza con volver a ejecutar esta celda.

## 4. Una consulta

En una celda nueva, o en la misma reemplazando el texto, escribir esta consulta y hacer clic en **Run**. Cuenta cuántos hogares de la encuesta hay en cada región:

```sql
SELECT region, COUNT(*) AS hogares
FROM hogares
GROUP BY region
ORDER BY hogares DESC;
```

El resultado:

| region | hogares |
|---|---:|
| Pampeana | 5084 |
| Noroeste | 2986 |
| Gran Buenos Aires | 2415 |
| Patagonia | 2042 |
| Noreste | 1508 |
| Cuyo | 1412 |

En el panel de la derecha, al hacer clic en una columna del resultado, se ve un resumen de sus valores.

## 5. Cerrar

Para terminar, se cierran la pestaña del navegador y la terminal. Los cuadernos quedan guardados y vuelven a aparecer la próxima vez que se abre la interfaz.

_Última actualización: noviembre de 2026._
