#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Ejecutar como root.' >&2; exit 1; }
H="${HESTIA:-/usr/local/hestia}"
PANEL="$H/web/templates/includes/panel.php"
[[ -x "$H/bin/v-list-web-domains" ]] || { echo "No se encontró Hestia en $H" >&2; exit 1; }

# Do not remove templates while any active domain configuration still includes them.
if grep -RIl --include='*.conf' 'nginx.tuhosting-nodejs-routes.conf' /home/*/conf/web 2>/dev/null | grep -q .; then
  echo 'Hay dominios que todavía incluyen la configuración Tuhosting Node.js.' >&2
  echo 'Cambiá primero esos dominios a otra plantilla proxy desde Hestia y reconstruí Nginx.' >&2
  echo 'No se modificó nada.' >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
B="/root/tuhosting-nodejs-uninstall-$STAMP"
mkdir -p "$B"
backup_remove() {
  local f="$1"
  if [[ -e "$f" ]]; then
    mkdir -p "$B$(dirname "$f")"
    cp -a "$f" "$B$f"
    rm -f "$f"
  fi
}
if [[ -f "$PANEL" ]]; then
  cp -a "$PANEL" "$B$PANEL"
  python3 - "$PANEL" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
start_marker = '<!-- Tuhosting Node.js Manager -->'
end_marker = '<!-- DNS tab -->'
if start_marker in s:
    start = s.index(start_marker)
    end = s.find(end_marker, start)
    if end < 0:
        raise SystemExit('No se encontró el final del bloque del menú; se aborta.')
    s = s[:start] + s[end:]
    p.write_text(s)
PY
  php -l "$PANEL"
fi
for f in \
  /usr/local/sbin/tnmctl /etc/sudoers.d/tuhosting-nodejs \
  "$H/web/nodejs/index.php" "$H/web/templates/pages/nodejs.php" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.tpl" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.stpl" \
  "$H/data/templates/web/nginx/tuhosting-nodejs.sh"; do
  backup_remove "$f"
done
visudo -c >/dev/null
echo 'Interfaz y archivos del administrador retirados.'
echo "Backup: $B"
echo 'Se conservaron registros, proyectos, unidades systemd y versiones Node.js.'
