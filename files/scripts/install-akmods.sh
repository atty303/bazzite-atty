#!/usr/bin/env bash
set -euo pipefail

kernel=$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
fedora=$(rpm -E '%fedora')
arch=$(rpm -E '%_arch')
# Refuse a changed kernel flavor or multiple kernels rather than replacing them.
if [[ "$kernel" != *-ogc*.fc"$fedora"."$arch" || "$kernel" == *$'\n'* ]]; then
    echo "Unsupported Bazzite kernel: $kernel" >&2
    exit 1
fi

tag="ogc-${fedora}-${kernel%."$arch"}"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
if ! command -v skopeo >/dev/null || ! command -v jq >/dev/null; then
    dnf install -y skopeo jq
fi

for target in common extra; do
    image=akmods
    [[ "$target" == common ]] || image=akmods-extra
    mkdir -p "$workdir/$target/oci" "$workdir/$target/root"
    skopeo copy --retry-times 3 --override-arch "${arch/x86_64/amd64}" \
        "docker://ghcr.io/ublue-os/$image:$tag" "dir:$workdir/$target/oci"
    while IFS= read -r digest; do
        tar -xf "$workdir/$target/oci/${digest#sha256:}" \
            -C "$workdir/$target/root"
    done < <(jq -r '.layers[].digest' "$workdir/$target/oci/manifest.json")
done

common="$workdir/common/root/rpms"
extra="$workdir/extra/root/rpms"
# Keep globs strict: missing kmods or userspace/support RPMs must fail the build.
packages=(
    "$common"/ublue-os/ublue-os-akmods*.rpm
    "$common"/kmods/kmod-openrazer-"$kernel"-*.rpm
    "$common"/common/openrazer-*.noarch.rpm
    "$extra"/kmods/kmod-new-lg4ff-"$kernel"-*.rpm
    "$extra"/extra/new-lg4ff-[0-9]*.noarch.rpm
    "$extra"/extra/new-lg4ff-akmod-modules-*.noarch.rpm
)
for package in "${packages[@]}"; do
    [[ -f "$package" ]] || { echo "Missing required RPM: $package" >&2; exit 1; }
done
for package in "${packages[@]}"; do
    if [[ "${package##*/}" == kmod-* ]]; then
        rpm -qp --requires "$package" | grep -Fx "kernel-uname-r = $kernel"
    fi
done
dnf install -y "${packages[@]}"
depmod -a "$kernel"
