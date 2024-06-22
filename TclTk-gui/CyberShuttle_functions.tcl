

# Function to update selected file labels
proc cybershuttlesubmit::update_selected_file_labels {} {
    variable selected_psf_file
    variable selected_traj_file
    variable selected_out_file
    
    # Check if a variable is assigned
	if {[info exists selected_psf_file]} {
		set psf_file $selected_psf_file
		.cybershuttlesubmit.f5.selected_psf_file_label config -text "Topology: $psf_file"
	}
	
	if {[info exists selected_traj_file]} {
		set traj_file $selected_traj_file
		.cybershuttlesubmit.f5.selected_traj_file_label config -text "Coord/Traj: $traj_file"
	}
	
	if {[info exists selected_out_file]} {
		set out_file $selected_out_file
		.cybershuttlesubmit.f5.selected_out_file_label config -text "Out/Log File: $out_file"
	}
    
}

proc cybershuttlesubmit::listFiles {} {
	variable token
	variable experimentId
	variable experimentFiles
	variable experimentFileNames
	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttlesubmit.org/api/experiment-storage/${experimentId}/"
	set httpreq [http::geturl $url -timeout 30000 -headers $headers]
	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https

	puts $status
	puts $answer
	
	
	# Clear the second treeview
    .cybershuttlesubmit.f4.tree  delete [.cybershuttlesubmit.f4.tree children {}]
	
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
			.cybershuttlesubmit.f4.tree insert "" end -values [list $n $s $u]
			lappend experimentFileNames $n
		}
		puts "####\nFilenames: ${experimentFileNames}\n###"
		
		cybershuttlesubmit::update_dropdown
		
	} else { tk_messageBox -title "Expired Token" -icon error -message "Your CyberShuttle Token is expired. Please get a new one and try again." }
	
}

proc cybershuttlesubmit::listExperiments {} {
	variable token
	variable experiments

	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttlesubmit.org/api/experiment-search/?limit=100&offset=0"
	set httpreq [http::geturl $url -timeout 30000 -headers $headers]
	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https

	puts $status
	puts $answer
	
	# Clear the second treeview
    .cybershuttlesubmit.f2.tree  delete [.cybershuttlesubmit.f2.tree children {}]

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
			.cybershuttlesubmit.f2.tree insert "" end -values [list $s $n $d $id $u]
		}
	} else { tk_messageBox -title "Expired Token" -icon error -message "Your CyberShuttle Token is expired. Please get a new one and try again." }
}

proc cybershuttlesubmit::listProjects {} {
	variable projects
	variable token
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

	puts $jsonDict
	set results  [dict get $jsonDict results]
	set projects [ dict create ]

	foreach r $results {
	  set name [dict get $r name] 
	  set projectID [dict get $r projectID]
	  puts "$name $projectID"
	  dict set projects $name $projectID
	}

	# Print the dictionary
	set cybershuttlesubmit::projects $projects
	
	# Update Combobox
	.cybershuttlesubmit.f3.c1  configure -values [dict keys $projects]
}

