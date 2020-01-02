# rig_trans
Transceiver Rig CAT Translator.   

This is example java code to perform the translation of rig CAT commands from ICOM to KENWOOD TS-2000. 

It's not complete by any stretch of the imagination. While playing around with YaDD (Yet antoher DSC Decoder) I wanted to give the "scanning" feature a go as the SDRPlay RSPPro2 only has a maximum window of 10MHZ and running 10MHZ windows nd 3 or 4 decoders is maxing out my older PCs used for Radio monitoring. I can either monitor (4, 6, 8 and 12 MHz)  or (8, 12 and 16 MHz) at any one time.  Geez how I wish I'd bought a KiwiSDR!!!! So YaDD CAT commands are ICOM like were as SDRUno and SDR Console3 expect Kenwood TS2000 like CAT commands to controlthe VFO.  

My original rig_trans tool was a PS script, however I was experiencing bad characters on the serial port either dure to bug in the .NET serial library or due to possible encoding clash with the characters sent by YaDD.  So here you guys go a Java version.

That all said and done,  the scanning feature did not work as well as hoped.  It missed many DSC bursts.  But hey gav it a go, but for me I'll stay with monitoring as many DSC channel at once as my equipment can handle.

# Author: Mark Rutherford (VK4TMZ) 

# Requirements:
   Virtual Serial Port - Eg. VSPE (http://www.eterlogic.com/Products.VSPE.html).  
         You will need to create a "Connector" which acts as the CatPortIn 

  Libraries required:
    - jSerialComm-2.3
    - Apache Commons Lang 3 and Codec

# Description:

This scripts purpose is to act as a rig translator / proxy for when Radio applications (ie Winlink) do not list your rig specifically and none of the listed can act as generic CAT control.

Currently the CatIn expecting ICOM CAT commands and its translating to Kenwood TS200 CAT Commands.  This is done via monitoring the CatIn port for commands and based on a specified "Terminating Character" (ie Kenwood and Yeasu use ";") once a command and its arguments are encountered it is then put through a translator to handle the translation.  For current needs was to set the VFOA frequency. 
  
Using regular expression (regex) I split each command sequence received into its Command Code and arguments. Then I apply A simplistic translation. I look for the Frequency command.  But you are able to alter to suit your needs with little effort. For example when I encountered the frequency change commands, I also inject extra commands to alter the frequency by -600hz.  

# Compiling and Running:
I've checked in "Eclipse" project files but they are specific to my location.  Please edit and or re-import into your own project and remember to add the 3 required external JAR library files.

Have Fun.!
De VK4TMZ
