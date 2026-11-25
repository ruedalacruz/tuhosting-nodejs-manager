#!/usr/bin/env bash
set -Eeuo pipefail

# Hestia arguments:
# user domain ip home docroot
USER_NAME="${1:?Falta usuario}"
DOMAIN="${2:?Falta dominio}"
HOME_DIR="${4:?Falta directorio HOME}"

# Validate path components before constructing paths.
[[ "$USER_NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || exit 1
[[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] || exit 1
[[ -d "$HOME_DIR/$USER_NAME" ]] || exit 1
getent group "$USER_NAME" >/dev/null || exit 1

CONF="$HOME_DIR/$USER_NAME/conf/web/$DOMAIN"
if [[ ! -d "$CONF" ]]; then
    install -d -o root -g "$USER_NAME" -m 0750 "$CONF"
fi

create_if_missing() {
    local target="$1"
    local content="$2"
    local tmp

    [[ -e "$target" ]] && return 0

    tmp="$(mktemp "$CONF/.tnm-init.XXXXXX")"
    printf '%b' "$content" > "$tmp"
    chown root:"$USER_NAME" "$tmp"
    chmod 0640 "$tmp"

    # Do not replace a file created concurrently or by the manager.
    if ! mv -n "$tmp" "$target"; then
        rm -f "$tmp"
    fi
    [[ ! -e "$tmp" ]] || rm -f "$tmp"
}

create_if_missing \
    "$CONF/nginx.tuhosting-nodejs-routes.conf" \
    "# Tuhosting Node.js Manager: application routes\n"

create_if_missing \
    "$CONF/nginx.nodejs-upstream.conf" \
    "# Tuhosting Node.js Manager: root application pending\nreturn 503;\n"

exit 0