# Multi-platform solution from http://wiki.tcl.tk/557
proc cybershuttlesubmit::invokeBrowser {url} {
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
proc cybershuttlesubmit::readToken {} {
    set cybershuttlesubmit::token [ .cybershuttlesubmit.f1.token get 1.0 end ]
    puts "Contents of the text field:\n${::cybershuttlesubmit::token}"
    
}




proc cybershuttlesubmit::populate_experiments {} {
    global myDict2
    foreach {item detail} $myDict2 {
        .cybershuttlesubmit.f2.tree insert "" end -values [list $item $detail]
    }
}

proc cybershuttlesubmit::update_experiments {} {
    global myDict2
    # Clear the second treeview
    .cybershuttlesubmit.f2.tree  delete [.cybershuttlesubmit.f2.tree children {}]

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
    cybershuttlesubmit::populate_experiments
}

proc cybershuttlesubmit::show_selected_experiment {} {
	variable experimentURL
	variable experimentId
	
	# Replace this crap by dictionary with all about an experiment.
	
    set selectedItem [.cybershuttlesubmit.f2.tree selection]

    if {[llength $selectedItem] > 0} {
        set itemId [lindex $selectedItem 0]
        set itemValues [.cybershuttlesubmit.f2.tree item $itemId -values]
        set status [lindex $itemValues 0]
        set name [lindex $itemValues 1]
        set detail [lindex $itemValues 2]
        set experimentId [lindex $itemValues 3]
        set experimentURL [string map {api workspace} [lindex $itemValues 4] ]
        
        .cybershuttlesubmit.f3.selectedLbl configure -text "Selected: $name"
    } else {
        .cybershuttlesubmit.f3.selectedLbl configure -text "Selected: None"
    }
}

proc cybershuttlesubmit::select_download_directory {} {   
    set dir [tk_chooseDirectory -title "Select Download Destination"]
    if {$dir != ""} {
        puts "Selected directory: $dir"
        cybershuttlesubmit::download_experiment $dir
    }
}

proc cybershuttlesubmit::download_experiment {dir} {
    variable experiments

	puts "Launching script in directory: $dir"

    # Add your script execution code here
    set selectedItem [.cybershuttlesubmit.f2.tree selection]

    if {[llength $selectedItem] > 0} {
        set itemId [lindex $selectedItem 0]
        set itemValues [.cybershuttlesubmit.f2.tree item $itemId -values]
        set experimentId [lindex $itemValues 3]        
		set url "https://md.cybershuttlesubmit.org/sdk/download-experiment-dir/${experimentId}/"
		cybershuttlesubmit::rundownloadFile $dir $url "${experimentId}.zip"
		puts "
# Downloading url: 
$url
# to:
$dir/${experimentId}.zip"
	}
}


proc cybershuttlesubmit::downloadFile {} {   
	set dir [tk_chooseDirectory -title "Select Download Destination"]
    if {$dir != ""} {
        puts "Selected directory: $dir"
        # Add your script execution code here
	    set selectedItem [.cybershuttlesubmit.f4.tree selection]

    	if {[llength $selectedItem] > 0} {
        	set itemId [lindex $selectedItem 0]
        	set itemValues [.cybershuttlesubmit.f4.tree item $itemId -values]
        	set name [lindex $itemValues 0]        
			# set url [lindex $itemValues 2]
			set url [string map {download download-file} [lindex $itemValues 2] ]        
			cybershuttlesubmit::rundownloadFile $dir $url $name
			puts "
# Downloading url: 
$url
# to:
${dir}/${name}"
	}

	}
}


proc cybershuttlesubmit::rundownloadFile {dir url filename} {
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


proc cybershuttlesubmit::update_dropdown {} {
	#variable psf_files
    #variable traj_files
    #variable out_files
    variable experimentFileNames
    
	#set psf_files  [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .psf ]]
	#set traj_files [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .pdb .coor .dcd] ]
	#set out_files  [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .out .log ]]
	
	# Create dropdown menus
	.cybershuttlesubmit.f5.psf_menu  configure -values [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .psf ]]
	.cybershuttlesubmit.f5.traj_menu configure -values [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .pdb .coor .dcd] ]
	.cybershuttlesubmit.f5.out_menu  configure -values [cybershuttlesubmit::filter_files "${experimentFileNames}" [list .out .log .stdout ]]
	
}

