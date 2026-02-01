#!/bin/bash

# Please clone this two repo before
# need clang-r353983c for Android Q release and aarch64_aarch64-linux-android-4.9 prebuilts
#
# git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 /media/iceows/Sauvegardes/iceows/Compiler/Google/GCC64
# git clone https://github.com/Iceows/android_prebuilts_clang_host_linux-x86_clang-r353983c /media/iceows/Sauvegardes/iceows/Compiler/Google/Clang/clang-r353983c
#


# Special Clean For Huawei Kernel.
if [ -d include/config ];
then
    echo "Find config,will remove it"
	rm -rf include/config
else
	echo "No Config,good."
fi

export HOME_COMPILER=/media/iceows/Sauvegardes/iceows/Compiler/Google

# Declare path export
export PATH=$PATH:$HOME_COMPILER/GCC64/bin:$HOME_COMPILER/Clang/clang-r353983c/bin

# Declare CLANG et LD_LIBRARY
export CLANG_PREBUILTS_PATH=$HOME_COMPILER/Clang/clang-r353983c/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CLANG_PREBUILTS_PATH/lib64/

export CROSS_COMPILE=aarch64-linux-android-
export GCC_COLORS=auto
export ARCH=arm64

rm -rf cp out/arch/arm64/boot/Image.gz

echo "***Building kernel...***"

start_time=$(date +%Y.%m.%d-%I_%M)
start_time_sum=$(date +%s)

make ARCH=arm64 O=out CC="ccache clang" merge_kirin970_defconfig
make ARCH=arm64 O=out CC="ccache clang" -j$(nproc --all)

end_time_sum=$(date +%s)
end_time=$(date +%Y.%m.%d-%I_%M)

# Durée
duration=$((end_time_sum - start_time_sum))
hours=$((duration / 3600))
minutes=$(( (duration % 3600) / 60 ))
seconds=$((duration % 60))

echo "Compilation time：${hours}:${minutes}:${seconds}"

if [ -f out/arch/arm64/boot/Image.gz ];
then
	echo "***Packing kernel...***"

	cp out/arch/arm64/boot/Image.gz Image.gz 
		
	# Pack Enforcing Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x00078000 --cmdline "loglevel=4 page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=permissif buildvariant=user" --tags_offset 0x37d88000 --kernel_offset 0x00008000 --second_offset 0x00e88000 --ramdisk_offset 0x37588000 --header_version 1 --os_version 10.0.0 --os_patch_level 2020-11 --output Kirin970_HOS2_PM-${end_time}.img
	
	# Pack Permissive Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x00078000 --cmdline "loglevel=4 page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=enforcing buildvariant=user" --tags_offset 0x37d88000 --kernel_offset 0x00008000 --second_offset 0x00e88000 --ramdisk_offset 0x37588000 --header_version 1 --os_version 10.0.0 --os_patch_level 2020-11 --output Kirin970_HOS2-${end_time}.img
# Now 


	echo "***Sucessfully built kernel...***"
	echo " "
	exit 0
else
	echo " "
	echo "***Failed!***"
	exit 0
fi
