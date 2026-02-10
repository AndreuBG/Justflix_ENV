#!/bin/bash
set -e

ruta_principal=$(pwd) # Ruta a la que volver despues de cada comando

cd ../Justflix_Suscripciones # Entramos al repositorio Justflix_Suscripciones
bash ./scripts/gen_keys_jwt.sh # Generamos las claves jwt

cd $ruta_principal # Volvemos a la ruta principal

TARGET_DIR="../Justflix_Suscripciones/extra-addons/odoo_jwt/setup/keys" # Ruta de las claves jwt

CATALOG_DIR="../Justflix_Catalogo/catalogo/src/main/resources/jwt-key" # Ruta de las claves jwt en el catalogo

mkdir -p $CATALOG_DIR # Creamos el directorio si no existe
cp $TARGET_DIR/public_key.pem $CATALOG_DIR/public_key.pem # Copiamos la clave publica al catalogo
echo "Public key copied to $CATALOG_DIR/public_key.pem"

MEDIA_DIR=../Justflix_Multimedia/src/jwt-key # Ruta de las claves jwt en multimedia

mkdir -p $MEDIA_DIR # Creamos el directorio si no existe
cp $TARGET_DIR/public_key.pem $MEDIA_DIR/public_key.pem # Copiamos la clave publica a multimedia
echo "Public key copied to $MEDIA_DIR/public_key.pem"