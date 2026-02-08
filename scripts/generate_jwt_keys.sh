#!/bin/bash
set -e

# Target directory relative to this script:
# Justflix_ENV/scripts/ -> Justflix_Suscripciones/extra-addons/odoo_jwt/setup/keys/
TARGET_DIR="../Justflix_Suscripciones/extra-addons/odoo_jwt/setup/keys"

echo "Directorio objetivo para las claves: $TARGET_DIR"

# Crear directorio si no existe
mkdir -p "$TARGET_DIR"

# Generar Clave Privada (2048 bits)
echo "Generando Clave Privada..."
openssl genrsa -out "$TARGET_DIR/private_key.pem" 2048

# Generar Clave Pública a partir de la Clave Privada
echo "Generando Clave Pública..."
openssl rsa -in "$TARGET_DIR/private_key.pem" -pubout -out "$TARGET_DIR/public_key.pem"

# Set permissions (Owner read/write only for private key)
chmod 600 "$TARGET_DIR/private_key.pem"
chmod 644 "$TARGET_DIR/public_key.pem"

echo "Claves generadas correctamente en '$TARGET_DIR'"
ls -l "$TARGET_DIR"

CATALOG_DIR=../Justflix_Catalogo/catalogo/src/main/resources/jwt-key

mkdir -p $CATALOG_DIR
cp $TARGET_DIR/public_key.pem $CATALOG_DIR/public_key.pem
echo "Public key copied to $CATALOG_DIR/public_key.pem"

MEDIA_DIR=../Justflix_Multimedia/jwt-key

mkdir -p $MEDIA_DIR
cp $TARGET_DIR/public_key.pem $MEDIA_DIR/public_key.pem
echo "Public key copied to $MEDIA_DIR/public_key.pem"