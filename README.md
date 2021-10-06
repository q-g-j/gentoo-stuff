A few config files and useful scripts from my Gentoo PC, mostly for **libvirt/kvm with GPU passthrough**. In case you find a mistake, something is not working for you or you have got a question, please use the issues tab.

**Gentoo related:**
- *Kernel:* sys-kernel/gentoo-sources-5.13.2 with patches ([config here](https://github.com/q-g-j/gentoo-stuff/blob/master/boot), [patches here](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage/patches/sys-kernel/gentoo-sources))<br/>
- `sudo eselect profile show` :<br/>
*default/linux/amd64/17.1/desktop/plasma/systemd*
- portage configs available in my repo: [*/etc/portage*](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage)
- enabled layman repos:<br/>
*4nykey*<br/>
*audio-overlay*<br/>
*bombo82*<br/>
[*cockpit*](https://github.com/orumin/cockpit-overlay.git)<br/>
*guru*<br/>
*holgersson-overlay*<br/>
[*qgj*](https://github.com/q-g-j/qgj-overlay)<br/>
*steam-overlay*<br/><br/>


**General information about my libvirt VMs:**
- host machine:<br/>
*Mainboard:* MSI X470 Gaming Plus Max<br/>
*CPU:* AMD Ryzen 5 3600XT (6 cores / 12 threads in total)<br/>
*Boot GPU:* MSI Radeon RX 570 Gaming X 4GB (for the VM)<br/>
*2nd GPU:* AMD Radeon R5 230 (for the host)<br/>
*libvirt*: v7.5.0<br/>
*QEMU*: v6.0.0
- my current libvirt guest XMLs for Win10 and macOS: [link](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/libvirt/qemu)
- passing only 5 cores with 2 threads on each core to the guest with proper CPU pinning (lstopo); No isolating via grub
- passing through the boot GPU (see my [grub config file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/default/grub) for details on how to do this). GPU BIOS ROM is needed (got it via GPU-Z in Win10 before).
- passing through the onboard USB 3 controller
- acs override patch needed on my system
- enabled avic in kvm_amd kernel module ([see here](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/modprobe.d) for the other module parameters). Avic will conflict with some hyper-v enlightenments according to [this site](https://www.reddit.com/r/VFIO/comments/fovu39/iommu_avic_in_linux_kernel_56_boosts_pci_device/), so I disabled them.
- using a custom libvirt [hooks file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) with the following features:<br/>
  * set the cpu governor<br/>
  * enable / disable some kernel optimizations<br/>
  * enable / disable hugepages<br/>
  * enable / disable WLAN bridging<br/>
  * start / stop scream audio<br/>
  * use one or more PCI devices alternately in the host and in the guest (unbind from driver on vm start / rescan PCI bus on vm shutdown)<br/><br/>


**WLAN bridging** (libvirt [hooks](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) function *"wlan_bridge*"):<br/><br/>
*Description:*<br/><br/>
The purpose of the function is to create a WLAN bridge, which shares the same subnet with the host.<br/>
What it does, is:
1. adding a new bridge device, which has to be assigned to all guests
2. starting *"dnsmasq"* which uses DHCP with a custom IP range
3. creating a new table via "ip rule add" and adding all possible IPs from the DHCP IP range to it
4. routing all these IPs through the hosts gateway (actually the dnsmasq server). You can print the rules with:<br/>`ip rule | grep --color=never 99; echo; echo Table 99:; ip route show table 99`
5. finally starting "parprouted". This is needed, because it will "join" the involved interfaces (wlan0 and bridge0) to one address space (the hosts subnet)

*Requirements:*
- `net.ipv4.ip_forward = 1` in */etc/sysctl.conf*
- the same bridge device (e.g. bridge0) assigned to each guests network interface. The bridge will be created if desired.
- *net-dns/dnsmasq*
- *net-firewall/parprouted* - not in gentoo portage but I found an old ebuild and fixed it. Get it from my [overlay](https://github.com/q-g-j/qgj-overlay)
- if I remember correctly, it was necessary to set *DNSStubListener=no* inside [*/etc/systemd/resolved.conf*](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/systemd/resolved.conf) to avoid conflicts between systemd and dnsmasq.

*Instructions:*<br/><br/>
Look into the [hooks file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) and change the necessary variables at the top of the file. At the bottom add *"wlan_bridge start"* and *"wlan_bridge stop"* in the *"prepare"* and *"stopped"* sections of your VMs.<br/>
For mdns multicasting to work, you can just uncomment the line *"enable-reflector=yes"* and change the line *"allow-interfaces="* to look like: `allow-interfaces=wlan0,bridge0` in [*/etc/avahi/avahi-daemon.conf*](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/avahi/avahi-daemon.conf) and restart avahi-daemon.service.<br/>
Now all guests, the host and devices connected to the hosts router will be able to communicate with each other (ping, SMB, printing via Bonjour, ...) and have internet. The IPs will be assigned via DHCP. <br/>
Note: The VMs MUST use an IP that is within the custom DHCP range (changeable variable inside the hooks file) if using the new function *"wlan_bridge"* due to the static routing table.<br/>
The hooks file creates the bridge device and starts the services on demand. When the last VM is stopped, the bridge will be deleted and the services killed.<br/><br/>


**Notes on the Win10 VM:**
- libvirt XML: [win10.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/win10.xml).
- enabled Message-Signaled Interrupt mode for the HDMI audio PCI interrupt with *MSI mode utility* ([download](https://github.com/q-g-j/gentoo-stuff/blob/master/win10/MSI_util/MSI_util_v3.zip?raw=true)) to get rid of sound cracklings (run as Administrator)
- using [Looking Glass](https://looking-glass.io/) (needs IVSHMEM device: [see here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Using_Looking_Glass_to_stream_guest_screen_to_the_host)) for remote desktop from Linux to Windows
- using [Scream](https://github.com/duncanthrax/scream) via network for audio in the guest (in alsa mode)
- added [instructions](https://github.com/q-g-j/gentoo-stuff/tree/master/win10/freerdp) for remote desktop from Windows to Linux using freerdp. Other solutions were too sluggish with my setup.
- applied an [acpi table patch](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/portage/patches/app-emulation/qemu-6.0.0/acpi-table.patch) to qemu and added custom smbios labels to the VMs xml. This made it possible for me to play the game *Red Dead Redemption 2* inside my guest without it crashing immediately. Found this tip on [Reddit](https://www.reddit.com/r/VFIO/comments/jy8ri4/a_possible_solution_to_red_dead_redemption_2_not/). You can use generic names for the smbios labels or get them from your own system with:<br/>
`sudo dmidecode --type 2`<br/>
`sudo dmidecode --type 4`<br/>
`sudo dmidecode --type 17`<br/><br/>
Here are the necessary changes to the [libvirt xml:](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/win10.xml):
```
domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>win10</name>
  ....
   <os>
    ....
    <smbios mode='host'/>
  </os>
  ....
   <qemu:commandline>
    <qemu:arg value='-smbios'/>
    <qemu:arg value='type=2,manufacturer=MSI,product=X470 GAMING PLUS MAX (MS-7B79),version=3.0,serial=K716632061'/>
    <qemu:arg value='-smbios'/>
    <qemu:arg value='type=4,manufacturer=AMD,version=AMD Ryzen 5 3600XT 6-Core Processor'/>
    <qemu:arg value='-smbios'/>
    <qemu:arg value='type=17,manufacturer=Unknown'/>
  </qemu:commandline>
</domain>
```
<br/>

**Notes on the Mac OS VM:**
- libvirt XMLs: [macOS-spice.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-spice.xml) and [macOS-gpu.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-gpu.xml)
- Update: just upgraded from macOS Catalina to Big Sur 11.4 and it seems to run just the same as before. The kexts are still loading fine. Now even network with *virtio-net* is working.
- Used *macOS-libvirt-Catalina.xml*, *BaseImage.img* (via *fetch-macOS-v2.py*), *OVMF_CODE.fd* and *OVMF_VARS-1024x768.fd* from [this site](https://github.com/kholia/OSX-KVM).
- Installed with spice graphics and switched to GPU passthrough later.
- Uploaded my own **OpenCore.qcow2**. Created the config.plist according to [this site](https://dortania.github.io/OpenCore-Install-Guide/). See [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore) for download and description. Can be used for installation too, just tested it (you will need to set the CPU to host-passthrough). This is only meant to be used with AMD Zen processors (e.g. Ryzen)! Propably not working for Intel, but cannot test.
- Made a few changes to the xml, like adding CPU pinning, enabling hugepages and some other things. As you might know, you need to change this line (google it, I'm not sure about the legal part):<br/>
`<qemu:arg value='isa-applesmc,osk=GOOGLE'/>`<br/>
- Modified my libvirt [hooks file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) to support the new guest.
- Mac OS Catalina installed just fine. Even when using virtio for the hard disk and for the graphics (in spice mode). Update: went back to SATA for the disk cause I couldn't get SSD TRIM working with virtio-blk.
- When the installation starts you need to go to disk utility first and **erase** the System partition, even if empty. This automatically reformats it to be used for the installation. Close the disk utility and start the installation.
- Downloaded homebrew and installed wget, xquartz (xorg for MacOS) and wine-staging :<br/>
In mac OS open a terminal:<br/>
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`<br/>
`brew install wget`<br/>
`brew install --cask xquartz`<br/>
`brew tap homebrew/cask-versions`<br/>
`brew install --cask --no-quarantine wine-staging`<br/>
Reboot.
- Removed BaseImage.img in libvirt xml before restarting the vm.
- enabled host-passthrough support for my Ryzen CPU. Needed the patches from this [site](https://github.com/AMD-OSX/AMD_Vanilla/blob/opencore/17h_19h/patches.plist). You can use my already patched config.plist or OpenCore image: See [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore).<br/>
You can now use host-passthrough as well as the topoext feature to pass cores and threads correctly. Of course you need to remove:<br/>
`<qemu:arg value='-cpu'/>`<br/>
`<qemu:arg value='Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,-x2apic,check'/>`<br/>
From<br/>
`<qemu:commandline>`<br/>
- Update: my old USB sound card (Behringer UCA-222) is working perfectly - though NOT via USB passthrough (LOTS of crackling), but when it's connected to the passed USB3 PCI controller

**macOS VM with GPU passthrough:**
- libvirt XML: [macOS-gpu.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-gpu.xml).
- Need the vendor-reset kernel module enabled (app-emulation/vendor-reset). See [*/etc/modules-load.d/vendor-reset.conf*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/modules-load.d/vendor-reset.conf) and [*/etc/modprobe.d/vendor-reset.conf*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/modprobe.d/vendor-reset.conf) in my repo. Got rid of kernel errors / warnings by adding `pci=noats` to `GRUB_CMDLINE_LINUX` in [*/etc/default/grub*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/default/grub)
- In order for HDMI audio to work, I had to **enable** *AppleALC.kext* and **disable** *VoodooHDA.kext*.
- Tested with the game *Middle-earth: Shadow of Mordor* and got stable 50-60 fps. Measured fps with *Quartz Debug*. See [here](https://www.addictivetips.com/mac-os/view-fps-on-macos/) for details. For Catalina I needed to download an older version of *Additional Tools for Xcode*, for example version 12 should work.
- Remote desktop from Mac OS to Linux: since I already had the freerdp server running on the host, I tried to get xfreerdp running in MacOS but it would not work well - frequent crashes, no true full screen. So I tried it with wine (see above for how to install it) and the Windows version of the FreeRDP client that I uploaded [here](https://github.com/q-g-j/gentoo-stuff/tree/master/win10/freerdp), and it runs surprisingly well! The instructions and parameters from the last link apply to this method as well. Of course start it with `wine64` in front:<br/>
`cd $HOME/wfreerdp`<br/>
`wine64 wfreerdp.exe  /v:182.12.100.1 /u:<linux-username> /p:<linux-password> /f /rfx /floatbar:sticky:off,default:hidden,show:fullscreen`<br/>
I'm using a simple shortcut app for this (made with *Automator*), that can be put into the Dock. See [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/apps) for instructions.
- to make input via evdev work I needed an additional driver: *VoodooPS2Controller.kext*. Already enabled in my [*OpenCore.qcow2*](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore).
