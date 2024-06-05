
#!/usr/bin/tclsh

package require http
package require tls
package require json
package require base64

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

proc uploadFile {filePath token} {
    set jsonData {{""}}

    set fileId [open "$filePath" r]
    fconfigure $fileId -translation binary
    set body [read $fileId]
    close $fileId

    set contentSize [string length $body]
    set fileName [file tail $filePath]
    set encodedFileName [base64::encode $fileName]

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


# Get token from https://md.cybershuttle.org/auth/login-desktop/?show-code=true

set token "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJzX0dPcDFvM1p6U19ncVZjN1U3M1BNbThsMmxKbmZLRDg1N29tV2RaX0U4In0.eyJqdGkiOiIyNjA0ZjBiYS1hODQyLTRiZWMtYWE5OS1kNGJhZTU1OTdkNzMiLCJleHAiOjE3MTczODU4ODMsIm5iZiI6MCwiaWF0IjoxNzE3Mzg0MDgzLCJpc3MiOiJodHRwczovL2lhbS5zY2lnYXAub3JnL2F1dGgvcmVhbG1zL21vbGVjdWxhci1keW5hbWljcyIsImF1ZCI6InBnYSIsInN1YiI6ImVjMzQ1NGY3LWFkNjctNDQ3NC04ZDg5LWUxYTA0NWViMzM4ZCIsInR5cCI6IkJlYXJlciIsImF6cCI6InBnYSIsImF1dGhfdGltZSI6MTcxNzM4NDA4Mywic2Vzc2lvbl9zdGF0ZSI6IjQwMGM3YzY3LTVhNGEtNGI2OS04Mjc2LWZlNWM4ODI3YzE0YSIsImFjciI6IjEiLCJjbGllbnRfc2Vzc2lvbiI6IjQ2NWIzNzI2LTc4ZDUtNDI3Yi1iZWI1LWVmYzU3M2Q4ZTQ5MSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL21kLmN5YmVyc2h1dHRsZS5vcmciXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYnJva2VyIjp7InJvbGVzIjpbInJlYWQtdG9rZW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJ2aWV3LXByb2ZpbGUiXX19LCJuYW1lIjoiRGltdXRodSBXYW5uaXB1cmFnZSIsInByZWZlcnJlZF91c2VybmFtZSI6ImR3YW5uaXB1QGl1LmVkdSIsImdpdmVuX25hbWUiOiJEaW11dGh1IiwiZmFtaWx5X25hbWUiOiJXYW5uaXB1cmFnZSIsImVtYWlsIjoiZHdhbm5pcHVAaXUuZWR1In0.cGxvGrnDmo_8E90eKx6k-GDXRe_ZUynJ1h4rNljMkDTRvgrVWt6q8duD8SKOVRLlF98Yxq97PMa4ZHLa8q79QHmN27WgDadXiK6rZv8Vd0fJjbIxr0ImLWxUzd7hXbDvwspmfOKLrIjoXR8Hq8_k1Ylub-JUV-2KKOQXwVMhVAqbisY37RI0HN3B2c0G5xl0baV8kbP5hss0MHSaiisqB0Vc4TNRYppc6f91UNQB7FrMnB2PMW9ajVgMQvPK5Io5ydnSUijFuZXSWrFYRD8kzuX_BUBidzzhYbrBTFxd8Edx4VIYGzHk07cVy3QVAlcyowqrUAk63pNJn1X1KerPlA"
set filePath "output.txt"
set uploadLocation [uploadFile $filePath $token]
set replicaData [finishUpload $uploadLocation $token]
puts "Replica Json: "
# Keep replicaData. it is the name of each file we upload.
puts $replicaData
