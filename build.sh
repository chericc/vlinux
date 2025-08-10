
export PATH=$PATH:$(pwd)/toolchain/arm-none-linux-gnueabifh/bin/

option=$1
cross="ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
nproc=$(nproc)

toolchain_dir=toolchain
kernel_dir=kernel
build_dir=build
image_dir=vm
rootfs_dir_path=$image_dir/rootfs

rootfs_ext4_name=rootfs.ext4
rootfs_ext4_filepath=$image_dir/$rootfs_ext4_name
rootfs_ext4_size_mb=500

disk_img_name=disk.img
disk_img_filepath=$image_dir/$disk_img_name
disk_img_size_mb=512

fun_download_toolchain()
{
    mkdir -p $toolchain_dir
    cd $toolchain_dir
    if [ ! -f $toolchain_dir/arm-none-linux-gnueabifh.tar.xz]; then
      wget -O arm-none-linux-gnueabifh.tar.xz https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz
      tar xf arm-none-linux-gnueabifh.tar.xz
    fi 
    cd -
}

fun_download_kernel()
{
    mkdir -p $kernel_dir
    cd $kernel_dir
    if [ ! -f linux-6.12.tar.xz ]; then
      wget -O linux-6.12.tar.xz https://mirrors.tuna.tsinghua.edu.cn/kernel/v6.x/linux-6.12.tar.xz
      tar xf linux-6.12.tar.xz
      mv linux-6.12 linux
    fi
    cd -
}

fun_build_kernel()
{
    echo 'build kernel'
    mkdir -p $kernel_dir/$build_dir
    cd $kernel_dir/$build_dir
    make -C ../linux/ O=$(pwd) $cross vexpress_defconfig
    make -C ../linux/ O=$(pwd) $cross -j$nproc
    cd -
}

fun_build_rootfs_ext4()
{
    echo 'build rootfs.ext4'
    mkdir -p $image_dir
    file_path=$rootfs_ext4_filepath
    filesize=$(stat -c%s $file_path)
    target_size=$(($rootfs_ext4_size_mb*1024*1024))
    if [ ! $target_size -eq $filesize ];then
      dd if=/dev/zero of=$file_path bs=1M count=$rootfs_ext4_size_mb
    fi

    mkfs.ext4 $file_path -qF
    tmp_dir_path=$image_dir/tmp_dir
    mkdir -p $tmp_dir_path
    sudo mount $file_path $tmp_dir_path
    sudo cp $rootfs_dir_path/* $image_dir/tmp_dir/ -rfP
    sudo umount $image_dir/tmp_dir
    rm $image_dir/tmp_dir -r
}

fun_build_disk_img()
{
    echo 'build disk.img'
    file_path=$disk_img_filepath
    filesize=$(stat -c%s $file_path)
    target_size=$(($disk_img_size_mb*1024*1024))
    if [ ! $target_size -eq $filesize ];then
      dd if=/dev/zero of=$file_path bs=1M count=$disk_img_size_mb
    fi

    dd if=$rootfs_ext4_filepath of=$disk_img_filepath bs=1M seek=1 conv=notrunc
}

if [ $# -lt 1 ]; then
  echo 'too few arguments'
  exit 1
fi

if [ $option = 'kernel' ]; then
  fun_build_kernel
elif [ $option = 'download_kernel' ]; then
  fun_download_kernel
elif [ $option = 'download_toolchain' ]; then
  fun_download_toolchain
elif [ $option = 'rootfs_ext4' ]; then
  fun_build_rootfs_ext4
elif [ $option = 'disk_img' ]; then
  fun_build_disk_img
else
  echo 'unknown options'
fi

