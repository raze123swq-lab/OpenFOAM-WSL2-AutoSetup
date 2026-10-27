#!/usr/bin/env bash
set -euo pipefail
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]]
[[ "$(uname -m)" == x86_64 ]]
printf 'PASS Ubuntu 22.04 x86_64\n'
