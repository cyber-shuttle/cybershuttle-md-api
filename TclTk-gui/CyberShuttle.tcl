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


set myDict2 {
    item1 "Detail 1" "bla"
    item2 "Detail 2" "blabla"
    item3 "Detail 3" "bla"
    item4 "Detail 4" "blablabla"
    item5 "Detail 5" "blablablabla"
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
	#set cybershuttle_path [file dirname [file normalize [info script]]]
	#source [file join $cybershuttle_path Forest-ttk-theme forest-light.tcl ]
        # Import the tcl file
        if { [ lsearch [ttk::themes] forest-light] > 0 } {
            source [ file join $env(CYBERSHUTTLEDIR) Forest-ttk-theme forest-light.tcl ]
            # Set theme using the theme use method
            ttk::style theme use forest-light
        }

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
	
	####################################################################
	# Experiments Treeview
	####################################################################
    ttk::labelframe $w.f2 -text "Experiments" -relief groove
    grid   $w.f2 -row 1 -column 0 -columnspan 2 -sticky nsew -padx 5 -pady 5 
    
    ttk::treeview $w.f2.tree -columns {status name description id url} -show headings -height 4
    grid $w.f2.tree -row 0 -column 0 -sticky nsew

    # Define column headings for the second treeview
    $w.f2.tree heading status 		-text "Status"
    $w.f2.tree heading name   		-text "Name"
    $w.f2.tree heading description 	-text "Description"
    $w.f2.tree heading id 			-text "id"
    $w.f2.tree heading url 			-text "url"
    
    # Define column properties for the second treeview
    $w.f2.tree column status 		-width 100 -anchor w
    $w.f2.tree column name   		-width 200 -anchor w
    $w.f2.tree column description 	-width 200 -anchor w
	$w.f2.tree column id 			-width 100  -anchor w
	$w.f2.tree column url 			-width 0  -anchor w

    # Add scrollbars for the second treeview
    ttk::scrollbar $w.f2.yscroll2 -orient vertical   -command "$w.f2.tree yview"
    ttk::scrollbar $w.f2.xscroll2 -orient horizontal -command "$w.f2.tree xview"
    $w.f2.tree configure -yscroll "$w.f2.yscroll2 set" -xscroll "$w.f2.xscroll2 set"
    grid $w.f2.yscroll2 -row 0 -column 1 -sticky ns
    grid $w.f2.xscroll2 -row 1 -column 0 -sticky ew

    # Bind the selection event to a procedure
    bind $w.f2.tree <<TreeviewSelect>> {cybershuttle::show_selected_experiment}

	####################################################################
	# Experiments Actions
	####################################################################
    ttk::labelframe $w.f3 -text "Experiment Actions" -relief groove
    grid $w.f3 -row 2 -column 0 -columnspan 2 -sticky nsew -padx 5 -pady 5

    # Button to update the experiments treeview
    #ttk::button $w.f3.updateBtn -text "List Experiments" -command [list cybershuttle::update_experiments ]
    ttk::button $w.f3.updateBtn -text "List Experiments" -command [list cybershuttle::listExperiments ]
    grid $w.f3.updateBtn -row 0 -column 0 -pady 5

    # Button to Download the selected experiment from the treeview
    #ttk::button $w.f3.downloadBtn -text "Download Selected" -command [list cybershuttle::download_experiment ]
    ttk::button $w.f3.downloadBtn -text "Download Selected" -command [list cybershuttle::select_download_directory ]
    grid $w.f3.downloadBtn -row 0 -column 1 -pady 5

    # Button to Download the selected experiment from the treeview
    ttk::button $w.f3.cybershuttledBtn -text "Show in Gateway" -command {cybershuttle::invokeBrowser "$cybershuttle::experimentURL"}
    grid $w.f3.cybershuttledBtn -row 0 -column 2 -pady 5

    # Button to Download the selected experiment from the treeview
    ttk::button $w.f3.listBtn -text "List files" -command [list cybershuttle::listFiles ]
    grid $w.f3.listBtn -row 0 -column 3 -pady 5

    # Button to Download the selected experiment from the treeview
    ttk::button $w.f3.downloadListBtn -text "Download file" -command [list cybershuttle::downloadFile ]
    grid $w.f3.downloadListBtn -row 0 -column 4 -pady 5

    # Statusbar: Label to show the selected item in the second treeview
    ttk::label $w.f3.selectedLbl -text "Selected Item: None"
    grid $w.f3.selectedLbl -row 1 -column 0 -columnspan 4  -sticky w -padx 5 -pady 5
        
    
	####################################################################
	# Experiment files
	####################################################################
	ttk::labelframe $w.f4 -text "Experiment Files" -relief groove
    grid $w.f4 -row 3 -column 0 -columnspan 2 -sticky nsew -padx 5 -pady 5

	ttk::treeview $w.f4.tree -columns {name size url} -show headings -height 4
    grid $w.f4.tree -row 0 -column 0 -sticky nsew

    # Define column headings for the second treeview
    $w.f4.tree heading name   		-text "Name"
    $w.f4.tree heading size   		-text "Size"
    $w.f4.tree heading url 			-text "url"
    
    # Define column properties for the second treeview
    $w.f4.tree column name   		-width 200 -anchor w
    $w.f4.tree column size   		-width 200 -anchor w
    $w.f4.tree column url 			-width 200 -anchor w

    # Add scrollbars for the second treeview
    ttk::scrollbar $w.f4.yscroll2 -orient vertical   -command "$w.f4.tree yview"
    ttk::scrollbar $w.f4.xscroll2 -orient horizontal -command "$w.f4.tree xview"
    $w.f4.tree configure -yscroll "$w.f4.yscroll2 set" -xscroll "$w.f4.xscroll2 set"
    grid $w.f4.yscroll2 -row 0 -column 1 -sticky ns
    grid $w.f4.xscroll2 -row 1 -column 0 -sticky ew

    # Bind the selection event to a procedure
    #bind $w.f4.tree <<TreeviewSelect>> {cybershuttle::show_selected_file}

	####################################################################
	# VMD interaction
	####################################################################
    ttk::labelframe $w.f5 -text "Load on VMD" -relief groove
    grid $w.f5 -row 4 -column 0 -columnspan 2 -sticky nsew -padx 5 -pady 5

	# Create labels for dropdown menus
	ttk::label  $w.f5.label1 -text "Topology:"
	ttk::label  $w.f5.label2 -text "Coord/Traj:"
	ttk::label  $w.f5.label3 -text "out/log:"

    # Grid layout for labels
	grid $w.f5.label1 -row 0 -column 0 -sticky "w" -padx 5 -pady 5
	grid $w.f5.label2 -row 0 -column 1 -sticky "w" -padx 5 -pady 5
	grid $w.f5.label3 -row 0 -column 2 -sticky "w" -padx 5 -pady 5

	# Create dropdown menus
	ttk::combobox $w.f5.psf_menu  -values $cybershuttle::psf_files  -width 20 -textvariable cybershuttle::selected_psf_file
	ttk::combobox $w.f5.traj_menu -values $cybershuttle::traj_files -width 20 -textvariable cybershuttle::selected_traj_file
	ttk::combobox $w.f5.out_menu  -values $cybershuttle::out_files  -width 20 -textvariable cybershuttle::selected_out_file
	
	# Grid layout for dropdown menus
	grid $w.f5.psf_menu  -row 1 -column 0 -sticky "w" -padx 5 -pady 5
	grid $w.f5.traj_menu -row 1 -column 1 -sticky "w" -padx 5 -pady 5
	grid $w.f5.out_menu  -row 1 -column 2 -sticky "w" -padx 5 -pady 5

	# TEMPORARY:
	# Create labels to display selected files
	ttk::label $w.f5.selected_psf_file_label  -text ""
	ttk::label $w.f5.selected_traj_file_label -text ""
	ttk::label $w.f5.selected_out_file_label  -text ""

	# Grid layout for selected file labels
	grid $w.f5.selected_psf_file_label  -row 2 -column 0 -sticky "w" -padx 5 -pady 5
	grid $w.f5.selected_traj_file_label -row 2 -column 1 -sticky "w" -padx 5 -pady 5
	grid $w.f5.selected_out_file_label  -row 2 -column 2 -sticky "w" -padx 5 -pady 5
    
	# Bind selection events to update labels
	bind $w.f5.psf_menu  <<ComboboxSelected>> { cybershuttle::update_selected_file_labels }
	bind $w.f5.traj_menu <<ComboboxSelected>> { cybershuttle::update_selected_file_labels }
	bind $w.f5.out_menu  <<ComboboxSelected>> { cybershuttle::update_selected_file_labels }

	ttk::button $w.f5.btn1   -text "Load" -command cybershuttle::load_in_vmd
	grid $w.f5.btn1   -row 1 -column 3 -sticky "w" -padx 5 -pady 5






    ttk::labelframe $w.f6 -text "Load ONLY selection" -relief groove
    grid   $w.f6 -row 5 -column 0 -sticky nsew -padx 5 -pady 5 
		# Current window/frame
		set wc $w.f6
		
		set item 0 ; set row 0
		ttk::label  $wc.l$item -text "Selection"
		ttk::entry  $wc.e$item  -width 60
		ttk::button $wc.b$item -text "Load"
		
		grid $wc.l$item -row $row -column 2 -sticky nsew -padx 5 -pady 5 	
		grid $wc.e$item -row $row -column 3 -columnspan 5 -sticky nsew -padx 5 -pady 5 	
		grid $wc.b$item -row $row -column 9 -sticky nsew -padx 5 -pady 5 	


}



