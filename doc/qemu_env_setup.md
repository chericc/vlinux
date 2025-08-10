# qemu_env_setup.md

## preinstalls

```bash
#sudo apt install gcc-mipsel-linux-gnu
sudo apt install gcc-arm-linux-gnueabi
sudo apt install u-boot-tools #mkimage
sudo apt install libgnutls28-dev # for u-boot
sudo apt install qemu-system-arm

https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz
mv arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf arm-none-linux-gnueabifh
PATH=$PATH:$(pwd)/toolchain/arm-none-linux-gnueabifh/bin/
arm-none-linux-gnueabihf-
```

## u-boot (mips or arm)

```bash
# Download
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2025.10-rc1.tar.gz

# Compile
MY_CROSS="ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
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

## kernel compile

### image download

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v6.x/linux-6.12.tar.xz
tar xf linux-6.12.tar.xz
mv linux-6.12 linux
```

### compile env

```bash
sudo apt install libncurses-dev flex bison libssl-dev libelf-dev -y
MY_CROSS="ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
make -C ../linux/ O=$(pwd) $MY_CROSS defconfig
make -C ../linux/ O=$(pwd) $MY_CROSS allnoconfig
make -C ../linux/ O=$(pwd) $MY_CROSS vexpress_defconfig # use this
make -C ../linux/ O=$(pwd) $MY_CROSS menuconfig 
make -C ../linux/ O=$(pwd) $MY_CROSS distclean # clean .config as well
make -C ../linux/ O=$(pwd) $MY_CROSS bzImage
make -C ../linux/ O=$(pwd) $MY_CROSS mrproper
make -C ../linux/ O=$(pwd) $MY_CROSS uImage LOADADDR=0x60008000
make -C ../linux/ O=$(pwd) $MY_CROSS -j16
make -C ../linux/ INSTALL_PATH=$(pwd)/output O=$(pwd) $MY_CROSS install

```

## busybox

### download

```bash
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar xf busybox-1.36.1.tar.bz2
mv busybox-1.36.1 busybox
```

### compile

```bash
tar xf 
mkdir build
export ARCH=arm
export CROSS_COMPILE=arm-none-linux-gnueabihf-
comment out CONFIG_TC=y # kernel >= 6.8 
make KBUILD_SRC=../busybox -f ../busybox/Makefile defconfig
make KBUILD_SRC=../busybox -f ../busybox/Makefile menuconfig
make KBUILD_SRC=../busybox -f ../busybox/Makefile CONFIG_PREFIX=./output install -j8

cp busybox/build/output/* vm/rootfs/ -rfP
```

### make rootfs.ext4

```bash
mkdir -p vm/rootfs/{bin,sbin,etc,proc,sys,dev,tmp,home,mnt,usr,var,lib}

cp toolchain/arm-none-linux-gnueabifh/arm-none-linux-gnueabihf/lib/* vm/rootfs/lib/ -rfP


# libs

cp toolchain/arm-none-linux-gnueabifh/arm-none-linux-gnueabihf/libc/lib/* vm/rootfs/lib/ -rfP

dd if=/dev/zero of=vm/rootfs.ext4 bs=1M count=500
mkfs.ext4 vm/rootfs.ext4
mkdir -p vm/rootfs_mount
sudo mount vm/rootfs.ext4 vm/rootfs_mount
sudo cp vm/rootfs/* vm/rootfs_mount -rfP
sudo umount vm/rootfs_mount
rm vm/rootfs_mount -r

```

## disk.img prepare

```bash
dd if=/dev/zero of=vm/disk.img bs=1M count=512

# parted vm/disk.img --script \
#     mklabel gpt \
#     mkpart primary fat32 1MiB 129MiB \
#     mkpart primary ext4 129MiB 100% \
#     print

parted vm/disk.img --script \
    mklabel gpt \
    mkpart primary 1MiB 100% \
    print

# dd if=kernel/build/arch/arm/boot/uImage of=vm/disk.img bs=1M seek=1 conv=notrunc

dd if=vm/rootfs.ext4 of=vm/disk.img bs=1M seek=1 conv=notrunc

# the verify
hexdump -C -n 64 -s 1048570 vm/disk.img

# 
# 12M --> 24576 sectors/512B
# mmc read 0x60008000 0x800 3000
# bootm 0x60008000
# bootz 0x60008000

```

## qemu setup

```bash

# qemu-system-arm \
#     -M vexpress-a9 \
#     -m 256M \
#     -kernel uboot/build/u-boot \
#     -drive file=vm/disk.img,format=raw,if=sd \
#     -dtb kernel/build/arch/arm/boot/dts/arm/vexpress-v2p-ca9.dtb \
#     -serial stdio \
#     -monitor none \
#     -nographic


qemu-system-arm \
    -M vexpress-a9 \
    -m 512M \
    -kernel kernel/build/arch/arm/boot/zImage \
    -dtb kernel/build/arch/arm/boot/dts/arm/vexpress-v2p-ca9.dtb \
    -drive file=vm/disk.img,format=raw,if=sd \
    -serial stdio \
    -monitor none \
    -nographic \
    -append "root=/dev/mmcblk0p1 console=ttyAMA0,115200 init=/linuxrc"


# Ctrl-a x to force exit qemu

```

