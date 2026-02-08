#!/bin/bash

set -e # Si da error se sale del script

cd .. # Salimos del repositorio Justflix_ENV

# Clonar repositorio Justflix_Catalogo
if [ ! -d "Justflix_Catalogo" ]; then
  git clone https://github.com/AndreuBG/Justflix_Catalogo.git
fi

# Clonar repositorio Justflix_Admin
if [ ! -d "Justflix_Admin" ]; then
  git clone https://github.com/AndreuBG/Justflix_Admin.git
fi

# Clonar repositorio Justflix_Reproductor
if [ ! -d "Justflix_Reproductor" ]; then
  git clone https://github.com/AndreuBG/Justflix_Reproductor.git
fi

# Clonar repositorio Justflix_Suscripciones
if [ ! -d "Justflix_Suscripciones" ]; then
  git clone https://github.com/AndreuBG/Justflix_Suscripciones.git
fi

# Clonar repositorio Justflix_Multimedia
if [ ! -d "Justflix_Multimedia" ]; then
  git clone https://github.com/AndreuBG/Justflix_Multimedia.git
fi

bash ./scripts/generate_jwt_keys.sh # Creamos los certificados para el jwt

bash ./scripts/generate_certs.sh # Creamos los certificados para el https