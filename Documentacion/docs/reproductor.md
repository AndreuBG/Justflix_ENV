# Reproductor (Flutter)

## Capacidades principales

- **Autenticación y sesión**
    -Mediante Odoo con `access-token` y `refres-token`

- **Búsqueda de contenido**
    - Tanto resultados como sugestiones

- **Reproducción de vídeo**
  - Visualización de video autenticado
  - Refresco de token
  - Bloqueo de pantalla activo durante reproducción
  - Control de orientación (vertical / horizontal)  

- **Multiplataforma y UI**
  - Soporte Android / Web
  - Tema claro / oscuro dinámico
  - Orientación forzada a vertical en la app  `

- **Arquitectura y estado**
  - Clean Architecture (Presentation / Domain / Infrastructure)
  - Estado reactivo con Riverpod para el login y globalización de los atributos del usuario

---

## Detalles técnicos

- **Vídeo**
  - Usa `video_player` + `chewie` para controles
  - Cabeceras requeridas:
    - `Authorization: Bearer <token>`
    - `x-refresh-token`
  - Si el token expira (401):
    - Se refresca automáticamente en `/api/update/access-token`
- **Búsqueda**
  - La búsqueda usa el endpoint:  
    `/catalogo/series/titulo/{encoded}`
  - Paginación:
    - `page: 0`
    - `size: 8` comodidad el usuario lo podria tapar el teclado si fuera mayor
  - Las entidades se mapean a `Map<String, dynamic>` para la UI  
- **Navegación**
  - Desde `SeriesScreen` se accede a:
    - `SeriesDetallScreen` (lista de episodios)
    - `VideoPlayerScreen` (reproducción)  
- **Configuración**
  - Orientación vertical forzada
  - Tema configurado con Material 3
  - Host dinámico `appId`:
    - `localhost` en Web
    - IP configurable en móvil  

---

### Notes

- La app fuerza **orientación vertical** en toda la interfaz, excepto durante la reproducción en pantalla completa, que cambia a horizontal.  

- El **modo invitado** permite navegar sin autenticación, pero la reproducción puede estar limitada por el backend (`403 Forbidden`).  

- Los **tokens JWT** se almacenan y se exponen globalmente a través de `authProvider`.

## Arquitectura

La aplicación sigue **Clean Architecture** con tres capas bien definidas:

- `lib/presentation`
- `lib/domain`
- `lib/infrastructure`

Utiliza **inyección de dependencias manual en `main()`** y **estado reactivo con Riverpod**.  

---

## Estructura del proyecto

```ruby
lib/  
├── main.dart                     # Inyección de dependecias, estilos y ProviderScope  
├── presentation/  
│   ├── screens/                  # Vistas principales  
│   │   ├── log_in_screen.dart  
│   │   ├── series_screen.dart  
│   │   ├── serie_detalls_screen.dart  
│   │   └── video_player_screen.dart  
│   ├── widgets/                  # Componentes reutilizables  
│   │   ├── my_container_widget.dart  
│   │   └── ...  
│   └── delegates/                # Delegadode busqueda de series 
│       └── search_series_delegate.dart  
├── domain/  
│   ├── entities/                 # Entidades  
│   │   ├── Video.dart  
│   │   ├── Serie.dart  
│   │   ├── User.dart  
│   │   └── page.dart  
│   ├── repositories/             # Interficies (repositorios abstractos)  
│   │   ├── videos_repositori.dart  
│   │   ├── series_repositori.dart  
│   │   └── user_repository.dart  
│   └── usecase/                  # Casos de uso  
│       ├── GetVideoUseCase.dart  
│       ├── GetSeriesUseCase.dart  
│       └── login_user_usecase.dart  
└── infrastructure/  
    ├── data_sources/             # APIs
    │   ├── videos_api.dart  
    │   ├── series_api.dart  
    │   └── auth_remote_data_source.dart  
    ├── repository/               # Implementaciones de repositorios  
    │   ├── videos_repository_impl.dart  
    │   ├── series_repository_impl.dart  
    │   └── user_repository_impl.dart  
    └── mappers/                  # Mapeadores 
        ├── Video_mapper.dart  
        ├── serie_mapper.dart  
        └── page_mapper.dart  
