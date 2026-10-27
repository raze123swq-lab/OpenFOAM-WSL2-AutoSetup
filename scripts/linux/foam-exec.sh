#!/usr/bin/env bash
# Isolated process: do not depend on interactive ~/.bashrc.
set -euo pipefail
export ZSH_NAME="${ZSH_NAME:-}"
set +e
set +u
set +o pipefail
. /opt/openfoam14/etc/bashrc
source_status=$?
set -euo pipefail
if [[ "$source_status" != 0 ]]; then
    printf 'OpenFOAM environment source failed: %s\n' "$source_status" >&2
    exit "$source_status"
fi
[[ "${WM_PROJECT_VERSION:-}" == 14 ]]
exec "$@"
