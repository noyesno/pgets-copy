array set config {
  title "PGets Copy"
  debug 1
  
  server.autostart  0
  server.port       7777
  server.root       "upload"
  
  client.server_host "localhost"
  client.server_port 7777
  client.debug  1
  client.root  "."
}

set config(server.root) [file join [pwd] upload]
set config(client.root) [file normalize "."]
