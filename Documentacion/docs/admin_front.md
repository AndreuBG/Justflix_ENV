# CAPACIDADES PRINCIPALES

- **Autenticación JWT con validación de roles**: Acceso exclusivo para usuarios con rol 'admin'  
  Componentes: LoginForm, validación de token JWT

- **Gestión de series**: Creación, edición y eliminación de series del catálogo  
  Componentes: Home, SeriesManager

- **Gestión de episodios**: CRUD completo de episodios asociados a series  
  Componentes: SerieDetail, VideoEditor

- **Subida de contenido multimedia**: Upload de videos con conversión HLS automática y generación de miniaturas  
  Componentes: UploadForm, integración con servidor multimedia

- **Eliminación completa de videos**: Eliminación dual (catálogo + archivos físicos del servidor multimedia)  
  Componentes: SerieDetail, VideoEditor

- **Gestión de miniaturas**: Upload y gestión de imágenes para series  
  Componentes: UploadForm, integración con API multimedia

- **Interfaz responsive**: Navegación mediante sidebar con rutas dinámicas  
  Componentes: Sidebar, App

- **Comunicación multi-backend**: Integración con Odoo (auth), Spring Boot (catálogo) y Node.js (multimedia)  
  Configuración: Vite proxy con manejo de CORS y certificados autofirmados

# ESTRUCTURA DEL PROYECTO

```ruby
admin_app/
├── index.html                    # Punto de entrada HTML
├── package.json                  # Dependencias del proyecto
├── vite.config.js                # Configuración de Vite con proxies
├── login.js                      # Lógica de autenticación (no utilizado en Vue)
├── mock-server.js                # Servidor mock para desarrollo
└── src/
    ├── main.js                   # Inicialización de Vue 3
    ├── App.vue                   # Componente raíz con router manual y sidebar
    └── components/
        ├── LoginForm.vue         # Formulario de login con validación de roles
        ├── Home.vue              # Dashboard principal con gestión de series
        ├── Media.vue             # Vista de gestión multimedia (legacy)
        ├── SerieDetail.vue       # Detalle de serie con listado de episodios
        ├── VideoEditor.vue       # Modal de edición de episodios
        ├── UploadForm.vue        # Formulario de subida de contenido
        └── Sidebar.vue           # Navegación lateral
```

# ARQUITECTURA

La aplicación sigue una **arquitectura de componentes Vue 3** con Composition API:

- **Capa de presentación**: Componentes Vue con lógica reactiva (`ref`, `reactive`, `computed`)
- **Capa de servicios**: Funciones auxiliares para peticiones HTTP autenticadas
- **Integración multi-backend**: Comunicación con 3 servicios independientes (Odoo, Spring Boot, Node.js)
- **Router manual**: Navegación implementada mediante estado reactivo sin Vue Router

---

## Flujo de autenticación

1. Usuario introduce email y contraseña en `LoginForm`
2. POST a `/api/login` (Odoo) con credenciales
3. Odoo responde con JWT que incluye:
   - `sub`: ID del usuario
   - `username`: Nombre de usuario
   - `roles`: Array con roles ['admin'] o ['user']
   - `has_subscription`: Boolean de suscripción activa
   - `exp`: Timestamp de expiración
4. `LoginForm` decodifica el JWT y valida que `roles` incluya 'admin'
5. Si es válido, emite evento `login-success` con el token
6. `App.vue` almacena el token y muestra la interfaz de administración

---

## Sistema de navegación

- **Estado reactivo**: `currentView` determina qué componente renderizar
- **Sidebar**: Botones que cambian `currentView` mediante eventos
- **Rutas disponibles**:
  - `home`: Dashboard principal con gestión de series
  - `upload`: Formulario de subida de contenido
  - `serie-detail`: Detalle de serie con episodios (recibe `serieId`)

---

## Gestión de estado

- **Token JWT**: Almacenado en `App.vue` y propagado via props
- **Series**: Estado local en `Home.vue` con `ref<Array>`
- **Episodios**: Estado local en `SerieDetail.vue` con reactividad
- **Modales**: Estado booleano para controlar visibilidad de `VideoEditor`

# COMPONENTES

## LoginForm.vue

**Propósito**: Autenticación con validación de rol de administrador

