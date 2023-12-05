# AmneziaWG kernel module

## Table of contents

- [Installation](#installation)
  - [Ubuntu](#ubuntu)
  - [Debian](#debian)
  - [Linux Mint](#linux-mint)
  - [RHEL/CentOS/SUSE/Fedora Core](#rhelcentossusefedora-core)
- [Manual installation](#manual-installation)
  - [With DKMS on any kernel](#with-dkms-on-any-kernel)
  - [Without DKMS on Linux kernel 3.10 - 5.5](#without-dkms-on-linux-kernel-310---55)
  - [Without DKMS on Linux kernel 5.5+](#without-dkms-on-linux-kernel-55)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Installation

### Ubuntu

Open `Terminal` and proceed with following instructions:

1. (Optionally) Upgrade your system to latest packages including latest available kernel by running `apt-get full-upgrade`.
After kernel upgrade reboot is required.
2. Ensure that you have source repositories configured for APT - run `vi /etc/apt/sources.list` and make sure that there is
at least one line starting with `deb-src` is present and uncommented.
3. Install pre-requisites - run `sudo apt install -y software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r)`.
4. Run `sudo add-apt-repository ppa:amnezia/ppa`.
5. Finally execute `sudo apt-get install -y amneziawg`.

### Debian

Open `Terminal` and do next steps:

1. (Optionally) Upgrade your system to latest packages including latest available kernel by running `apt-get full-upgrade`.
   After kernel upgrade reboot is required.
2. Ensure that you have source repositories configured for APT - run `vi /etc/apt/sources.list` and make sure that there is
   at least one line starting with `deb-src` is present and uncommented.
3. Execute following commands:
```shell
sudo apt install -y software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r)
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 57290828
echo "deb https://ppa.launchpadcontent.net/amnezia/ppa/ubuntu focal main" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://ppa.launchpadcontent.net/amnezia/ppa/ubuntu focal main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y amneziawg
```

### Linux Mint

Open `Software Sources` and make sure that `Source code repositories` (under `Optional Sources`) are enabled.

Proceed to `PPAs` section and add `ppa:amnezia/ppa` PPA repository, after that save configuration and rebuild `apt` cache.

After that, open `Terminal` and run:

```shell
sudo apt-get install -y amneziawg
```

### RHEL/CentOS/SUSE/Fedora Core

Open `Terminal` and run:

```shell
sudo dnf copr enable amneziavpn/amneziawg
sudo dnf install amneziawg-dkms amneziawg-tools
```

Before installation it is strictly recommended to upgrade your system kernel to the latest available version and perform
the reboot afterwards.

## Manual installation

You may need to install kernel headers and/or build essentials packages before running following steps.

### With DKMS on any kernel

Grab sources of your system's kernel by yourselves and set to `AWG_KERNEL_SOURCE_PATH` environment variable path to it. Then execute:

```shell
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
cd amneziawg-linux-kernel-module/src
sudo make dkms-install
sudo dkms add -m amneziawg -v 1.0.0
sudo dkms build -m amneziawg -v 1.0.0
sudo dkms install -m amneziawg -v 1.0.0
```

### Without DKMS on Linux kernel 3.10 - 5.5

In Terminal:

```shell
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
cd amneziawg-linux-kernel-module/src
make
sudo make install
```

### Without DKMS on Linux kernel 5.5+

Grab sources of your system's kernel by yourselves and apply all patches from 
[this tree](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module/tree/amnezia/src/patches)
to WireGuard's sources in it (sources are located in `drivers/net/wireguard` subtree):

```shell
patch -F3 -t -p0 -i <patch>
```

Afterwards applying patches make and install resulting tree as usual:

```shell
make
sudo make install
```

## Troubleshooting

### Low space on `/tmp` filesystem

Most installation instructions above assumes that you have enough space in system's `/tmp` partition (as setup script needs 
to manipulate with kernel's sourcetree with is pretty huge).

If you can not afford enough space in your `/tmp`, you may override temporary dir by setting `AWG_TEMP_DIR` environment variable
before the installation:

```shell
export AWG_TEMP_DIR="/home/ubuntu/tmp"
```

This setting should persist for future and will not require repeating.

### Kernel sourcetree could not be found automatically

In some rare cases, setup script may not find your kernel's sourcetree automatically. You may find appropriate sources by yourself
then and point setup script to them by setting `AWG_KERNEL_SOURCE_PATH` environment variable before the installation:

```shell
export AWG_KERNEL_SOURCE_PATH="/path/to/your/kernel/sources"
```

This setting should persist for future and will not require repeating.

## License

This project is released under the [GPLv2](COPYING).
