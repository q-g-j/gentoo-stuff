A few config files and useful scripts from my Gentoo PC, mostly for **libvirt/kvm with GPU passthrough**. In case you find a mistake, something is not working for you or you have got a question, please use the issues tab.

## Gentoo related:
- *Kernel:* sys-kernel/gentoo-sources:5.15.0
- `eselect profile show` :<br/>
*default/linux/amd64/17.1/desktop/plasma/systemd*
- portage configs available in my repo: [*/etc/portage*](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage)
- enabled layman repos:<br/>
*4nykey*<br/>
*audio-overlay*<br/>
[*cockpit*](https://github.com/orumin/cockpit-overlay.git)<br/>
*dlang*<br/>
*guru*<br/>
*holgersson-overlay*<br/>
[*qgj*](https://github.com/q-g-j/qgj-overlay)


## General information about my libvirt VMs:
- host machine:<br/>
*Mainboard:* MSI X470 Gaming Plus Max<br/>
*CPU:* AMD Ryzen 5 3600XT (6 cores / 12 threads in total)<br/>
*Boot GPU:* MSI Radeon RX 570 Gaming X 4GB (for the VM)<br/>
*2nd GPU:* AMD Radeon R5 230 (for the host)<br/>
*libvirt*: v7.7.0<br/>
*QEMU*: v6.0.0
- my current libvirt guest XMLs for Win11 and macOS: [link](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/libvirt/qemu)
- passing only 5 cores with 2 threads on each core to the guest with proper CPU pinning (lstopo); No isolating via grub
- passing through the boot GPU (see my [grub config file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/default/grub) for details on how to do this). GPU BIOS ROM is needed (got it via GPU-Z in Win10 before).
- passing through the onboard USB 3 controller
- enabled avic in kvm_amd kernel module ([see here](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/modprobe.d) for the other module parameters)<br/>
Note: according to [this site](https://www.reddit.com/r/VFIO/comments/pn3etv/maxim_levitskys_latest_work_on_apicvavic_allows/) the new kernel 5.15 has some improvements to the AVIC code.
Disabling hyper-v enlightenments like vapic, stimer and synic should not be necessary anymore.
- using a custom libvirt [hooks file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) with the following features:<br/>
  * set the cpu governor<br/>
  * enable / disable some kernel optimizations<br/>
  * enable / disable hugepages<br/>
  * enable / disable WLAN bridging<br/>
  * start / stop scream audio<br/>
  * use one or more PCI devices alternately in the host and in the guest (unbind from driver on vm start / rescan PCI bus on vm shutdown)

### WLAN bridging *(libvirt [hooks](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) function *"wlan_bridge*"):*
#### *Description:*
The purpose of the function is to create a WLAN bridge, which shares the same subnet with the host.<br/>
What it does, is:
1. adding a new bridge device, which has to be assigned to all guests
2. starting *"dnsmasq"* which uses DHCP with a custom IP range
3. creating a new table via "ip rule add" and adding all possible IPs from the DHCP IP range to it
4. routing all these IPs through the hosts gateway (actually the dnsmasq server). You can print the rules with:<br/>`ip rule | grep --color=never 99; echo; echo Table 99:; ip route show table 99`
5. finally starting "parprouted". This program "joins" the involved interfaces (wlan0 and bridge0) to one address space (the hosts subnet)

#### *Requirements:*
- `net.ipv4.ip_forward = 1` in */etc/sysctl.conf*
- the same bridge device (e.g. bridge0) assigned to each guests network interface. The bridge will be created if desired.
- *net-dns/dnsmasq*
- *net-firewall/parprouted* - not in gentoo portage but I found an old ebuild and fixed it. Get it from my [overlay](https://github.com/q-g-j/qgj-overlay)

#### *Instructions:*
Look into the [hooks file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) and change the necessary variables at the top of the file. At the bottom add *"wlan_bridge start"* and *"wlan_bridge stop"* in the *"prepare"* and *"stopped"* sections of your VMs.<br/>
For mdns multicasting to work, you can just uncomment the line *"enable-reflector=yes"* and change the line *"allow-interfaces="* to look like: `allow-interfaces=wlan0,bridge0` in [*/etc/avahi/avahi-daemon.conf*](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/avahi/avahi-daemon.conf) and restart avahi-daemon.service.<br/>
Now all guests, the host and devices connected to the hosts router will be able to communicate with each other (ping, [SMB](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/samba/smb.conf), printing via Bonjour, ...) and have internet. The IPs will be assigned via DHCP. For proper LAN hostname detection in Windows Explorer I installed *net-misc/wsdd* (from *guru* overlay) - activate with `systemctl enable --now wsdd`.<br/>
Note: The VMs MUST use an IP that is within the custom DHCP range (changeable variable inside the hooks file) if using the new function *"wlan_bridge"* due to the static routing table.<br/>
The hooks file creates the bridge device and starts the services on demand. When the last VM is stopped, the bridge will be deleted and the services killed.

## Notes on the Win11 VM:
- libvirt XML: [win11.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/win11.xml).
- enabled Message-Signaled Interrupt mode for the HDMI audio PCI interrupt with *MSI mode utility* ([download](https://github.com/q-g-j/gentoo-stuff/blob/master/win11/MSI_util/MSI_util_v3.zip?raw=true)) to get rid of sound cracklings (run as Administrator)
- using [Looking Glass](https://looking-glass.io/) (needs IVSHMEM device: [see here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Using_Looking_Glass_to_stream_guest_screen_to_the_host)) for remote desktop from Linux to Windows
- using [Scream](https://github.com/duncanthrax/scream) via network for audio in the guest (in alsa mode)
- applied an [acpi table patch](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/portage/patches/app-emulation/qemu-6.0.0/acpi-table.patch) to qemu and added custom smbios labels to the VMs xml. This made it possible for me to play the game *Red Dead Redemption 2* inside my guest without it crashing immediately. Found this tip on [Reddit](https://www.reddit.com/r/VFIO/comments/jy8ri4/a_possible_solution_to_red_dead_redemption_2_not/). You can use generic names for the smbios labels or get them from your own system with:<br/>
`sudo dmidecode --type 2`<br/>
`sudo dmidecode --type 4`<br/>
`sudo dmidecode --type 17`<br/><br/>
Note: *"sys-apps/dmidecode"* has to be installed if using the following changes to the xml! On gentoo it was pulled in as a dependency of *"libvirt"*, on arch I had to manually install it.
Here are the necessary changes to the [libvirt xml:](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/win11.xml):
```
domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>win11</name>
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

### Scream Audio via ALSA:
I chose to run scream audio in network mode so no 2nd IVSHMEM device is needed.<br/>
To not rely on a running pulseaudio session, scream uses ALSA in my system. To have no ALSA program block the sound card, I adjusted `/etc/asound.conf` to make the [dmix](https://alsa.opensrc.org/Dmix) and [dsnoop](https://alsa.opensrc.org/Dsnoop) plugins from ALSA the default devices for output and input and use these explicitly for pipewire (and its pulseaudio implementation).<br/>
- */etc/asound.conf*: look [here](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/asound.conf) for an example<br/>
- */etc/pipewire/pipewire.conf*: look near the bottom of [this file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/pipewire/pipewire.conf) inside the `context.objects = [ ... ]` section. There, inside `{   factory = adapter ... }`, you can specify, which alsa devices pipewire should use (one for output, one for input).

## Notes on the Mac OS VM:
- libvirt XMLs: [macOS-spice.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-spice.xml) and [macOS-gpu.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-gpu.xml)
- Update: just upgraded from macOS Catalina to Big Sur and it seems to run just the same as before. The kexts are still loading fine. Now even network with *virtio-net* is working.
- Used *macOS-libvirt-Catalina.xml*, *BaseImage.img* (via *fetch-macOS-v2.py*), *OVMF_CODE.fd* and *OVMF_VARS-1024x768.fd* from [this site](https://github.com/kholia/OSX-KVM).
- Installed with spice graphics and switched to GPU passthrough later.
- Uploaded my own **OpenCore.qcow2**. Created the config.plist according to [this site](https://dortania.github.io/OpenCore-Install-Guide/). See [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore) for download and description. Can be used for installation too, just tested it (you will need to set the CPU to host-passthrough). This is only meant to be used with AMD Zen processors (e.g. Ryzen)! Propably not working for Intel, but cannot test.
- Made a few changes to the xml, like adding CPU pinning, enabling hugepages and some other things. As you might know, you need to change this line (google it, I'm not sure about the legal part):<br/>
`<qemu:arg value='isa-applesmc,osk=GOOGLE'/>`<br/>
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

## macOS VM with GPU passthrough:
- libvirt XML: [macOS-gpu.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS-gpu.xml).
- Need the vendor-reset kernel module enabled (app-emulation/vendor-reset). See [*/etc/modules-load.d/vendor-reset.conf*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/modules-load.d/vendor-reset.conf) and [*/etc/modprobe.d/vendor-reset.conf*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/modprobe.d/vendor-reset.conf) in my repo. Got rid of kernel errors / warnings by adding `pci=noats` to `GRUB_CMDLINE_LINUX` in [*/etc/default/grub*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/default/grub)
- In order for HDMI audio to work, I had to **enable** *AppleALC.kext* and **disable** *VoodooHDA.kext*.
- Tested with the game *Middle-earth: Shadow of Mordor* and got stable 50-60 fps. Measured fps with *Quartz Debug*. See [here](https://www.addictivetips.com/mac-os/view-fps-on-macos/) for details. For Catalina I needed to download an older version of *Additional Tools for Xcode*, for example version 12 should work.
- to make input via evdev work I needed an additional driver: *VoodooPS2Controller.kext*. Already enabled in my [*OpenCore.qcow2*](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore).