**Características**:
- Formulario reactivo con email y contraseña
- Validación de rol 'admin' mediante decodificación de JWT
- Mensajes de error específicos (credenciales inválidas, acceso denegado)
- Emisión de evento `login-success` con token válido

**Flujo**:
1. Usuario completa formulario y hace submit
2. POST a `/api/login` con `{ login, password }`
3. Si 200: decodifica token con `atob(tokenParts[1])`
4. Valida que `payload.roles.includes('admin')`
5. Si no es admin: lanza error "Acceso denegado: Solo administradores..."
6. Si es admin: emite `login-success(token)`

## App.vue

**Propósito**: Componente raíz que gestiona autenticación y navegación

**Características**:
- Estado global de autenticación (`isLoggedIn`, `token`)
- Router manual mediante `currentView`
- Props drilling para pasar token y callbacks de navegación
- Renderizado condicional (LoginForm vs Dashboard)

**Métodos clave**:
- `handleLogin(token)`: Almacena token y activa sesión
- `handleLogout()`: Limpia token y retorna a login
- `goToUpload()`: Navega a formulario de subida
- `goToSerieDetail(serieId)`: Navega a detalle de serie
- `goHome()`: Retorna al dashboard principal

---

## Home.vue

**Propósito**: Dashboard principal con gestión de series

**Características**:
- Listado de todas las series del catálogo
- Creación de nuevas series mediante formulario inline
- Navegación a detalle de serie
- Botón para acceder a formulario de subida de contenido
- Actualización automática tras crear serie

**Funciones principales**:
- `fetchSeries()`: GET a `/catalogo/series` (paginado)
- `createSerie()`: POST a `/catalogo/series` con título y descripción
- `goToSerieDetail(id)`: Emite evento de navegación

**Estado**:
- `series`: Array de series del catálogo
- `newTitle`, `newDesc`: Campos del formulario de creación

---

## SerieDetail.vue

**Propósito**: Vista detallada de serie con gestión de episodios

**Características**:
- Información de la serie (título, descripción)
- Listado de episodios asociados a la serie
- Edición de episodios mediante modal `VideoEditor`
- **Eliminación dual**: catálogo + archivos multimedia
- Actualización automática tras operaciones CRUD

**Funciones principales**:
- `fetchSerie(id)`: GET a `/catalogo/series/${id}`
- `fetchEpisodes(id)`: GET a `/catalogo/videos/series/${id}/episodios`
- `remove(video)`: **Eliminación dual**
  1. DELETE a `/catalogo/videos/${video.id}` (elimina entrada en BD)
  2. DELETE a `/multimedia/api/videolist/delete/${video.id}` (elimina archivos físicos)
- `openEditor(video)`: Abre modal de edición
- `closeEditor()`: Cierra modal y refresca episodios

---

## VideoEditor.vue

**Propósito**: Modal de edición de metadatos de episodios

**Características**:
- Formulario reactivo con campos: título, descripción, número de temporada, número de episodio
- Guardar cambios mediante PATCH
- **Eliminación dual** desde el modal
- Cierre automático tras operaciones exitosas

**Funciones principales**:
- `onSave()`: PATCH a `/catalogo/videos/${video.id}` con campos actualizados
- `onDelete()`: **Eliminación dual** (mismo patrón que `SerieDetail.remove()`)
- `onClose()`: Emite evento para cerrar modal

**Validaciones**:
- Todos los campos son requeridos
- Número de temporada y episodio deben ser enteros positivos

---

## UploadForm.vue

**Propósito**: Formulario de subida de contenido multimedia

**Características**:
- Upload de videos con conversión HLS automática
- Upload de miniaturas para series
- Asociación de videos a series existentes
- Progreso en tiempo real mediante WebSocket
- Validación de archivos y campos

**Funciones principales**:
- `uploadVideo()`: POST multipart/form-data a `/multimedia/api/videolist/upload`
  - Incluye: archivo de video, título, descripción, temporada, episodio, serieId
  - Respuesta: `{ videoId, websocketUrl, duration, resolution }`
  - Conecta WebSocket para recibir progreso (metadata → thumbnail → processing → complete)
- `uploadThumb()`: POST multipart/form-data a `/multimedia/api/serielist/upload`
  - Incluye: archivo PNG
  - Respuesta: `{ idThumb }`
  - Actualiza serie con PATCH a `/catalogo/series/${serieId}` con nuevo `idThumb`

