# Instalación y operación 0.4.2

Esta guía describe la preparación de Node.js 24/26, la instalación del manager en HestiaCP y las tareas básicas de operación. Los comandos de instalación de Node.js están escritos para Ubuntu/Debian x86_64 y deben ejecutarse como `root`.

## 1. Requisitos

- HestiaCP instalado y funcionando.
- Nginx, PHP del panel, systemd y sudo.
- `python3`, `php`, `visudo`, `nginx`, `systemctl`, `runuser` y `ss`.
- Para descargar y preparar los paquetes: `wget` o `curl`, `unzip`, `tar`, `xz-utils` y `ca-certificates`.
- Node.js 24 y/o 26 para ejecutar aplicaciones.

El manager no instala HestiaCP, Nginx, PHP, Python, systemd ni Node.js. Tampoco reemplaza versiones de Node.js ni cambia automáticamente las plantillas de dominios existentes.

## 2. Instalar Node.js 24 y 26

Se recomienda instalar las distribuciones oficiales en directorios versionados y utilizar enlaces simbólicos estables. De esta manera, ambas líneas pueden coexistir:

```text
/opt/tuhosting-node/versions/
├── 24 -> 24.22.3
├── 24.22.3/
├── 26 -> 26.13.1
└── 26.13.1/
```

