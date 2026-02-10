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

actor "Usuario" as user

participant "Admin Frontend" as admin
participant "Multimedia" as multimedia
participant "Catalogo" as catalogo
participant "Odoo" as odoo

user -> admin : Acceder al login

admin -> odoo: Petición de login /api/authenticate
admin <-- odoo: Devuelve access_token y refresh_token

user <-- admin : Muestra la pagina de inicio

user -> admin : Crear una serie
admin -> multimedia: Envia imagen de la serie a /api/serielist/upload
admin <-- multimedia: Devuelve la id de la serie
admin -> catalogo: Envia la id_serie + informacion de la serie a /catalogo/series
admin <-- catalogo: Devuelve el objeto de la serie

user <-- admin : Muestra la pagina de la serie

user -> admin : Crear un video en la serie
admin -> multimedia: Envia video a /api/videolist/upload
admin <-- multimedia: Devuelve video_id y metadatos (duracion, resolucion)
admin -> catalogo: Envia video_id y metadatos a /catalogo/video
admin <-- catalogo: Devuelve el objeto del video

user <-- admin : Muestra el progreso y actualiza la lista de episodios

@enduml
```

### Suscriptor

```puml
@startuml

actor "Usuario" as user
participant "Reproductor" as reproductor
participant "Multimedia" as multimedia
participant "Catalogo" as catalogo
participant "Odoo" as odoo



user -> reproductor : Acceder al login

reproductor -> odoo: Petición de login /api/authenticate
reproductor <-- odoo: Devuelve access_token y refresh_token

reproductor -> catalogo: Peticion de los videos simples /catalogo/videos
reproductor <-- catalogo: Devuelve una pagina con la info de los videos

reproductor -> catalogo: Peticion de las series simples /catalogo/series
reproductor <-- catalogo: Devuelve una pagina con la info de las series

loop Por cada video

reproductor -> multimedia: Pide los thumbnails /public/thumbnail/:id_video.png
reproductor <-- multimedia: Devuelve la imagen

end

loop Por cada serie

reproductor -> multimedia: Pide los thumbnails /public/thumb_series/:id_serie.png
reproductor <-- multimedia: Devuelve la imagen

end

user <-- reproductor : Muestra la pagina de inicio

user -> reproductor : Selecciona video
reproductor -> catalogo : Pide la info del video /catalogo/videos/:id_video
reproductor <-- catalogo : Devuelve el video al completo

reproductor -> catalogo : Pide la info de la serie /catalogo/series/:id_serie
reproductor <-- catalogo : Devuelve la serie

user <-- reproductor : Muestra la info del video

user -> reproductor : Reproducir video

reproductor -> multimedia : Pide el listado de fragmentos /api/videolist/:id_video/index.m3u8
multimedia -> multimedia: Verificar que el token no esta expirado o vaya a expirar
multimedia -> multimedia: Verificar token con la clave publica
reproductor <-- multimedia : Devuelve el listado

loop Por cada segmento .ts

reproductor -> multimedia : Pide el fragmento /api/videolist/:id_video/indexN.ts
multimedia -> multimedia: Verificar que el token no esta expirado o vaya a expirar
multimedia -> multimedia: Verificar token con la clave publica
reproductor <-- multimedia : Devuelve el fragmento
user <-- reproductor: Mostrar fragmento del video

end









@enduml
```