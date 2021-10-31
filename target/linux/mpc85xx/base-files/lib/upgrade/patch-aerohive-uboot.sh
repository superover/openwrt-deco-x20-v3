#!/bin/sh
# Copyright (C) 2014 OpenWrt.org
#

. /lib/functions.sh

aerohive_patch_uboot() {
	tmpd=/tmp/uboot_patch;
	mkdir -p ${tmpd}

	# Back up
	dd if=/dev/mtd1 of=${tmpd}/mtd1;
	echo /dev/mtd1 backed up to ${tmpd}/mtd1. >&2

	# Patch
	cp ${tmpd}/mtd1 ${tmpd}/mtd1_patched;
	strings -td < ${tmpd}/mtd1 | grep setenv | grep 'setenv bootargs.*nand read' |
		awk '{print $1}' |
		while read offset; do
			echo "run owrt_boot;" | dd of=${tmpd}/mtd1_patched bs=1 seek=${offset} conv=notrunc
		done;

	# Write
	insmod mtd_rw i_want_a_brick=y
	mtd erase /dev/mtd1
	mtd write ${tmpd}/mtd1_patched /dev/mtd1

	# Verify
	cmp /dev/mtd1 ${tmpd}/mtd1_patched || {
		echo "Warning: written media differs from write source!" >&2;
		return 2;
	}
}
