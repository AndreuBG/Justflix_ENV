# Justflix ENV - Entorno Global

Configuración centralizada de Docker Compose para ejecutar todos los servicios de Justflix en un solo comando.

## Servicios Incluidos

- **catalogo** - Servicio de catálogo (Spring Boot + Java)
- **mysql_db** - Base de datos MySQL para catálogo
- **ts-multimedia** - Servidor de multimedia (Node.js/TypeScript)
- **odoo** - Sistema de suscripciones (Odoo)
- **postgres_db** - Base de datos PostgreSQL para Odoo
- **nginx** - Proxy inverso con SSL

## Requisitos Previos

- Docker
- Docker Compose
- Mkcert
- Flutter


## Instalación Rápida

1. **Instala Mkcert:**
   ```bash
   sudo apt install mkcert
   ```

2. **Clona todos los repositorios necesarios :**

> [!IMPORTANT]  
> Ejecutar el script desde Justflix_ENV

   ```bash
   ./scripts/install.sh
   ```

3. **Inicia casi todos los servicios:**
   ```bash
   docker compose up -d --build
   ```

4. **Inicia servidor multimedia (express):**
   ```bash
   cd ../Justflix_Multimedia
   npm install
   npm run build
   npm start
   ```

5. **Inicia Odoo:**
Accede a `https://localhost` y utiliza la ultima copia de seguridad de Odoo para iniciar sesión.

> [!NOTE]  
> Correo : admin@gmail.com
> Contraseña : admin
> Cambiar info al iniciar sesión

6.1 **Iniciar reproductor (Flutter):**
   ```bash
   cd ../Justflix_Reproductor
   flutter pub get
   flutter run
   ```

6.2 **Iniciar frontend admin (Vue):**
   ```bash
   cd ../Justflix_Admin/admin_app
   npm install
   npm run dev
   ```
7. **Cambiar contraseñas:**

* Cambiar variables en .env
* Cambiar odoo.conf en carpeta config para que coincida con las variables de .env


## URLs de Acceso

- **Catálogo**: http://localhost:8090
- **Multimedia**: http://localhost:8080
- **Odoo**: https://localhost
- **Vue**: http://localhost:5173

## Credenciales por Defecto

Ver archivo `.env` para:
- `MYSQL_ROOT_PASSWORD` - Contraseña root de MySQL
- `MYSQL_USER` - Usuario de MySQL
- `MYSQL_PASSWORD` - Contraseña de MySQL
- `POSTGRES_USER` - Usuario de PostgreSQL
- `POSTGRES_PASSWORD` - Contraseña de PostgreSQL
- `ODOO_USER` - Usuario de Odoo
- `ODOO_PASSWORD` - Contraseña de Odoo

## Comandos Útiles

```bash
# Iniciar servicios
docker compose up -d

# Detener servicios
docker compose down

# Reconstruir e iniciar
docker compose up -d --build

# Eliminar volúmenes (CUIDADO: borra datos)
docker compose down -v

# Reiniciar un servicio
docker compose restart <servicio>

# Detener un servicio específico
docker compose stop <servicio>
```


## Estructura

```
Justflix_ENV/
├── docker-compose.yml      # Configuración principal
├── .env                     # Variables de entorno
├── scripts/                 # Scripts auxiliares
│   ├── generate_certs.sh   # Generar certificados SSL
│   ├── generate_jwt_keys.sh # Generar claves JWT
│   ├── install.sh          # Instalación
└── README.md               # Este archivo
```