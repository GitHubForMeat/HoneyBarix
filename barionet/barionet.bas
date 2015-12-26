'===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by pc
'===============================================================================

' ------------------------------------------------------------------------------
' INIT: Version handling
' ------------------------------------------------------------------------------

 DIM VERS$(15) ' string
 DIM anap4  ' integer variable
 DIM delay4
 DIM state4
 DIM msnow
 
 VERS$="01.08 20151226"   ' Version of Main Application
 SYSLOG "Analog "+VERS$, 1


 
'===============================================================================
' MAIN: Main program loop
'===============================================================================

DELAY 100 ' 1000ms delay
100 'Main Program

anap4=IOSTATE(504) ' Read analog input #4 
msnow = _TMR_(0)

IF state4=0 THEN GOTO 1000 ELSE GOTO 1100 

GOTO 100


1000 
  IF anap4 > 750 THEN
    IOCTL  211, 1         ' Set the virtual digital register HIGH
    delay4=1000+msnow
	state4=1 
    SYSLOG "HI ANALOG IN 4="+STR$(anap4)
  ENDIF
  GOTO 100
  
  
  
 1100 ' state4 = high
  IF AND(anap4 <= 750, msnow > delay4)  THEN
    IOCTL  211, 0         ' Set the virtual digital register LOW
    state4=0 
    SYSLOG "LO ANALOG IN 4="+STR$(anap4)
	delay4=0 
  ELSE
    IF anap4 > 750 THEN
  	  delay4=1000+msnow
	ENDIF
  ENDIF
  GOTO 100
  


END 'EOF