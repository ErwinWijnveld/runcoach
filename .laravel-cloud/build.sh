#!/usr/bin/env bash
# Laravel Cloud build script for the runcoach monorepo.
#
# Laravel Cloud only supports Laravel/Symfony apps at the repo root, so this
# script promotes the api/ subdirectory to the deployment root before running
# the usual Laravel build steps.
#
# Usage (Laravel Cloud > Environment > Build command):
#   bash .laravel-cloud/build.sh

set -euo pipefail

echo "==> Promoting api/ to deployment root"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Move every top-level app directory out of the way.
for dir in api app docs; do
  if [ -e "$dir" ]; then
    mv "$dir" "$TMP_DIR/"
  fi
done

# Copy the Laravel app contents (including dotfiles) to the repo root.
cp -Rf "$TMP_DIR/api/." .

echo "==> Installing PHP dependencies"
composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction

echo "==> Building frontend assets"
npm ci
npm run build

echo "==> Build script completed"
