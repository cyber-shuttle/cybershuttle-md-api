#!/usr/bin/env tclsh

package require Tk
package require Ttk

proc create_ui {} {
    wm title . "File Browser"

    frame .frame 
    pack .frame -expand yes -fill both

    ttk::treeview .frame.tree -columns {name size date} -show headings
    pack .frame.tree -expand yes -fill both

    # Define column headings
    .frame.tree heading name -text "Name"
    .frame.tree heading size -text "Size"
    .frame.tree heading date -text "Date Modified"

    # Define column properties
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

    # Add some sample data
    .frame.tree insert "" end -id 1 -values {"file1.txt" "15 KB" "2024-06-01"}
    .frame.tree insert "" end -id 2 -values {"file2.txt" "22 KB" "2024-06-02"}
    .frame.tree insert "" end -id 3 -values {"file3.txt" "10 KB" "2024-06-03"}

    # Load files from a directory
    load_directory .
}

proc load_directory {dir} {
    set directory [glob -directory $dir *]
    foreach file $directory {
        if {[file isdirectory $file]} {
            continue
        }
        set name [file tail $file]
        set size [file size $file]
        set modtime [file mtime $file]
        set date [clock format $modtime -format "%Y-%m-%d %H:%M"]
        .frame.tree insert "" end -values [list $name [format_size $size] $date]
    }
}

proc format_size {size} {
    if {$size < 1024} {
        return "$size B"
    } elseif {$size < 1024*1024} {
        return "[expr {$size / 1024.0}] KB"
    } else {
        return "[expr {$size / (1024.0*1024)}] MB"
    }
}

create_ui

