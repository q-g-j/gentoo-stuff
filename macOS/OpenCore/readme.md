Custom OpenCore Images with AMD Vanilla Patches
-----------------------------------------------

**Only for AMD Zen CPUs like Ryzens!**<br/><br/>
*Based on OpenCore 0.7.6.*<br/><br/>
Enabled HDMI audio for my AMD RX 570 GPU (enabled AppleALC.kext and disabled VoodooHDA.kext).<br/>
Applied the AMD Vanilla CPU patches from [https://github.com/AMD-OSX/AMD_Vanilla](https://github.com/AMD-OSX/AMD_Vanilla).<br/>

UPDATE: finally got the time to update the config.plist to support Monterey.<br/>
Now I use the newest version of the AMD vanilla patches, which unfortunately requires some manual steps. The config.plist has to be altered to match the actual CPU core count.<br/>
So I decided to provide an OpenCore image for each of the following core counts:<br/>
**4, 6, 8, 12, 16, 24, 32**<br/><br/>

**Additionally added and enabled drivers:**<br/>
- AppleALC.kext 1.6.7
- Lilu 1.5.8
- WhateverGreen.kext 1.5.5
- VoodooPS2Controller.kext 1.9.2 - RehabMan version (for evdev input devices)
- RadeonBoost.kext 1.6 - [found here](https://www.hackintosh-forum.de/forum/thread/47791-radeonboost-kext-benchmark-scores-wie-am-echten-mac-unter-windows/) (German)