```

---

## Arquitectura (Clean Architecture)

### Capas

- **Presentation**
  - Consume **casos de uso** y **entidades**
  - No depende de Infrastructure
  - La lógica de UI
  
- **Domain**
  - Núcleo de la aplicación
  - Contiene:
    - Entidades (`Video`, `Serie`, `User`)
    - Interfaces de repositorio
    - Casos de uso

- **Infrastructure**
    - Llamadas a APIs
    - Repositorios concretos
    - Mappers
  - Depende de **Domain**
  - Ejemplo:
    - `VideoRepositoryImpl` implementa `VideoRepository` y usa `VideosApi` y `VideoMapper`

---

### Idea clave

La UI (**Presentation**) nunca conoce detalles de red o persistencia.  
El **Domain** define qué se puede hacer.  
La **Infrastructure** decide cómo se hace.


## Detalles de uso

- **Paginación**
  - Los endpoints de listado usan:
    - `?page={n}&size={m}`
- **Búsqueda**
  - La búsqueda por título:
    - Llama a `/catalogo/series/titulo/{encoded}`

- **Reproduccion**
  - Construcción de URL:
    - `http://{appId}:8080/api/videolist/{id}/index.m3u8`
  - Acceso mediante cabeceras:
    - `Authorization: Bearer {token}`
    - `x-refresh-token: {refreshToken}`

- **Refresco de token**
  - Si el la peticion previa a la reproduccion responde `401`:
    - Se ejecuta `POST /api/update/access-token`
    - Se envía `{ refresh_token }` en el body
    - Se actualiza el provider con el nuevo `access_token`

## Paginas & Widgets

### Pantalla 

| Screen               | Propósito                                                                 |
|----------------------|---------------------------------------------------------------------------|
| LogInScreen          | Autenticación (email/contraseña), modo invitado y registro externo        |
| SeriesScreen         | Pantalla principal con carrusel de destacados, lista de series y últimos videos|
| AllSeriesSrchScreen  | Listado paginado infinito de todo el catálogo                             |
| SeriesDetallScreen   | Detalle de serie con listado de episodios                                 |
| VideoPlayerScreen    | Reproductor con metadatos del video                                   |

---

### Widgets

| Widget                         | Rol                                                                 |
|--------------------------------|---------------------------------------------------------------------|
| JustflixAppBar                 | Barra superior con logo, búsqueda y botón de retroceso              |
| MyContainerWidget              | Wrapper del reproductor de video (Chewie) con gestión de token       |
| AllSeriesWidget                | GridView infinito con paginación y `ScrollController`               |
| SearchSeriesDelegate           | Búsqueda nativa con sugerencias y resultados                         |
| FeaturedCarouselWidget         | Carrusel de contenido destacado                                     |
| CarouselVideoLatestWidget      | Carrusel de últimos videos                                          |
| MyListSeriesWidget             | Lista horizontal de series                                          |
| AppNavigationBar               | Barra de navegación inferior (Series / Todas)                       |


### Flujos clave

- **Login / Invitado → SeriesScreen**
  - Navegación inicial tras autenticación o acceso como invitado mediante `pushReplacement`.

- **Tocar una serie → SeriesDetallScreen**
  - Abre la pantalla de detalle de la serie.
  - Se pasa la información como `Map<String, dynamic>` para desacoplar la UI del dominio.

- **Tocar un episodio → VideoPlayerScreen**
  - Inicia la reproducción del episodio seleccionado.
  - Se pasa el mapa del episodio (`film map`) al reproductor.

- **Tocar el logo en el AppBar → SeriesScreen**
  - Retorna al hub principal desde cualquier pantalla.
  - Navegación mediante `pushReplacement`.

---

### Notas
- Los widgets de lista convierten entidades del dominio a `Map<String, dynamic>` para desacoplar la UI de las entidades de `domain`.
- La búsqueda y el listado infinito utilizan `FutureBuilder` y `ScrollController` con manejo de estados (`loading`, `error`, `empty`).
- `JustflixAppBar` actúa como punto de entrada tanto a la búsqueda como al home desde múltiples pantallas.

## Provider

### authProvider (Riverpod)

- **Nombre:** `authProvider`
- **Tipo:** `Notifier<AuthNotifier, AuthState>`
- **Responsabilidad:** Gestionar el estado de autenticación y exponer acciones de login y refresco de token

---

### Estado gestionado (AuthState)