# Function to filter files by extension
proc cybershuttlesubmit::filter_files {file_list extension} {
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

proc cybershuttlesubmit::load_in_vmd {} {
	variable selected_psf_file
    variable selected_traj_file

	set file_url {}
	foreach f $cybershuttlesubmit::experimentFiles { 
	    dict set file_url [dict get $f name] [dict get $f downloadURL]
	}

	set url_psf    [ dict get $file_url $cybershuttlesubmit::selected_psf_file ]
	set url_traj   [ dict get $file_url $cybershuttlesubmit::selected_traj_file ]

    # BugFix
	set url_psf  [string map {download download-file} $url_psf  ]
	set url_traj [string map {download download-file} $url_traj  ]

    set tmpdir "/tmp"

	# Download Topology (PSF)
	cybershuttlesubmit::rundownloadFile $tmpdir $url_psf [file join $cybershuttlesubmit::selected_psf_file] 
	
	# Download Coordinates/Trajectory (.PDB,.COOR,.DCD)
	cybershuttlesubmit::rundownloadFile $tmpdir $url_traj [file join $cybershuttlesubmit::selected_traj_file] 

	# Load on VMD
    set psf  [file join $tmpdir $cybershuttlesubmit::selected_psf_file ]
	set traj [file join $tmpdir $cybershuttlesubmit::selected_traj_file ]
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

# Define the command to change the text in the entry widget
proc cybershuttlesubmit::changeEntry {} {
    global entry
    $entry delete 0 end
    $entry insert 0 "Button Clicked"
}

proc cybershuttlesubmit::set_config {parent field} {
	variable namdConfig 
	set namdConfig [tk_getOpenFile -parent $parent -initialdir [pwd] -title "Configuration" -filetypes {{NAMD .conf} {NAMD .namd}} ] 
}

proc cybershuttlesubmit::set_psf {parent field} {
	variable namdPSF
	set namdPSF [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Topology" -filetypes {{Topology .psf}} ]	
}

proc cybershuttlesubmit::set_structure {parent field} {
	variable namdPDB
	set namdPDB [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Structure" -filetypes {{Structure .pdb}} ]
}

proc cybershuttlesubmit::set_coordinates {parent field} {
	variable namdCOR
	set namdCOR [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Coordinates" -filetypes {{Coordinates .coor} {Coordinates .pdb}} ]
}

proc cybershuttlesubmit::set_velocities {parent field} {
	variable namdVEL
	set namdVEL [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Velocities" -filetypes {{Velocities .vel}} ]
}

proc cybershuttlesubmit::set_extended {parent field} {
	variable namdXSC
	set namdXSC [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Extended" -filetypes {{Extended .xsc}} ]
}

proc cybershuttlesubmit::set_restraints {parent field} {
	variable namdRES
	set namdRES [ tk_getOpenFile -parent $parent -initialdir [pwd] -title "Restraints" -filetypes {{Restraints .pdb}} ]
}		

proc cybershuttlesubmit::set_parameters {parent field} {
	variable namdPRM
	set namdPRM [ tk_getOpenFile -parent $parent -initialdir [pwd] -multiple true -title "Parameters" -filetypes {{Parameters .prm} {Parameters .str}} ]
}		


### Job submission
# Step 1 - Upload files
proc httpreq {so host sublocation body} {

    # Get the length of the file contents
    set contentSize [string length $body]

    # Print the size of the file contents
    #puts "The size of the file contents is: $contentSize bytes"

    fconfigure $so -translation crlf
    puts $so "PATCH $sublocation HTTP/1.1"
    puts $so "Host: $host"
    puts $so "Connection: close"
    puts $so "Tus-Resumable: 1.0.0"
    puts $so "Upload-Offset: 0"
    puts $so "Accept: */*"
    puts $so "Content-Type: application/offset+octet-stream"
    puts $so "Content-Length: $contentSize"
    puts $so ""
    fconfigure $so -translation binary
    puts $so $body
    fconfigure $so -translation crlf
    puts $so ""
    flush $so
}


proc cybershuttlesubmit::uploadFile {filePath token} {
    set jsonData {{""}}

    set fileId [open "$filePath" r]
    fconfigure $fileId -translation binary
    set body [read $fileId]
    close $fileId

    set contentSize [string length $body]
    set fileName [file tail $filePath]
#   set encodedFileName [base64::encode $fileName]
    set encodedFileName [binary encode base64 $fileName]

    # Define your headers with the token
    set headers [list Authorization "Bearer $token" Tus-Resumable "1.0.0" Content-Length "0" Upload-Length "$contentSize" Upload-Metadata "relativePath bnVsbA==,name $encodedFileName,type dGV4dC9wbGFpbg==,filetype dGV4dC9wbGFpbg==,filename $encodedFileName"]

    # This is your code, cut-n-pasted with blank lines removed
    http::register https 443 tls::socket
    set url "https://tus.airavata.org/files/"
    set httpreq [http::geturl $url -timeout 30000 -headers $headers -type application/json -query $jsonData]
    set respHeaders [http::meta $httpreq]
    http::cleanup $httpreq
    http::unregister https

    # puts $respHeaders

    set location [dict get $respHeaders "Location"]
    #puts $location
    set sublocation [string range $location 24 end]
    #set sublocation [string range $location 21 end]

    #puts $sublocation

    set so [tls::socket tus.airavata.org 443]
    #set so [socket localhost 8080]

    httpreq $so tus.airavata.org $sublocation $body

    #read $so

    set response ""
    while {[gets $so line] >= 0} {
        append response $line
        append response \n
    }
    close $so

    #puts $response

    return $location
}

proc finishUpload {uploadLocation token} {

    set formDataStr "------WebKitFormBoundaryAPtcuHAobNHq7AVv\r\nContent-Disposition: form-data; name=\"uploadURL\"\r\n\r\n$uploadLocation\r\n------WebKitFormBoundaryAPtcuHAobNHq7AVv--\r\n"
    #puts $formDataStr

    # Define your headers with the token
    set headers [list Authorization "Bearer $token" Accept "application/json"]

    # This is your code, cut-n-pasted with blank lines removed
    http::register https 443 tls::socket
    set url "https://md.cybershuttle.org/api/tus-upload-finish"
    set httpreq [http::geturl $url -query $formDataStr -headers $headers -type "multipart/form-data; boundary=----WebKitFormBoundaryAPtcuHAobNHq7AVv"]

    set status [http::status $httpreq]
    set responseData [http::data $httpreq]

    set rheaders [http::meta $httpreq]

    # Print the response headers
    #puts "Response Headers:"
    #puts $rheaders

    #set status_code [http::ncode $httpreq]
    #puts "Status code"
    #puts $status_code

    http::cleanup $httpreq
    http::unregister https

    #puts $status
    #puts $responseData

    return $responseData
}



proc cybershuttlesubmit::submit {} {
	 cybershuttlesubmit::upload_files
	 cybershuttlesubmit::create_experiment
  	 cybershuttlesubmit::launch_experiment
}

proc cybershuttlesubmit::upload_files {} {
	variable token
	variable url_list
	variable namdConfig 
	variable namdPSF
	variable namdPDB
	variable namdCOR
	variable namdVEL
	variable namdXSC 
	variable namdRES
	variable namdPRM
	
	#set directory "/home/dgomes/cybershuttle_demo/SciencePull/replicas/pull"
	#set directory [file join [pwd] pull ] 	
	#set fileList [glob -nocomplain -types f $directory/*]
	set fileList [list $namdConfig $namdPSF $namdPDB $namdCOR $namdVEL $namdXSC $namdRES {*}$namdPRM]

	set url_list {} 
	set jsonfile [open filePaths.json w]

	foreach filePath $fileList {
		set uploadLocation [uploadFile $filePath $token]
		set replicaData [finishUpload $uploadLocation $token]
		puts $jsonfile $replicaData
		lappend url_list $replicaData
		puts "Replica Json: "
		# Keep replicaData. it is the name of each file we upload.
		puts $replicaData
	}
	close $jsonfile
}

proc cybershuttlesubmit::create_experiment {} {
	variable token
	variable namdConfig 
	variable namdOther
        variable experimentName
        variable experimentId

	set namdConfigUrl [list]
	set namdOtherUrl [list]
	
	foreach line $::cybershuttlesubmit::url_list { 
		set jsonDict [json::json2dict $line]
		set uri  [ dict get $jsonDict data-product productUri  ]
		set file [ dict get $jsonDict data-product productName  ]
	
		set extension [file extension $file]
		if {$extension == ".conf" || $extension == ".namd"} {
			lappend namdConfigUrl $uri  
		} else {
			lappend namdOtherUrl $uri
		}

		puts "$file $uri"
	}

	puts "###########################################"
	puts "# CyberShuttle submit file list"
	puts "###########################################"
	puts "File list"
	puts "NAMD Config: $namdConfigUrl"
	set namdOtherUrl [join $namdOtherUrl ","]
	puts "NAMD Other: $namdOtherUrl"


	# Open the JSON file
	set fp [open "create-exp.json.TEMPLATE" r]
	set jsonData [read $fp]
	close $fp

#	set experimentId "VMD submit 3"
	#set resourceHostId "NCSADelta_e75b0d04-8b4b-417b-8ab4-da76bbd835f5"
	set resourceHostId "expanse_34f71d6b-765d-4bff-be2e-30a74f5c8c32"
	set projectId "Demo_1760240a-7c27-4444-90bb-668284d4078f"

	# Replace the words
	set jsonData [string map [list "REPLACE_Execution_Type" "GPU" ] $jsonData ]
	set jsonData [string map [list "REPLACE_projectId" "${projectId}" ] $jsonData ]
	set jsonData [string map [list "REPLACE_experimentName"  "${experimentName}"] $jsonData ]
	set jsonData [string map [list "REPLACE_resourceHostId"  "${resourceHostId}"] $jsonData ]
	set jsonData [string map [list "REPLACE_namdConf"  "${namdConfigUrl}"] $jsonData ]
	set jsonData [string map [list "REPLACE_namdOther"  "${namdOtherUrl}"] $jsonData ]


	# Write the modified data back to the file
	set fp [open "modified.json" w]
	puts $fp $jsonData
	close $fp

	set headers [list Authorization "Bearer $token"]

	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttle.org/api/experiments/"
	set httpreq [http::geturl $url -timeout 30000 -headers $headers -type application/json -query $jsonData]
	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https

	puts $status
	puts $answer

        set jsonDict [json::json2dict $answer]
        set experimentId  [ dict get $jsonDict experimentId  ]
	puts "experimentId ${experimentId} $::cybershuttlesubmit::experimentId"
	
}


proc cybershuttlesubmit::launch_experiment {} {
	variable token
 	variable experimentId
        variable experimentName
	set jsonData {{"name":"GO"}}

	# Define your headers with the token
	set headers [list Authorization "Bearer $token"]
	
	# This is your code, cut-n-pasted with blank lines removed
	http::register https 443 tls::socket
	set url "https://md.cybershuttle.org/api/experiments/${experimentId}/launch/"
        set httpreq [http::geturl $url -timeout 30000 -headers $headers -type application/json -query $jsonData]

	set status [http::status $httpreq]
	set answer [http::data $httpreq]
	http::cleanup $httpreq
	http::unregister https
	
	puts $status
	puts $answer
}



proc confparser {} {
  variable namdConfig 
  variable namdPSF
  variable namdPDB
  variable namdCOR
  variable namdVEL 
  variable namdXSC
  variable namdRES
  variable namdPRM

  set namdPSF ""
  set namdPDB ""
  set namdCOR ""
  set namdVEL ""
  set namdXSC ""
  set namdRES ""
  set namdPRM ""

  # Read the configuration file
  #set filename "pull.conf"
  set file [open $namdConfig]
  set content [read $file]
  close $file

  # Split the content into lines
  set lines [split $content "\n"]

  # Iterate over each line
  foreach line $lines {
    # Skip lines that start with a hash
    if {[string index $line 0] eq "#"} continue
    # Split the line into words
    set words [split $line]
    # Check if the first word is a keyword and store the second word as the value
    switch -- [lindex $words 0] {
        "coordinates" {
            set namdPDB [lindex $words 1]
        }
        "bincoordinates" {
            set namdCOR [lindex $words 1]
        }
        "extendedsystem" {
            set namdXSC [lindex $words 1]
        }
        "binvelocities" {
            set namdVEL [lindex $words 1]
        }
        "structure" {
            set namdPSF [lindex $words 1]
        }
        "parameters" {
            # Since there are multiple 'parameters' lines, append them
            set namdPRM "$namdPRM [lindex $words 1]"
        }
        "conskfile" {
            set namdRES [lindex $words 1]
        }
    }
  }

}




proc test {} {
	# Go to https://md.cybershuttlesubmit.org/auth/login-desktop/?show-code=true
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
