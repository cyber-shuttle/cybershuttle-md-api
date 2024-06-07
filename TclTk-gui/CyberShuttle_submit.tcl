lappend auto_path /home/dgomes/software/vmd_dependencies/tcltls/lib/tcltls1.7.22/
lappend auto_path /home/dgomes/software/vmd-1.9.4.58dgomes/lib/plugins/noarch/tcl/json1.0/

package provide cybershuttle 0.8
package require Tk
package require Ttk
package require http
package require tls
package require json

namespace eval cybershuttle {
	variable w          ;# handle to main window
	variable projects
	variable project
	variable replicas
	variable token
	variable experiments
	variable experimentId
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
}

proc cybershuttle::main {} {
	variable w
    global env
	
    # Main window
    set           w [ toplevel .cybershuttle ]
	wm title     $w "CyberShuttle Interface" ; # Create window
	wm resizable $w 0 0     				 ; # Prevent resizing

	if {[winfo exists $w] != 1} {
		raise $w

	} else {
		wm deiconify $w
	}
	
	# Import the tcl file
	source /home/dgomes/github/Forest-ttk-theme/forest-light.tcl

	# Set theme using the theme use method
	ttk::style theme use forest-light

	
	####################################################################
    # Token frame
    ####################################################################
    ttk::labelframe $w.f1 -text "Connect/Reconnect to CyberShuttle" -relief groove
    grid   $w.f1 -row 0 -column 0 -sticky nsew -padx 5 -pady 5 
	
	# Create a button to read the contents of the text widget
	ttk::button $w.f1.connect -text "Get token" -command [list cybershuttle::invokeBrowser "https://md.cybershuttle.org/auth/login-desktop/?show-code=true"]
	grid   $w.f1.connect -row 0 -column 0 -sticky nsew

	# Create a button to read the contents of the text widget
	ttk::button $w.f1.readToken -text "Apply" -command {cybershuttle::readToken}
	grid   $w.f1.readToken -row 1 -column 0 -sticky nsew

	# Text field for token
	text   $w.f1.token -height 3 -width 70 -borderwidth 2 -relief sunken -setgrid true 
	grid   $w.f1.token -row 0 -rowspan 2 -column 1 -sticky nsew

#	# Create a button to read the contents of the text widget
#	ttk::button $w.f1.printToken -text "print" -command { puts $::cybershuttle::token }
#	grid   $w.f1.printToken -row 2 -column 0 -sticky nsew
	
	
    ttk::labelframe $w.f2 -text "Simulation files" -relief groove
    grid   $w.f2 -row 1 -column 0 -sticky nsew -padx 5 -pady 5 
	
		# Current window/frame
		set wc $w.f2
		
		set item 0 ; set row 0 
		ttk::label  $wc.l$row -text "Configuration"
		set text ".conf autofils"
		ttk::entry  $wc.e$row -textvariable $text -width 15
		$wc.e$row insert 0 $text
		ttk::button $wc.b$row -text "Browse" -command "cybershuttle::set_config $wc $wc.e$item"

		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Topology"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_psf $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::label  $wc.l$item -text "Structure"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_structure $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Coordinates"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_coordinates $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	


		incr item ; incr row
		ttk::label  $wc.l$item -text "Velocities"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_velocities $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Extended"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_extended $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

		incr item ; incr row
		ttk::label  $wc.l$item -text "Restraints"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_restraints $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	

		incr item
		ttk::label  $wc.l$item -text "Parameters"
		ttk::entry  $wc.e$item  -width 15
		ttk::button $wc.b$item -text "Browse" -command "cybershuttle::set_parameters $wc $wc.e$item"
	
		grid $wc.l$item -row $row -column 3 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 4 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	





    ttk::labelframe $w.f3 -text "New experiment" -relief groove
    grid   $w.f3 -row 2 -column 0 -sticky nsew -padx 5 -pady 5 
	
		# Current window/frame
		set wc $w.f3
		
		set item 0
		ttk::label  $wc.l$item -text "Project"
		ttk::button $wc.b$item -text "Replace by dropdown menu"
	
		grid $wc.l$item -row $row -column 0 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 1 -sticky nsew -padx 5 -pady 5 	
		
		incr item
		ttk::label  $wc.l$item -text "Name"
		ttk::entry  $wc.e$item 
	
		grid $wc.l$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 3 -columnspan 5 -sticky nsew -padx 5 -pady 5 	

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
		ttk::button $wc.b$item -text "Submit"
		grid $wc.b$item -row $row -column 5 -sticky nsew -padx 5 -pady 5 	

}




source CyberShuttle_functions.tcl
cybershuttle::main
