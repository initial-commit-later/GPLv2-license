#!/bin/bash

is_modern_kernel() {
  version_good=$(uname -r | awk 'BEGIN{ FS="."};
      { if ($1 < 5) { print "N"; }
        else if ($1 == 5) {
            if ($2 <= 5) { print "N"; }
            else { print "Y"; }
        }
        else { print "Y"; }
      }')

  if [ "$version_good" = "N" ]; then
    return 1
  fi
}

if ! is_modern_kernel; then
  echo "Legacy kernel - using the compat sources"
  exit 0
fi

if [ -f /var/lib/amnezia/amneziawg/.kernelsourcedir ] && [ "${AWG_KERNEL_SOURCE_PATH}" == "" ]; then
  AWG_KERNEL_SOURCE_PATH="$(cat /var/lib/amnezia/amneziawg/.kernelsourcedir)"
fi

if [ "${AWG_KERNEL_SOURCE_PATH}" != "" ]; then
  mkdir -p /var/lib/amnezia/amneziawg
  echo "${AWG_KERNEL_SOURCE_PATH}" > /var/lib/amnezia/amneziawg/.kernelsourcedir
  pushd "${AWG_KERNEL_SOURCE_PATH}" > /dev/null 2>&1 || exit 1
else
  DISTRO_FLAVOR=$(cat /etc/*-release 2>/dev/null | grep -E ^ID_LIKE=  | sed 's/ID_LIKE=//' | sed 's/"//g')
  DISTRO_FLAVOR=${DISTRO_FLAVOR:-$(cat /etc/*-release 2>/dev/null | grep -E ^ID=  | sed 's/ID=//' | sed 's/"//g')}

  if [ "${AWG_TEMP_DIR}" != "" ]; then
    mkdir -p /var/lib/amnezia/amneziawg
    echo "${AWG_TEMP_DIR}" > /var/lib/amnezia/amneziawg/.tempdir
  elif [ -f /var/lib/amnezia/amneziawg/.tempdir ]; then
    AWG_TEMP_DIR="$(cat /var/lib/amnezia/amneziawg/.tempdir)"
  fi

  PREFIX=${AWG_TEMP_DIR:-/tmp}
  WORKDIR="${PREFIX}/amneziawg"

  [ -d "${WORKDIR}" ] && rm -rf "${WORKDIR}"
  mkdir -p "${WORKDIR}"
  pushd "${WORKDIR}" > /dev/null 2>&1 || exit 1

  echo "Downloading Linux kernel source"

  if [[ "${DISTRO_FLAVOR}" =~ debian ]]; then
    export DEBIAN_FRONTEND=noninteractive
    ac=$(apt-cache search --names-only linux-image "$(uname -r)" unsigned 2>/dev/null|head -n 1)
    [ "${ac}" == "" ] && ac=$(apt-cache search --names-only linux-image "$(uname -r)" 2>/dev/null|head -n 1)
    if [ "${ac}" == "" ]; then
      echo "Could not find suitable image for your Linux distribution!"
      exit 255
    fi

    PACKAGE_NAME="${ac% - *}"
    PACKAGE_VERSION=$(apt-cache madison "${PACKAGE_NAME}"|grep Sources|head -n 1|awk '{ print $3; }')
    echo "Downloading as $(whoami)"
    apt-get -yq -o APT::Sandbox::User="$(whoami)" source "${PACKAGE_NAME}=${PACKAGE_VERSION}"
    cd "$(ls -d */)" || exit 255
  else
    yumdownloader --source kernel
    [ -f "${HOME}/.rpmmacros" ] && mv "${HOME}/.rpmmacros" "${HOME}/.rpmmacros.orig"
    echo "%_topdir $(pwd)" > "${HOME}/.rpmmacros"
    rpm -ivh "$(ls *.rpm)"
    cd SPECS || exit 255
    rpmbuild -bp --target="$(uname -m)" --nodeps kernel.spec
    rm -rf "${HOME}/.rpmmacros"
    [ -f "${HOME}/.rpmmacros.orig" ] && mv "${HOME}/.rpmmacros.orig" "${HOME}/.rpmmacros"
    cd ../BUILD || exit 255
  fi
fi

cd "$(find . -name wireguard -type d | grep 'drivers/net/wireguard' | head -n 1)" || exit 255
WG_SOURCE_PATH=$(pwd)
popd > /dev/null 2>&1 || exit 1

mkdir -p uapi
cp -pfr "${WG_SOURCE_PATH}"/* .
cp "${WG_SOURCE_PATH}/../../../include/uapi/linux/wireguard.h" uapi

for patch in ./patches/*.patch; do
  echo "Applying ${patch}"
  patch -F3 -t -p0 -i "${patch}"
done
