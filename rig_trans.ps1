
##########################################################################
#
# Author: Mark Rutherford (VK4TMZ) 
#
# Requirements:
#    Virtual Serial Port - Eg. VSPE (http://www.eterlogic.com/Products.VSPE.html).  
#          You will need to create a "Connector" which acts as the CatPortIn 
#
# Description:
#
#    This scripts purpose is to act as a rig translator / proxy for when Radio applications (ie Winlink) do not list your rig specifically 
#    and none of the listed can act as generic CAT control.
#
#    Currently the CatIn expecting TS2000 CAT commands and its translating to FT991/A CAT Commands.  This is done via monitoring the CatIn port
#    for commands and based on a specified "Terminating Character" (ie Kenwood and Yeasu use ";") once a command and its arguments are encountered 
#    it is then put through a if/then set to handle the translation.  For current needs was to have WinLink Trimode work with my FT991A. The TS2000 
#    rig is normally one of those that are always supported as CAT. Below you'll see the set of cat comamnds WinLink sends as each channel is 
#    scanned. Majority of commands that are sent I was able to ignore as I handle them via (catOutPreconfig and catOutDeinit). I look for the 
#    Frequency and TX/RX commands. 
#   
#    Using regular expression (regex) I split each command sequence received into its Command Code and arguments. Then I apply A simplistic 
#    translation. I look for the Frequency and TX/RX commands.  But you are able to alter to suit your needs with little effort. 
#    For example when I encountered the frequency change commands, I also inject extra commands to the FT991 to control the Preamp 80-10m IPO, 
#    20m-17m AMP1, 15m-10m AMP2.  Please note Winlink allows the user to select method how handling PTT. Fortunately I was able to use "CAT for PTT" 
#    allowing me to look for the TX / RX commands; This allowed me to handle the split/mode so when I encountered the TX command I would set VFOB 
#    and then pass the TX via CAT to FT991 itself.  
#
#    The catOutPreconfig and catOutDeinit functions allow rig commands to be sent to your CatOut port for setup and tear down. Currently for FT991 
#    Preinitialisation set mode, bandwidth, disables (NB, NR, Notch), agc, txpwr lvl and enables split mode. Deintialisation disables split mode.
#
#    Note: the concepts for catOutPreconfig and catOutDeinit are from PCALE (MMI-RADIO) as the ALE is scanning its best to put rig (if supported) 
#    into split mode so the filter relays are not clanking away.    
#
#     
#
# Running:
#   PowerShell.exe -ExecutionPolicy UnRestricted -File rig_trans.ps1 -gComPortIn COM25 -gComPortOut COM11
#   
# 
# List the Comm Ports:
#
# [System.IO.Ports.SerialPort]::getportnames()

param (
    [string]$gComPortIn = "COM25",   # CatPort VPSE to allow Winlink to connect to and this script to read
    [string]$gComPortOut = "COM11"   # CatPort of rig FT991
)


# Global Read Buffer
$gReadbuffer = ""


function readCommand($port, $termch, $timeout) {
    $cmd = ""
    while (1 -eq 1) {
        # Parse String as <CMD><TERMCH><OTHER CMDS>
        $cmds = $gReadbuffer | Select-String -Pattern '^(.*?);(.*)$'
        $m = $cmds.Matches
        if ( ($m.Length -eq 0) -Or ($m.Groups.Length -le 1) ) {
          Start-Sleep -Milliseconds 25
          $buf = $port.ReadExisting()
          $gReadbuffer = $gReadbuffer + $buf
        }
        else {
            $cmd = $m.Groups[1].Value
            break;
        }
        
    }
    return $cmd
}

function QSSEnable($port) {
    ## Copy VFO-A to VFOB -- TX on VFOB
    $gPortOut.Write("AB;FT3;")
}


function QSSDisable($port) {
    ## VFO-A to VFO-B, TX to VFO-A
    $gPortOut.Write("AB;FT2;")
    Start-Sleep -Milliseconds 10;
}



