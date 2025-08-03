# qemu_env_setup.md

## Cross-compiler

```bash
sudo apt install gcc-mipsel-linux-gnu
sudo apt install u-boot-tools #mkimage
```

## u-boot (mips or arm)

```bash
# Download
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2025.10-rc1.tar.gz

# `
```




## Kernel compile

### Image download

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v6.x/linux-6.12.tar.xz
tar xf linux-6.12.tar.xz
mv linux-6.12 linux
```

### Compile env

```bash
sudo apt install libncurses-dev flex bison libssl-dev libelf-dev -y
MY_CROSS=ARCH="mips CROSS_COMPILE=mipsel-linux-gnu-"
make -C ../linux/ O=$(pwd) $MY_CROSS defconfig
make -C ../linux/ O=$(pwd) $MY_CROSS allnoconfig
make -C ../linux/ O=$(pwd) $MY_CROSS menuconfig 
make -C ../linux/ O=$(pwd) $MY_CROSS distclean # clean .config as well
make -C ../linux/ O=$(pwd) $MY_CROSS bzImage
make -C ../linux/ O=$(pwd) $MY_CROSS mrproper
make -C ../linux/ O=$(pwd) $MY_CROSS -j16
make -C ../linux/ INSTALL_PATH=$(pwd)/output O=$(pwd) $MY_CROSS install

```

## Busybox

### Download

```bash
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar xf busybox-1.36.1.tar.bz2
mv busybox-1.36.1 busybox
```

### Compile

```bash
tar xf 
mkdir build
make -C ../busybox O=$(pwd) defconfig [allyesconfig|defconfig|menuconfig]
make -C ../busybox O=$(pwd) -j4
```

## Image prepare

```bash
dd if=/dev/zero of=disk.img bs=1M count=256
parted disk.img --script mklabel gpt mkpart primary 0% 100%
```

## Qemu setup

```bash
sudo apt update
sudo apt install 
sudo apt install virt-manager

# will have qemu-system-amd64
```

