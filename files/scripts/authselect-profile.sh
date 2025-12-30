#!/usr/bin/env -S bash -euo pipefail

UP=/usr/share/authselect/default/local
OUT=/etc/authselect/custom/local

mkdir -p "$OUT"
cp "$UP"/* "$OUT"

gawk -i inplace '!f && /^auth.*pam_fprintd.so\s+ /{print "auth sufficient pam_howdy.so {include if \"with-howdy\"}"; f=1} {print}' "$OUT/system-auth"
