#!/bin/bash

set -e # Si da error se sale del script

ruta_principal=$(pwd)

cd ../Justflix_Catalogo
bash ./scripts/gen_key_spring.sh
echo "Certificados para spring generados"

cd $ruta_principal

cd ../Justflix_Suscripciones
bash ./scripts/gen_keys_nginx.sh
echo "Certificados para nginx generados"

cd $ruta_principal