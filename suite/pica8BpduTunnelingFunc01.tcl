proc pica8BpduTunnelingFunc01 {} {

	sdbPicaIxPortPairFmtGet PX1 XR1 PX2 XR2 PX3 XR3
	set DutPortCfg "
		set vlans vlan-id 4052
		set vlans vlan-id 4053
		commit
		set interface gigabit-ethernet $PX1 family ethernet-switching native-vlan-id 4052
		set interface gigabit-ethernet $PX2 family ethernet-switching native-vlan-id 4053
		commit
		set interface gigabit-ethernet $PX1 family ethernet-switching port-mode trunk
		set interface gigabit-ethernet $PX1 family ethernet-switching vlan members 4052
		set interface gigabit-ethernet $PX1 family ethernet-switching vlan members 4053
		commit
		set interface gigabit-ethernet $PX2 family ethernet-switching port-mode trunk
		set interface gigabit-ethernet $PX2 family ethernet-switching vlan members 4052
		set interface gigabit-ethernet $PX2 family ethernet-switching vlan members 4053
		commit
		set interface gigabit-ethernet $PX3 family ethernet-switching port-mode trunk
		set interface gigabit-ethernet $PX3 family ethernet-switching vlan members 4052
		set interface gigabit-ethernet $PX3 family ethernet-switching vlan members 4053
		commit
		
		set interface gigabit-ethernet $PX1 family ethernet-switching bpdu-tunneling protocol stp
		set interface gigabit-ethernet $PX2 family ethernet-switching bpdu-tunneling protocol stp
		commit
		set interface bpdu-tunneling destination-mac 01:0E:00:00:00:01
		commit"
		
	pica8TestStart
	
	pInfo "======================= Step 1: bpdu-tunneling transparent transmission ====================="
	picaCliScriptRun $DutPortCfg
	pSleep 5 "Wait the configurations are committed"
	
	#source address, destination address, bpdu-tunneling desetination address
	set sDA {01 80 C2 00 00 00}
   	set sSA {22 22 22 22 22 22}
   	set sBPDUDA {01 0E 00 00 00 01}
   	
   	#iXia transmission
   	wixPortInit "$XR1 $XR2 $XR3"
   	set sBpduPacketPattern [buildBpduPatternPacket $sSA]
   	ixBuildEthPacket -pXR $XR1 -dMac $sDA -sMac $sSA \
                     -fraNum 10 -frameSize 64 -dataPattern userpattern -pattern $sBpduPacketPattern \
                     -patternType nonRepeat -rateMode streamRateModeFps -fpsRate 10 \
                     -protocolType noType
        Port_write_config $XR1
        ixiaCaptureFilter -pXR $XR2 -dMac $sDA
        Port_write_config $XR2
        PortList_clearStats $XR2
        ixiaCaptureFilter -pXR $XR3 -dMac $sBPDUDA
        Port_write_config $XR3
        PortList_clearStats $XR3
        pSleep 2 "Waiting for ixia port clear port counter complete"
        PortList_startTransmit $XR1
        PortList_startCapture $XR2
        PortList_startCapture $XR3
        pSleep 5 "Waiting ixia port transmit packet complete"
        
        #iXia result check
        Port_getallStats $XR2
        CaptureFilter_chk_packetNum 10
        PortList_stopCapture $XR2
        Port_getallStats $XR3
        CaptureFilter_chk_packetNum 10
        PortList_stopCapture $XR3
        
        
        pInfo "============================= Step 2: bpdu-tunneling isolation ================================="
        #iXia transmission with vlan tag
   	wixPortInit "$XR1 $XR2 $XR3"
   	set sBpduPacketPattern [buildBpduPatternPacket $sSA]
   	ixBuildEthPacket -pXR $XR1 -dMac $sDA -sMac $sSA \
                     -fraNum 10 -frameSize 64 -dataPattern userpattern -pattern $sBpduPacketPattern \
                     -patternType nonRepeat -rateMode streamRateModeFps -fpsRate 10 \
                     -protocolType noType -vid 4052
        Port_write_config $XR1 
        ixBuildEthPacket -pXR $XR2 -dMac $sDA -sMac $sSA \
                     -fraNum 10 -frameSize 64 -dataPattern userpattern -pattern $sBpduPacketPattern \
                     -patternType nonRepeat -rateMode streamRateModeFps -fpsRate 10 \
                     -protocolType noType -vid 4053
        Port_write_config $XR2
        ixiaCaptureFilter -pXR $XR3 -dMac $sBPDUDA -offset 14 -pattern 0FD4     #Filter vlan 4052
        Port_write_config $XR3
        PortList_clearStats $XR3
        pSleep 2 "Waiting for ixia port clear port counter complete"
        PortList_startTransmit $XR1
        PortList_startTransmit $XR2
        PortList_startCapture $XR3
        pSleep 5 "Waiting ixia port transmit packet complete"
        
        #iXia result check
        Port_getallStats $XR3
        CaptureFilter_chk_packetNum 10
        PortList_stopCapture $XR3
        
        
        pInfo "============================= Step 3: bpdu-tunneling ending ================================="
        set DutDelPortCfg "
        	delete interface bpdu-tunneling destination-mac
		delete interface gigabit-ethernet $PX1 family
		delete interface gigabit-ethernet $PX2 family
		delete interface gigabit-ethernet $PX3 family
		commit
		delete vlans vlan-id 4052
		delete vlans vlan-id 4053
		commit"
	picaCliScriptRun $DutDelPortCfg
	pica8TestStop
}

        
        
        