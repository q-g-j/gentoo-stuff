Kernel config (for sys-kernel/gentoo-sources:5.13.2) tuned for the following system:

*Mainboard:* MSI X470 Gaming Plus Max<br/>
*CPU:* AMD Ryzen 5 3600XT (6 cores / 12 threads in total)<br/>
*Boot GPU:* MSI Radeon RX 570 Gaming X 4GB (for the VM)<br/>
*2nd GPU:* AMD Radeon R5 230 (for the host)

kernel patches applied ([find them here:](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage/patches/sys-kernel/gentoo-sources)):

- acso.patch: [acs override patch](https://queuecumber.gitlab.io/linux-acs-override/)
- more-uarches-for-kernel-5.8+.patch: [additional CPU Optimizations for GCC](https://github.com/graysky2/kernel_compiler_patch)
- No_irq_handler_for_vector.patch: custom: suppress certain annoying kernel messages
- 5.13_xhci-pci-renesas_missing-firmware.patch: custom: my Renesas USB 3.0 PCI controller was not working anymore after updating from v5.12.7 to v5.13.2
- bluetooth-fake-csr.patch: custom: my new "fake CSR" bluetooth USB dongle was not detected correctly
