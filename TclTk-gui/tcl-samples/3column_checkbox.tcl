#!/usr/bin/env tclsh

package require Tk
package require Ttk

# Global variable to store the states of checkbuttons
array set checkStates {}

proc create_ui {} {
    wm title . "File Browser with Checkboxes"

    frame .frame
    pack .frame -expand yes -fill both

    ttk::treeview .frame.tree -columns {check name size date} -show headings
    pack .frame.tree -expand yes -fill both

    # Define column headings
    .frame.tree heading check -text "Sel"
    .frame.tree heading name -text "Name"
    .frame.tree heading size -text "Size"
    .frame.tree heading date -text "Date Modified"

    # Define column properties
    .frame.tree column check -width 30 -minwidth 30 -stretch no
    .frame.tree column name -width 200
    .frame.tree column size -width 100
    .frame.tree column date -width 150

    # Add scrollbars
    ttk::scrollbar .frame.yscroll -orient vertical -command ".frame.tree yview"
    ttk::scrollbar .frame.xscroll -orient horizontal -command ".frame.tree xview"
    .frame.tree configure -yscroll ".frame.yscroll set" -xscroll ".frame.xscroll set"
    grid .frame.tree -row 0 -column 0 -sticky nsew
    grid .frame.yscroll -row 0 -column 1 -sticky ns
    grid .frame.xscroll -row 1 -column 0 -sticky ew

    grid rowconfigure .frame 0 -weight 1
    grid columnconfigure .frame 0 -weight 1

    # Load files from a directory
    load_directory .
}

proc load_directory {dir} {
    global checkStates
    set directory [glob -directory $dir *]
    foreach file $directory {
        if {[file isdirectory $file]} {
            continue
        }
        set name [file tail $file]
        set size [file size $file]
        set modtime [file mtime $file]
        set date [clock format $modtime -format "%Y-%m-%d %H:%M"]
        
        # Generate a unique ID for the file entry
        set fileID [string range [md5::md5 -hex $file] 0 7]
        
        # Initialize the checkbutton state variable
        set checkStates($fileID) 0
        
        # Insert the file information into the treeview
        .frame.tree insert "" end -id $fileID -values [list $fileID $name [format_size $size] $date]
    }

    # After populating the treeview, add checkbuttons
    #add_checkbuttons
}

#proc add_checkbuttons {} {
#    global checkStates
#    foreach item [.frame.tree children {}] {
#        set id [.frame.tree item $item -values 0]
#        ttk::checkbutton .frame.tree.cb_${id} -variable checkStates($id) -width 0 -style Toolbutton
#        .frame.tree configure $item -column 0 -window .frame.tree.cb_$id
#    }
#}

proc format_size {size} {
    if {$size < 1024} {
        return "$size B"
    } elseif {$size < 1024*1024} {
        return "[expr {$size / 1024.0}] KB"
    } else {
        return "[expr {$size / (1024.0*1024)}] MB"
    }
}

# Load the required package for MD5 hashing
package require md5

create_ui

