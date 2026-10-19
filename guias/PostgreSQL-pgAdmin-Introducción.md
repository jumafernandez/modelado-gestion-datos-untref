# Introducción a la gestión de PostgreSQL desde pgAdmin

La forma tradicional de administración de una DB es mediante la consola del Sistema Operativo, sin embargo, existen herramientas gráficas de administración de bases de datos que brindan diversas utilidades y propenden a una administración más sencilla.
La herramienta de administración más utilizada para PostgreSQL es **pgAdmin**. pgAdmin provee una interfaz gráfica intuitiva que permite la ejecución tanto de los comandos DDL como los DML de forma gráfica, brindando un gestor de consultas, herramientas de backup y restore, una herramienta para diagramar las tablas y sus relaciones (*ERD Tool*), etc.

<p align="center">
<img src="./imgs/pgadmin-logo.png" width="350px" />
</p>

## Configuración inicial del servidor PostgreSQL en pgAdmin
Cuando recién instalamos pgAdmin, lo primero que debemos hacer para poder administrar PostgreSQL desde la aplicación es configurar el acceso de pgAdmin al Servidor de Bases de Datos de PostgreSQL. Si instalamos PostgreSQL con el instalador de EDB (Windows o macOS), ese acceso ya viene configurado: en *Servers* aparece *PostgreSQL 18* y alcanza con desplegarlo e ingresar la contraseña del usuario *postgres*. Los pasos que siguen hacen falta en Linux o para conectarse a otro servidor.
A continuación, se realiza un paso a paso de esta configuración:
1. Cuando iniciamos pgAdmin, ir al ícono *Servers*, presionar botón derecho sobre él y elegir la opción *Register > Server...*.

<p align="center">
<img src="./imgs/pgadmin-1.png" width="500px" />
</p>

<p align="center">
<img src="./imgs/pg-admin-2.png" width="500px" />
</p>

2. Aquí vamos a configurar el acceso, para ello debemos determinar una serie de datos mínimos:
- *Name* en la pestaña *General*: Este nombre podrá ser cualquier nombre de su interés, por ejemplo: PC-local, lo cual indica que es una conexión local. Este campo admite cualquier nombre.
- *Host name/address* en la pestaña *Connection*: aquí debemos poner *localhost*.
- *Port* en la pestaña *Connection*: en caso que hayamos modificado el puerto de escucha de la DB, debemos escribirlo. De lo contrario dejamos el puerto por defecto (5432).
- *Username* en la pestaña *Connection*: *postgres*, el superusuario que crea la instalación (es el valor por defecto).
- *Password* en la pestaña *Connection*: Aquí escribimos la contraseña del usuario *postgres* que definimos al instalar PostgreSQL.
- *Save password?* en la pestaña *Connection*: Aquí podemos elegir que guarde la clave para no volver a ingresarla cada vez que iniciamos la conexión. Esto es recomendable solo para instalaciones locales.

## Utilización básica de pgAdmin
Una vez que configuramos el acceso al Servidor de PostgreSQL desde pgAdmin podemos comenzar a trabajar con nuestras Bases de Datos.
1. En primer lugar, debemos crear una Base de Datos. Para crear la DB, debemos expandir el Servidor creado y hacer clic derecho sobre el ícono *Databases* y elegir la opción *Create > Database*. También puede crearse con SQL (`CREATE DATABASE prueba;`) desde el *Query Tool* abierto sobre la base *postgres*: cada conexión trabaja sobre una única base, así que para crear una nueva hay que estar conectados a otra que ya exista.

<p align="center">
<img src="./imgs/pgadmin-3.png" width="500px" />
</p>

2. Si bien es posible definir un sinfín de parámetros como el *encoding* y la configuración regional, con el solo hecho de elegir un nombre ya podemos crearla. En nuestro caso, elegimos el nombre *prueba* para completar esta demostración.
3. Una vez que tenemos la Base de Datos creada, podemos ejecutar todas las instrucciones, tanto DDL como DML, desde la herramienta *Query Tool*, que debemos abrir siempre parados sobre la Base de Datos en la que vamos a ejecutar las instrucciones. Si en algún momento vamos a pasar de una DB a otra, hay que abrir el *Query Tool* desde la otra DB (seleccionándola en el árbol) o cambiar la conexión desde la barra superior del *Query Tool*, donde figura la base a la que está conectado.

<p align="center">
<img src="./imgs/pgadmin-4.png" width="500px" />
</p>

4. Si bien, como comentaba antes, es posible ejecutar todas las instrucciones (DDL y DML) desde *Query Tool*, entre las funcionalidades de pgAdmin, brinda la posibilidad de crear las tablas, con sus columnas y CONSTRAINTS, también desde una interfaz gráfica sin necesidad de escribir código SQL. Para ello, se debe expandir el ícono *Schemas*, también el *public* (esquema por defecto), bajar hasta la opción *Tables*, hacer clic derecho sobre esta opción y seleccionar *Create > Table...*.

<p align="center">
<img src="./imgs/pgadmin-5.png" width="500px" />
</p>

5. Una vez que se ingresa a la opción, podrán definirse todas las propiedades de una Tabla que vimos en clase, con la ventaja de que pgAdmin irá generando el código SQL (en la pestaña *SQL*, la última) en función de las columnas y CONSTRAINTS que escojamos.

<p align="center">
<img src="./imgs/pgadmin-6.png" width="500px" />
</p>

6. Hasta aquí una guía básica de pgAdmin, luego seguiremos profundizando en clase.

_Última actualización: octubre de 2026._

