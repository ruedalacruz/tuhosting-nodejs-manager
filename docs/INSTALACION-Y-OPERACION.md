# Instalación y operación 0.4.0

## Instalación global

1. Descomprimir el paquete.
2. Ejecutar `./install-tuhosting-nodejs.sh` como root.
3. Revisar la ruta del backup que informa.
4. Confirmar que el menú Node.js aparece en Hestia.

No se activa ningún dominio automáticamente.

## Activar un dominio

1. En Hestia, editar el dominio.
2. Seleccionar `tuhosting-nodejs` como plantilla proxy Nginx.
3. Guardar y reconstruir el dominio.
4. Abrir Web → Node.js.
5. Crear primero la app raíz `/`; luego las rutas secundarias.

El helper sólo permite administrar dominios cuya plantilla PROXY sea `tuhosting-nodejs`.

## Versiones Node.js

El helper detecta Node.js 24 y 26 en las rutas administradas y ubicaciones globales habituales. El instalador no instala ni actualiza Node.js. Cada aplicación queda asociada a la versión detectada al crearla.

## Diagnóstico y desinstalación

Usar `./diagnose-tuhosting-nodejs.sh` y `nginx -t` para diagnóstico. El desinstalador no elimina datos ni servicios y aborta si encuentra configuraciones Nginx que todavía incluyen los archivos de rutas del manager.