Las versiones 24.22.3 y 26.13.1 son las utilizadas en las pruebas documentadas. Antes de instalar, consultá [Node.js Previous Releases](https://nodejs.org/en/about/previous-releases) y [Node.js dist](https://nodejs.org/dist/) para comprobar las versiones vigentes. Si instalás una revisión posterior, sustituí el número de versión en los comandos y mantené los enlaces estables `24` y `26`.

### 2.1. Preparar dependencias y directorios

```bash
apt update
apt install -y ca-certificates curl wget xz-utils tar unzip libatomic1
install -d -o root -g root -m 0755 /opt/tuhosting-node/versions
cd /tmp
```

`libatomic1` puede ser necesario para los binarios oficiales en algunas distribuciones. En otra distribución Linux, instalá el paquete equivalente.

### 2.2. Instalar Node.js 24.22.3

Para Linux x86_64:

```bash
cd /tmp
wget https://nodejs.org/dist/v24.22.3/node-v24.22.3-linux-x64.tar.xz
wget https://nodejs.org/dist/v24.22.3/SHASUMS256.txt
grep 'node-v24.22.3-linux-x64.tar.xz' SHASUMS256.txt
sha256sum node-v24.22.3-linux-x64.tar.xz
```

Compará la suma publicada en `SHASUMS256.txt` con la salida de `sha256sum`. Deben coincidir exactamente. No instales el archivo si las sumas no coinciden.

```bash
mkdir -p /opt/tuhosting-node/versions/24.22.3
tar -xJf node-v24.22.3-linux-x64.tar.xz \
  --strip-components=1 \
  -C /opt/tuhosting-node/versions/24.22.3
ln -sfn /opt/tuhosting-node/versions/24.22.3 \
  /opt/tuhosting-node/versions/24
/opt/tuhosting-node/versions/24/bin/node -v
export PATH=/opt/tuhosting-node/versions/24/bin:$PATH
npm -v
```

La primera comprobación debe devolver `v24.22.3`.

### 2.3. Instalar Node.js 26.13.1

Para Linux x86_64:

```bash
cd /tmp
wget https://nodejs.org/dist/v26.13.1/node-v26.13.1-linux-x64.tar.xz
wget https://nodejs.org/dist/v26.13.1/SHASUMS256.txt
grep 'node-v26.13.1-linux-x64.tar.xz' SHASUMS256.txt
sha256sum node-v26.13.1-linux-x64.tar.xz
```

Compará ambas sumas SHA256. Deben coincidir exactamente. No instales el archivo si no coinciden.

```bash
mkdir -p /opt/tuhosting-node/versions/26.13.1
tar -xJf node-v26.13.1-linux-x64.tar.xz \
  --strip-components=1 \
  -C /opt/tuhosting-node/versions/26.13.1
ln -sfn /opt/tuhosting-node/versions/26.13.1 \
  /opt/tuhosting-node/versions/26
/opt/tuhosting-node/versions/26/bin/node -v
export PATH=/opt/tuhosting-node/versions/26/bin:$PATH
npm -v
```

La primera comprobación debe devolver `v26.13.1`.

### 2.4. Arquitectura, permisos y coexistencia

Los comandos anteriores son exclusivamente para Linux x86_64. En servidores ARM64 descargá el archivo oficial `linux-arm64` correspondiente. No instales un binario x64 en un servidor ARM64.

Los binarios deben ser administrados por root y legibles/ejecutables por los usuarios de las aplicaciones:

```bash
chown -R root:root /opt/tuhosting-node/versions
/opt/tuhosting-node/versions/24/bin/node -v
/opt/tuhosting-node/versions/26/bin/node -v
```

No ejecutes `chmod` recursivo sobre todos los archivos: podrías quitar permisos de ejecución a binarios o scripts. La extracción del tarball oficial conserva sus permisos. No es obligatorio instalar ambas líneas; podés instalar solamente la que quieras ofrecer.

## 3. Instalar TuHosting Node.js Manager

Descomprimí el paquete y ejecutá el instalador como root:

```bash
unzip tuhosting-nodejs-manager-0.4.2.zip
cd tuhosting-nodejs-manager
chmod +x *.sh
./install-tuhosting-nodejs.sh
```

Si el usuario PHP-FPM del panel no se detecta automáticamente, indicá el usuario real:

```bash
HESTIA_PHP_FPM_USER=usuario_php ./install-tuhosting-nodejs.sh
```

Reemplazá `usuario_php` por el usuario que ejecuta PHP-FPM del panel; no lo adivines. Para una ruta Hestia no estándar, también podés definir `HESTIA=/ruta/a/hestia`.

El instalador:

- Detecta y valida Hestia y sus plantillas.
- Crea las plantillas propias `tuhosting-nodejs` a partir de las plantillas `nodejs` de esa instalación.
- Instala la interfaz `/nodejs/`, el helper y el inicializador.
- Agrega una única entrada al menú del panel.
- Crea un backup fechado en `/root/`.
- No modifica las plantillas nativas, certificados, versiones de Node.js ni dominios existentes.

## 4. Comprobaciones posteriores

Ejecutá como root:

```bash
php -l /usr/local/hestia/web/nodejs/index.php
php -l /usr/local/hestia/web/templates/pages/nodejs.php
nginx -t
visudo -cf /etc/sudoers.d/tuhosting-nodejs
ls -l /usr/local/sbin/tnmctl
ls -l /usr/local/hestia/data/templates/web/nginx/tuhosting-nodejs.*
```

Comprobá las versiones instaladas:

```bash
/opt/tuhosting-node/versions/24/bin/node -v
/opt/tuhosting-node/versions/26/bin/node -v
```

Si no instalaste una de las dos líneas, su comando correspondiente fallará; eso no significa que el manager no esté instalado.

## 5. Activar Node.js en un dominio

La instalación global no modifica los dominios existentes. Para habilitar un dominio:

1. Ingresá a Hestia como administrador.
2. Editá el dominio que vas a utilizar.
3. Seleccioná la plantilla proxy `tuhosting-nodejs`.
4. Guardá y reconstruí la configuración del dominio desde Hestia.
5. Comprobá Nginx con `nginx -t`.
6. Abrí **Web → Node.js → Administrar**.
7. Creá primero la aplicación raíz `/`; después podés agregar rutas como `/api/` o `/panel/`.

No selecciones la plantilla nativa `nodejs`: el manager necesita `tuhosting-nodejs` para incorporar las rutas secundarias. Probá primero con un dominio de staging. No cambies dominios de producción sin backup y autorización.

## 6. Operación y diagnóstico

Cada aplicación obtiene un ID único, una ruta URL, un puerto exclusivo automático entre 3100 y 3999, una unidad systemd independiente y un directorio bajo:

```text
/home/USUARIO/web/DOMINIO/private/nodejs/apps/ID/
```

Al crearla, se generan `server.js` y `package.json` mínimos. La aplicación debe escuchar en `process.env.PORT` y `process.env.HOST` (o en `127.0.0.1`). Para desplegar el proyecto, subí los archivos al directorio indicado conservando `package.json` y el archivo de entrada configurado; luego ejecutá NPM desde el panel e iniciá o reiniciá el servicio.

Comandos útiles:

```bash
./diagnose-tuhosting-nodejs.sh
nginx -t
systemctl status tuhosting-node-USUARIO-HASH-ID.service
journalctl -u tuhosting-node-USUARIO-HASH-ID.service -n 100 --no-pager
```

## 7. Desinstalación

Ejecutá como root:

```bash
./uninstall-tuhosting-nodejs.sh
```

El desinstalador se niega a retirar las plantillas si detecta dominios que todavía incluyen los archivos de rutas del manager. Primero cambiá esos dominios a otra plantilla proxy desde Hestia y reconstruí Nginx.

La desinstalación retira la interfaz, el helper, sudoers y las plantillas propias. Conserva intencionalmente registros, código de aplicaciones, unidades systemd y Node.js. Los servicios existentes no se detienen automáticamente.

## 8. Alcance y validación

La versión 0.4.2 actualiza la documentación y el paquete de distribución; no modifica el código del administrador respecto de 0.4.0. La versión 0.4.0 fue probada por el usuario en Ubuntu 24.04.4 LTS con HestiaCP 1.10.10. Se recomienda probar también en una instalación Hestia limpia y en otra versión de Hestia antes de declarar el proyecto estable.
