
console show

proc act_httpd_start {w args} {
  puts $args
  
  httpd::start
  $w configure -text "Stop"
  puts "sever.root = $::config(server.root)"
}


. configure -menu .menubar

set w .menubar
menu $w
menu $w.theme
menu $w.help
menu $w.system
menu $w.view
$w add command -label "Server"
$w add command -label "Client"
$w add command -label "View"
$w add cascade -label "Theme" -menu $w.theme
$w add cascade -label "Help" -menu $w.help
$w add cascade -label "System" -menu $w.system
#.menubar entryconfigure 3 -menu .menubar.theme

set w .menubar.theme
foreach theme [ttk::style theme names] {
  $w add radiobutton -label "$theme" -command [list act_change_theme $theme]
}

set w .menubar.system
$w add command -label "command 1"
$w add command -label "command 2"

set w .menubar.help
$w add command -label "Help Online"
$w add command -label "About"

set w .menubar.view
$w add checkbutton -label "View Log"

proc act_change_theme {theme} {
  ttk::style theme use $theme 
}

pack [ttk::notebook .tabs -padding 8] -side top -fill both -expand 0


proc act_choose_server_dir {varname} {
  set dir [tk_chooseDirectory -initialdir [set $varname] \
      -title "Choose a directory"]
  # TODO: must exist
  
  if {$dir eq ""} {
     return
  }
  
  set $varname $dir
}




set w .tabs.server

ttk::frame  $w -padding 6 ;# -text "Server"
checkbutton $w.check -text "Server"
#.server configure -labelwidget .server.check
pack [ttk::frame $w.left] -side left -fill both -expand 1 -padx "0 8" -anchor n
pack [ttk::frame $w.left.port ] -side top -fill x
pack [ttk::frame $w.left.ip] -side top -fill x -expand 1
pack [ttk::label $w.left.ip._root -text "Root:" -justify right -width 6] -side left
#pack [entry  $w.left.ip.port  -textvar httpd::port -width 6] -side left
pack [ttk::entry  $w.left.ip.root  -textvar ::config(server.root)] -side left -fill x -expand 1
place [ttk::button $w.left.ip.btn_choose  -text "Choose" -command "act_choose_server_dir ::config(server.root)"] -in $w.left.ip.root -relx 1.0 -rely 0.5 -anchor e
pack [ttk::label  $w.left.port.l_port2 -text "Port:" -justify right -width 6] -side left
pack [ttk::entry  $w.left.port.port  -textvar ::httpd::port -width 6] -side left
pack [ttk::button $w.btn_start -width 9  -text "Start" \
    -command "act_httpd_start $w.btn_start"] \
    -side right -anchor n -fill y

set w .tabs.client
ttk::frame  $w -padding 6 ;# -text "Client"
checkbutton $w.check -text "Client"
#.client configure -labelwidget .client.check
set w .tabs.client.connect
ttk::frame  $w -padding 6 ;# -text "Client"
pack $w -side top -fill x -expand 1
pack [ttk::label  $w._host -text "Server:" -width 6] -side left
pack [ttk::entry  $w.host  -textvar ::config(client.server_host) -justify right] -side left
pack [ttk::label  $w._port -text ":"] -side left
pack [ttk::entry  $w.port  -textvar ::config(client.server_port) -width 5] -side left
pack [ttk::button $w.btn_start -text "Connect" -width 9 \
  -command "client_open"] \
  -side right -padx {6 0}

set w .tabs.client.upload
ttk::frame  $w -padding 6 ;# -text "Client"
pack $w -side top -fill x -expand 1
pack [ttk::label  $w._file -text "Root:" -justify right -width 6] -side left
pack [ttk::entry  $w.file  -textvar ::config(client.root)] -side left -fill x -expand 1
place [ttk::button $w.btn_choose  -text "Choose" -command "act_choose_server_dir ::config(client.root)"] -in $w.file -relx 1.0 -rely 0.5 -anchor e
pack [ttk::button $w.btn_send  -text "Upload"  -width 9 \
  -command "btn_send"] \
  -side right -padx {6 0}

set w .tabs
.tabs add $w.server -text "Server"
.tabs add $w.client -text "Client"
# .tabs add $w.upload -text "Upload"
.tabs add [frame $w.about] -text "About"


#pack .server -side top -fill both -padx 8 -expand 0
#pack .client -side top -fill both -padx 8 -pady 8 -expand 0
set w .log
labelframe $w -text "Log"
pack $w -side top -fill both -padx 8 -expand 1
pack [text $w.output -state disable] -side top -fill both -padx 6 -pady 6 -expand 1


wm title . $::config(title)