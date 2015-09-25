set aWs(sType) "Function"
set aWs(sTitle) "Check OVS Web services"
set aWs(sDescription) ""

proc Ovs_WebCheck_01 {} {

    set timeout -1
    
    # Test start
    pica8TestStart

    # Get the Ip address 
    set sIp [pica8OvsCmd 1 "ifconfig eth0"]
    regexp {inet addr:([0-9]+.[0-9]+.[0-9]+.[0-9]+)} $sIp sTmp sIp

    #Check web services function
    pInfo ":::step1: check web service when startup ovs"  
    picaCliSrcCapture "sudo service picos restart"
    picaCheckSrcCapture "Starting web server: lighttpd"
    pSleep 1
    pInfo ":::step2: check web sevices on process"
    picaCliSrcCapture "ps aux | grep python"
    picaCheckSrcCapture ".*/srv/www/htdocs/backend/app.py"
    pSleep 1
    pInfo ":::step3: check the web function"
    picaCliSrcCapture "sudo wget http://$sIp"
    picaCheckSrcCapture ".*$sIp:80... connected"
    pSleep 1
    pInfo ":::step4:check the result from web get"
    picaCliSrcCapture "ls -lt index.html"
    picaCheckSrcCapture "1952.*index.html"   
    pSleep 1
    set sMatch [pica8OvsCmd 1 "grep \"placeholder\" index.html"]
    set flag1 [regexp "placeholder=\"Username\"" $sMatch]
    set flag2 [regexp "placeholder=\"Password\"" $sMatch]
    pInfo "###flag1 is $flag1;flag2 is $flag2###" 
    
    if {$flag1==1 && $flag2 ==1} {
        errnoSet pass
    } else {
        errnoSet fail
    }
    
    pInfo ":::step5:remove the file"
    picaCliCmdRun "rm -rf  index.html"

   
    # Test end
    pica8TestEnd   
}

