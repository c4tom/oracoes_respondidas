#!/bin/bash

# Instalar dependências
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Baixar e instalar Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar instalação do Flutter
flutter doctor