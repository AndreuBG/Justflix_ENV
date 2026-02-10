# Justflix_ENV

## Propósito y Alcance
Justflix_ENV es un repositorio de **orquestación Docker Compose** que permite a los desarrolladores ejecutar toda la plataforma de microservicios de Justflix con un solo comando. No contiene código de aplicación; en su lugar, el repositorio:

- Orquesta múltiples repositorios de servicios independientes mediante Docker Compose  
- Gestiona dependencias de servicios, health checks y orden de inicio  
- Genera y distribuye infraestructura de seguridad (claves JWT y certificados SSL)  
- Proporciona configuración centralizada mediante el archivo `.env`  
- Define la topología de red y la estrategia de persistencia de datos  

El repositorio actúa como **"meta-repositorio"** que coordina seis repositorios Git separados que contienen el código de aplicación real, aplicaciones cliente e implementaciones de servicios.

## Scripts

### install.sh
Sirve para instalar todos los repositorios y utilizar el resto de scripts para la configuración del proyecto.

### generate_certs
Llama a los scripts del catalogo y de odoo, generando sus certificados necesarios para el uso de https.

### generate_jwt_keys
Utiliza el script de odoo para que genere un par de claves para encriptar los tokens. Luego, copiar la clave public a un directorio del catalogo (`/src/main/resources/jwt-key`) y un directorio del backend multimedia (`/src/jwt_key`), que utilizarán para verificar los tokens.
