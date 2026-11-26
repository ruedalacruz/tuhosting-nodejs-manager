# TuHosting Node.js Manager 0.4.2

Administrador multiaplicación Node.js integrado en HestiaCP. Esta versión instala la interfaz y las plantillas de forma global, sin depender de un usuario o dominio de pruebas. **No cambia los dominios existentes durante la instalación.**

## Características

- Integración global con HestiaCP.
- Administración de múltiples aplicaciones Node.js por dominio.
- Plantilla proxy Nginx propia: `tuhosting-nodejs`.
- Servicios independientes mediante systemd.
- Puertos automáticos por aplicación.
- Soporte para Node.js 24 y 26 cuando están instalados.

## Requisitos

- HestiaCP en `/usr/local/hestia` (o configurar `HESTIA=/ruta/a/hestia`).
- Nginx, PHP del panel, systemd y sudo.
- `python3`, `php`, `visudo`, `nginx`, `systemctl`, `runuser` y `ss`.
- Node.js 24 y/o 26 instalado. El manager busca, entre otras, estas rutas:
  - `/opt/tuhosting-node/versions/24/bin/node`
  - `/opt/tuhosting-node/versions/26/bin/node`
  - `/usr/local/bin/node`, `/usr/bin/node` y `/opt/nodejs/bin/node`.

El instalador del manager **no instala ni actualiza Node.js**. Podés instalar las versiones antes o después, siguiendo la [guía de instalación de Node.js](docs/INSTALACION-Y-OPERACION.md#instalar-nodejs-24-y-26). Si Node.js 24/26 no está disponible, la interfaz se instala igualmente, pero no podrás crear aplicaciones con una versión compatible hasta instalarla.

## Instalación rápida de Node.js 24 y 26

Los siguientes comandos son para Ubuntu/Debian en arquitectura x86_64. Las versiones indicadas son las utilizadas en las pruebas documentadas; antes de instalar, comprobá las revisiones vigentes en [Node.js Previous Releases](https://nodejs.org/en/about/previous-releases) y [Node.js dist](https://nodejs.org/dist/).

```bash
apt update
apt install -y ca-certificates curl wget xz-utils tar unzip libatomic1
install -d -o root -g root -m 0755 /opt/tuhosting-node/versions
cd /tmp
```

**Node.js 24.22.3**

```bash
wget https://nodejs.org/dist/v24.22.3/node-v24.22.3-linux-x64.tar.xz
wget https://nodejs.org/dist/v24.22.3/SHASUMS256.txt
grep 'node-v24.22.3-linux-x64.tar.xz' SHASUMS256.txt
sha256sum node-v24.22.3-linux-x64.tar.xz
mkdir -p /opt/tuhosting-node/versions/24.22.3
tar -xJf node-v24.22.3-linux-x64.tar.xz --strip-components=1 -C /opt/tuhosting-node/versions/24.22.3
ln -sfn /opt/tuhosting-node/versions/24.22.3 /opt/tuhosting-node/versions/24
/opt/tuhosting-node/versions/24/bin/node -v
export PATH=/opt/tuhosting-node/versions/24/bin:$PATH
npm -v
```

**Node.js 26.13.1**

```bash
wget https://nodejs.org/dist/v26.13.1/node-v26.13.1-linux-x64.tar.xz
wget https://nodejs.org/dist/v26.13.1/SHASUMS256.txt
grep 'node-v26.13.1-linux-x64.tar.xz' SHASUMS256.txt
sha256sum node-v26.13.1-linux-x64.tar.xz
mkdir -p /opt/tuhosting-node/versions/26.13.1
tar -xJf node-v26.13.1-linux-x64.tar.xz --strip-components=1 -C /opt/tuhosting-node/versions/26.13.1
ln -sfn /opt/tuhosting-node/versions/26.13.1 /opt/tuhosting-node/versions/26
/opt/tuhosting-node/versions/26/bin/node -v
export PATH=/opt/tuhosting-node/versions/26/bin:$PATH
npm -v
```

**Verificación SHA256:** en cada versión, compará la suma que muestra `grep` con la que calcula `sha256sum`. Deben coincidir exactamente. No continúes si no coinciden. Los comandos anteriores son para x86_64; en ARM64 descargá el archivo `linux-arm64` correspondiente. No es obligatorio instalar ambas versiones.

## Instalar TuHosting Node.js Manager

Descargá el ZIP desde [GitHub Releases](https://github.com/ruedalacruz/tuhosting-nodejs-manager/releases), descomprimilo y ejecutá como root:

```bash
unzip tuhosting-nodejs-manager-0.4.2.zip
cd tuhosting-nodejs-manager
chmod +x *.sh
./install-tuhosting-nodejs.sh
```

Si Hestia está en una ruta no estándar o usa otro usuario PHP-FPM:

```bash
HESTIA=/ruta/a/hestia HESTIA_PHP_FPM_USER=usuario ./install-tuhosting-nodejs.sh
```

El instalador detecta Hestia y sus plantillas, instala la interfaz `/nodejs/`, el helper, el inicializador y las plantillas propias, agrega una entrada al menú y crea un backup fechado en `/root/`. No modifica plantillas nativas, certificados, versiones de Node.js ni dominios existentes.

## Activar Node.js en un dominio

1. En Hestia, entrá en **Web** y editá el dominio.
2. En la plantilla proxy Nginx, seleccioná `tuhosting-nodejs`.
3. Guardá y reconstruí la configuración del dominio desde Hestia.
4. Abrí **Web → Node.js → Administrar**.
5. Creá primero la aplicación raíz `/`; luego podés crear rutas secundarias como `/api/` o `/panel/`.

No selecciones la plantilla nativa `nodejs`: el manager necesita `tuhosting-nodejs` para incorporar sus rutas secundarias.

## Documentación

- [Instalación y operación](docs/INSTALACION-Y-OPERACION.md): instalación de Node.js, manager, verificación, activación de dominios, diagnóstico y desinstalación.
- [Arquitectura](docs/ARQUITECTURA.md): componentes y funcionamiento.
- [Historial de cambios](CHANGELOG.md).

## Diagnóstico y desinstalación

```bash
./diagnose-tuhosting-nodejs.sh
nginx -t
```

Para desinstalar, ejecutá `./uninstall-tuhosting-nodejs.sh` como root. El desinstalador conserva intencionalmente los registros, el código de las aplicaciones, las unidades systemd y Node.js. Se niega a retirar las plantillas si detecta dominios que todavía las utilizan.

## Alcance y validación

La versión 0.4.2 actualiza la documentación y el paquete de distribución; no modifica el código del administrador respecto de 0.4.0. La versión 0.4.0 fue probada por el usuario en Ubuntu 24.04.4 LTS con HestiaCP 1.10.10. Antes de declararla estable, se recomienda probar también en una instalación Hestia limpia y en otra versión de Hestia.
