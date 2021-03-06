A few config files and useful scripts from my Gentoo PC, mostly for **libvirt/kvm with GPU passthrough**. In case you find a mistake, something is not working for you or you have got a question, please use the issues tab.

Table of contents
=================

   * [Gentoo related](#gentoo-related)
   * [General information about my VMs](#general-information-about-my-vms)
     * [My libvirt XMLs](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/libvirt/qemu)
     * [Notes on QEMU 6.1.0](#notes-on-qemu-610)
     * [CPU topology of my Ryzen 5](#cpu-topology)
     * [L3 cache fix](#l3-cache-fix)
     * [WLAN bridging](#wlan-bridging)
       * [Description](#description)
       * [Requirements](#requirements)
       * [Instructions](#instructions)
   * [Notes on the Windows VM](#notes-on-the-windows-vm)
     * [Cinebench R20 results](#cinebench-r20)
     * [ACPI table patch (for hiding QEMU)](#acpi-table-patch)
     * [Scream audio via ALSA](#scream-audio-via-alsa)
   * [Notes on the macOS VM](#notes-on-the-macos-vm)
     * [Custom OpenCore image with AMD Vanilla Patches](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore)
     * [macOS VM with GPU passthrough](#macos-vm-with-gpu-passthrough)

Gentoo related:
===============
- *Kernel:* sys-kernel/gentoo-sources:5.15.5
- `eselect profile show` :
*default/linux/amd64/17.1/desktop/plasma/systemd*
- portage configs available in my repo: [*/etc/portage*](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/portage)
- enabled layman repos:<br/>
*4nykey*<br/>
*audio-overlay*<br/>
[*cockpit*](https://github.com/orumin/cockpit-overlay.git)<br/>
*dlang*<br/>
*guru*<br/>
*holgersson-overlay*<br/>
[*qgj*](https://github.com/q-g-j/qgj-overlay)<br/>
*qt*<br/>
*snapd*

The [*cockpit*](https://github.com/orumin/cockpit-overlay.git) overlay and my overlay ([*qgj*](https://github.com/q-g-j/qgj-overlay)) need to be added manually:
```
sudo layman -o https://raw.githubusercontent.com/q-g-j/gentoo-stuff/master/etc/layman/overlays/cockpit.xml -f -a cockpit
sudo layman -o https://raw.githubusercontent.com/q-g-j/qgj-overlay/master/qgj.xml -f -a qgj
```

General information about my VMs:
=================================
- host machine:<br/>
*Mainboard:* MSI X470 Gaming Plus Max<br/>
*CPU:* AMD Ryzen 5 3600XT (6 cores / 12 threads in total)<br/>
*Boot GPU:* MSI Radeon RX 570 Gaming X 4GB (for the VM)<br/>
*2nd GPU:* AMD Radeon R5 230 (for the host)<br/>
*libvirt*: v7.7.0<br/>
*QEMU*: v6.0.0
- my current libvirt guest XMLs for Win11 and macOS: [link](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/libvirt/qemu)
- ~~using 5 cores / 10 threads for the guests, leaving 1 core / 2 threads for "emulatorpin" and "iothreadpin"~~
- now passing all cores, dropped emulatorpin and iothreads
- passing through the onboard USB 3 controller
- fixed the L3 cache in my VMs - see [below](https://github.com/q-g-j/gentoo-stuff#l3-cache-fix)
- enabled avic in the *kvm_amd* kernel module ([see here](https://github.com/q-g-j/gentoo-stuff/tree/master/etc/modprobe.d) for the other module parameters)
Note: according to [this site](https://www.reddit.com/r/VFIO/comments/pn3etv/maxim_levitskys_latest_work_on_apicvavic_allows/) the new kernel 5.15 has some improvements to the AVIC code.
Disabling hyper-v enlightenments like vapic, stimer and synic should not be necessary anymore.
- using a custom libvirt [hook script](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) with the following features:<br/>
  * set the cpu governor<br/>
  * enable / disable some kernel optimizations<br/>
  * enable / disable hugepages<br/>
  * enable / disable WLAN bridging<br/>
  * start / stop scream audio<br/>
  * use one or more PCI devices alternately in the host and in the guest (unbind from driver on vm start / rescan PCI bus on vm shutdown)

Notes on QEMU 6.1.0:
------------------

**QEMU 6.1.0 is known to cause a few problems in both Windows and macOS VMs.**<br/><br/>
The easiest way to avoid those is by changing the line:<br/>
```
<type arch="x86_64" machine="pc-q35-6.1">hvm</type>
```
to<br/>
```
<type arch="x86_64" machine="pc-q35-6.0">hvm</type>
```
inside the XML.<br/><br/>
Another option is adding the following to the XML (after ``</devices>``):<br/>
```
<qemu:commandline>
    <qemu:arg value="-global"/>
    <qemu:arg value="ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"/>
</qemu:commandline>
```
<br/>
Or just skip the update.

CPU Topology:
-------------

**command:**

```
lstopo -p
```

*(from sys-apps/hwloc)*<br/><br/>
<img src="https://github.com/q-g-j/gentoo-stuff/raw/master/lstopo.svg" width="600">

L3 Cache fix:
-------------
Running `lstopo -p` in a Windows VM (get it [here](https://www.open-mpi.org/software/hwloc/v2.6/)) revealed that the Level 3 cache is not detected correctly.<br/>

In the host it is:

```
L3 Cache 1:
   CPUs 0,6
   CPUs 1,7
   CPUs 2,8
L3 Cache 2:
   CPUs 3,9
   CPUs 4,10
   CPUs 5,11
```

But in the VM it is detected in 4 core steps like this:

```
L3 Cache 1:
   vCPUs 0,1
   vCPUs 2,3
   vCPUs 4,5
   vCPUs 6,7
L3 Cache 2:
   vCPUs 8,9
   vCPUs 10,11
```

I found [this thread](https://www.reddit.com/r/VFIO/comments/erwzrg/think_i_found_a_workaround_to_get_l3_cache_shared/) on Reddit which suggests to trick the VM by setting more **virtual** cores/threads than needed and disabling every 4th virtual core with the "hotpluggable" feature:

```
  <vcpu placement="static" current="12">14</vcpu>
  <vcpus>
    <vcpu id="0" enabled="yes" hotpluggable="no"/>
    <vcpu id="1" enabled="yes" hotpluggable="yes"/>
    <vcpu id="2" enabled="yes" hotpluggable="yes"/>
    <vcpu id="3" enabled="yes" hotpluggable="yes"/>
    <vcpu id="4" enabled="yes" hotpluggable="yes"/>
    <vcpu id="5" enabled="yes" hotpluggable="yes"/>
    <vcpu id="6" enabled="no" hotpluggable="yes"/>
    <vcpu id="7" enabled="no" hotpluggable="yes"/>
    <vcpu id="8" enabled="yes" hotpluggable="yes"/>
    <vcpu id="9" enabled="yes" hotpluggable="yes"/>
    <vcpu id="10" enabled="yes" hotpluggable="yes"/>
    <vcpu id="11" enabled="yes" hotpluggable="yes"/>
    <vcpu id="12" enabled="yes" hotpluggable="yes"/>
    <vcpu id="13" enabled="yes" hotpluggable="yes"/>
  </vcpus>
  <cputune>
    <vcpupin vcpu="0" cpuset="0"/>
    <vcpupin vcpu="1" cpuset="6"/>
    <vcpupin vcpu="2" cpuset="1"/>
    <vcpupin vcpu="3" cpuset="7"/>
    <vcpupin vcpu="4" cpuset="2"/>
    <vcpupin vcpu="5" cpuset="8"/>
    <vcpupin vcpu="8" cpuset="3"/>
    <vcpupin vcpu="9" cpuset="9"/>
    <vcpupin vcpu="10" cpuset="4"/>
    <vcpupin vcpu="11" cpuset="10"/>
    <vcpupin vcpu="12" cpuset="5"/>
    <vcpupin vcpu="13" cpuset="11"/>
  </cputune>
```
```
  <cpu mode="host-passthrough" check="none" migratable="off">
    <topology sockets="1" dies="1" cores="7" threads="2"/>
    <cache mode="passthrough"/>
    <feature policy="require" name="invtsc"/>
    <feature policy="require" name="topoext"/>
    <feature policy="disable" name="x2apic"/>
  </cpu>
```

Now `lstopo -p` in Windows results in this:

```
L3 Cache 1:
   vCPUs 0,1
   vCPUs 2,3
   vCPUs 4,5
L3 Cache 2:
   vCPUs 6,7
   vCPUs 8,9
   vCPUs 10,11
```

#### Here are some benchmark results from AIDA64:

Before disabling vCPUs 6 and 7:

```
L3 Cache: 
    Read:     80881 MB/s
    Write:    23342 MB/s
    Copy:     40729 MB/s
    Latency:   11.2 ns

```
After disabling vCPUs 6 and 7:

```
L3 Cache: 
    Read:     562.97 GB/s
    Write:    476.64 GB/s
    Copy:     257.79 GB/s
    Latency:    10.4  ns
```

WLAN bridging:
==============
*(libvirt [hook](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) function *"wlan_bridge*"):*
### *Description:*
The purpose of the function is to create a WLAN bridge, which shares the same subnet with the host.<br/>
What it does, is:
1. adding a new bridge device, which has to be assigned to all guests
2. starting *"dnsmasq"* which acts as a DNS server and a DHCP server with a changeable IP range
3. creating a new policy routing rule via "ip rule add" and adding all possible IPs from the DHCP IP range to it
4. routing all these IPs through the dnsmasq server. You can print the rules with:<br/>`ip rule | grep --color=never 99; echo; echo Table 99:; ip route show table 99`
5. finally starting "parprouted". This program automatically creates the necessary routes and updates the ARP table, so that the wireless adapter can find the  interfaces which are assigned to the bridge. This also allows the bridge and the WiFi adapter to share the same subnet.

### *Requirements:*
- `net.ipv4.ip_forward = 1` in */etc/sysctl.conf*
- the same bridge device (e.g. wlanbridge) assigned to each guest's network interface. The bridge will be created if desired.
- *net-dns/dnsmasq*
- *net-firewall/parprouted* - not in gentoo portage but I found an old ebuild and fixed it. Get it from my [overlay](https://github.com/q-g-j/qgj-overlay)

### *Instructions:*
Look into the [hook script](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/hooks/qemu) and change the necessary variables at the top of the file. <br/>
There you have to set a custom DHCP range for the DHCP server (provided by dnsmasq) so I strongly recommend making sure that this range is not within the DHCP range of your physical WiFi router. For example:<br/>
If your router uses a DHCP range from 192.168.100.20 to 192.168.100.200 (my FRITZ!Box allows to change this range), you could use 192.168.100.202 to 192.168.100.220 for the vms and 192.168.100.201 for the bridge device (variable *bridge_ip*).<br/>
At the bottom of the script add *"wlan_bridge start"* and *"wlan_bridge stop"* in the *"prepare"* and *"stopped"* sections of your VMs.<br/>


For **multicast-DNS** to work, edit [*/etc/avahi/avahi-daemon.conf*](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/avahi/avahi-daemon.conf) and uncomment and change the following lines:<br/>
`enable-reflector=yes`<br/>
`allow-interfaces=wlan0,wlanbridge`<br/><br/>
Then restart the avahi-daemon service:<br/>
`sudo systemctl restart avahi-daemon`<br/><br/>
You can test multicast-DNS / Bonjour with this tool: [zeroconfServiceBrowser](https://www.tobias-erichsen.de/software/zeroconfservicebrowser.html).<br/>

For proper **LAN hostname detection** in Windows Explorer I installed *net-misc/wsdd* (from *guru* overlay) - activate with:<br/>
`sudo systemctl enable --now wsdd`.<br/>

Now all guests, the host and devices connected to the host's router will be able to communicate with each other (ping, [SMB](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/samba/smb.conf), printing via Bonjour, ...) and have internet. The IPs will be assigned via DHCP.<br/>

Note: If you assign the IP address inside a guest manually, it MUST be an IP that is within the custom DHCP range (changeable variables inside the hook script) if using the new function *"wlan_bridge"* due to the static routing table.<br/>

The hook script creates the bridge device and starts the services on demand. When the last VM is stopped, the bridge will be deleted and the services killed.

Notes on the Windows VM:
========================
- libvirt XML: [win11.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/win11.xml).
- Windows 11 needs TPM 2.0 enabled. This can easily be emulated:<br/>
Change `OVMF_CODE.fd` to `OVMF_CODE.secboot.fd`, install *app-crypt/swtpm* and add these lines to the xml (in `<devices>`):
```
<tpm model="tpm-tis">
    <backend type="emulator" version="2.0"/>
</tpm>
```
- Halo Infinite needs this setting:
```
<cpu mode ...>
    ...
    <feature policy="disable" name="hypervisor"/>
</cpu>
```
- enabled Message-Signaled Interrupt mode for the HDMI audio PCI interrupt with *MSI mode utility* ([download](https://github.com/q-g-j/gentoo-stuff/blob/master/win11/MSI_util/MSI_util_v3.zip?raw=true)) to get rid of sound cracklings (run as Administrator)
- using [Looking Glass](https://looking-glass.io/) (needs IVSHMEM device: [see here](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Using_Looking_Glass_to_stream_guest_screen_to_the_host)) for remote desktop from Linux to Windows
- using [Scream](https://github.com/duncanthrax/scream) via network for audio in the guest (in alsa mode). See [below](https://github.com/q-g-j/gentoo-stuff#scream-audio-via-alsa) for instructions

Cinebench R20:
--------------

### Native Windows 11:

```
Multi CPU:    3650 pts.
Single CPU:    516 pts.
```

### Windows 11 VM:

```
Multi CPU:    3470 pts. (95,1 %)
Single CPU:    493 pts. (95,5 %)
```

ACPI table patch
----------------
*Found this tip on [Reddit](https://www.reddit.com/r/VFIO/comments/jy8ri4/a_possible_solution_to_red_dead_redemption_2_not/):*<br/><br/>
Applied an [acpi table patch](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/portage/patches/app-emulation/qemu-6.0.0/acpi-table.patch) to qemu and added custom smbios labels to the VMs xml.<br/>
This made it possible for me to play the game *Red Dead Redemption 2* inside my guest without it crashing immediately.<br/>
Could be useful for hiding QEMU from other games as well, but only needed this for RDR2 so far.<br/><br/>
You can use generic names for the smbios labels or get them from your own system with:<br/>
`sudo dmidecode --type 2`<br/>
`sudo dmidecode --type 4`<br/>
`sudo dmidecode --type 17`<br/><br/>
Note: *"sys-apps/dmidecode"* has to be installed if using the following changes to the xml! On Gentoo it was pulled in as a dependency of *"libvirt"*, on Arch I had to manually install it.
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

Scream audio via ALSA:
----------------------
I chose to run scream audio in network mode so no 2nd IVSHMEM device is needed.<br/>
To not rely on a running pulseaudio session, scream uses ALSA in my system. To have no ALSA program block the sound card, I created `/etc/asound.conf` and made the [dmix](https://alsa.opensrc.org/Dmix) and [dsnoop](https://alsa.opensrc.org/Dsnoop) plugins from ALSA the default devices for output and input and use these explicitly for pipewire (and its pulseaudio implementation).<br/>
- */etc/asound.conf*: look [here](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/asound.conf) for an example<br/>
- */etc/pipewire/pipewire.conf*: look near the bottom of [this file](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/pipewire/pipewire.conf) inside the `context.objects = [ ... ]` section.<br/>
There, inside `{   factory = adapter ... }`, you can specify, which alsa devices pipewire should use (one adapter for output, one for input).

Notes on the macOS VM:
======================
- libvirt XML: [macOS.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS.xml)
- updated to macOS Monterey (uploaded OpenCore images with Monterey support: see [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore))
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
A reboot is required.
- Removed BaseImage.img in libvirt xml before restarting the vm.
- enabled host-passthrough support for my Ryzen CPU. Needed the patches from this [site](https://github.com/AMD-OSX/AMD_Vanilla). You can use my already patched config.plist or OpenCore image: See [here](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore).<br/>
You can now use host-passthrough as well as the topoext feature to pass cores and threads correctly. Of course you need to remove:
```
<qemu:arg value='-cpu'/>
<qemu:arg value='Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,-x2apic,check'/>
```
- Update: my old USB sound card (Behringer UCA-222) is working perfectly - though NOT via USB passthrough (LOTS of crackling), but when it's connected to the passed USB3 PCI controller

macOS VM with GPU passthrough:
------------------------------
- libvirt XML: [macOS.xml](https://github.com/q-g-j/gentoo-stuff/blob/master/etc/libvirt/qemu/macOS.xml).
- Need the vendor-reset kernel module enabled (app-emulation/vendor-reset). See [*/etc/modprobe.d/vendor-reset.conf*](https://github.com/q-g-j/gentoo-stuff/raw/master/etc/modprobe.d/vendor-reset.conf) in my repo.
- In order for HDMI audio to work, I had to **enable** *AppleALC.kext* and **disable** *VoodooHDA.kext*.
- Tested with the game *Middle-earth: Shadow of Mordor* and got stable 50-60 fps. Measured fps with *Quartz Debug*. See [here](https://www.addictivetips.com/mac-os/view-fps-on-macos/) for details. For Catalina I needed to download an older version of *Additional Tools for Xcode*, for example version 12 should work.
- to make input via evdev work I needed an additional driver: *VoodooPS2Controller.kext*. Already enabled in my [*OpenCore.qcow2*](https://github.com/q-g-j/gentoo-stuff/tree/master/macOS/OpenCore).