function catOutPreconfig($port){

    ## Power Control: 100 watts - Mode: DATA-USB - Pre-amp: IPO
    ## RADCMD MD0C;PC100;PA00;
    #$gPortOut.Write("MD0C;PC100;")
    #$gPortOut.Write("MD0C;PC055;")
    $gPortOut.Write("MD0C;PC075;")
    Start-Sleep -Milliseconds 10;

    ## AUTO Notch: Off - Manual Notch: Off - Noise Blanker: Off
    $gPortOut.Write("BC00;BP00000;NB00;")
    Start-Sleep -Milliseconds 10;

    ## Width: 3000 Hz - Noise Reduction: Off  - RF Attenuator: Off
    $gPortOut.Write("SH017;NR00;RA00;")
    Start-Sleep -Milliseconds 10;

    ## Moni: On, Level 35
    $gPortOut.Write("ML01;ML1029;")
    Start-Sleep -Milliseconds 10;

    ## AGC: Fast
    $gPortOut.Write("GT01;")
    Start-Sleep -Milliseconds 10;

    ## SSB Display Shift: +1500hz
    $gPortOut.Write("EX064+1500;")
    Start-Sleep -Milliseconds 10;

    ## SSB Freq Shift: +1620
    $gPortOut.Write("EX065+1500;")
    Start-Sleep -Milliseconds 10;

    ## SSB TX BPF: 200-2800
    $gPortOut.Write("EX1122;")
    Start-Sleep -Milliseconds 10;

    QSSEnable -port $port

}


function catOutDeinit($port) {
    ## Power Control: 5 watts - Mode: USB - Pre-amp: IPO
    ##RADCMD MD02;PC005;PA00;

    ## AGC: Auto
    $gPortOut.Write("GT04;")

    ## SSB Display Shift: +1500hz
    $gPortOut.Write("RADCMD EX064+1500;")
    Start-Sleep -Milliseconds 10;

    ## SSB Freq Shift: +1500
    $gPortOut.Write("EX065+1500;")
    Start-Sleep -Milliseconds 10;

    ## SSB TX BPF: 200-2800hz
    $gPortOut.Write("EX1122");
    Start-Sleep -Milliseconds 10;

    QSSDisable -port $port

}




############################
#
# TS-2000 Sequence Send from WinLink on Scan
# A00;BC0;NB0;NR0;FR0;FT0;RC;FA00003572700;
#
# A00 - 
# BC0 - Manual Notch Off 
# NB0 - Noise Blanker Off
# NR0 - Noice Reduction Off
# FR0 - Set RX VFO A
# FT0 - Set TX VFO A
# RC - Set RIT 0
# FA00003572700 - Set VFO A Frequency Hz 

Write-Host "Opening CAT-IN Port: [$gComPortIn]"
$gPortIn = new-Object System.IO.Ports.SerialPort $gComPortIn,38400,None,8,one
$gPortIn.Open()
Write-Host "  -- Successfully Opened Port: [$gComPortIn]"

try {

    Write-Host "Opening CAT-IN Port: [$gComPortOut]"
    $gPortOut = new-Object System.IO.Ports.SerialPort $gComPortOut,38400,None,8,one
    $gPortOut.Open()
    Write-Host "  -- Successfully Opened Port: [$gComPortOut]"
    
    catOutPreconfig -port $gPortOut
    Write-Host "  -- Successfully Preconfigured Port: [$gComPortOut]"

    try {
        while (1 -eq 1) {
            $cmd = readCommand -port $gPortIn -termch ";" -timeout 30000
  
            $args = $cmd | Select-String -Pattern '^(\w\w)(.*)$'
            $m = $args.Matches
            if ( ($m.Length -eq 0) -Or ($m.Groups.Length -le 1) ) {
                Write-Host "Invalid CMD: [$cmd]"
            } else {
                $code = $m.Groups[1].Value
                $arg = $m.Groups[2].Value
                Write-Host "CMD: [$cmd] - Code: [$code]::[$arg]"

                # Translation Time
                #

                if ($code -eq "FA") {
                    $freq = $arg.Substring(2);
                    $ncmd = "FA" + $freq
                    Write-Host ("  -- Setting Frequency: [$arg] --> [$ncmd]")

                    $freq_int = [int]$freq
                    if ($freq_int -le 11000000) {
                        $amp = "PA00"
                    } elseif ($freq_int -le 18000000) {
                        $amp = "PA01"
                    } else {
                        $amp = "PA02"
                    }
                    $gPortOut.Write("$ncmd;$amp;")
                } elseif ($code -eq "TX")
                {
                    Write-Host ("  -- Transmitting: [$arg] ")
                    QSSEnable -port $gPortOut
                    $gPortOut.Write("TX1;")
                } elseif ($code -eq "RX")
                {
                Write-Host ("  -- Receiving: [$arg] ")
                    QSSEnable -port $gPortOut
                    $gPortOut.Write("TX0;")
                }
            }
    
        }
    } finally {

        catOutDeinit -port $gPortOut
        Write-Host "  -- Successfully De-Initialised Port: [$gComPortOut]"

        $gPortOut.Close()
        Write-Host "  -- Successfully Closed Port: [$gComPortOut]"
    }
} finally {

    $gPortIn.Close()
    Write-Host "  -- Successfully Closed Port: [$gComPortIn]"

}