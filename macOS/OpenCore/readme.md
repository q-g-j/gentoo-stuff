Based on OpenCore 0.7.2.<br/><br/>
Only for AMD Zen CPUs!<br/>
Enabled HDMI audio for my AMD RX 570 (enabled AppleALC.kext and disabled VoodooHDA.kext).<br/>
Applied the AMD Vanilla CPU patches from [https://github.com/AMD-OSX/AMD_Vanilla](https://github.com/AMD-OSX/AMD_Vanilla) (17h_19h).<br/><br/>

**Additionally added and enabled drivers:**<br/>
- AppleALC.kext 1.6.3
- Lilu 1.5.5
- WhateverGreen.kext 1.5.2
- VoodooPS2Controller.kext 2.2.4 (for evdev input devices)
- RadeonBoost.kext 1.6 - [found here](https://www.hackintosh-forum.de/forum/thread/47791-radeonboost-kext-benchmark-scores-wie-am-echten-mac-unter-windows/) (German)
