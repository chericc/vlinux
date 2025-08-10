
.PHONY: \
	all \
	kernel \
	download_kernel \
	download_toolchain \
	rootfs_ext4 \
	disk_img \
	test

all:
	@echo "Need an option"

kernel:
	sh build.sh kernel

download_kernel:
	sh build.sh download_kernel

download_toolchain:
	sh build.sh download_toolchain

rootfs_ext4:
	sh build.sh rootfs_ext4

disk_img:
	sh build.sh disk_img

test:
	qemu-system-arm \
		-M vexpress-a9 \
		-m 512M \
		-kernel kernel/build/arch/arm/boot/zImage \
		-dtb kernel/build/arch/arm/boot/dts/arm/vexpress-v2p-ca9.dtb \
		-drive file=vm/disk.img,format=raw,if=sd \
		-serial mon:stdio \
		-monitor none \
		-nographic \
		-append "root=/dev/mmcblk0p1 console=ttyAMA0,115200 init=/linuxrc"