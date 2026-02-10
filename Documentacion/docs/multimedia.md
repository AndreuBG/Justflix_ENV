# Multimedia (TypeScript)

## Capacidades principales
- **Subida de vídeo**:Componentes: videoRoutes, inicialVideoService.

- **Conversión a HLS**: conversión asíncrona a segmentos HLS basada en FFmpeg.  
  Componentes: processVideoService, FFmpeg.

- **Generación de miniaturas**: extracción automática de fotogramas de vista previa del vídeo.  
  Componentes: thumbnailService.

- **Streaming de vídeo**: entrega de segmentos HLS autenticada mediante token.  
  Componentes: videoRoutes, middleware refreshToken.

- **Progreso en tiempo real**: actualizaciones del progreso durante el procesamiento mediante WebSocket.  
  Componentes: websocketService.

- **Autenticación por token**: verificación de JWT con comprobaciones de suscripción y roles.  
  Componentes: verifyToken, verifyAdminToken.

- **Renovación de tokens**: renovación de tokens mediante Odoo.  
  Componentes: middleware refreshToken.

- **Gestión de series**: gestión de miniaturas de series.

## Estructura del proyecto

```ruby
src/
├── index.ts
└── app/
├── data/
├── domain/
├── http/
│ ├── controllers/ #controladores tanto de video como de serie
│ ├── routes/ #las rutas de los endpoints de serie y video
│ └── server.ts
└── services/ #guardar servicios (websocket y procesamiento de video)
└── videos/ # servicios para procesar los videos y generar miniaturas

public/
├── uploads/ # almacenamiento temporal durante la subida inicial
├── videos/:id/ # HLS permanente (index.m3u8, segmentos .ts)
├── thumbnails/ # miniaturas de vídeos
└── thumb_series/ # miniaturas de series
```

## Endpoints
- **Ruta:** /api/videolist/:id/:file  
  **Método HTTP:** GET  
  **Middlewares aplicados:** refreshToken, verifyToken  
  **Controlador asociado:** getWatchVideo  
  **Registro en servidor:** app.use("/api/videolist", videoRoutes)

- **Ruta:** /api/videolist/upload  
  **Método HTTP:** POST  
  **Middlewares aplicados:** verifyAdminToken  
  **Controlador asociado:** postProcessVideoClean  
  **Registro en servidor:** app.use("/api/videolist", videoRoutes)

- **Ruta:** /api/videolist/delete/:id  
  **Método HTTP:** DELETE  
  **Middlewares aplicados:** verifyAdminToken  
  **Controlador asociado:** videoDelete  
  **Registro en servidor:** app.use("/api/videolist", videoRoutes)

- **Ruta:** /api/serielist/upload  
  **Método HTTP:** POST  
  **Controlador asociado:** postThumbVideo  
  **Registro en servidor:** app.use("/api/serielist", serieRouter)

- **Ruta:** /api/serielist/delete/:id  
  **Método HTTP:** DELETE  
  **Middlewares aplicados:** verifyAdminToken  
  **Controlador asociado:** deleteThumbSerie  
  **Registro en servidor:** app.use("/api/serielist", serieRouter)

## Middlewares
Los middlewares de autenticación se implementan en `authTokenSub.ts`  

- **verifyToken:** Verifica JWT y suscripción activa  
- **verifyAdminToken:** Verifica JWT y rol de administrador  
- **refreshToken:** Refresca tokens próximos a expirar usando Odoo

## Controladores

### video.controller.ts

| Función | Método HTTP | Respuestas 
|---------|-------------|------------
| postProcessVideoClean | POST | 202 con metadata; 400/500 en errores |
| getWatchVideo | GET | 404 si no existe; stream con headers adecuados | 
| videoDelete | DELETE | 200 si eliminado; 404 si no existe; 500 en errores |

#### Flujo de subida (`postProcessVideoClean`)
1. Validación de `req.file` 
2. Llamar al servicio `inicialVideoService` para crear directorios y extraer metadatos 
3. Respuesta 202 con `videoId`, `websocketUrl`, `duration`, `resolution` 
4. Llamar al segundo servicio `processVideoService` para la creacion de miniaturas y el procesamiento de los videos

