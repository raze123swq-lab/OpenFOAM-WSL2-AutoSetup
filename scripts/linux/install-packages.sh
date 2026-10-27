#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$here/check-ubuntu.sh"
[[ $# == 1 ]] || { echo 'Usage: install-packages.sh LOG_DIRECTORY' >&2; exit 2; }
mkdir -p -- "$1"
log="$1/packages-$(date +%Y%m%d-%H%M%S)-$$.log"
# Password is entered by the operator through the terminal, never logged.
sudo -v
exec > >(tee -a "$log") 2>&1
if [[ "$(dpkg-query -W -f='${Status}' openfoam14 2>/dev/null || true)" != 'install ok installed' ]]; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates wget gnupg
    # Existing repository configuration belongs to the user. Reuse it, do not delete it.
    if ! grep -Rqs 'dl.openfoam.org' /etc/apt/sources.list /etc/apt/sources.list.d; then
        key=/etc/apt/keyrings/openfoam-autosetup.asc
        list=/etc/apt/sources.list.d/openfoam-autosetup.list
        if [[ -e "$key" || -e "$list" ]]; then
            echo 'Partial repository setup exists; inspect it manually before retrying.' >&2; exit 1
        fi
        tmp="$(mktemp -d)"
        trap 'rm -rf -- "$tmp"' EXIT
        wget --https-only -O "$tmp/key.asc" https://dl.openfoam.org/gpg.key
        gpg --show-keys "$tmp/key.asc"
        sudo install -d -m 755 /etc/apt/keyrings
        sudo install -m 644 "$tmp/key.asc" "$key"
        printf 'deb [arch=amd64 signed-by=%s] http://dl.openfoam.org/ubuntu jammy main\n' "$key" | sudo tee "$list"
    fi
    sudo apt-get update
    sudo apt-get install -y openfoam14
fi
missing=()
command -v paraview >/dev/null || missing+=(paraview)
command -v pvpython >/dev/null || missing+=(python3-paraview)
command -v python3 >/dev/null || missing+=(python3)
if (( ${#missing[@]} )); then sudo apt-get update; sudo apt-get install -y "${missing[@]}"; fi
echo 'Package phase finished; environment acceptance runs separately.'
