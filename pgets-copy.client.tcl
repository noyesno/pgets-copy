
# Usage: client_send_dir "" $basedir
proc client_send_dir {dir {basedir ""}} {
  set dir_path [file join $basedir $dir]
  set files [glob -nocomplain -tail -dir $dir_path *]
  
  foreach name $files {
    set path     [file join $dir      $name]
    set type     [file type [file join $dir_path $name]]
    
    switch -- $type {
      "file" {
        client_send_file $path $basedir
      }
      "directory" {
        client_send_dir $path  $basedir
      }
      "link" -
      default {
        puts "file type = $type"
      }
    }
  }
}


encoding system utf-8

set client_sock ""

proc client_open {} {
  upvar #0 client_sock sock
  
  set sock [socket $::config(client.server_host) $::config(client.server_port)]
  puts [fconfigure $sock]
  fconfigure $sock -encoding binary -translation binary
}

proc client_send_data {file data} {
  upvar #0 client_sock sock
  
  set data [encoding convertto $data]
  puts $sock "POST /fcopy HTTP/1.1"
  puts $sock "X-Command: file save"
  # puts $sock "Content-Encoding: [fconfigure $sock -encoding]"
  puts $sock "X-File: $file"
  set size [string length $data]
  puts $sock "Content-Length: $size"
  puts $sock ""
  flush $sock
  puts -nonewline $sock $data
  flush $sock
}

proc client_send_done {fp sock bytes args} {
  close $fp
  flush $sock
  set ::client_send_done 1
  puts "copy done: $bytes $args"
  incr ::bytes_sent $bytes
}

proc client_send_file {file {dir ""}} {
  upvar #0 client_sock sock
  
  set file_path [file join $dir $file]
  set file_size [file size $file_path]
  
  puts $sock "POST /fcopy HTTP/1.1"
  puts $sock "X-Command: file save"
  # puts $sock "Content-Encoding: [fconfigure $sock -encoding]"
  puts $sock "X-File: $file"
  puts $sock "X-Path: $file_path"
  puts $sock "Content-Length: $file_size"
  puts $sock "X-Debug: $::config(client.debug)"
  
  puts $sock ""
  flush $sock
  
  if {$::config(client.debug)} {
    return
  }
  
  set fp [open $file_path "rb"]
  fconfigure $fp -encoding binary -translation binary
  #fcopy $fp $sock
  #close $fp
  #flush $sock
  
  set ::client_send_done 0
  fcopy $fp $sock -command [list client_send_done $fp $sock]
  vwait ::client_send_done
  
  update_meter 
}

proc client_close {} {
  upvar #0 client_sock sock
  
  close $sock
}

proc btn_send {} {
  upvar #0 config(client.root) client_root
  
  set ::time_start [clock seconds]
  set ::bytes_sent 0
  if {[file isdir $client_root]} {
    client_send_dir  "" $client_root
  } else {
    client_send_file [file tail $client_root]  [file dir $client_root]  
    
  }
  
  
  # client_send_data "tmp1.txt" "1234567890你好abcdefghij"
  # client_send_data "tmp2.txt" "1234567890你不好abcdefghij"
}

proc update_meter {} {
  # TODO after idle
  set ::time_end [clock seconds]
  
  set time_elapse [expr {$::time_end-$::time_start}]
  set speed [expr {$::bytes_sent*1.0/($time_elapse<<20)}]
  set bytes_mb [expr {$::bytes_sent*1.0/(1024<<10)}]
  puts [format "%d ~ %d bytes: %d/%d %.1f MB speed: %.1f MB/s" $::time_start $::time_end $::bytes_sent $time_elapse $bytes_mb $speed]

}