# Function to update selected file labels
proc cybershuttle::update_selected_file_labels {} {
    variable selected_psf_file
    variable selected_traj_file
    variable selected_out_file
    
    # Check if a variable is assigned
	if {[info exists selected_psf_file]} {
		set psf_file $selected_psf_file
		.cybershuttle.f5.selected_psf_file_label config -text "Topology: $psf_file"
	}
	
	if {[info exists selected_traj_file]} {
		set traj_file $selected_traj_file
		.cybershuttle.f5.selected_traj_file_label config -text "Coord/Traj: $traj_file"
	}
	
	if {[info exists selected_out_file]} {
		set out_file $selected_out_file
		.cybershuttle.f5.selected_out_file_label config -text "Out/Log File: $out_file"
	}
    
}


proc cybershuttle::listFiles {} {
	variable token
	variable experimentId
	variable experimentFiles
	variable experimentFileNames
	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttle.org/api/experiment-storage/${experimentId}/"
	set httpreq [http::geturl $url -timeout 30000 -headers $headers]
	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https

	puts $status
	puts $answer
	
	
	# Clear the second treeview
    .cybershuttle.f4.tree  delete [.cybershuttle.f4.tree children {}]
	
	if { ($status == "ok") && ( [ regexp {failed} $answer ] == 0 ) } {
		# Parse the JSON data
		set jsonDict [json::json2dict $answer]

		# We're only interested in "results"
		set files [dict get $jsonDict files]

		# Save to namespace
		set experimentFiles $files
		
		set experimentFileNames [list]
		
		# Available keys
		#experimentId projectId gatewayId creationTime userName name description executionId resourceHostId experimentStatus statusUpdateTime url project userHasWriteAccess

		foreach f $files {
			set n  [dict get $f name]
			set s  [dict get $f size]
			set u  [dict get $f downloadURL]
			.cybershuttle.f4.tree insert "" end -values [list $n $s $u]
			lappend experimentFileNames $n
		}
		puts "####\nFilenames: ${experimentFileNames}\n###"
		
		cybershuttle::update_dropdown
		
	} else { tk_messageBox -title "Expired Token" -icon error -message "Your CyberShuttle Token is expired. Please get a new one and try again." }
	
}

