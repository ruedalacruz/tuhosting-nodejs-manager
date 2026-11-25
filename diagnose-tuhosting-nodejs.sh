#!/usr/bin/env bash
set -u
H="${HESTIA:-/usr/local/hestia}"
printf '%-34s' 'HestiaCP'; [[ -x "$H/bin/v-list-web-domains" ]] && echo OK || echo NO
printf '%-34s' 'tnmctl'; [[ -x /usr/local/sbin/tnmctl ]] && echo OK || echo NO
for v in 24 26; do
  printf '%-34s' "Node.js $v"
  if [[ -x /usr/local/sbin/tnmctl ]]; then
    /usr/local/sbin/tnmctl root versions 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((x['version']+' ('+x.get('path','')+')' for x in d.get('versions',[]) if x['alias']=='$v'),'NO'))" 2>/dev/null || echo NO
  else echo NO; fi
done
printf '%-34s' 'sudoers'; visudo -cf /etc/sudoers.d/tuhosting-nodejs 2>/dev/null >/dev/null && echo OK || echo NO
printf '%-34s' 'state directory'; [[ -d /var/lib/tuhosting-nodejs ]] && stat -c '%A %U:%G' /var/lib/tuhosting-nodejs || echo NO
printf '%-34s' 'PHP syntax'; php -l "$H/web/nodejs/index.php" 2>/dev/null | tail -1 || true
printf '%-34s' 'Nginx config'; nginx -t 2>&1 | tail -2 || true
