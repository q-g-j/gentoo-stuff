Based on OpenCore 0.7.3.<br/><br/>
Only for AMD Zen CPUs!<br/>
Enabled HDMI audio for my AMD RX 570 (enabled AppleALC.kext and disabled VoodooHDA.kext).<br/>
Applied the AMD Vanilla CPU patches from [https://github.com/AMD-OSX/AMD_Vanilla](https://github.com/AMD-OSX/AMD_Vanilla) (17h_19h).<br/><br/>

UPDATE: finally got the time to update the config.plist to support Monterey.<br/>
Now I use the newest version of the AMD vanilla patches, which unfortunately require some manual steps. The config.plist has to be altered to match the actual CPU core count.<br/>
I decided to provide an OpenCore image for each of the following core counts:<br/>
**4, 6, 8, 12, 16, 24, 32**<br/><br/>

**Additionally added and enabled drivers:**<br/>
- AppleALC.kext 1.6.4
- Lilu 1.5.6
- WhateverGreen.kext 1.5.3
- VoodooPS2Controller.kext 2.2.4 (for evdev input devices)
- RadeonBoost.kext 1.6 - [found here](https://www.hackintosh-forum.de/forum/thread/47791-radeonboost-kext-benchmark-scores-wie-am-echten-mac-unter-windows/) (German)
