# Laravel Cloud (monorepo workaround)

Laravel Cloud only supports Laravel/Symfony apps at the repo root. Our Laravel
API lives in `api/` alongside the Flutter app in `app/`, so we use the
unofficial monorepo workaround confirmed by Laravel Cloud support:

1. A copy of `api/composer.lock` sits at the repo root so framework detection
   recognises the repo as a Laravel app.
2. `build.sh` promotes the `api/` subdirectory to the deployment root before
   running `composer install` and the Vite build.

## Laravel Cloud environment settings

- **Repository**: this repo, root directory `/`
- **Build command**: `bash .laravel-cloud/build.sh`
- **Deploy command** (typical Laravel): `php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan event:cache`
- **Environment variables**: set the same keys as `api/.env` (see
  `CLAUDE.md` → "Required env vars").

## When `composer.lock` changes

If `api/composer.lock` changes, re-copy it to the repo root so framework
detection stays in sync:

```bash
cp api/composer.lock composer.lock
```

Commit both files together. There is no `composer.json` at the repo root — do
not add one; the build script moves `api/composer.json` into place.

## Why not submodule / split repo?

We considered splitting `api/` into its own repo, but the monorepo keeps
backend + mobile changes atomic in PRs. The workaround above is cheaper than
repo surgery. Revisit if Laravel Cloud ships official monorepo support.
