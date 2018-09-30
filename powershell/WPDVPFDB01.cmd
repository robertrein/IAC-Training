:: This script will configure (or reconfigure) the indicated elements of a VM guest. 

@ECHO off 

SetLocal 

::***********************************************************************************
::*  Configure Primary network interface name and IP.                               *
::***********************************************************************************

::Rename PRI NIC to standard. 
::Clear DNS and WINS server entries. 
::Set Primary NIC as first in binding order. 

netsh interface set interface name="DATA" newname="WPDVPFDB01_PRI" 
sleep 10 
netsh int ip set address name="WPDVPFDB01_PRI" source=Static addr=10.122.73.51 mask=255.255.254.0 gateway=10.122.72.1 gwmetric=0 
netsh int ip set dns name="WPDVPFDB01_PRI" addr=none source=Static 
netsh int ip set wins name="WPDVPFDB01_PRI" addr=none source=Static 



nvspbindxp.exe /++ WPDVPFDB01_PRI ms_tcpip 
REG ADD HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /v "SearchList" /d "ksc.pcl.ingenix.com,pcl.ingenix.com,geoaccess.com,dmzkc1.geoaccess.com,ms.ds.uhc.com,uhc.com" /f 


::***********************************************************************************
::*  Configure Primary network interface DNS and WINS, per standard (Internal).     *
::***********************************************************************************

netsh int ip add dns name="WPDVPFDB01_PRI" addr=10.90.40.105 index=1 
netsh int ip add dns name="WPDVPFDB01_PRI" addr=10.4.148.103 index=2 
netsh int ip add dns name="WPDVPFDB01_PRI" addr=10.3.116.104 index=3 
netsh int ip add wins name="WPDVPFDB01_PRI" addr=10.175.231.100 index=1 
netsh int ip add wins name="WPDVPFDB01_PRI" addr=10.223.192.155 index=2 


