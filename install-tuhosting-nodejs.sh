#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Ejecutar como root.' >&2; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"
H="${HESTIA:-/usr/local/hestia}"
WEB_USER="${HESTIA_PHP_FPM_USER:-}"
STAMP="$(date +%Y%m%d-%H%M%S)"
B="/root/tuhosting-nodejs-backup-$STAMP"

for f in \
  "$H/bin/v-list-web-domains" "$H/bin/v-change-web-domain-proxy-tpl" \
  "$H/bin/v-rebuild-web-domain" "$H/data/templates/web/nginx/nodejs.tpl" \
  "$H/data/templates/web/nginx/nodejs.stpl" "$H/web/inc/main.php" \
  "$H/web/templates/includes/panel.php"; do
  [[ -e "$f" ]] || { echo "No parece una instalación Hestia válida: falta $f" >&2; exit 1; }
done
for c in python3 php visudo nginx systemctl; do
  command -v "$c" >/dev/null || { echo "Falta el comando requerido: $c" >&2; exit 1; }
done

if [[ -z "$WEB_USER" ]]; then
  for candidate in hestiaweb www-data; do
    if id "$candidate" >/dev/null 2>&1; then WEB_USER="$candidate"; break; fi
  done
fi
[[ -n "$WEB_USER" ]] && id "$WEB_USER" >/dev/null 2>&1 || {
  echo 'No se pudo detectar el usuario PHP-FPM del panel. Definí HESTIA_PHP_FPM_USER y reintentá.' >&2
  exit 1
}

mkdir -p "$B"
backup() {
  [[ ! -e "$1" ]] || { mkdir -p "$B$(dirname "$1")"; cp -a "$1" "$B$1"; }
}
for f in \
  "$H/web/nodejs/index.php" "$H/web/templates/pages/nodejs.php" \
  /usr/local/sbin/tnmctl /etc/sudoers.d/tuhosting-nodejs \
  "$H/data/templates/web/nginx/tuhosting-nodejs.tpl" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.stpl" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.sh" \
  "$H/web/templates/includes/panel.php"; do backup "$f"; done

# Build isolated templates from the server's own Hestia Node.js templates.
python3 - "$H/data/templates/web/nginx" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
for ext in ('tpl', 'stpl'):
    src = p / f'nodejs.{ext}'
    content = src.read_text()
    marker = 'include %home%/%user%/conf/web/%domain%/nginx.tuhosting-nodejs-routes.conf;'
    if marker not in content:
        match = re.search(r'(?m)^\s*location\s+/\s*\{', content)
        if not match:
            raise SystemExit(f'No se encontró location / en {src}; no se modificó el template nativo.')
        content = content[:match.start()] + '    ' + marker + '\n\n' + content[match.start():]
    (p / f'tuhosting-nodejs.{ext}').write_text(content)
PY

install -o root -g root -m 0750 "$SRC/templates/nginx/tuhosting-nodejs.sh" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.sh"
install -d -o root -g root -m 0755 "$H/web/nodejs" "$H/web/templates/pages" /var/lib/tuhosting-nodejs
install -o root -g root -m 0750 "$SRC/bin/tnmctl" /usr/local/sbin/tnmctl
install -o root -g root -m 0644 "$SRC/web/nodejs-index.php" "$H/web/nodejs/index.php"
install -o root -g root -m 0644 "$SRC/web/templates/pages/nodejs.php" "$H/web/templates/pages/nodejs.php"

printf '%s ALL=(root) NOPASSWD: /usr/local/sbin/tnmctl *\n' "$WEB_USER" > /etc/sudoers.d/tuhosting-nodejs
chmod 0440 /etc/sudoers.d/tuhosting-nodejs
visudo -cf /etc/sudoers.d/tuhosting-nodejs >/dev/null
php -l "$H/web/nodejs/index.php"
php -l "$H/web/templates/pages/nodejs.php"
python3 -m py_compile /usr/local/sbin/tnmctl
chmod 0700 /var/lib/tuhosting-nodejs

PANEL="$H/web/templates/includes/panel.php"
python3 - "$PANEL" <<'PYMENU'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
marker = '<!-- Tuhosting Node.js Manager -->'
anchor = '<!-- DNS tab -->'
if marker not in s:
    if s.count(anchor) != 1:
        raise SystemExit('No se encontró un ancla única para el menú; revisar versión de Hestia.')
    block = """\t\t\t\t<!-- Tuhosting Node.js Manager -->
\t\t\t\t<?php if (isset($_SESSION["WEB_SYSTEM"]) && !empty($_SESSION["WEB_SYSTEM"]) && $panel[$user]["WEB_DOMAINS"] != "0") { ?>
\t\t\t\t\t<li class="main-menu-item">
\t\t\t\t\t\t<a class="main-menu-item-link <?php if (strpos($_SERVER["REQUEST_URI"], "/nodejs/") === 0) { echo "active"; } ?>" href="/nodejs/" title="Tuhosting Node.js Manager">
\t\t\t\t\t\t\t<p class="main-menu-item-label">Node.js<i class="fab fa-node-js"></i></p>
\t\t\t\t\t\t</a>
\t\t\t\t\t</li>
\t\t\t\t<?php } ?>

"""
    s = s.replace(anchor, block + anchor, 1)
    p.write_text(s)
PYMENU
php -l "$PANEL"

echo 'Instalación global completada.'
echo "Backup: $B"
echo "Hestia: $H"
echo "Usuario PHP-FPM: $WEB_USER"
echo 'No se cambió ningún dominio ni se instalaron/reemplazaron versiones de Node.js.'
echo 'En cada dominio que vaya a usar Node.js, seleccioná la plantilla proxy tuhosting-nodejs desde Hestia.'
echo 'Node.js 24/26 se detecta en /opt/tuhosting-node/versions/<versión>, /usr/local/bin/node o /usr/bin/node.'
