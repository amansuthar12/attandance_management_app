#!/bin/bash

  # Exit immediately if a command fails
  set -e

  echo "Downloading Flutter SDK..."
  wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.0-stable.tar.xz
  tar xf flutter_linux_3.13.0-stable.tar.xz
  export PATH="$PATH:$(pwd)/flutter/bin"

  echo "Enabling Flutter web support..."
  flutter config --enable-web

  echo "Fetching dependencies..."
  flutter pub get

  echo "Building Flutter web app..."
  flutter build web