**WebSocket de progreso**:
- URL recibida en respuesta de upload: `ws://localhost:8080?videoId={id}`
- Mensajes recibidos:
  - `{ stage: 'metadata', progress: 30, duration, resolution }`
  - `{ stage: 'thumbnail_complete', progress: 40 }`
  - `{ stage: 'processing', progress: 45-95 }`
  - `{ stage: 'complete', progress: 100 }`
  - `{ stage: 'error', progress: 0, message }`

**Flujo completo de subida de video**:
1. Usuario selecciona archivo y completa formulario
2. POST multipart a endpoint multimedia
3. Servidor responde con videoId y websocketUrl
4. Frontend conecta WebSocket para recibir progreso
5. Servidor procesa video en background (FFmpeg → HLS + thumbnail)
6. Frontend muestra progreso en tiempo real
7. Al completar, POST a catálogo para registrar metadatos
8. Video queda disponible en el catálogo

---

## Sidebar.vue

**Propósito**: Navegación lateral con botones de acción

**Características**:
- Botón "Inicio": Retorna al dashboard
- Botón "Subir contenido": Navega a formulario de upload
- Botón "Cerrar sesión": Limpia token y retorna a login
- Navegación mediante emisión de eventos

# INTEGRACIÓN DE BACKENDS

La aplicación se comunica con **3 servicios backend independientes**:

## 1. Odoo (Autenticación y Suscripciones)

**Base URL**: `http://localhost:8069`  
**Proxy en dev**: `/api` → `http://localhost:8069`

**Características del JWT**:
- Algoritmo: RS256 (firma asimétrica)
- Payload decodificable en frontend (base64)
- Campo `roles`: Array con ['admin'] o ['user']
- Validación de firma en backend, validación de roles en frontend

## 2. Spring Boot (Catálogo)

**Base URL**: `https://localhost:8090`  
**Proxy en dev**: `/catalogo` → `https://localhost:8090`

**Notas**:
- Todas las peticiones requieren token JWT en header `Authorization: Bearer {token}`
- Paginación estándar Spring Data: `?page={n}&size={m}`

---

## 3. Node.js (Multimedia)

**Base URL**: `http://localhost:8080`  
**Proxy en dev**: `/multimedia` → `http://localhost:8080`

---

## Configuración de proxies (vite.config.js)

```javascript
server: {
  proxy: {
    '/api': { 
      target: 'http://localhost:8069', 
      changeOrigin: true 
    },
    '/catalogo': { 
      target: 'https://localhost:8090', 
      changeOrigin: true, 
      secure: true
    },
    '/multimedia': { 
      target: 'http://localhost:8080', 
      changeOrigin: true, 
      rewrite: (path) => path.replace(/^\/multimedia/, '') 
    }
  }
}
```

**Ventajas**:
- Evita problemas de CORS en desarrollo
- Permite trabajar con certificados autofirmados (Spring Boot)
- Mantiene URLs relativas en el código
- Simplifica configuración de producción (reverse proxy en Nginx)

# FUNCIONES AUXILIARES

## authFetch / authGet / authPost / authPatch / authDelete

**Propósito**: Abstracciones para peticiones HTTP autenticadas

**Uso**:
- Todas las funciones reciben el token como último parámetro
- Se utilizan en todos los componentes que hacen peticiones autenticadas
- Simplifican la gestión de headers de autorización

# SEGURIDAD

## Validación de roles en frontend

**Estrategia**: Decodificación y validación de payload JWT sin verificar firma

**Justificación**:
- La verificación de firma se realiza en el backend
- Frontend solo necesita leer el contenido para decisiones de UI
- No es una vulnerabilidad: el backend siempre valida permisos en cada petición

# FLUJOS DE USUARIO

## 1. Login y acceso al dashboard

1. Usuario abre aplicación
2. Se muestra `LoginForm`
3. Usuario introduce email y contraseña
4. Click en "Acceder"
5. POST a `/api/login` con credenciales
6. Odoo valida y retorna JWT
7. Frontend decodifica token y valida rol 'admin'
8. Si es admin: navega a `Home` (dashboard)
9. Si no es admin: muestra error "Acceso denegado"

