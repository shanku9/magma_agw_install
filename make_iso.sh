#!/bin/bash
set -euo pipefail
temp_dir="isofiles"

if [ $# -ne 2 ]; then
    echo usage $0 ISO preseed.cfg
    exit 1
fi

source_iso=$1
source_iso_name=$(basename $source_iso)
preseed=$2

[ -f "$source_iso" ] || (echo source_iso does not exist && exit 1)
[ -f "$preseed" ] || (echo preseed does not exist && exit 1)

if [ ! -d "$temp_dir" ]; then
    mkdir -p "$temp_dir"
    bsdtar -C "$temp_dir" -xf "$source_iso"
    gunzip "$temp_dir"/install.amd/initrd.gz
    echo "$preseed" | cpio -H newc -o -A -F "$temp_dir"/install.amd/initrd
    gzip "$temp_dir"/install.amd/initrd
fi

sed -i 's/^timeout.*/timeout 1/' "$temp_dir"/isolinux/isolinux.cfg
cat >"$temp_dir"/isolinux/menu.cfg <<EOF
menu hshift 4
menu width 70
menu title Debian GNU/Linux installer menu (BIOS mode)
include stdmenu.cfg
include txt.cfg
EOF

cat >"$temp_dir"/isolinux/txt.cfg <<EOF
label install
        menu label ^Install
        menu default
        kernel /install.amd/vmlinuz
        append vga=788 auto=true priority=critical file=/preseed.cfg initrd=/install.amd/initrd.gz --- quiet
default install
EOF
md5sum `find $temp_dir -follow -type f` > "$temp_dir"/md5sum.txt
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "preseed-$source_iso_name" "$temp_dir"/
#rm -r "$temp_dir"

