#lappend auto_path /home/dgomes/software/vmd_dependencies/tcltls/lib/tcltls1.7.22/
#lappend auto_path /home/dgomes/software/vmd-1.9.4.58dgomes/lib/plugins/noarch/tcl/json1.0/
lappend auto_path {Applications/VMD 1.9.4a57-arm64-Rev12.app/Contents/vmd/plugins/noarch/tcl/json1.0}
lappend auto_path /opt/homebrew/Cellar/tcl-tk/8.6.14/lib/tcltls1.7.22/

package provide cybershuttlesubmit 0.8
package require Tk
package require Ttk
package require http
package require tls
package require json

namespace eval cybershuttlesubmit {
	variable w          ;# handle to main window
	variable projects [dict create]
	variable project
	variable replicas
	variable token
	variable experiments
	variable experimentId
        variable experimentName
	variable experimentFiles
	variable experimentFileNames
	variable experimentURL
	variable psf_files [list]
    variable traj_files [list]
    variable out_files [list]
	variable selected_psf_file
    variable selected_traj_file
    variable selected_out_file
	variable tmpDir /tmp/
	variable namdConfig 
	variable namdPSF
	variable namdPDB
	variable namdCOR
	variable namdVEL
	variable namdXSC 
	variable namdRES
	variable namdPRM
	# List of uploaded files
	variable url_list
	variable namdConfigUrl
	variable namdOtherUrl
}

proc cybershuttlesubmit::main {} {
	variable w

    global env
	
    # Main window
    set           w [ toplevel .cybershuttlesubmit ]
	wm title     $w "CyberShuttle Interface" ; # Create window
	wm resizable $w 0 0     				 ; # Prevent resizing

	if {[winfo exists $w] != 1} {
		raise $w

	} else {
		wm deiconify $w
	}
	
	# Import the tcl file
	#source /home/dgomes/github/Forest-ttk-theme/forest-light.tcl

	# Set theme using the theme use method
	#ttk::style theme use forest-light

	
	####################################################################
    # Token frame
    ####################################################################
    ttk::labelframe $w.f1 -text "Connect/Reconnect to CyberShuttle" -relief groove
    grid   $w.f1 -row 0 -column 0 -sticky nsew -padx 5 -pady 5 
	
	# Create a button to read the contents of the text widget
	ttk::button $w.f1.connect -text "Get token" -command [list cybershuttlesubmit::invokeBrowser "https://md.cybershuttle.org/auth/login-desktop/?show-code=true"]
	grid   $w.f1.connect -row 0 -column 0 -sticky nsew

	# Create a button to read the contents of the text widget
	ttk::button $w.f1.readToken -text "Apply" -command {cybershuttlesubmit::readToken}
	grid   $w.f1.readToken -row 1 -column 0 -sticky nsew

	# Text field for token
	text   $w.f1.token -height 3 -width 70 -borderwidth 2 -relief sunken -setgrid true 
	grid   $w.f1.token -row 0 -rowspan 2 -column 1 -sticky nsew

#	# Create a button to read the contents of the text widget
#	ttk::button $w.f1.printToken -text "print" -command { puts $::cybershuttlesubmit::token }
#	grid   $w.f1.printToken -row 2 -column 0 -sticky nsew
	
	
    ttk::labelframe $w.f2 -text "Simulation files" -relief groove
    grid   $w.f2 -row 1 -column 0 -sticky nsew -padx 5 -pady 5 
	
		# Current window/frame
		set wc $w.f2
		
		set item 0 ; set row 0 
		ttk::label  $wc.l$item -text "Configuration"
		set namdConfig ".conf autofils"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdConfig -width 15 -state readonly
		
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_config $wc $wc.e$item" 

		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Topology"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdPSF -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_psf $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::label  $wc.l$item -text "Structure"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdPDB -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_structure $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Coordinates"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdCOR -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_coordinates $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::label  $wc.l$item -text "Velocities"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdVEL -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_velocities $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Extended"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdXSC -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_extended $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::label  $wc.l$item -text "Restraints"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdRES -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_restraints $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Parameters"
		ttk::entry  $wc.e$item -textvariable cybershuttlesubmit::namdPRM -width 15 -state readonly
		ttk::button $wc.b$item -text "Browse" -command "cybershuttlesubmit::set_parameters $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	





    ttk::labelframe $w.f3 -text "New experiment" -relief groove
    grid   $w.f3 -row 2 -column 0 -sticky nsew -padx 5 -pady 5 
	
		# Current window/frame
		set wc $w.f3
		
		set row 0 ; set item 0
                ttk::label    $wc.l$item -text "Experiment Name"
                ttk::entry    $wc.e$item -textvariable cybershuttlesubmit::experimentName 
                grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5
                grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5


		incr row ; incr item
		ttk::label    $wc.l$item -text "Project"
		ttk::button   $wc.b$item -text "Load Projects" -command { cybershuttlesubmit::listProjects }
		ttk::combobox $wc.c$item -values [dict keys $cybershuttlesubmit::projects]
		$wc.c$item set "Default Project"

		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.c$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	
		
#		incr item
#		ttk::label  $wc.l$item -text "Name"
#		ttk::entry  $wc.e$item 
	
#		grid $wc.l$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	
#		grid $wc.e$item -row $row -column 3 -columnspan 5 -sticky nsew -padx 5 -pady 5 	

    ttk::labelframe $w.f4 -text "Description" -relief groove
    grid   $w.f4 -row 3 -column 0 -sticky nsew -padx 5 -pady 5 
		# Current window/frame
		set wc $w.f4
		
		set item 0; set row 0
		# Text field for token
		text   $wc.description -height 3 -width 70 -borderwidth 2 -relief sunken -setgrid true 
		grid   $wc.description -row $row -rowspan 2 -column 0 -columnspan 5 -sticky nsew

		incr item ;
		ttk::button $wc.b$item -text "Review"
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::button $wc.b$item -text "Submit" -command {cybershuttlesubmit::submit}
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

}

source CyberShuttle_functions.tcl
cybershuttlesubmit::main

proc cybershuttlesubmit_tk {} {
  cybershuttlesubmit::main
  return $cybershuttlesubmit::w
}