proc cybershuttle::listExperiments {} {
	variable token
	variable experiments

	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttle.org/api/experiment-search/?limit=100&offset=0"
	set httpreq [http::geturl $url -timeout 30000 -headers $headers]
	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https

	puts $status
	puts $answer
	
	# Clear the second treeview
    .cybershuttle.f2.tree  delete [.cybershuttle.f2.tree children {}]

	if { ($status == "ok") && ( [ regexp {failed} $answer ] == 0 ) } {
		# Parse the JSON data
		set jsonDict [json::json2dict $answer]

		# We're only interested in "results"
		set results [dict get $jsonDict results]

		# Save to namespace
		set experiments $results
		
		# Available keys
		#experimentId projectId gatewayId creationTime userName name description executionId resourceHostId experimentStatus statusUpdateTime url project userHasWriteAccess

		foreach result $results {
			#foreach k [ list experimentStatus name description ] {
				#puts "$k [dict get $result $k]"		
			#}
			set s  [dict get $result experimentStatus]
			set n  [dict get $result name]
			set d  [dict get $result description]
			set id [dict get $result experimentId]
			set u  [dict get $result url]
			.cybershuttle.f2.tree insert "" end -values [list $s $n $d $id $u]
		}
	} else { tk_messageBox -title "Expired Token" -icon error -message "Your CyberShuttle Token is expired. Please get a new one and try again." }
}

