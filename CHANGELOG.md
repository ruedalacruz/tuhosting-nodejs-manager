# Changelog

## 0.4.1
- README ampliado con instalación rápida de Node.js 24 y 26.
- Documentación detallada de instalación, verificación SHA256, arquitectura x86_64/ARM64, permisos y coexistencia de versiones.
- Se aclara que el instalador del manager no instala ni actualiza Node.js.
- Sin cambios en el código funcional del manager respecto de 0.4.0.

## 0.4.0
- Instalador global: elimina usuario y dominio de staging hardcodeados.
- No cambia automáticamente dominios existentes.
- Detección de Node.js 24/26 en rutas administradas y ubicaciones globales habituales.
- Desinstalador global conservador: se niega a retirar plantillas mientras sigan referenciadas.
- Documentación actualizada para instalación y activación por dominio.
- Helper exige la plantilla `tuhosting-nodejs` para evitar crear servicios sin proxy compatible.

## 0.3.0-RC3
- UI integrada con Hestia, helper privilegiado, plantillas proxy y pruebas de humo.
