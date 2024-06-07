

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


proc cybershuttle::set_config {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Configuration" -filetypes {{NAMD .conf} {NAMD .namd}}
}

proc cybershuttle::set_psf {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Topology" -filetypes {{Topology .psf}}
}

proc cybershuttle::set_structure {parent field} {
	set $field %f
	tk_getOpenFile -parent $wc -initialdir [pwd] -title "Structure" -filetypes {{Structure (PDB)} {.pdb}}
}

proc cybershuttle::set_velocities {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Coordinates" -filetypes {{Coordinates (.coor/.pdb)} {.coor .pdb}}
}

proc cybershuttle::set_velocities {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Velocities" -filetypes {{Velocities (.vel)} {.vel}}
}

proc cybershuttle::set_extended {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Extended" -filetypes {{Extended (.xsc)} {.xsc}}
}		

proc cybershuttle::set_extended {parent field} {
	set $field %f
	tk_getOpenFile -parent $parent -initialdir [pwd] -title "Restraints" -filetypes {{Restraints (.pdb)} {.pdb}}
}		



set types {
	{{NAMD configuration} {.conf .namd}}
	{{Topology (PSF)} {.psf}}
	{{Structure (PDB)} {.pdb}}
	{{Coordinates (.coor/.pdb)} {.coor .pdb}}
	{{Velocities (.vel)} {.vel}}
	{{Extended (.xsc)} {.xsc}}
	{{Restraints (.pdb)} {.pdb}}
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
