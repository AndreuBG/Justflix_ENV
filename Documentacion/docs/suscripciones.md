# Suscripciones (Odoo)

## Propósito y Alcance
Justflix_Suscripciones es una plataforma de gestión de suscripciones construida sobre **Odoo 16.0**. Este sistema proporciona autenticación basada en API usando tokens JWT y gestiona ciclos de vida de suscripciones recurrentes, incluyendo creación, facturación y cancelación. La plataforma se ejecuta como una aplicación contenerizada con tres servicios Docker: un proxy inverso Nginx, un servidor de aplicaciones Odoo con addons personalizados y una base de datos PostgreSQL.


## Arquitectura del Sistema
El sistema sigue una arquitectura contenerizada de tres niveles orquestada con Docker Compose:

El contenedor `nginx_proxy` redirige el tráfico HTTPS al servidor de Odoo.  
El contenedor `odoo_suscripciones` aloja el framework Odoo con tres addons personalizados montados desde `./extra-addons`.  
El contenedor `postgres_db` proporciona almacenamiento persistente para todos los datos de la aplicación.


## Componentes Principales

### Servicios Docker

| Servicio | Nombre del Contenedor | Imagen         | Puertos Expuestos | Propósito |
|----------|---------------------|----------------|-----------------|-----------|
| nginx    | nginx_proxy         | nginx:latest   | 80, 443         | Terminación SSL y proxy inverso |
| odoo     | odoo_suscripciones  | Build personalizado | 8069         | Servidor de aplicaciones Odoo |
| postgres | postgres_db         | postgres:14    | 5432             | Base de datos relacional |

El contenedor de Odoo incluye un **health check** en `/web/login` que asegura que la aplicación esté lista antes de que Nginx comience a reenviar las solicitudes.

### Addons Personalizados de Odoo
El sistema extiende Odoo con tres módulos personalizados ubicados en `./extra-addons`:

#### Módulo `odoo_jwt`
Proporciona autenticación basada en JWT para acceso a la API. Implementa criptografía de clave asimétrica RSA para firma y verificación de tokens. El módulo expone **cuatro endpoints HTTP** e intercepta solicitudes que requieren autenticación JWT.

**Clases Clave:**

- `ApiAuth` - Controlador HTTP que expone endpoints de autenticación -> Modificado para devolver respuestas http
- `JwtToken` - Clase utilitaria para generación y validación de tokens -> Modificado para comprobar las suscripciones y permisos, además de añadir contenido en el payload
- `IrHttp` - Interceptor de solicitudes para validación JWT  

[Enlace a su página oficial](https://odoo-community.org/shop/subscription-management-715311#attr=938468)


#### Módulo `subscription_oca`
Implementa la lógica central de suscripciones basada en el módulo de suscripción OCA (Odoo Community Association). Gestiona el ciclo de vida de las suscripciones a través de etapas (`draft`, `pre`, `in_progress`, `post`), genera facturas recurrentes mediante **cron jobs** y aplica restricciones de negocio.

**Modelos Clave:**

- `sale.subscription` - Entidad principal de suscripción  
  `extra-addons/subscription_oca/models/sale_subscription.py 14-504`  
- `sale.order` - Extendida para crear suscripciones al confirmar órdenes  
  `extra-addons/subscription_oca/models/sale_order.py 12-126`

Estos modelos han sido modificados para añadir validación en la compra de las suscripciones.

**Reglas de Negocio:**

- Una suscripción por orden  
- Una plantilla por orden   
- Máximo una suscripción activa por cliente   
- Máximo una unidad de cantidad  

[Enlace a su página](https://apps.odoo.com/apps/modules/17.0/odoo_jwt)

#### Módulo `subscription_website`
Proporciona interfaz web para que los usuarios finales puedan ver y cancelar sus suscripciones. Expone el portal `/mi-suscripcion`.

También expone un endpoint `/mi-suscripcion/cancelar` utilizado para cancelar la suscripcion.

## Autenticación y API
El sistema de autenticación utiliza un enfoque de **doble token**:

- Tokens de acceso de corta duración (incluidos en payload JWT)  
- Tokens de refresco de larga duración (almacenados en la base de datos)  

La mayoría de los endpoints usan `auth: none` para permitir operaciones de token cuando expiran los tokens de acceso, excepto `/api/update/refresh-token` que requiere `auth: jwt` para mayor seguridad durante la rotación de tokens. Esta autenticación exige un `access-token` valido en los headers para poder continuar.

## Endpoints

| Endpoint                     | Método | Autenticación (auth)                                | Propósito                                                         | Input clave                       | Output (200)                       | Errores comunes                                           |
|-------------------------------|--------|----------------------------------------------------|------------------------------------------------------------------|----------------------------------|-----------------------------------|-----------------------------------------------------------|
| /api/authenticate             | POST   | none                                               | Inicia sesión y emite access + refresh tokens                   | {login, password, db *(opcional)*}            | {token, refreshToken}             | 400/401: credenciales faltantes o inválidas (`api_uth.py:27-59`) |
| /api/update/access-token      | POST   | none                                               | Renueva el access token usando refresh token                    | {refresh_token}                  | {access_token}                    | 400/401: token no proporcionado o inválido (`api_uth.py:61-79`) |
| /api/update/refresh-token     | POST   | jwt (requiere Authorization: Bearer <access_token>) | Rota el refresh token (requiere access token válido)            | {refresh_token}                  | {status: done, refreshToken}      | 400/401: token no proporcionado o inválido (`api_uth.py:81-108`) |
| /api/revoke/token             | POST   | none                                               | Revoca el refresh token (logout)                                 | {refresh_token}                  | {status: success, logged_out: 1} | 400/401: token no proporcionado o inválido (`api_uth.py:110-125`) |


## Seguridad y Control de Acceso
La seguridad se implementa en múltiples capas:

- **Capa de Transporte**: Nginx aplica HTTPS con certificados SSL generados por `gen_keys_nginx.sh`  
- **Capa de Autenticación**: Tokens JWT firmados con claves RSA generadas por `gen_keys_jwt.sh`  
- **Capa de Autorización**: Grupos de seguridad de Odoo mapean roles JWT en el payload del token  

El grupo **"Gestor del catálogo"** recibe el rol de administrador en los tokens JWT, otorgando privilegios elevados para la gestión de contenido.

## Configuración del Entorno
El sistema usa variables de entorno para credenciales y configuración:

| Variable          | Propósito                        | Definido en |
|------------------|---------------------------------|-------------|
| ODOO_USER         | Usuario de la aplicación Odoo    | `.env`      |
| ODOO_PASSWORD     | Contraseña de Odoo               | `.env`      |
| POSTGRES_USER     | Usuario de PostgreSQL            | `.env`      |
| POSTGRES_PASSWORD | Contraseña de PostgreSQL         | `.env`      |

El archivo `odoo.conf` configura:

- `addons_path`: ubicación de addons personalizados  
- `db_host`: hostname del contenedor PostgreSQL (`postgres_db`)  
- `db_port`: puerto de la base de datos (5432)  
- `db_user` y `db_password`: credenciales de la base de datos  
- `proxy_mode`: habilita soporte de proxy inverso  
- `logfile`: ruta de salida de logs


## Almacenamiento Persistente de Datos
El sistema utiliza **volúmenes Docker** para datos persistentes que sobreviven reinicios de contenedores.  
Se usan **bind mounts** para desarrollo local:  

- `./extra-addons` → módulos personalizados  
- `./config` → archivos de configuración  
- `./log` → logs de la aplicación  

Archivos sensibles y datos generados se excluyen del control de versiones mediante `.gitignore`.