if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded tls 1.8.0 [list load [file join $dir tcl9tls180t.dll]] 
} else { 
package ifneeded tls 1.8.0 [list load [file join $dir tls180t.dll]] 
} 
