param(
   $irc = $(PowerBot\Get-PowerBotIrcClient)
)

$BadWords = @("VBS","Fuck","Cunt")
$BadWords = '\b' + ($BadWords -join '\b|\b') + '\b'
function Test-Language {
   param($source, $event)
   $c = $event.Data.Channel
   $n = $event.Data.Nick
   $m = $event.Data.Message
   if($m -match $BadWords) {
      $irc.SendMessage("Message", $n, "Hey, watch your language. '$($matches[0])' won't be tolerated in $c" )
   }
}   



function Expand-URL {
   param($source, $event)
   $c = $event.Data.Channel
   $n = $event.Data.Nick
   $m = $event.Data.Message
   Write-Host "Resolve-AllUrl $M" -Fore Black -Back White
   Resolve-AllUrl $m | % { $irc.SendMessage("Message", $c, "<$($n)> $_" ) }
}

function Resolve-URL {
   param( 
      [Parameter(Mandatory=$true, Position=0)]
      [String]$Uri
   )

   $request = Invoke-WebRequest -Uri $uri -MaximumRedirection 0 -ErrorAction Ignore

   if($request.StatusCode -ge 300 -and $request.StatusCode -lt 400)
   {
      $request.Headers.Location
   } else { 
      $request 
   }
}


$tinyDomains = 'is.gd','ff.im','xrl.us','cli.gs','snurl.com','snipr.com','snipurl.com','twurl.nl','bit.ly','j.mp','amzn.to','tr.imsu.pr','tinyUrl.com','t.co'
$tinyDomains = @($tinyDomains | %{ [regex]::escape($_) }) -join '|'
[regex]$tinyUrl   = "(?:https?://)?(?:$tinyDomains)/([^?/ ]+)\b"

function Resolve-AllUrl { 
   #.SYNOPSIS
   # Figure out the real url behind those shortened forms
   param(
      # Text which (possibly) contains tiny forwarding urls
      [string[]]$text
   )

   foreach($line in $text) {
      if(($matches = $tinyUrl.Matches($line)).Count -gt 0) {
         for($i = $matches.Count-1; $i -ge 0; $i--) {
            $line = $line.Remove($matches[$i].Index, $matches[$i].Length).Insert($matches[$i].Index, ( Resolve-URL $matches[$i].value ))
         }
         write-output $line
      }
   }
}
