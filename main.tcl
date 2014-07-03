############################################################
# Project Name: PGets Copy                                 #
############################################################

#----------------------------------------------------------#
# Global Setting
#----------------------------------------------------------#
encoding system utf-8
source config.tcl

#----------------------------------------------------------#
# Command Line Setting
#----------------------------------------------------------#
if {$argc>0} {
  set config(server.port) [lindex $argv 0]
}

#----------------------------------------------------------#
# Load Package
#----------------------------------------------------------#
source pgets-copy.server.tcl
source pgets-copy.client.tcl

#----------------------------------------------------------#
# Apply Setting
#----------------------------------------------------------#
set httpd::port $config(server.port)
set config(server.root) [file join [pwd] upload]

#----------------------------------------------------------#
# GUI
#----------------------------------------------------------#
source gui/toplevel.tcl

#----------------------------------------------------------#
# Launch
#----------------------------------------------------------#
if {$::config(server.autostart)} {
  ::httpd::start
}

#----------------------------------------------------------#
# Event Loop
#----------------------------------------------------------#
vwait forever

#----------------------------------------------------------#
# Exit
#----------------------------------------------------------#
exit

#----------------------------------------------------------#
# Tail Memo
#----------------------------------------------------------#
