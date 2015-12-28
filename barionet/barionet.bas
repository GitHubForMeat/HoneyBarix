'===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by ME
'===============================================================================

' Register Mapping
' Barionet 100  Milestone
' ------------  ---------
' 211           Input 11   Virtual IO bit
' 504                      Analog input 4 value

' ------------------------------------------------------------------------------
' INIT: Version handling
' ------------------------------------------------------------------------------

 DIM VERS$(15) ' string
 DIM anap4  ' holds a/d value for analog input 4
 DIM delay4 ' Time value for hysterisis, to prevent signal bouncing on output
 DIM state4 ' Holds state machine value
 DIM msnow  ' Holds current time in milliseconds, rolls over every 49 days
 
 VERS$="01.09 20151227"   ' Version of Main Application
 SYSLOG "Analog "+VERS$, 1

DELAY 250 ' Quarter seconds delay on bootup
 
'===============================================================================
' MAIN: Main program loop
'===============================================================================

100 'Main Program

anap4=IOSTATE(504) ' Read analog input #4 
msnow=_TMR_(0)     ' Update current time variable 

IF state4=0 THEN GOTO 1000 ELSE GOTO 1100 

GOTO 100

'===============================================================================
' 1000: State Machine 4 = 0 
'===============================================================================

1000  
  IF anap4>750 THEN       ' Check for 5V on the analog input 4
    IOCTL 211, 1          ' Set the virtual digital register HIGH
    delay4=1000+msnow     ' Add 1 second to delay  
	state4=1              ' Change the state to 1  
    SYSLOG "HI ANALOG IN 4="+STR$(anap4)
  ENDIF
  GOTO 100

'===============================================================================
' 1100: State Machine 4 = 1 
'===============================================================================
  
1100 ' state4 = high
  IF AND(anap4<=750,msnow>delay4) THEN  ' Check voltage is low for > 1 second
    IOCTL 211, 0          ' Set the virtual digital register LOW
    state4=0              ' Change the state to 0 
    SYSLOG "LO ANALOG IN 4="+STR$(anap4)
	delay4=0              ' Reset the delay timer 
  ELSE                    ' Output is high, but haven't passed hysterisis time   
    IF anap4>750 THEN   ' Check to see if input is still high
  	  delay4=1000+msnow   ' Add another second to the delay 
	ENDIF
  ENDIF
  GOTO 100

END 'EOF