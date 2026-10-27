#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$here/check-ubuntu.sh"
[[ "$(dpkg-query -W -f='${Status}' openfoam14)" == 'install ok installed' ]]
bash -n /opt/openfoam14/etc/bashrc
for app in blockMesh checkMesh foamRun; do
    bash "$here/foam-exec.sh" "$app" -help >/dev/null
    printf 'PASS %s -help\n' "$app"
done
[[ -d /opt/openfoam14/tutorials/incompressibleFluid/pitzDailySteady ]]
command -v python3
command -v paraview
command -v pvpython
printf 'PASS OpenFOAM 14 non-interactive environment\n'
