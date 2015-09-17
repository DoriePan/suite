set aWs(sType) "Function"
set aWs(sTitle) "dories static routing test"
set aWs(sDescription) ""

proc DoriesStaticRouting { } {
	global aSetup

	Fun_Static_Route_TestDbLoad

	#get the port of ixia and dut
	sdbPicaIxPortPairFmtGet PX1 XR1 PX2 XR2 PX3 XR3 
	#ixia init
	wixPortInit "$XR1 $XR2 $XR3"

	#Test Start
	pica8TestStart

	#configure the DUT
	picaCliScriptRun "
	set vlans vlan-id 2
	set vlans vlan-id 3
	set vlans vlan-id 4
	set interface gigabit-ethernet $PX1 family ethernet-switching native-vlan-id 2
	set interface gigabit-ethernet $PX2 family ethernet-switching native-vlan-id 3
	set interface gigabit-ethernet $PX3 family ethernet-switching native-vlan-id 4
	set vlans vlan-id 2 l3-interface vlan-2
	set vlans vlan-id 3 l3-interface vlan-3
	set vlans vlan-id 4 l3-interface vlan-4
	commit
	set vlan-interface interface vlan-2 vif vlan-2 address 10.10.1.1 prefix-length 24
	set vlan-interface interface vlan-3 vif vlan-3 address 10.10.2.1 prefix-length 24
	set vlan-interface interface vlan-4 vif vlan-4 address 10.10.3.1 prefix-length 24
	set protocols static route 20.10.51.0/24 next-hop 10.10.3.2
	set protocols static route 0.0.0.0/0 next-hop 10.10.3.2
	commit
	"
	
	#Check the static route
	pInfo "Check the static route"
	pica8CheckCmd 1 "show route table ipv4 unicast final"
	pica8CheckText "20.10.51.0/24.*static"
	pica8CheckText "0.0.0.0/0.*static"


	#Step 1:Transmit arp request to DUT
	pInfo "Transmit arp request to DUT"
	ixiaGenArp -pXR $XR3 -dArpIP 10.10.3.1 -sArpIP 10.10.3.2
	Port_write_config $XR3
	Port_startTransmit "$XR3"
	pica8CheckCmd 1 "show arp"
	pica8CheckText "10.10.3.2.*00:00:00:00:00:01"
       pSleep 5
	#Add route table check before packets sending
	pica8CheckCmd 1 "show mac-address table "
	pica8CheckCmd 1 "show route forward-route ipv4 all"
	pica8CheckText "20.10.51.0/24.*00:00:00:00:00:01.*$PX3"

	#Step 2:Transmit packet from XR1 to XR3
	pInfo "Transmit packet from XR1 to XR3"
	ixiaGenPktTran -pXR $XR1 -dMac $aSetup(pica,1,sMacAddr)  -dIP 20.10.51.1 -sIP 10.10.1.2 -ipProtocol 0x11
	Port_write_config $XR1
	ixiaCaptureFilter -pXR $XR3 -dIP 20.10.51.1
	Port_write_config $XR3
	CheckIxiaPktTranResult $XR1 $XR3 10000

	#Add route table check before packets sending
	pica8CheckCmd 1 "show route forward-route ipv4 all"
	pica8CheckText "20.10.51.0/24.*00:00:00:00:00:01.*$PX3"
	pica8CheckText "0.0.0.0/0.*00:00:00:00:00:01.*$PX3"

	#Clear the configuration
	pica8CheckCmd 1 "clear arp all"
	picaCliScriptRun "
	delete interface gigabit-ethernet $PX1 family 
	delete interface gigabit-ethernet $PX2 family 
	delete interface gigabit-ethernet $PX3 family 
	commit
	delete vlan-interface interface vlan-2
	delete vlan-interface interface vlan-3
	delete vlan-interface interface vlan-4
	commit
	delete vlans vlan-id 2
	delete vlans vlan-id 3
	delete vlans vlan-id 4
	commit"
	picaCliScriptRun " 
	delete protocols static route 20.10.51.0/24
	delete protocols static route 0.0.0.0/0
	commit
	"
	
	devCliClose
	pica8TestStop
}
