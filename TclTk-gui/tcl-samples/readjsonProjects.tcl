package require json

# Define the path to the JSON file
set jsonFile "projects.json"

# Read the JSON file content
set jsonData ""
set fileId [open $jsonFile r]
set jsonData [read $fileId]
close $fileId

# Parse the JSON data
set jsonDict [json::json2dict $jsonData]

# We're only interested in "results"
set results [dict get $jsonDict results]

# 
foreach result $results {
    set out "Result: $result "
    foreach k [dict keys $result ] {
        lappend out "$k [dict get $result $k]" 
    }
    puts $out
}

#    set projectID [dict get $result projectID]
#    set name [dict get $result name]
#    set description [dict get $result description]
#    puts "$name $projectID $description"
#}


