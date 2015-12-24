'===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by pc
'===============================================================================

' ------------------------------------------------------------------------------
' INIT: Version handling
' ------------------------------------------------------------------------------

 DIM VERS$(15) ' string
 DIM anap4  ' integer variable
 
 VERS$="01.01 20151220"   ' Version of Main Application
 SYSLOG "Analog "+VERS$, 1


 
'===============================================================================
' MAIN: Main program loop
'===============================================================================

100 'Main Program
DELAY 100 ' 1000ms delay
anap4=IOSTATE(504) ' Read analog input #4 

IF anap4>750 THEN 
  IOCTL  211, 1
  SYSLOG "ANALOG IN 4 = "+STR$(anap4)  
  DELAY 1000
ELSE
  IOCTL 211, 0
ENDIF

GoTo 100


End
'EOF
