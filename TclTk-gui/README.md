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

## Using the GUI
To communicate securely with CyberShuttle you need a session token. Click on **Get token**. A webBrowser will open and you'll be guided to login using your ACCESS our University account. Once done, copy the token and click on **Apply**


### CyberShuttle Submit
Submiting a job to CyberShuttle one needs to get a token, provide the input files, and submit the job.
Go ahead and setup you system using QwikMD, Charmm-GUI, manually, using psfgen.
In VMD2, cybershuttle submit will also be intergrated in QwikMD.

![Slide1](images/Slide1.png)
![Slide2](images/Slide2.png)
![Slide3](images/Slide3.png)
![Slide4](images/Slide4.png)
![Slide5](images/Slide5.png)
![Slide6](images/Slide6.png)

### CyberShuttle View
![Slide7](images/Slide7.png)
![Slide8](images/Slide8.png)
![Slide9](images/Slide9.png)
![Slide10](images/Slide10.png)
![Slide11](images/Slide11.png)
![Slide12](images/Slide12.png)
![Slide13](images/Slide13.png)
![Slide14](images/Slide14.png)
![Slide15](images/Slide15.png)
![Slide16](images/Slide16.png)





