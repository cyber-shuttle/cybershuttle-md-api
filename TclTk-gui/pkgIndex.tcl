#package ifneeded cybershuttle 0.8 "set env(CYBERSHUTTLEDIR) [list $dir]; [list source [file join $dir CyberShuttle.tcl] [list source [file join $dir CyberShuttle_submit.tcl] [file join $dir CyberShuttle_functions.tcl]] ]"
package ifneeded cybershuttle 0.8 "set env(CYBERSHUTTLEDIR) [list $dir]; [list source [file join $dir CyberShuttle.tcl]]"
package ifneeded cybershuttlesubmit 0.8 "set env(CYBERSHUTTLEDIR) [list $dir]; [list source [file join $dir CyberShuttle_submit.tcl] [file join $dir CyberShuttle_functions.tcl]]"



