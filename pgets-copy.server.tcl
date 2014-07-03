
package provide httpd 0.1

# stat = accept -> header -> body -> close
#          |__________________|

namespace eval ::httpd {
  variable port 8080
  variable clients [dict create]
  variable hooks   [dict create]
  
  proc start {} {
    variable port
    
    if {[catch { set sock [socket -server ::httpd::accept $port] }]} {
      puts "start server fail"
    } else {
      puts "listen on $port"
      event generate . <<ServerStart>> -data [fconfigure $sock]
    }
  }
  
  proc next_state {sock state} {
    variable clients 
    variable hooks
    
    puts "next state: $sock $state"
    if {$state eq "open"} {
      dict set clients $sock stat $state
      return
    }
    
    set prev_stat [dict get $clients $sock stat]
    dict set clients $sock stat $state
    
    # TODO: handle stat 'close'
    
    if {![dict exist $hooks $prev_stat]} {
      return
    }
    set stat_hooks [dict get $hooks $prev_stat]
    set request [dict get $clients $sock request]
    foreach hook $stat_hooks {
      catch {{*}$hook $sock $request} ;# TODO: ???
    }
  }
}

proc ::httpd::readlines {sock} {
  variable clients
  
  puts "... request $sock"

  set stat [dict get $clients $sock stat]
  switch -- $stat {
    "accept" {
      read_accept $sock
    }
    "header" {
      read_header $sock
    }
    "body" {
      read_body $sock
    }
    "close" {
      read_close $sock
    }
    "open" -
    default {
      error "Invalid State: $stat"
    }
  }

  catch {
    if {[eof $sock]} {
      read_close $sock
    }
  }
}

proc ::httpd::read_close {sock} {
  puts "DEBUG: close $sock read"
  
  fileevent $sock readable {}
  close $sock read
  # TODO: do cleanup
}

proc ::httpd::read_accept {sock} {
  variable clients
  
  set nbytes [gets $sock line]
  
  if {$nbytes<0} {
    if {[eof $sock]} {
      #next_state $sock "close" ;# TODO: can be removed
    }
    return
  }
  
  lassign $line method uri version
  
  set supported {GET POST}
  if {[lsearch $supported $method]<0} {
    error "Invalid request method: $method"
  }
  
  dict set clients $sock request "REQUEST_METHOD" $method
  dict set clients $sock request "REQUEST_URI"    $uri
  dict set clients $sock request "HTTP_VERSION"   $version
  
  next_state $sock "header"
}

proc ::httpd::read_header {sock} {
  variable clients
  variable buffer ""
  
  while {[gets $sock line]>=0} {
    if {$line eq ""} {
      next_state $sock "body"
      break
    }
    
    regexp {^([-\w]+)(:|\s+)(.*)$} $line -> key sp value
    puts "$sock: $line"
    set key   [string tolower $key]
    set value [string trim $value]
    dict set clients $sock request $key $value
  }
}

proc ::httpd::read_body {sock} {
  variable clients
  variable buffer
  set req_end 0
  
  set request   [dict get $clients $sock request]
  set file_debug [dict get $request "x-debug"]
  set file_path  [dict get $request "x-file"]
  set file_size  [dict get $request "content-length"]
  
  puts "DEBUG: request copy: $file_size $file_path"
  if {$file_debug} {
    next_state $sock "accept"
    return
  }
  
  set ofile [file join $::config(server.root) [encoding convertfrom $file_path]]
  file mkdir [file dirname $ofile]
  
  set fout [open $ofile "w"]
  fconfigure $fout -encoding binary -translation binary
  set nout [fcopy $sock $fout -size $file_size]
  close $fout
  
  if {$nout != $file_size} {
    error "Invalid fcopy size: $file_size v.s. $nout"
  }
  puts "DEBUG: copy end. nout = $nout"
  #seek $sock $size current
  next_state $sock "accept"
}

proc ::httpd::read_body_http {sock} {
  variable clients
  variable buffer
  set req_end 0
  
  puts [dict get $clients $sock request]
  if {[dict exists $clients $sock request "content-length"]} {
    set body_length [dict get $clients $sock request "content-length"]
    set nleft [expr {$body_length - [string bytelength $buffer]}]
    append buffer [read $sock $nleft]
    set nbytes [string bytelength $buffer]
    set nchars [string length $buffer]
    puts "DEBUG: $body_length / $nleft $nchars / $nbytes"
    
    if {$nbytes == $body_length} {
      set req_end 1
    }
  } else {
    append buffer [read $sock]
    if {[eof $sock]} {
      set req_end 1
    }
  }
  
  if {$req_end} {
    dict set clients $sock request body $buffer
    next_state $sock "accept"
    # ::httpd::response $sock [dict get $clients $sock request]
  }
  
}

proc ::httpd::accept {sock client_addr client_port} {
  variable clients
  
  
  event generate . <<ClientConnected>> -data [fconfigure $sock]
  
  puts "DEBUG: sock [fconfigure $sock]"
  fconfigure $sock -encoding binary -translation binary
  puts "DEBUG: sock [fconfigure $sock]"
  
  
  next_state $sock "open"    ;# For hooks only
  next_state $sock "accept"
  
  puts "connected $client_addr $client_port"
  flush stdout
  fconfigure $sock -blocking 0
  fileevent $sock readable [list ::httpd::readlines $sock]
}

proc ::httpd::hook {step callback} {
  variable hooks
  
  dict lappend hooks $step $callback 
}


proc ::httpd::write_header {sock request} {
  puts  $sock "HTTP/1.1 200 OK"
  puts  $sock "Content-Type: text/plain"
  puts  $sock "Cache-Control: max-age=0"
  puts  $sock "Connection: close"
  puts  $sock ""
  flush $sock
}

#=========================================================#


