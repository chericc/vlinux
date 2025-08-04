# qemu_env_setup.md

## Preinstalls

```bash
#sudo apt install gcc-mipsel-linux-gnu
sudo apt install gcc-arm-linux-gnueabi
sudo apt install u-boot-tools #mkimage
sudo apt install libgnutls28-dev # for u-boot
sudo apt install qemu-system-arm
```

## u-boot (mips or arm)

```bash
# Download
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2025.10-rc1.tar.gz

# Compile
MY_CROSS="ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
make -C ../u-boot O=$(pwd) $MY_CROSS vexpress_ca9x4_defconfig
make -C ../u-boot O=$(pwd) $MY_CROSS

# boot with qemu 
qemu-system-arm \
    -M vexpress-a9 \
    -m 256M \
    -kernel u-boot \
    -nographic
# Ctrl-a x to force exit qemu
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
MY_CROSS=ARCH="arm CROSS_COMPILE=arm-linux-gnueabi-"
make -C ../linux/ O=$(pwd) $MY_CROSS defconfig
make -C ../linux/ O=$(pwd) $MY_CROSS allnoconfig
make -C ../linux/ O=$(pwd) $MY_CROSS menuconfig 
make -C ../linux/ O=$(pwd) $MY_CROSS distclean # clean .config as well
make -C ../linux/ O=$(pwd) $MY_CROSS bzImage
make -C ../linux/ O=$(pwd) $MY_CROSS mrproper
make -C ../linux/ O=$(pwd) $MY_CROSS uImage LOADADDR=0x60008000
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
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
comment out CONFIG_TC=y # kernel >= 6.8 
make KBUILD_SRC=../busybox -f ../busybox/Makefile defconfig
make KBUILD_SRC=../busybox -f ../busybox/Makefile CONFIG_PREFIX=./output install -j8
```

## Image prepare

```bash
dd if=/dev/zero of=vm/disk.img bs=1M count=256
parted vm/disk.img --script \
    mklabel gpt \
    mkpart primary fat32 1MiB 129MiB \
    mkpart primary ext4 129MiB 100% \
    print

dd if=kernel/build/arch/arm/boot/uImage of=vm/disk.img bs=1M seek=1 conv=notrunc

# the verify
hexdump -C -n 64 -s 1048570 vm/disk.img

12M 
--> 24576 sectors/512B
mmc read 0x60008000 0x800 6000
bootm 0x60008000

mmc read 0x60100000 0x800 6000
bootm 0x60100000
```

## Qemu setup

```bash
qemu-system-arm \
    -M vexpress-a9 \
    -m 256M \
    -kernel uboot/build/u-boot \
    -drive file=vm/disk.img,format=raw,if=sd \
    -serial stdio \
    -monitor none \
    -nographic



# Ctrl-a x to force exit qemu

```

