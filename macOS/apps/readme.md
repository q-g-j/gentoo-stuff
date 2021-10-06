**FreeRDP Remote Desktop.app**:

Simple shortcut app made with *Automator* that starts a remote desktop session to a FreeRDP server.<br/>
Dependencies:<br/>
- wine64 (available via homebrew)
- [wfreerdp](https://github.com/q-g-j/gentoo-stuff/blob/master/win10/freerdp/wfreerdp.zip?raw=true) extracted into $HOME/wfreerdp

*Instructions*:<br/>
- First, setup the freerdp server on the Linux host as described [here](https://github.com/q-g-j/gentoo-stuff/tree/master/win10/freerdp)
- The app will connect to a server at IP address `182.12.100.1` by default and expects the server being run with `-auth` (no user / passwd). The IP can easily be changed:<br/>
In Mac OS open the *Automator* app. In the popup window select "Open an existing document..." and open the extracted app (FreeRDP Remote Desktop).
You will see a shell script in the black box. There change FREERDP_SERVER_IP to the IP the freerdp server is running on. Click on File->Save.
Now open Finder and just drag the modified app into programs.
