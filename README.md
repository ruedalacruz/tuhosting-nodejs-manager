# Tuhosting Node.js Manager 0.4.0

Administrador multiaplicación Node.js integrado en HestiaCP. Esta versión instala la interfaz y las plantillas de forma global, sin depender de un usuario o dominio de pruebas. **No cambia los dominios existentes durante la instalación.**

## Requisitos

- HestiaCP en la ruta estándar `/usr/local/hestia` (o `HESTIA=/ruta/a/hestia`).
- Nginx, PHP del panel, systemd y sudo.
- `python3`, `php`, `visudo`, `nginx`, `systemctl`, `runuser` y `ss`.
- Node.js 24 y/o 26 instalado globalmente. Se detecta en:
  - `/opt/tuhosting-node/versions/24/bin/node` y `/26/bin/node`
  - `/usr/local/bin/node`
  - `/usr/bin/node`
  - `/opt/nodejs/bin/node`
- El usuario PHP-FPM del panel debe poder identificarse automáticamente como `hestiaweb` o `www-data`. Si tu instalación usa otro, indicarlo con `HESTIA_PHP_FPM_USER`.

El instalador no descarga ni reemplaza Node.js. Si no hay Node.js 24/26, la interfaz se instala igualmente, pero no se podrán crear aplicaciones hasta instalar una versión compatible.

## Instalación

Descomprimir el ZIP y ejecutar como root:

```bash
cd tuhosting-nodejs-manager
./install-tuhosting-nodejs.sh
```

Si Hestia está en una ruta no estándar o usa otro usuario PHP-FPM:

```bash
HESTIA=/ruta/a/hestia HESTIA_PHP_FPM_USER=usuario ./install-tuhosting-nodejs.sh
```

El instalador:
- Detecta y valida Hestia y sus plantillas nativas.
- Crea plantillas propias `tuhosting-nodejs` a partir de las plantillas `nodejs` de esa instalación.
- Instala la interfaz `/nodejs/`, el helper y el inicializador de configuración.
- Agrega una única entrada al menú del panel.
- Crea un backup fechado en `/root/`.
- No modifica las plantillas nativas, certificados, versiones de Node.js ni dominios existentes.

## Activar Node.js en un dominio

La instalación es global, pero cada dominio se activa individualmente:

1. Entrá en Hestia → Web.
2. Editá el dominio que querés administrar.
3. En la plantilla proxy Nginx, seleccioná `tuhosting-nodejs`.
4. Guardá y reconstruí la configuración del dominio desde Hestia.
5. Abrí Web → Node.js → Administrar.

No selecciones la plantilla nativa `nodejs`: el manager necesita la plantilla `tuhosting-nodejs` para incorporar las rutas secundarias.

La primera aplicación del dominio debe usar `/`. Después podés crear `/api/`, `/panel/`, etc.

## Uso

Cada aplicación obtiene:
- ID único (slug).
- Ruta URL.
- Puerto exclusivo automático entre 3100 y 3999.
- Unidad systemd independiente.
- Directorio `/home/USUARIO/web/DOMINIO/private/nodejs/apps/ID/`.
- Variables `PORT` y `HOST=127.0.0.1`.

Al crearla, se generan `server.js` y `package.json` mínimos. Para desplegar el proyecto real, subí los archivos por FTP al directorio indicado, conservando el `package.json` y el archivo de entrada que configuraste. Luego ejecutá NPM desde el panel e iniciá/reiniciá el servicio.

La aplicación debe escuchar en `process.env.PORT` y `process.env.HOST` (o en `127.0.0.1`).

## Diagnóstico

```bash
./diagnose-tuhosting-nodejs.sh
nginx -t
systemctl status tuhosting-node-USUARIO-HASH-ID.service
journalctl -u tuhosting-node-USUARIO-HASH-ID.service -n 100 --no-pager
```

## Desinstalación

```bash
./uninstall-tuhosting-nodejs.sh
```

El desinstalador se niega a retirar las plantillas si detecta dominios que todavía incluyen los archivos de rutas del manager. Primero cambiá esos dominios a otra plantilla proxy desde Hestia y reconstruí Nginx.

La desinstalación retira interfaz, helper, sudoers y plantillas propias. Conserva intencionalmente registros, código de aplicaciones, unidades systemd y Node.js. Los servicios existentes no se detienen automáticamente.

## Alcance y validación

0.4.0 elimina la dependencia del dominio `node-test`, pero todavía debe probarse en una instalación Hestia limpia y en una segunda versión de Hestia antes de declararse estable. El helper utiliza rutas estándar de Hestia y el usuario PHP-FPM obtiene permiso sudo sobre el helper; no exponer el helper fuera del panel.
