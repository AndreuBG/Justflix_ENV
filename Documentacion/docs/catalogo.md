# Catálogo (Spring boot)

## Propósito y Alcance
Este documento proporciona una visión general completa del microservicio JustFlix Catálogo, su diseño arquitectónico y su rol dentro del ecosistema de la plataforma de streaming JustFlix. El servicio de catálogo es responsable de gestionar el inventario completo de videos y series disponibles en la plataforma, exponiendo APIs RESTful tanto para la navegación pública como para la gestión administrativa de contenidos.

## Rol y Responsabilidades del Servicio
El microservicio JustFlix Catálogo opera como un servicio REST API independiente, protegido por OAuth2, dentro de la plataforma JustFlix. Sirve como fuente autorizada de todos los datos del catálogo, gestionando dos tipos principales de contenido: videos y series. El servicio aplica un modelo de seguridad estricto, donde las operaciones de lectura (navegación de contenido) son accesibles públicamente, mientras que las operaciones de escritura (administración de contenido) requieren autenticación JWT válida con privilegios administrativos.

El servicio expone dos grupos principales de endpoints:

- `/catalogo/videos` - Gestión de la entidad Video  
- `/catalogo/series` - Gestión de la entidad Serie

## Modelo de Dominio Principal

- **Serie**: Representa un contenedor de series con metadatos  
- **Video**: Representa contenido de video individual 
- **Resolucion**: Enumeración que define niveles de calidad de video disponibles (4K, 2K, 1080p, 720p, 480p, 360p, 240p, 144p)

---

## Arquitectura en Capas
La aplicación sigue una arquitectura limpia en capas con separación estricta de responsabilidades:

**Responsabilidades de las Capas**:

| Capa          | Paquete       | Propósito |
|---------------|---------------|-----------|
| Presentación  | controllers   | Manejo de solicitudes HTTP, validación de parámetros, formato de respuesta |
| Servicio      | services      | Implementación de lógica de negocio, validación de datos, conversión DTO-Entidad |
| Transferencia | DTO           | Definiciones de contratos de API, modelos de serialización (vistas simple/completa) |
| Repositorio   | repositories  | Abstracción de acceso a datos, ejecución de queries JPA, soporte de paginación |
| Modelo Dominio| models        | Mapeo de entidades de base de datos, definición de relaciones, anotaciones JPA |


## Arquitectura de Seguridad
El servicio implementa un modelo de seguridad integral utilizando las capacidades de OAuth2 Resource Server de Spring Security:

**Características Clave de Seguridad:**

- **OAuth2 Resource Server**: Valida JWT emitidos por `https://justflix.com` *(Odoo)* 
- **Verificación de Firma RSA**: Usa criptografía de clave pública para verificar la autenticidad de tokens  
- **Control de Acceso Basado en Roles**: Requiere rol de administrador para operaciones de escritura  
- **Seguridad a Nivel de Método**: Anotaciones `@PreAuthorize` en métodos de controladores  
- **Soporte CORS**: Reglas configurables de acceso cross-origin  
- **Aplicación HTTPS**: SSL/TLS mediante keystore `justflix.p12`  

Los endpoints públicos (operaciones GET) permiten acceso sin autenticación para navegación de contenido. Los endpoints protegidos (POST, PUT, DELETE) requieren un JWT válido con el rol de administrador.

Para detalles completos de implementación de seguridad, ver Security.

## Arquitectura de Despliegue
El servicio está contenerizado usando Docker y orquestado con Docker Compose:

**Componentes de Despliegue:**

| Componente    | Contenedor      | Puertos     | Propósito |
|---------------|----------------|------------|-----------|
| Aplicación    | catalogo_app    | 8090       | Microservicio Spring Boot |
| Base de datos | catalogo_bd     | 3306→3308  | Almacén de datos MySQL 8.0 |
| Cache Maven   | maven_cache     | N/A        | Caché de dependencias |
| Datos MySQL   | mysql_data      | N/A        | Persistencia de base de datos |

El `Dockerfile` implementa builds multi-etapa con objetivos separados para desarrollo (hot-reload habilitado) y producción (ejecución optimizada de JAR). El contenedor de la aplicación espera la verificación de salud de la base de datos antes de iniciarse.

Para procedimientos de despliegue y configuración, ver Getting Started y Docker Deployment.

## Resumen del Stack Tecnológico
El servicio se construye sobre las siguientes tecnologías principales:

| Tecnología       | Versión   | Propósito |
|-----------------|-----------|-----------|
| Java             | 21        | Plataforma de ejecución |
| Spring Boot      | 4.0.1     | Framework de aplicación |
| Spring Security  | (incluido)| OAuth2 Resource Server |
| Spring Data JPA  | (incluido)| Capa de persistencia de datos |
| MySQL            | 8.0       | Base de datos relacional |
| Maven            | 3.9       | Herramienta de construcción |
| Docker           | (latest)  | Contenerización |
| Lombok           | (latest)  | Generación de código |

**Dependencias adicionales notables:**

- `spring-boot-starter-oauth2-resource-server` - Validación de JWT  
- `mysql-connector-j` - Driver JDBC para MySQL  
- `spring-boot-devtools` - Hot-reload de desarrollo  

Para información completa de dependencias y versiones, ver Technology Stack.


## Resumen de Endpoints de la API
El servicio expone dos grupos principales de endpoints accesibles en `https://localhost:8090`:

| Patrón de Endpoint                  | Métodos        | Autenticación | Propósito |
|------------------------------------|---------------|---------------|-----------|
| /catalogo/videos                    | GET           | Público       | Listar/buscar videos |
| /catalogo/videos/{id}               | GET           | Público       | Obtener detalles de video |
| /catalogo/videos                    | POST          | Admin         | Crear video |
| /catalogo/videos/{id}               | PUT           | Admin         | Actualizar video |
| /catalogo/videos/{id}               | DELETE        | Admin         | Eliminar video |
| /catalogo/series                     | GET           | Público       | Listar/buscar series |
| /catalogo/series/{id}               | GET           | Público       | Obtener detalles de serie |
| /catalogo/series/{id}/episodios     | GET           | Público       | Listar episodios de serie |
| /catalogo/series                     | POST          | Admin         | Crear serie |
| /catalogo/series/{id}               | PUT           | Admin         | Actualizar serie |
| /catalogo/series/{id}               | DELETE        | Admin         | Eliminar serie |

Todos los endpoints de lista soportan paginación mediante el parámetro `Pageable` de Spring Data y selección de vista (`view=simple` o `view=full`). Las vistas simples devuelven DTOs ligeros optimizados para listados, mientras que las vistas completas devuelven representaciones completas de la entidad.

Para documentación completa de la API con ejemplos de request/response, ver API Reference.

## Patrón de Data Transfer Objects (DTO)
El servicio implementa un patrón dual de DTOs para optimizar la transferencia de datos:

**Estrategia de DTOs:**

- DTOs completos (`VideoDTO`, `SerieDTO`): Representación completa de la entidad para vistas de detalle y mutaciones  
- DTOs simples (`VideoSimpleDTO`, `SerieSimpleDTO`): Campos mínimos para operaciones de lista, reduciendo tamaño de payload y complejidad de queries

Los repositorios implementan queries personalizadas que proyectan directamente en DTOs simples usando arrays `Object[]`, evitando sobrecarga de cargar grafos completos de entidad cuando solo se requiere información básica.