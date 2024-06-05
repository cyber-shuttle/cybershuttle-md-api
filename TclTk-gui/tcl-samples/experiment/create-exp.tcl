# Load the json package
package require json
package require http
package require tls


proc dict2json {dictionary} {
    dict for {key value} $dictionary {
    if {[string match {\[*\]} $value]} {
        lappend Result "\"$key\":$value"
    } elseif {![catch {dict size $value}]} {
        lappend Result "\"$key\":\"[dict2json $value]\""
    } else {
        lappend Result "\"$key\":\"$value\""
    }
    }
    return "\{[join $Result ",\n"]\}"
}
proc createExperiment {token expName projectId groupResourceProfileId clusterId cpu nodeCount wallTimeLimit} {
    # Define the path to the JSON file
    set jsonFile "create-exp.json"

    # Read the JSON file content
    set jsonData ""
    set fileId [open $jsonFile r]
    set jsonData [read $fileId]
    close $fileId

    # Parse the JSON data
    set jsonDict [json::json2dict $jsonData]

    dict set jsonDict experimentName $expName
    dict set jsonDict projectId $projectId
    dict set jsonDict userConfigurationData computationalResourceScheduling resourceHostId $clusterId
    dict set jsonDict userConfigurationData computationalResourceScheduling totalCPUCount $cpu
    dict set jsonDict userConfigurationData computationalResourceScheduling nodeCount $nodeCount
    dict set jsonDict userConfigurationData computationalResourceScheduling wallTimeLimit $wallTimeLimit
    dict set jsonDict userConfigurationData groupResourceProfileId $groupResourceProfileId

    # Print the parsed JSON data (as a Tcl dictionary)
    puts "Parsed JSON data:"
    #puts $jsonDict

    # Convert the JSON-compatible dictionary to a JSON string
    set jsonData [dict2json $jsonDict]
    
    puts $jsonData

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
}

set expName "Dimuthu Namd"
set clusterId "NCSADelta_e75b0d04-8b4b-417b-8ab4-da76bbd835f5"
set projectId "DimuthuSample_efb0b290-7664-4234-8a48-86f7176c297"
set token "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJzX0dPcDFvM1p6U19ncVZjN1U3M1BNbThsMmxKbmZLRDg1N29tV2RaX0U4In0.eyJqdGkiOiJhYjFkNDE1ZC1iNjQ0LTQ4YjAtOGNlZC1hNGRmNDgyODcxNDYiLCJleHAiOjE3MTczOTgxODUsIm5iZiI6MCwiaWF0IjoxNzE3Mzk2Mzg1LCJpc3MiOiJodHRwczovL2lhbS5zY2lnYXAub3JnL2F1dGgvcmVhbG1zL21vbGVjdWxhci1keW5hbWljcyIsImF1ZCI6InBnYSIsInN1YiI6ImVjMzQ1NGY3LWFkNjctNDQ3NC04ZDg5LWUxYTA0NWViMzM4ZCIsInR5cCI6IkJlYXJlciIsImF6cCI6InBnYSIsImF1dGhfdGltZSI6MTcxNzM5NjM4NCwic2Vzc2lvbl9zdGF0ZSI6IjQ5ZDM2ZjQ4LTVmOGEtNDk5Yi1iNTYzLWM1ODU5MzlhZDY2MyIsImFjciI6IjEiLCJjbGllbnRfc2Vzc2lvbiI6IjhkZmEwOTVjLWI4ZGItNDJhYy05YzdlLWQ2MmFmZTAyMDA5NCIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL21kLmN5YmVyc2h1dHRsZS5vcmciXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYnJva2VyIjp7InJvbGVzIjpbInJlYWQtdG9rZW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJ2aWV3LXByb2ZpbGUiXX19LCJuYW1lIjoiRGltdXRodSBXYW5uaXB1cmFnZSIsInByZWZlcnJlZF91c2VybmFtZSI6ImR3YW5uaXB1QGl1LmVkdSIsImdpdmVuX25hbWUiOiJEaW11dGh1IiwiZmFtaWx5X25hbWUiOiJXYW5uaXB1cmFnZSIsImVtYWlsIjoiZHdhbm5pcHVAaXUuZWR1In0.XF_xzSC5zEnt2SgcNs44kya3fgwwII8w9lU7F50owFyZZuZVP33alBZ1OcCI7VI8Bvbp-2azvt-Hir0KBHzLvuK9V1wmXYQgvgjY2hjZku7AgIz1kVvgSfW2UgndCPqkp8rpLvpfF0_5DVBclCNmlRW9SH5TawzfPIg8WXsfwuJOqr6tc3JdeU7TqYpYWBbSbhPO2XTIr7DdRNaHdJqn1vmndUeQ2WaZyH7DYT9-9t31KxjIP9Gh0yu8X1f_FsXlfRH0kE4tq6_eUlA3QA7OfkmD0kDqNy5zRLmeQQl6QmxJuP0cqglr5TXRdVP5jLWfPH4N-4p1wUtCUZpLgl_fQA"
set groupResourceProfileId "f47130f7-33a8-4856-8ac9-19967724c1b8"

createExperiment $token $expName $projectId $groupResourceProfileId $clusterId 16 1 30