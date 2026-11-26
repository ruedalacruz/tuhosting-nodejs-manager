#!/usr/bin/env python3
"""Create TNM Nginx templates from Hestia's stock default templates."""
import pathlib
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("Uso: build-templates.py /ruta/a/hestia/data/templates/web/nginx")

base = pathlib.Path(sys.argv[1])
marker_routes = 'include %home%/%user%/conf/web/%domain%/nginx.tuhosting-nodejs-routes.conf;'
marker_upstream = 'include %home%/%user%/conf/web/%domain%/nginx.nodejs-upstream.conf;'


def matching_block(text: str, opening: int) -> tuple[int, int]:
    """Return body offsets for a brace-balanced Nginx block."""
    brace = text.find('{', opening)
    if brace < 0:
        raise ValueError('bloque location sin llave de apertura')
    depth = 1
    quote = None
    escaped = False
    for pos in range(brace + 1, len(text)):
        char = text[pos]
        if quote:
            if escaped:
                escaped = False
            elif char == '\\\\':
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in ('"', "'"):
            quote = char
        elif char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                return brace + 1, pos
    raise ValueError('bloque location sin llave de cierre')


def build(ext: str) -> None:
    source = base / f'default.{ext}'
    target = base / f'tuhosting-nodejs.{ext}'
    if not source.is_file():
        raise SystemExit(f'No existe la plantilla base requerida: {source}')
    text = source.read_text()

    loc = re.search(r'(?m)^\s*location\s+/(?:\s*\{)', text)
    if not loc:
        raise SystemExit(f'No se encontró location / en {source}; no se creó la plantilla.')
    body_start, body_end = matching_block(text, loc.start())
    body = text[body_start:body_end]

    # The root app proxy is managed per-domain by TNM, not by Hestia's default backend.
    if marker_upstream not in body:
        proxy = re.search(r'(?m)^([ \t]*)proxy_pass[ \t]+[^;]+;[ \t]*$', body)
        if proxy:
            indent = proxy.group(1)
            body = body[:proxy.start()] + indent + marker_upstream + body[proxy.end():]
        else:
            body = '\n    ' + marker_upstream + '\n' + body
        text = text[:body_start] + body + text[body_end:]

    # Recompute offsets after modifying the root location.
    loc = re.search(r'(?m)^\s*location\s+/(?:\s*\{)', text)
    if marker_routes not in text:
        text = text[:loc.start()] + '    ' + marker_routes + '\n\n' + text[loc.start():]

    target.write_text(text)
    target.chmod(0o644)


for suffix in ('tpl', 'stpl'):
    build(suffix)
print('Plantillas Tuhosting Node.js creadas desde default.tpl/default.stpl.')