proc listProjects {token} {
    #!/usr/bin/tclsh

    package require http
    package require tls
    package require json

    # Define your headers with the token
    set headers [list Authorization "Bearer $token"]

    # This is your code, cut-n-pasted with blank lines removed
    http::register https 443 tls::socket
    set url "https://md.cybershuttle.org/api/projects/"
    set httpreq [http::geturl $url -timeout 30000 -headers $headers]
    set status [http::status $httpreq]
    set answer [http::data $httpreq]
    http::cleanup $httpreq
    http::unregister https

    puts $status
    puts $answer

    # Parse the JSON data
    set jsonDict [json::json2dict $answer]

    # We're only interested in "results"
    # set results [dict get $jsonDict results]
    return [dict get $jsonDict results]
}

# Multi-platform solution from http://wiki.tcl.tk/557
proc cybershuttle::invokeBrowser {url} {
  # open is the OS X equivalent to xdg-open on Linux, start is used on Windows
  set commands {xdg-open open start}
  foreach browser $commands {
    if {$browser eq "start"} {
      set command [list {*}[auto_execok start] {}]
    } else {
      set command [auto_execok $browser]
    }
    if {[string length $command]} {
      break
    }
  }
    
  if {[string length $command] == 0} {
    return -code error "couldn't find browser"
  }
  if {[catch {exec {*}$command $url &} error]} {
    return -code error "couldn't execute '$command': $error"
  } 
}   


# Function to read the contents of the text widget
proc cybershuttle::readToken {} {
    set cybershuttle::token [ .cybershuttle.f1.token get 1.0 end ]
    puts "Contents of the text field:\n${::cybershuttle::token}"
    
}




proc cybershuttle::populate_experiments {} {
    global myDict2
    foreach {item detail} $myDict2 {
        .cybershuttle.f2.tree insert "" end -values [list $item $detail]
    }
}

proc cybershuttle::update_experiments {} {
    global myDict2
    # Clear the second treeview
    .cybershuttle.f2.tree  delete [.cybershuttle.f2.tree children {}]

    # Update the second dictionary with new data
    set myDict2 {
        item1 "Updated Detail 1"
        item2 "Updated Detail 2"
        item3 "Updated Detail 3"
        item4 "Updated Detail 4"
        item5 "Updated Detail 5"
        item6 "Additional Detail"
    }

    # Repopulate the second treeview with updated dictionary data
    cybershuttle::populate_experiments
}

proc cybershuttle::show_selected_experiment {} {
	variable experimentURL
	variable experimentId
	
	# Replace this crap by dictionary with all about an experiment.
	
    set selectedItem [.cybershuttle.f2.tree selection]

    if {[llength $selectedItem] > 0} {
        set itemId [lindex $selectedItem 0]
        set itemValues [.cybershuttle.f2.tree item $itemId -values]
        set status [lindex $itemValues 0]
        set name [lindex $itemValues 1]
        set detail [lindex $itemValues 2]
        set experimentId [lindex $itemValues 3]
        set experimentURL [string map {api workspace} [lindex $itemValues 4] ]
        
        .cybershuttle.f3.selectedLbl configure -text "Selected: $name"
    } else {
        .cybershuttle.f3.selectedLbl configure -text "Selected: None"
    }
}

proc cybershuttle::select_download_directory {} {   
    set dir [tk_chooseDirectory -title "Select Download Destination"]
    if {$dir != ""} {
        puts "Selected directory: $dir"
        cybershuttle::download_experiment $dir
    }
}

