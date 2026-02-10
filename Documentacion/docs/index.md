# Inicio

## Propósito
El propósito de la aplicación es crear una plataforma de streaming que gestione usuarios, suscriptores y administradores, proporcionando un catálogo completo de series y vídeos de alta calidad.

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

## Flujos del Sistema

Para que la monitorización de subidas sea fluida, el administrador cuenta con una interfaz que informa en tiempo real del estado de los archivos mediante **WebSockets**.

```puml
@startuml
skinparam actorStyle awesome
autonumber

actor "Administrador" as admin
participant "Admin Frontend\n(Vue.js)" as vue
participant "Servicio Multimedia\n(Node.js)" as media
participant "Catálogo\n(Spring Boot)" as cat

== Autenticación y JWT ==
admin -> vue: Inicia sesión
vue -> cat: Valida credenciales
cat -> vue: Devuelve JWT Token

== Subida de Contenido ==
admin -> vue: Selecciona Video (.mp4)
vue -> media: POST /api/videolist/upload (Stream)

note right of vue
  Se establece conexión WS para
  monitorizar la transcodificación
end note

vue <-> media: Conexión WebSocket establecida

group Feedback en tiempo real (WS)
    media -> vue: Progreso: 25% (Procesando)
    media -> vue: Progreso: 75% (Transcodificando)
    media -> vue: Evento: "status_complete" (video_id)
end

vue -> cat: POST /catalogo/video (video_id + metadatos)
cat -> cat: Persistencia en MySQL
cat -> vue: Confirmación de publicación

vue -> admin: Notificación: "Vídeo disponible"
@enduml
```