# Inicio

## Proposito
El proposito de la aplicacion es crear una plataforma de streaming, que gestione usuarios, suscriptores y administradores. Que proporcionará un listado de series y videos.

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
| Admin Frontend     | Vue.js    | Interfaz de gestión de contenido       | Justflix_Admin      |
| Reproductor        | Flutter   | Aplicación de streaming para usuarios finales | Justflix_Reproductor |

## Flujos Generales

### Administrador

```puml
@startuml

participant "Admin Frontend" as admin
participant "Multimedia" as multimedia
participant "Catalogo" as catalogo
participant "Odoo" as odoo

admin -> odoo: Petición de login /api/authenticate
admin <-- odoo: Devuelve access_token y refresh_token

admin -> multimedia: Envia imagen de la serie a /api/serielist/upload
admin <-- multimedia: Devuelve la id de la serie
admin -> catalogo: Envia la id_serie + informacion de la serie a /catalogo/series
admin <-- catalogo: Devuelve el objeto de la serie

admin -> multimedia: Envia video a /api/videolist/upload
admin <-- multimedia: Devuelve video_id y metadatos (duracion, resolucion)
admin -> catalogo: Envia video_id y metadatos a /catalogo/video
admin <-- catalogo: Devuelve el objeto del video




@enduml
```