proc cybershuttle::download_experiment {dir} {
    variable experiments

	puts "Launching script in directory: $dir"

    # Add your script execution code here
    set selectedItem [.cybershuttle.f2.tree selection]

    if {[llength $selectedItem] > 0} {
        set itemId [lindex $selectedItem 0]
        set itemValues [.cybershuttle.f2.tree item $itemId -values]
        set experimentId [lindex $itemValues 3]        
		set url "https://md.cybershuttle.org/sdk/download-experiment-dir/${experimentId}/"
		cybershuttle::rundownloadFile $dir $url "${experimentId}.zip"
		puts "
# Downloading url: 
$url
# to:
$dir/${experimentId}.zip"
	}
}


proc cybershuttle::downloadFile {} {   
	set dir [tk_chooseDirectory -title "Select Download Destination"]
    if {$dir != ""} {
        puts "Selected directory: $dir"
        # Add your script execution code here
	    set selectedItem [.cybershuttle.f4.tree selection]

    	if {[llength $selectedItem] > 0} {
        	set itemId [lindex $selectedItem 0]
        	set itemValues [.cybershuttle.f4.tree item $itemId -values]
        	set name [lindex $itemValues 0]        
			# set url [lindex $itemValues 2]
			set url [string map {download download-file} [lindex $itemValues 2] ]        
			cybershuttle::rundownloadFile $dir $url $name
			puts "
# Downloading url: 
$url
# to:
${dir}/${name}"
	}

	}
}


proc cybershuttle::rundownloadFile {dir url filename} {
	variable token
	set f [open [ file join $dir $filename ] wb]

	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket

	# Request download
	set httpreq [http::geturl $url -timeout 30000 -headers $headers -channel $f -binary 1]

	if {[http::status $httpreq] eq "ok" && [http::ncode $httpreq] == 200} {
		puts "Downloaded successfully"
	}

	http::cleanup $httpreq
	http::unregister https
	close $f		
}



# Convert to MB
proc toMB {n} {
    return [expr {$n / (1024*1024)}]
}


proc cybershuttle::update_dropdown {} {
	#variable psf_files
    #variable traj_files
    #variable out_files
    variable experimentFileNames
    
	#set psf_files  [cybershuttle::filter_files "${experimentFileNames}" [list .psf ]]
	#set traj_files [cybershuttle::filter_files "${experimentFileNames}" [list .pdb .coor .dcd] ]
	#set out_files  [cybershuttle::filter_files "${experimentFileNames}" [list .out .log ]]
	
	# Create dropdown menus
	.cybershuttle.f5.psf_menu  configure -values [cybershuttle::filter_files "${experimentFileNames}" [list .psf ]]
	.cybershuttle.f5.traj_menu configure -values [cybershuttle::filter_files "${experimentFileNames}" [list .pdb .coor .dcd] ]
	.cybershuttle.f5.out_menu  configure -values [cybershuttle::filter_files "${experimentFileNames}" [list .out .log .stdout ]]
	
}

# Function to filter files by extension
proc cybershuttle::filter_files {file_list extension} {
    set filtered_files {}
    foreach file $file_list {
		foreach ext $extension {
            if {[file extension $file] eq $ext} {
                lappend filtered_files $file
            }
        }
    }
    return $filtered_files
}

