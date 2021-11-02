Updated kernel to *sys-kernel/gentoo-sources:5.15.0* (with USE flag *experimental* enabled)<br/>
Switched from grub to systemd-boot.

kernel patches applied ([find them here:](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage/patches/sys-kernel/gentoo-sources)):
- ipx-headers.patch: net-wireless/rtl88x2bu (in my [overlay](https://github.com/q-g-j/qgj-overlay)) needs the ipx network layer header files that were removed in the 5.15 kernel

