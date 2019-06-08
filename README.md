# rig_trans
Transceiver Rig CAT Translator.   A basic script for translating the rig commands from software that may noy currently handle their rig.  I encounted this requirement when using the WinLink RMS Trimode as it did not support Yaesu FT991.  I was able to configure it to use Kenwood TS2000 which is common and the translator translated the required commands to that of the FT991.  Hopefully the script can help others out until the software they are using eventually supports their rig.

# Author: Mark Rutherford (VK4TMZ) 

# Requirements:
   Virtual Serial Port - Eg. VSPE (http://www.eterlogic.com/Products.VSPE.html).  
         You will need to create a "Connector" which acts as the CatPortIn 

# Description:

This scripts purpose is to act as a rig translator / proxy for when Radio applications (ie Winlink) do not list your rig specifically and none of the listed can act as generic CAT control.

Currently the CatIn expecting TS2000 CAT commands and its translating to FT991/A CAT Commands.  This is done via monitoring the CatIn port for commands and based on a specified "Terminating Character" (ie Kenwood and Yeasu use ";") once a command and its arguments are encountered it is then put through a if/then set to handle the translation.  For current needs was to have WinLink Trimode work with my FT991A. The TS2000 rig is normally one of those that are always supported as CAT. Below you'll see the set of cat comamnds WinLink sends as each channel is scanned. Majority of commands that are sent I was able to ignore as I handle them via (catOutPreconfig and catOutDeinit). I look for the Frequency and TX/RX commands. 
  
Using regular expression (regex) I split each command sequence received into its Command Code and arguments. Then I apply A simplistic translation. I look for the Frequency and TX/RX commands.  But you are able to alter to suit your needs with little effort. For example when I encountered the frequency change commands, I also inject extra commands to the FT991 to control the Preamp 80-10m IPO, 20m-17m AMP1, 15m-10m AMP2.  Please note Winlink allows the user to select method how handling PTT. Fortunately I was able to use "CAT for PTT" allowing me to look for the TX / RX commands; This allowed me to handle the split/mode so when I encountered the TX command I would set VFOB and then pass the TX via CAT to FT991 itself.  

The catOutPreconfig and catOutDeinit functions allow rig commands to be sent to your CatOut port for setup and tear down. Currently for FT991 Preinitialisation set mode, bandwidth, disables (NB, NR, Notch), agc, txpwr lvl and enables split mode. Deintialisation disables split mode.

Note: the concepts for catOutPreconfig and catOutDeinit are from PCALE (MMI-RADIO) as the ALE is scanning its best to put rig (if supported) into split mode so the filter relays are not clanking away.    

# Running:
powerShell.exe -ExecutionPolicy UnRestricted -File rig_trans.ps1 -gComPortIn COM25 -gComPortOut COM11
  
