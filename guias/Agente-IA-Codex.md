# Un agente de IA que consulta PostgreSQL con Codex

Un **agente** es un modelo de lenguaje que, además de responder, usa herramientas: buscar en la web, leer un archivo o ejecutar una consulta SQL. Para conectarlo con nuestros datos se usa **MCP** (Model Context Protocol), el estándar abierto que adoptaron Claude, ChatGPT, Gemini y muchas otras aplicaciones.

Esta guía repite la de [Claude](./Agente-IA-Claude.md) con **Codex**, el agente de OpenAI que viene en la aplicación de escritorio de ChatGPT. El servidor MCP es el mismo, **DBHub**, y la pregunta también: así se ve que la misma herramienta sirve para agentes de empresas distintas.

Hay dos diferencias con la guía de Claude. En Codex, DBHub no se instala como una extensión sino que se configura a mano, y para funcionar necesita **Node.js**. Además, Codex no se conecta con el usuario `postgres` sino con un usuario nuevo que solo puede leer.

## 1. Lo que hace falta

- La **aplicación de escritorio de ChatGPT**, que se descarga de [chatgpt.com/download](https://chatgpt.com/download), con una cuenta de ChatGPT. Codex está incluido en todos los planes, también en el gratuito.
- **Node.js**, que se descarga de [nodejs.org](https://nodejs.org) (la versión LTS) y se instala como cualquier programa. DBHub está escrito en JavaScript y Node.js es el que lo ejecuta.
- **PostgreSQL** y **pgAdmin**, con la base `eph` del [cuaderno de la EPH](https://jumafernandez.github.io/modelado-gestion-datos-untref/guias/cuaderno-eph/). Si no la armaste, se crea en pocos minutos: la sección 4.1 crea la base y los scripts de la sección 5.8 cargan los datos.

## 2. Un usuario que solo puede leer

Un agente puede equivocarse, y con el usuario `postgres` podría modificar o borrar tablas. La extensión de Claude Desktop trae activado el modo de solo lectura de DBHub, pero en Codex ese modo pide un archivo de configuración aparte. Usamos una solución más simple y más segura: un usuario de la base que solo puede consultar.

En pgAdmin, abrir el **Query Tool** sobre la base `eph` y ejecutar estas tres sentencias, reemplazando `CLAVE` por una clave nueva:

```sql
CREATE ROLE lector LOGIN PASSWORD 'CLAVE';
GRANT USAGE ON SCHEMA public TO lector;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lector;
```

La primera sentencia crea el usuario `lector`. La segunda le permite usar el esquema `public`, donde están las tablas, y la tercera le permite leer todas las tablas y vistas. No le damos ningún otro permiso: si Codex intentara modificar un dato, PostgreSQL lo rechazaría.

Conviene elegir una clave sin `@`, `:` ni `/`, porque va dentro de la cadena de conexión. Si más adelante se vuelven a crear las tablas con los scripts del cuaderno, hay que repetir la última sentencia.

## 3. Agregar el servidor en Codex

1. Abrir **Settings** (en Mac, desde el menú **ChatGPT → Settings…**) y entrar en **Plugins**.
2. En la pestaña **MCPs**, hacer clic en **Add** y elegir **Add MCP server**.
3. Completar el formulario y hacer clic en **Save**:
   - **Name**: `eph`.
   - **Type**: **STDIO**.
   - **Command to launch**: `npx`.
   - **Arguments**: `-y` y, con **+ Add argument**, `@bytebase/dbhub@1.5.1`.
   - **Environment variables**: en **Key**, `DSN`, y en **Value**, esta cadena de conexión, reemplazando `CLAVE` por la clave de `lector`:

```
postgres://lector:CLAVE@localhost:5432/eph
```

<img src="./imgs/codex-01-servidor.png" alt="Formulario de Codex para agregar el servidor MCP eph con DBHub" width="650px"/>

`npx` viene con Node.js: descarga DBHub y lo ejecuta. El número `1.5.1` fija la versión, para que la guía siga funcionando aunque DBHub cambie. La variable `DSN` es la cadena de conexión, con los mismos datos que usamos en pgAdmin, R y Python, pero con el usuario `lector`.

Al guardar, `eph` aparece en la lista de servidores, activado.

## 4. Hacerle una pregunta

1. Elegir **Codex** en el menú de arriba a la izquierda y hacer clic en **New chat**.
2. Escribir la misma pregunta que en la guía de Claude y enviarla:

> En la base de datos eph, ¿cuál fue la tasa de desocupación de Gran Buenos Aires en el primer trimestre de 2026? Mostrame el SQL que usaste.

<img src="./imgs/codex-02-respuesta.png" alt="Codex responde la tasa de desocupación de Gran Buenos Aires con el SQL que usó" width="650px"/>

Codex usó las dos herramientas de DBHub: buscó las tablas con **Search Database Objects** y ejecutó tres consultas con **Execute SQL**. Los pasos se ven haciendo clic en **Worked for**. La respuesta, 8,68%, es el mismo 8,7% que obtuvimos con SQL en PostgreSQL, con MongoDB, con R, con BigQuery y con Claude.

La primera vez, Codex descarga DBHub y puede tardar un minuto en conectarse. Si en ese primer chat no encuentra la base, esperar un momento y volver a preguntar en un chat nuevo.

## 5. Aprobar cada consulta

El menú que está debajo del cuadro de texto define cuándo pide permiso Codex:

- **Ask for approval**: pide permiso antes de cada consulta y muestra el SQL que va a ejecutar.
- **Approve for me**: Codex decide solo y pregunta únicamente si detecta algo potencialmente inseguro. Con este modo ejecutó, sin preguntar, las consultas de la captura anterior.
- **Full access**: no pide permiso para nada.

Para esta práctica conviene **Ask for approval**. Antes de cada consulta, Codex muestra el SQL y espera la respuesta: **Allow once** permite esa consulta, **Always allow** deja de preguntar por esa herramienta y **Deny** la rechaza.

<img src="./imgs/codex-03-aprobacion.png" alt="Codex pide permiso para ejecutar una consulta SQL con DBHub" width="650px"/>

## 6. Revisar el SQL

El modelo puede equivocarse, así que el SQL se revisa siempre. En esta consulta conviene mirar tres cosas:

- **El ponderador.** La tasa se calcula con `pondera`, que en nuestro modelo está en la tabla `hogares`: todas las personas de un hogar tienen el mismo ponderador. Sin ponderador, cada persona de la muestra pesaría lo mismo y la tasa sería otra.
- **La definición.** Desocupados (`id_condicion_actividad = 2`) sobre la población económicamente activa: ocupados más desocupados (`1` y `2`).
- **Los filtros.** Primer trimestre de 2026 y la región por su nombre, `'Gran Buenos Aires'`. Claude había filtrado por el código de la región, 1: los dos caminos llegan al mismo resultado.

Para confirmar el resultado, se puede copiar el SQL y ejecutarlo en pgAdmin.

## 7. Cuidados

- **Solo lectura.** El usuario `lector` solo puede consultar: aunque el agente se equivoque, PostgreSQL no deja modificar los datos.
- **La clave queda en un archivo.** Codex guarda la configuración de los servidores en un archivo de texto de la computadora, con la clave a la vista. Por eso la clave de `lector` tiene que ser distinta de la de `postgres`.
- **Datos personales.** Los resultados de las consultas viajan a los servidores de OpenAI. No hay que conectar bases con datos personales o confidenciales sin autorización.
- **Aprobar cada acción.** Codex también puede ejecutar comandos en la computadora. Con **Ask for approval** se ve qué va a hacer antes de que lo haga.

## 8. Para llevarse

- El mismo servidor MCP, DBHub, funciona en Claude y en Codex: MCP es un estándar.
- La seguridad conviene ponerla en la base: un usuario que solo puede leer protege los datos aunque el agente se equivoque.
- La pregunta se hace en castellano, pero la respuesta sale de una consulta SQL: hay que pedir el SQL y revisarlo.

_Última actualización: noviembre de 2026._
