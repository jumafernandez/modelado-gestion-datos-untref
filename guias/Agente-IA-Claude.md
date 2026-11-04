# Un agente de IA que consulta PostgreSQL con Claude

Un **agente** es un modelo de lenguaje que, además de responder, usa herramientas: buscar en la web, leer un archivo o ejecutar una consulta SQL. Para conectarlo con nuestros datos se usa **MCP** (Model Context Protocol), el estándar abierto que adoptaron Claude, ChatGPT, Gemini y muchas otras aplicaciones.

En esta guía conectamos **Claude Desktop**, la aplicación de escritorio de Claude, con la base `eph` de PostgreSQL que armamos con el cuaderno de la EPH. Después le hacemos una pregunta en castellano: Claude busca las tablas, escribe el SQL, lo ejecuta y explica el resultado.

El servidor MCP es **DBHub**, que se instala en Claude Desktop como una extensión: no hace falta instalar nada más ni editar archivos de configuración, y trabaja en modo de solo lectura.

## 1. Lo que hace falta

- **Claude Desktop**, que se descarga de [claude.ai/download](https://claude.ai/download), con una cuenta de Claude.
- **PostgreSQL** con la base `eph` del [cuaderno de la EPH](https://jumafernandez.github.io/modelado-gestion-datos-untref/guias/cuaderno-eph/). Si no la armaste, se crea en pocos minutos: la sección 4.1 crea la base y los scripts de la sección 5.8 cargan los datos.
- La **clave del usuario `postgres`**, la que elegiste al instalar PostgreSQL.

## 2. Instalar la extensión DBHub

1. Entrar a la [última versión de DBHub](https://github.com/bytebase/dbhub/releases/latest) y, en **Assets**, descargar el archivo `dbhub-<versión>.mcpb`.
2. Hacer doble clic en el archivo. Claude Desktop pregunta si se quiere instalar la extensión: hacer clic en **Instalar**. También se puede arrastrar el archivo a **Configuración → Extensiones**.
3. En **Database connection string (DSN)**, escribir esta cadena de conexión, reemplazando `CLAVE` por la clave de `postgres`, y hacer clic en **Guardar**:

```
postgres://postgres:CLAVE@localhost:5432/eph
```

La cadena tiene los mismos datos que usamos para conectarnos desde pgAdmin, R y Python: el usuario, la clave, el servidor (`localhost`, la propia computadora), el puerto y la base. Claude Desktop la guarda en el llavero de la computadora, no en un archivo.

<img src="./imgs/claude-01-extension.png" alt="Configuración de la extensión DBHub en Claude Desktop" width="650px"/>

Abajo aparecen las dos herramientas que DBHub le da a Claude: **Search Database Objects**, para buscar tablas y columnas, y **Execute SQL**, para ejecutar consultas. Las dos son de solo lectura y, como indica **Requiere aprobación**, Claude pide permiso antes de usarlas.

## 3. Hacerle una pregunta

1. Abrir un chat nuevo en Claude Desktop.
2. Escribir la pregunta y enviarla:

> En la base de datos eph, ¿cuál fue la tasa de desocupación de Gran Buenos Aires en el primer trimestre de 2026? Mostrame el SQL que usaste.

3. Cuando Claude pida permiso para usar las herramientas de DBHub, hacer clic en **Permitir**.

<img src="./imgs/claude-02-respuesta.png" alt="Claude responde la tasa de desocupación de Gran Buenos Aires con el SQL que usó" width="650px"/>

Claude buscó las tablas de la base, vio que el modelo separa personas, hogares, viviendas y aglomerados, escribió una consulta que une las cuatro tablas y la ejecutó. Gran Buenos Aires da 8,7%, el mismo resultado que obtuvimos con SQL en PostgreSQL, con MongoDB, con R y con BigQuery.

La pregunta nombra la base a propósito. El agente decide qué herramienta usar en cada paso, y la tasa de desocupación también la publica el INDEC: sin esa aclaración, Claude puede ir a buscar la respuesta a internet. En la captura, además de usar DBHub, también buscó en la web. Para que use solo la base, se puede desactivar la búsqueda web desde el menú de herramientas del chat.

## 4. Revisar el SQL

El modelo puede equivocarse, así que el SQL se revisa siempre. En esta consulta conviene mirar tres cosas:

- **El ponderador.** La tasa se calcula con `pondera`, como corresponde en la EPH. Sin ponderador, cada persona de la muestra pesaría lo mismo y la tasa sería otra.
- **La definición.** Desocupados (`id_condicion_actividad = 2`) sobre la población económicamente activa: ocupados más desocupados (`1` y `2`).
- **Los filtros.** Primer trimestre de 2026 y región 1, que en la tabla `regiones` es Gran Buenos Aires.

Para confirmar el resultado, se puede copiar el SQL y ejecutarlo en pgAdmin.

## 5. Cuidados

- **Solo lectura.** El usuario `postgres` puede modificar cualquier tabla. El modo de solo lectura de DBHub rechaza todo lo que no sea consultar, pero en un proyecto real conviene conectarse además con un usuario que solo pueda leer, como hacemos en la [guía de Codex](./Agente-IA-Codex.md).
- **Datos personales.** Los resultados de las consultas viajan a los servidores de Anthropic. No hay que conectar bases con datos personales o confidenciales sin autorización.
- **Aprobar cada acción.** Conviene dejar las herramientas en **Requiere aprobación**, para ver qué va a hacer Claude antes de que lo haga.

## 6. Para llevarse

- Un agente combina un modelo de lenguaje con herramientas, y MCP es el estándar que las conecta.
- Con una extensión, Claude Desktop se conecta a PostgreSQL sin instalar nada más.
- La pregunta se hace en castellano, pero la respuesta sale de una consulta SQL: hay que pedir el SQL y revisarlo.

_Última actualización: noviembre de 2026._