proc cybershuttle::load_in_vmd {} {
	variable selected_psf_file
    variable selected_traj_file

	set file_url {}
	foreach f $cybershuttle::experimentFiles { 
	    dict set file_url [dict get $f name] [dict get $f downloadURL]
	}

	set url_psf    [ dict get $file_url $cybershuttle::selected_psf_file ]
	set url_traj   [ dict get $file_url $cybershuttle::selected_traj_file ]

    # BugFix
	set url_psf  [string map {download download-file} $url_psf  ]
	set url_traj [string map {download download-file} $url_traj  ]

    set tmpdir "/tmp"

	# Download Topology (PSF)
	cybershuttle::rundownloadFile $tmpdir $url_psf [file join $cybershuttle::selected_psf_file] 
	
	# Download Coordinates/Trajectory (.PDB,.COOR,.DCD)
	cybershuttle::rundownloadFile $tmpdir $url_traj [file join $cybershuttle::selected_traj_file] 

	# Load on VMD
    set psf  [file join $tmpdir $cybershuttle::selected_psf_file ]
	set traj [file join $tmpdir $cybershuttle::selected_traj_file ]
    mol new $psf
	mol addfile $traj waitfor all
  mol modselect 0 0 protein
 mol modstyle 0 0 NewCartoon 0.300000 10.000000 4.100000 0
 mol modcolor 0 0 Structure
 mol color Structure
 mol representation NewCartoon 0.300000 10.000000 4.100000 0
 mol selection protein
 mol material Opaque
 mol addrep 0
 mol modselect 1 0 water oxygen
 mol modcolor 1 0 Name
 color Display Background white
 mol modstyle 1 0 Points 2.000000


}


proc test {} {
	# Go to https://md.cybershuttle.org/auth/login-desktop/?show-code=true
	set token "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJzX0dPcDFvM1p6U19ncVZjN1U3M1BNbThsMmxKbmZLRDg1N29tV2RaX0U4In0.eyJqdGkiOiI2NzgyNjA0OC04NWUwLTQ5ZDgtOTcyYi1kOTE3MjZkMGJmN2UiLCJleHAiOjE3MTc0NjIwNzUsIm5iZiI6MCwiaWF0IjoxNzE3NDYwMjc1LCJpc3MiOiJodHRwczovL2lhbS5zY2lnYXAub3JnL2F1dGgvcmVhbG1zL21vbGVjdWxhci1keW5hbWljcyIsImF1ZCI6InBnYSIsInN1YiI6IjZmZDI1MWFlLWUzMGUtNGI4Yi1hOTNlLWQyNjExNDM2NzIzYSIsInR5cCI6IkJlYXJlciIsImF6cCI6InBnYSIsImF1dGhfdGltZSI6MTcxNzQ2MDI3NSwic2Vzc2lvbl9zdGF0ZSI6ImI4MzhhMjUxLTYwYmUtNDcyYy1hODhmLTdiMzJhNGUwMThmYiIsImFjciI6IjEiLCJjbGllbnRfc2Vzc2lvbiI6ImI3OWU2NDFiLTQwYmYtNDBlNi1iZWMxLWM2YzFlNWFkYzYxOSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL21kLmN5YmVyc2h1dHRsZS5vcmciXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYnJva2VyIjp7InJvbGVzIjpbInJlYWQtdG9rZW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJ2aWV3LXByb2ZpbGUiXX19LCJuYW1lIjoiRGllZ28gQmFycmV0byBHb21lcyIsInByZWZlcnJlZF91c2VybmFtZSI6ImRlYjAwNTRAYXVidXJuLmVkdSIsImdpdmVuX25hbWUiOiJEaWVnbyIsImZhbWlseV9uYW1lIjoiQmFycmV0byBHb21lcyIsImVtYWlsIjoiZGViMDA1NEBhdWJ1cm4uZWR1In0.QpLvPhuww9dCFiQYnw2Fm8kM-wMw_LPqKbRwJLkCvb-a6QRLiA_nb8i-4iXMyP8Uqb1T-rFnKp-Net53vXOe_bIqGNSZ2AY9nmNR5t7GGbPVarehp2OIgPchGXGgSZwuz25SPL0aTEzOxtFINPU1qeGE21App2sBAzUDc8zgkLeqjd_FKUpxDT4xjSRhbSvqFaGSoEH0y1VQHBkSTVOlR8jhksRLBE9TVfgQu9yvRPU0AUcYxx4TXPbQ0clgvx55SG9BYNATDpnDrWyykMK5Xip-ZMccTejb56iR_pEarx2Eh0_oUvlSnRIwhtKSZdinYlfhO1CDitl554jaohF_dg"

	set projects [listProjects $token]
	 
	foreach p $projects {
		set out "Result: $p "
		foreach k [dict keys $p ] {
			lappend out "$k [dict get $p $k]" 
		}
		puts $out
	}
}


#cybershuttle::main

proc cybershuttle_tk {} {
  cybershuttle::main
  return $cybershuttle::w
}
