package require json

# Define the path to the JSON file
set jsonFile "experiments.json"

# Read the JSON file content
set jsonData ""
set fileId [open $jsonFile r]
set jsonData [read $fileId]
close $fileId

# Parse the JSON data
set jsonDict [json::json2dict $jsonData]

# We're only interested in "results"
set results [dict get $jsonDict results]

# Available keys
#experimentId projectId gatewayId creationTime userName name description executionId resourceHostId experimentStatus statusUpdateTime url project userHasWriteAccess

foreach result $results {
  puts "**************"
#  foreach k [list experimentStatus project name description experimentId projectId ] 
  foreach k [ list experimentId url experimentStatus name description ] {
     puts "$k [dict get $result $k]"
  }
}



puts "#################"
set experiment [lindex $results 0]
foreach k [ list experimentId url experimentStatus name description ] {
   puts "$k [dict get $experiment $k]"
}


puts "#@#@#@#@#"
#set name "5xh3 mini from VMD"
set name "5xh3 minimization"
set count 0
foreach experiment $results {
  if { [dict filter $experiment value $name] != "" } {
    puts "${count}"
    break
  }
  incr count
}

set name "5xh3 mini from VMD"
puts [ dict keys [dict filter $results name $name] ]

#    set projectID [dict get $result projectID]
#    set name [dict get $result name]
#    set description [dict get $result description]
#    puts "$name $projectID $description"
#}


