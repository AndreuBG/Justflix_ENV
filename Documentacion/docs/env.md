# Justflix_ENV

## Propósito y Alcance
Justflix_ENV es un repositorio de **orquestación Docker Compose** que permite a los desarrolladores ejecutar toda la plataforma de microservicios de Justflix con un solo comando. No contiene código de aplicación; en su lugar, el repositorio:

- Orquesta múltiples repositorios de servicios independientes mediante Docker Compose  
- Gestiona dependencias de servicios, health checks y orden de inicio  
- Genera y distribuye infraestructura de seguridad (claves JWT y certificados SSL)  
- Proporciona configuración centralizada mediante el archivo `.env`  
- Define la topología de red y la estrategia de persistencia de datos  

El repositorio actúa como **"meta-repositorio"** que coordina seis repositorios Git separados que contienen el código de aplicación real, aplicaciones cliente e implementaciones de servicios.


## Componentes del Sistema
La plataforma Justflix consiste en los siguientes **componentes principales**, todos orquestados por Justflix_ENV:

### Servicios Backend

| Servicio     | Tecnología             | Puerto | Propósito                                        |
|-------------|-----------------------|--------|-------------------------------------------------|
| catalogo    | Spring Boot + Java     | 8090   | Gestión del catálogo de contenido y metadatos  |
| ts-multimedia | Node.js/TypeScript    | 8080   | Streaming de medios y entrega de contenido    |
| odoo        | Python (Odoo ERP)      | 8069   | Gestión de suscripciones y autenticación       |
| nginx       | Nginx                  | 80, 443 | Proxy inverso con terminación SSL             |

### Capa de Datos

| Base de Datos  | Tipo           | Puerto | Usado por        |
|----------------|----------------|--------|-----------------|
| mysql_db       | MySQL 8.0      | 3308   | Servicio catalogo |
| postgres_db    | PostgreSQL 14  | 5432   | Servicio Odoo    |

### Aplicaciones Cliente

| Aplicación          | Tecnología | Propósito                               | Repositorio          |
|--------------------|-----------|----------------------------------------|--------------------|
| Admin Dashboard     | Vue.js    | Interfaz de gestión de contenido       | Justflix_Admin      |
| Player App          | Flutter   | Aplicación de streaming para usuarios finales | Justflix_Reproductor |