#### Visualización del Video (`getWatchVideo`)
- Ruta a `public/videos/:id/:file`  
- Headers: `Content-Type` según si son el listado de segmentos o los segmentos en sí   
- Usa `fs.createReadStream` + `pipe` para streaming eficiente  

### serie.controller.ts

| Función | Método HTTP | Respuestas |
|---------|-------------|------------|
| postThumbVideo | POST | 200 con idThumb; 400/500 en errores | 
| deleteThumbSerie | DELETE | 200 si eliminada; 404 si no existe; 500 en errores | 

#### Subida de miniatura (`postThumbVideo`)
- Genera `thumbId` con `Date.now()`  
- Guarda en `public/thumb_series/${thumbId}.png` desde `req.file.buffer` 

## Servicios

| Servicio | Archivo | Propósito |
|----------|---------|-----------|
| processVideoService | processVideo.service.ts | Orquesta (metadata → thumbnail → HLS) |  
| createThumbnail | thumbnail.service.ts | Genera miniatura PNG a 1s del vídeo |
| startHlsProcess | ffmpeg.service.ts | Convierte a HLS con segmentos de 10s 
| websocketService | websocket.service.ts | Gestiona conexiones WebSocket y envía progreso 
| getVideoDuration / getVideoResolution / getVideoMetadata | getMetadatosVideo.ts | Extraen metadatos vía ffprobe 

---

### processVideoService
Orquesta y notifica progreso:  

- **metadata (30%)**: Envía duración y resolución obtenidas por `inicialVideoService`  
- **Verificación de FFmpeg**: Aborta si `ffmpeg-static` no está disponible  
- **thumbnail (35-40%)**: Llama a `createThumbnail`; en caso de error solo lo loguea y continúa 
- **processing (45-95%)**: Inicia HLS con `startHlsProcess`  

---

### createThumbnail
- Extrae un frame a 1 segundo y guarda en `public/thumbnails/${videoId}.png`  
- **Comando FFmpeg**: `-ss 00:00:01 -i origenPath -frames:v 1 -q:v 2 thumbPath`  
- Si FFmpeg falla, elimina archivo parcial y rechaza la promesa  
- En éxito, notifica `thumbnail_complete (40%)` 

---

### startHlsProcess
Convierte a HLS con progreso en tiempo real:  

- Parámetros HLS: `-hls_time 10 -hls_playlist_type vod -hls_segment_filename index%d.ts`
- Parsea `out_time_ms` de stdout para calcular progreso: `45 + floor((currentSeconds / duration) * 50)`  
- Throttling: solo envía si el porcentaje cambió (`progressOld != processVideo`)  
- Al finalizar (code 0), limpia temporal y envía `complete (100%)` 
- En error, envía `error (0%)` con código de salida   

---

### websocketService
Gestiona conexiones por `videoId`:  

- Al conectar, envía `connected (0%)`  
- `sendProgress` envía JSON si el socket está `OPEN`   
- Cierra conexión tras `complete/error` con 2s de delay 

---

### getVideo (Metadatos)
- **getVideoDuration**: extrae `format.duration` en segundos - 
- **getVideoResolution**: mapea ancho a etiquetas (K4, K2, P1080, etc.) para Springboot
- **getVideoMetadata**: devuelve JSON completo de ffprobe 

## WebSocket 

El servicio WebSocket proporciona **comunicación en tiempo real** durante el procesamiento de vídeos, enviando actualizaciones de progreso a los clientes conectados por `videoId`.  

### Inicialización y conexión

- En `server.ts`, se crea un `WebSocketServer` y se integra con el servidor HTTP mediante el evento `upgrade`.  

- Al conectar, el cliente debe incluir `videoId` en la URL como un parametro.  

- Se eliminan al cerrar o en caso de error.

---

### Envío de progreso

- `sendProgress(videoId, data)` envía JSON solo si el socket está abierto.  

- **Formato del mensaje:**
```json
{
  "stage": "...",
  "progress": ...,
  "message": "...",
  "duration?": ...,
  "resolution?": ...
}
```
### Etapas principales del procesamiento:

- `connected(0%)`
- `metadata(30%)`
- `thumbnail_complete(40%)`
- `processing(45-95%)`
- `complete(100%)`o `error(0%)`

### Cierre de conexion

`closeConnection(videoId)` cierra el socket y lo elimina, este se invoca tras `complete` o `error`, con un retardo de 2 segundos.