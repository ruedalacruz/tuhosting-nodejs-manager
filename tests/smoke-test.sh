#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 -m py_compile "$ROOT/bin/tnmctl"
php -l "$ROOT/web/nodejs-index.php"
php -l "$ROOT/web/templates/pages/nodejs.php"
bash -n "$ROOT/install-tuhosting-nodejs.sh" "$ROOT/uninstall-tuhosting-nodejs.sh" "$ROOT/diagnose-tuhosting-nodejs.sh"
python3 "$ROOT/bin/tnmctl" --help >/dev/null
echo 'Smoke tests OK (sintaxis y parser; no se ejecutaron acciones de sistema).'


if [[ $EUID -eq 0 ]]; then
  # Test Hestia Node.js template initializer in an isolated temporary directory.
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  TEST_USER="$(id -un)"
  TEST_DOMAIN="hook-test.example"
  mkdir -p "$TMP/$TEST_USER"

  "$ROOT/templates/nginx/tuhosting-nodejs.sh" \
    "$TEST_USER" "$TEST_DOMAIN" 127.0.0.1 "$TMP" "$TMP/public_html"

  CONF="$TMP/$TEST_USER/conf/web/$TEST_DOMAIN"
  test -f "$CONF/nginx.tuhosting-nodejs-routes.conf"
  test -f "$CONF/nginx.nodejs-upstream.conf"
  grep -q 'return 503;' "$CONF/nginx.nodejs-upstream.conf"

  printf '# preserve-me\n' > "$CONF/nginx.tuhosting-nodejs-routes.conf"
  "$ROOT/templates/nginx/tuhosting-nodejs.sh" \
    "$TEST_USER" "$TEST_DOMAIN" 127.0.0.1 "$TMP" "$TMP/public_html"
  grep -q 'preserve-me' "$CONF/nginx.tuhosting-nodejs-routes.conf"

  test "$(stat -c '%a' "$CONF/nginx.nodejs-upstream.conf")" = "640"
  test "$(stat -c '%a' "$CONF")" = "750"

  rm -rf "$TMP"
  trap - EXIT
  echo 'Initializer tests OK.'

else
  echo 'Initializer test skipped (requires root for ownership checks).'
fi

# Test proxy_files in an isolated temporary directory.
python3 - "$ROOT/bin/tnmctl" <<'PY'
import runpy
import sys
import tempfile
from pathlib import Path

namespace = runpy.run_path(sys.argv[1], run_name="tnmctl_test")
proxy_files = namespace["proxy_files"]

with tempfile.TemporaryDirectory() as tmp:
    conf = Path(tmp)

    # Root application.
    proxy_files(conf, [{"route": "/", "port": 3100}])
    upstream = (conf / "nginx.nodejs-upstream.conf").read_text()
    assert upstream == "proxy_pass http://127.0.0.1:3100;\n"

    # No root application: must return 503.
    proxy_files(conf, [])
    upstream = (conf / "nginx.nodejs-upstream.conf").read_text()
    assert "return 503;" in upstream

    # Secondary application.
    proxy_files(conf, [{"route": "/api/", "port": 3101}])
    routes = (conf / "nginx.tuhosting-nodejs-routes.conf").read_text()
    assert "location ^~ /api/" in routes
    assert "proxy_pass http://127.0.0.1:3101/;" in routes

print("Proxy tests OK (root, no-root and secondary routes).")
PY

# Test installer template builder against a clean Hestia layout (default only).
TMP_TEMPLATES="$(mktemp -d)"
trap 'rm -rf "$TMP_TEMPLATES"' EXIT
mkdir -p "$TMP_TEMPLATES/nginx"
cat > "$TMP_TEMPLATES/nginx/default.tpl" <<'TPL'
server {
    listen %ip%:%proxy_port%;
    location / {
        proxy_pass http://%ip%:%web_port%;
        proxy_set_header Host $host;
    }
}
TPL
cat > "$TMP_TEMPLATES/nginx/default.stpl" <<'STPL'
server {
    listen %ip%:%proxy_ssl_port% ssl;
    location / {
        proxy_pass http://%ip%:%web_ssl_port%;
        proxy_set_header Host $host;
    }
}
STPL
python3 "$ROOT/templates/nginx/build-templates.py" "$TMP_TEMPLATES/nginx"
for ext in tpl stpl; do
  test -f "$TMP_TEMPLATES/nginx/tuhosting-nodejs.$ext"
  grep -q 'nginx.tuhosting-nodejs-routes.conf' "$TMP_TEMPLATES/nginx/tuhosting-nodejs.$ext"
  grep -q 'nginx.nodejs-upstream.conf' "$TMP_TEMPLATES/nginx/tuhosting-nodejs.$ext"
done
! grep -q 'nodejs\.tpl' "$ROOT/install-tuhosting-nodejs.sh"
rm -rf "$TMP_TEMPLATES"
trap - EXIT
echo 'Clean Hestia template-builder tests OK.'
