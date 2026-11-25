# Arquitectura 0.4.0

- **UI:** `/nodejs/` usa sesión Hestia y `verify_csrf()` para POST.
- **Helper:** `/usr/local/sbin/tnmctl`, Python root-owned; valida usuario Linux, dominio Hestia, slug, versión Node y puerto.
- **Registro:** `/var/lib/tuhosting-nodejs/`, archivos JSON root-only.
- **Aplicaciones:** `/home/USUARIO/web/DOMINIO/private/nodejs/apps/ID/`.
- **Procesos:** una unidad systemd por aplicación, con usuario Hestia, puerto y límites de recursos.
- **Proxy:** `nginx.nodejs-upstream.conf` para raíz y `nginx.tuhosting-nodejs-routes.conf` para locations secundarios.
- **Plantillas:** derivadas de las plantillas nativas `nodejs` del propio servidor; no se modifican los originales.

La instalación es global. Cada dominio debe optar por la plantilla proxy `tuhosting-nodejs` desde Hestia. Nginx es el punto de entrada público; las apps escuchan en loopback.
