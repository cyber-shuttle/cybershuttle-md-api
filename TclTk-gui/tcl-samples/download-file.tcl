#!/usr/bin/tclsh

package require http
package require tls


set filename "output.txt"
set f [open $filename wb]

set token "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJzX0dPcDFvM1p6U19ncVZjN1U3M1BNbThsMmxKbmZLRDg1N29tV2RaX0U4In0.eyJqdGkiOiJhN2JlZmQyZC00ZDI1LTRjMTgtOThjOS0zZTNjN2VmN2NkMGMiLCJleHAiOjE3MTc2MTI0OTQsIm5iZiI6MCwiaWF0IjoxNzE3NjEwNjk0LCJpc3MiOiJodHRwczovL2lhbS5zY2lnYXAub3JnL2F1dGgvcmVhbG1zL21vbGVjdWxhci1keW5hbWljcyIsImF1ZCI6InBnYSIsInN1YiI6IjZmZDI1MWFlLWUzMGUtNGI4Yi1hOTNlLWQyNjExNDM2NzIzYSIsInR5cCI6IkJlYXJlciIsImF6cCI6InBnYSIsImF1dGhfdGltZSI6MTcxNzYwNTUzNSwic2Vzc2lvbl9zdGF0ZSI6ImJlMmE4ZTAyLThhYmYtNDYwNC04MzhiLTNhYWViZmFjMDJmOSIsImFjciI6IjEiLCJjbGllbnRfc2Vzc2lvbiI6IjgxYjYzZjhiLWU2YTctNGM0NC1hMjg4LTg4NTY0YjEyNTA2MyIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL21kLmN5YmVyc2h1dHRsZS5vcmciXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYnJva2VyIjp7InJvbGVzIjpbInJlYWQtdG9rZW4iXX0sImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJ2aWV3LXByb2ZpbGUiXX19LCJuYW1lIjoiRGllZ28gQmFycmV0byBHb21lcyIsInByZWZlcnJlZF91c2VybmFtZSI6ImRlYjAwNTRAYXVidXJuLmVkdSIsImdpdmVuX25hbWUiOiJEaWVnbyIsImZhbWlseV9uYW1lIjoiQmFycmV0byBHb21lcyIsImVtYWlsIjoiZGViMDA1NEBhdWJ1cm4uZWR1In0.Sxvvz9PfU-FAgQ_R1qHmotf2rJVfhxTfX-PUrWLGXG0Kdr6498Oi-dxmTbCTSiT3bWkeJJ6IaYfBkoNw7S4MFS6enwLpCWu_Hhf6KIEU8G0Q6kTEQbh0L8JFKhvu8zltBUKyzei9ogfAyjZ1QORREKiDt_-nDqyngzSSj91GjsE02YBMLcAqe1iTMgGDWiRkF1TLflbzNvqpzzNvhlSeIRpYNaxkVRm9duGzItjSBp6KAR8xj7iAsGHtDpRwLeKBh7ZNVrkBapS5P5VOgHhgOV6JLhDZyBTTFveVA_Xik2ZpyfV3waL7ISvsxa4Zn1mnz1QpDEYoky_XOkpyqvQ9-g" 

# Define your headers with the token
set headers [list Authorization "Bearer $token"]

# This is your code, cut-n-pasted with blank lines removed
http::register https 443 tls::socket
#set url "https://md.cybershuttle.org/sdk/download-file/?data-product-uri=airavata-dp%3A%2F%2Fc24cfa16-e153-4adc-8ef0-6f7b6536a43d"
#set url "https://md.cybershuttle.org/sdk/download-experiment-dir/5xh3_463f9fe0-60ff-478d-845b-3c7e46a9be9e/"
set url "https://md.cybershuttle.org/sdk/download-file/?data-product-uri=airavata-dp%3A%2F%2F580a78e4-afba-4be7-a185-0f4c9f7fbd83"
set httpreq [http::geturl $url -timeout 30000 -headers $headers -channel $f -binary 1]

if {[http::status $httpreq] eq "ok" && [http::ncode $httpreq] == 200} {
    puts "Downloaded successfully"
}

http::cleanup $httpreq
http::unregister https
close $f

