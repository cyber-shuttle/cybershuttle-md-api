# Using the CyberShuttle VMD plugin (Tcl/Tk)
(Temporary guide)

## Step 1 - Clone this repository.
```bash
git clone https://github.com/cyber-shuttle/cybershuttle-md-api.git
```

## Step 2 - Go to the TclTk-gui folder.
```bash
cd cybershuttle-md-api/TclTk-gui
```


## Pre-requisites
Secure communication with CyberShuttle requires "tcltls" which isn't shipped with VMD. Make sure to build a local top and add it to <b>~/.vmdrc</b>
```bash
lappend auto_path /home/dgomes/software/vmd_dependencies/tcltls/lib/tcltls1.7.22/
```

## Installing CyberShuttle VMD plugin
Add the path to the TclTk-gui directory to <b>~/.vmdrc</b>
```bash
lappend auto_path /home/dgomes/github/cybershuttle-md-api/TclTk-gui/
vmd_install_extension cybershuttle cybershuttle_tk "CyberShuttle Viewer"
vmd_install_extension cybershuttlesubmit cybershuttlesubmit_tk "CyberShuttle Submit"
```

## Start VMD from the command line.
```bash
vmd
```
### Open the plugin
In VMD go to Extensions->CyberShuttle Viewer
In VMD go to Extensions->CyberShuttle Submit

### It if fails... go to the plugin folder. 
```bash
cd PATH-TO/cybershuttle-md-api/TclTk-gui/
```
Open the Tk Console and manually source the plugins.
In VMD go to Extensions->Tk Console.
```bash
source CyberShuttle.tcl
source CyberShuttle_submit.tcl
source CyberShuttle_functions.tcl
```

## Get the token!




