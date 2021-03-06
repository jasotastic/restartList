# Run a ping on an IP address (or DNS name) and send a shutdown command to the machine.
# Wait for the machine to stop pinging, then when it starts again, report back that it was
# restarted successfully. Parameter and input can be comma semicolon or space separated list.
Param(
  [Parameter(Mandatory=$False)]
  [string]$ipList
)

# Check for parameter, and ask for ipList if it was empty.
If ($ipList -eq ""){
  $ipList = Read-Host 'What servers are we restarting today?'
}

$log = ".\ipList{0}.txt" -f (get-date -Format 'yyyyMMdd')

$out = "Restarting servers on list @ {0}" -f (get-date -Format G)
$out >> $log
write-host $out -foregroundcolor cyan
$regex = ';, '
$servers = $ipList.Split($regex)

foreach ($server in $servers){
  $server = $server.Trim()
  if ($server -ne ""){
    $attempt = 0
    do{
      $ping = Test-connection -computerName $server -Count 1 -delay 2 -EA SilentlyContinue
	  $attempt = $attempt + 1
    }until ($ping.statuscode -eq 0 -or $attempt -gt 10)
    if ($attempt -gt 10) {
      $out = "Could not find $server"
  	  $fgc = "red"
    }
    else{
      $sd = shutdown /m $server /f /r /t 0
	  if ($LASTEXITCODE -ne 0){
  	    $out = "could not restart $server"
	    $fgc = "yellow"
	}
	$attemptTwo = 0
	do {
	  $ping = Test-connection -computerName $server -Count 1 -delay 2 -EA SilentlyContinue
	}while ($ping.statuscode -eq 0)
	do {
	  $ping = Test-connection -computerName $server -Count 1 -delay 6 -EA SilentlyContinue
	}until($ping.statuscode -eq 0 -or $attemptTwo -gt 10)
	if ($attemptTwo -gt 10) {
	  $out = "Could not ping $server after restart"
	  $fgc = "orange"
	}
	else{
	  $out = "Successfully restarted $server"
	  $fgc = "green"
    }
  }
  $out >> $log
  write-host $out -foregroundcolor $fgc
  }
}