## 2. Crear una nueva serie

1. Usuario está en `Home` (dashboard)
2. Completa formulario inline: título y descripción
3. Click en "Crear Serie"
4. POST a `/catalogo/series` con datos
5. Spring Boot crea serie en base de datos
6. Frontend refresca listado de series
7. Nueva serie aparece en el dashboard

## 3. Subir un nuevo episodio

1. Usuario navega a "Subir contenido" desde sidebar
2. Se muestra `UploadForm`
3. Usuario selecciona archivo de video
4. Completa metadatos: título, descripción, temporada, episodio, serie
5. Click en "Subir Video"
6. POST multipart a `/multimedia/api/videolist/upload`
7. Servidor multimedia responde con `videoId` y `websocketUrl`
8. Frontend conecta WebSocket para recibir progreso
9. Servidor procesa video en background:
   - Extrae metadatos (30%)
   - Genera miniatura (40%)
   - Convierte a HLS con FFmpeg (45-95%)
   - Completa procesamiento (100%)
10. Frontend muestra barra de progreso en tiempo real
11. Al completar, video queda disponible en el servidor multimedia
12. Usuario navega a detalle de serie para ver el nuevo episodio

## 4. Editar un episodio existente

1. Usuario navega a detalle de serie desde `Home`
2. Se muestra `SerieDetail` con listado de episodios
3. Usuario hace click en "Editar" en un episodio
4. Se abre modal `VideoEditor` con datos actuales
5. Usuario modifica campos (título, descripción, temporada, episodio)
6. Click en "Guardar"
7. PATCH a `/catalogo/videos/{id}` con campos actualizados
8. Spring Boot actualiza registro en base de datos
9. Modal se cierra y `SerieDetail` refresca listado
10. Cambios se reflejan inmediatamente

## 5. Eliminar un episodio

1. Usuario está en `SerieDetail` viendo episodios
2. Click en "Editar" en un episodio
3. En modal `VideoEditor`, click en "Eliminar"
4. Confirmación: "¿Seguro que quieres eliminar este episodio?"
5. Usuario confirma
6. **Eliminación dual**:
   - DELETE a `/catalogo/videos/{id}` (elimina registro en BD)
   - DELETE a `/multimedia/api/videolist/delete/{id}` (elimina archivos físicos)
7. Servidor multimedia elimina:
   - `/public/videos/{id}/` (directorio con segmentos HLS)
   - `/public/thumbnails/{id}.png`
8. Modal se cierra y `SerieDetail` refresca listado
9. Episodio desaparece del catálogo

**Nota crítica**: La eliminación dual garantiza que no queden archivos huérfanos en el servidor multimedia.

## 6. Actualizar miniatura de una serie

1. Usuario navega a "Subir contenido"
2. En sección "Subir miniatura de serie"
3. Selecciona archivo PNG
4. Selecciona serie del dropdown
5. Click en "Subir Miniatura"
6. POST multipart a `/multimedia/api/serielist/upload`
7. Servidor guarda imagen y retorna `idThumb`
8. Frontend hace PATCH a `/catalogo/series/{id}` con nuevo `idThumb`
9. Spring Boot actualiza registro
10. Miniatura actualizada se refleja en el catálogo

## Configuración

### vite.config.js

Verificar que los proxies apunten a las URLs correctas de los servicios backend:

```javascript
server: {
  proxy: {
    '/api': { target: 'http://localhost:8069', changeOrigin: true },
    '/catalogo': { target: 'https://localhost:8090', changeOrigin: true, secure: false },
    '/multimedia': { target: 'http://localhost:8080', changeOrigin: true }
  }
}
```

## Vue 3 Composition API

**Ventajas**:
- Mejor organización de lógica reactiva
- Reutilización de código mediante composables
- TypeScript-friendly (aunque no se usa en este proyecto)
- Mejor tree-shaking

**Funciones principales utilizadas**:
- `ref`: Estado reactivo primitivo
- `reactive`: Estado reactivo de objetos
- `computed`: Propiedades computadas
- `watch`: Observadores de cambios
- `onMounted`: Hook de ciclo de vida

## Vite

**Características utilizadas**:
- Dev server con proxy para evitar CORS
- Build de producción con minificación
- Plugin de Vue para SFC
