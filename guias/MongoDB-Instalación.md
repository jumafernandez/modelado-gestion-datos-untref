# Guía de instalación de MongoDB y MongoDB Compass

En esta guía instalamos el servidor de MongoDB (Community Server) y **MongoDB Compass**, la interfaz gráfica oficial y gratuita con la que trabajamos en el curso. Compass reemplaza a Robo 3T, que dejó de actualizarse en 2022. Al final están los comandos para respaldar, restaurar e importar bases desde la terminal.

Si no podés instalar el servidor en tu computadora, la sección [MongoDB Atlas en la nube](#mongodb-atlas-en-la-nube) explica cómo usar un cluster gratuito en la nube.

## Windows

1. Descargar el instalador de MongoDB Community Server desde el [Centro de descargas](https://www.mongodb.com/try/download/community). En *Platform* elegir *Windows* y en *Package*, *msi*.
2. Ejecutar el instalador y elegir la instalación **Complete**.
3. En *Service Configuration*, dejar marcada la opción **Install MongoD as a Service** con los valores que propone. Así el servidor arranca solo cada vez que se enciende la computadora, y no hace falta crear carpetas ni ejecutar `mongod` a mano.
4. Dejar marcada la opción **Install MongoDB Compass** y terminar la instalación.

El servidor queda escuchando en el puerto 27017. Si hay que detenerlo o volver a iniciarlo, se hace desde la aplicación *Servicios* de Windows, sobre el servicio *MongoDB*.

La versión 9.0 de MongoDB requiere Windows 11. Con una versión anterior de Windows, la alternativa más simple es Atlas.

## macOS

Con [Homebrew](https://brew.sh) instalado, en la Terminal:

```bash
brew tap mongodb/brew
brew trust mongodb/brew
brew update
brew install mongodb-community
brew services start mongodb-community
```

La instalación incluye el servidor, la consola `mongosh` y las herramientas de línea de comandos. `brew services start` deja el servidor corriendo en segundo plano, también después de reiniciar la computadora; para detenerlo se usa `brew services stop mongodb-community`.

Compass se instala aparte: se descarga el archivo `.dmg` desde la [página de descarga de Compass](https://www.mongodb.com/try/download/compass) y se arrastra la aplicación a *Aplicaciones*.

La versión 9.0 de MongoDB requiere macOS 14 o posterior.

## Ubuntu

Estos comandos instalan MongoDB 9.0 en Ubuntu 24.04 desde el repositorio oficial. En Ubuntu 22.04 hay que reemplazar `noble` por `jammy`.

```bash
sudo apt-get install gnupg curl
curl -fsSL https://pgp.mongodb.com/server-9.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-9.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-9.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/9.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-9.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

El paquete `mongodb-org` incluye el servidor, `mongosh` y las herramientas de línea de comandos. `systemctl enable` hace que el servidor arranque solo con el sistema. No hay que usar el paquete `mongodb` de Ubuntu: no lo mantiene MongoDB y entra en conflicto con el oficial.

Compass se descarga como paquete `.deb` desde la [página de descarga de Compass](https://www.mongodb.com/try/download/compass) y se instala desde la carpeta de descargas:

```bash
sudo apt install ./mongodb-compass_*_amd64.deb
```

## Conectarse con Compass

1. Abrir Compass y hacer clic en **Add New Connection**.
2. En el campo de la URI dejar `mongodb://localhost:27017`: el servidor de nuestra computadora, en el puerto por defecto.
3. Hacer clic en **Save & Connect**.

A la izquierda aparecen las bases del servidor; `admin`, `config` y `local` son internas de MongoDB. Compass trae integrada la consola `mongosh`, que se abre con el botón **Open MongoDB shell** y sirve para escribir los comandos que vemos en clase. La guía [Primeros pasos con MongoDB Compass](MongoDB-Introducción.md) sigue desde acá: crear una base, importar datos y consultarlos.

## MongoDB Atlas en la nube

MongoDB Atlas es el servicio oficial de MongoDB en la nube y tiene un cluster gratuito de 512 MB, suficiente para el curso:

1. Crear una cuenta en [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register).
2. Crear un cluster de tipo *Free*.
3. Crear un usuario de base de datos, con su contraseña, y habilitar el acceso desde tu dirección IP. Atlas propone los dos pasos al crear el cluster.
4. En el cluster, elegir **Connect** y después **Compass**. Atlas muestra una cadena de conexión que empieza con `mongodb+srv://`; se copia, se completa con la contraseña del usuario y se pega en Compass en lugar de `mongodb://localhost:27017`.

La guía [Un cluster gratuito en MongoDB Atlas](MongoDB-Atlas.md) muestra cada paso con capturas, y también cómo cargar los datos de la EPH en el cluster.

## Respaldo, restauración e importación desde la terminal

Las herramientas de línea de comandos de MongoDB (*Database Tools*) se instalan junto con el servidor en macOS y Ubuntu. En Windows se descargan aparte desde la página de [MongoDB Database Tools](https://www.mongodb.com/try/download/database-tools); después de instalarlas, hay que agregar su carpeta `bin` (por ejemplo, `C:\Program Files\MongoDB\Tools\100\bin`) a la variable de entorno `PATH`, o ejecutar los comandos desde esa carpeta.

Respaldar la base `eph`, comprimida, en la carpeta `respaldo`:

```bash
mongodump --db eph --gzip --out respaldo
```

Restaurar ese respaldo con el mismo nombre de base, o con otro nombre:

```bash
mongorestore --gzip respaldo
mongorestore --gzip --nsFrom "eph.*" --nsTo "eph_copia.*" respaldo
```

Importar un archivo JSON a una colección. Por defecto, `mongoimport` espera un documento por línea; si el archivo es un array de documentos, hay que agregar `--jsonArray`:

```bash
mongoimport --db eph --collection hogares --file eph_hogares_2026t1.json
```

Para un CSV se agregan `--type csv --headerline`, que toma los nombres de los campos de la primera fila.