- `user?`: Usuario autenticado
- `token?`: Access token JWT
- `refreshToken?`: Refresh token
- `loading`: Indica operación en curso (login / refresh)
- `error?`: Mensaje de error en caso de fallo

---

### Uso del provider

#### Patrones comunes

- **ref.watch**
  - Observa el estado y reconstruye widgets
  - Ejemplo: deshabilitar botón durante login cuando `loading == true`

- **ref.read**
  - Lee el provider sin observar cambios
  - Usado para ejecutar acciones
  - Ejemplo:
    - `ref.read(authProvider.notifier).login(...)`

- **ref.listen**
  - Reacciona a cambios de estado sin reconstruir la UI
  - Usado para navegación y mostrar errores
---

### Flujo de login

- El usuario introduce email y contraseña y pulsa **Acceder**
- `Datos.login()`:
  - Valida campos
  - Llama a:
    - `authProvider.notifier.login(() => usecase(email, password))`
- El provider:
  - Ejecuta `LoginUserUsecase`
  - Obtiene un `User`
  - Actualiza `AuthState`
- `ref.listen`:
  - Detecta `next.user != null`
  - Navega a `SeriesScree`

## Dominio (`lib/domain/`)

### Componentes clave

- **Entidades**
  - Ejemplos: `Video`, `Serie`, `User`, `PageModel<T>`
  - Responsabilidad:
    - Modelos de negocio puros
    - Sin dependencias externas ni lógica de infraestructura

- **Contratos (interfaces de repositorio)**
  - Ejemplos: `VideoRepository`, `SerieRepository`, `UserRepository`
  - Responsabilidad:
    - Definir qué operaciones de datos existen
    - No contienen implementación
    - Aíslan el dominio de la infraestructura

- **Casos de uso**
  - Ejemplos: `GetVideosUseCase`, `GetSeriesUseCase`, `LoginUserUsecase`
  - Responsabilidad:
    - Exponer una API simple a la capa de presentación

---

### Flujo típico en el dominio

- Un **caso de uso**:
  - Recibe una **interfaz de repositorio** por constructor
- El caso de uso:
  - Invoca métodos del repositorio (ej. `getVideos(page, size)`)
- El repositorio:
  - Devuelve **entidades de dominio**
    - Ejemplo: `PageModel<Video>`
- El caso de uso:
  - Retorna esas entidades a la capa de presentación

---

## Infraestructura (`lib/infrastructure/`)

### Componentes clave

- **Data Sources**
  - Ejemplos: `VideosApi`, `SeriesApi`, `AuthRemoteDataSource`
  - Responsabilidad:
    - Comunicación HTTP directa con el backend
    - Manejo de endpoints REST
    - Devuelven `Map<String, dynamic>` (JSON crudo)

- **Repositorios (implementaciones)**
  - Ejemplos: `VideoRepositoryImpl`, `SerieRepositoryImpl`
  - Responsabilidad:
    - Implementar los contratos definidos en el dominio
    - Orquestar llamadas a APIs + mappers
    - Centralizar lógica de errores y paginación

- **Mappers**
  - Ejemplos: `VideoMapper`, `SerieMapper`, `PageMapper`
  - Responsabilidad:
    - Convertir JSON ↔ entidades de dominio
    - Aislar al dominio del formato del backend

---

### Flujo de datos (ejemplo: `getVideos`)

- `VideoRepositoryImpl.getVideos(page, size)`:
  - Llama a `VideosApi.getVideos(page, size)`

- `VideosApi`:
  - Hace HTTP GET a:
    - `/catalogo/videos?page=X&size=Y`
  - Devuelve JSON

- El repositorio:
  - Usa:
    - `PageMapper.fromJson(json, VideoMapper.fromJson)`
  - Convierte el JSON en `PageModel<Video>`

- El caso de uso:
  - Recibe la página de entidades
  - La devuelve a la UI sin exponer detalles de infraestructura

---

### Manejo de errores y paginación

- **Errores**
  - Si ocurre un error HTTP o de parsing:
    - El repositorio devuelve una página vacía
    - Conserva metadatos de paginación
  - Objetivo:
    - No romper la UI

- **Paginación**
  - Los endpoints aceptan:
    - `page`
    - `size`
- `PageModel` incluye:
    - `totalElements`
    - `totalPages`
    - `first`
    - `last`
