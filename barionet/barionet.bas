'===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by ME
'===============================================================================

' Register Mapping
' Barionet 100  Milestone  Description           Application usage
' ------------  ---------  --------------------- -------------------------------
' 001           Output 5   Barix relay 1         DW PIR De-bounced output
' 205                      Digital Input 5       Perimeter Door Open (1 = open)
' 206                      Digital Input 6       Armed Stay/Away (1 = armed) 
' 211           Input 11   Virtual IO bit        camera 1 record
' 212           Input 12   Virtual IO bit        camera 1 record + send email
' 213           Input 13   Virtual IO bit        camera 5 record
' 214           Input 14   Virtual IO bit        camera 5 record + send email
' 503                      Analog input 3 value  DW PIR
' 504                      Analog input 4 value  PC PIR

' Unused Barionet 100 IO
' 206 

' Barionet 100  Milestone  Description
' ------------  ---------  ---------------------
' 002           Output 6   Barix relay 2 - Zone is wired to NO and COM in case
'                                          Barix loses power, zone will open
' 101                      Digital Output 1
' 102                      Digital Output 2
' 103                      Digital Output 3
' 104                      Digital Output 4
' 207                      Digital Input 7
' 208                      Digital Input 8
' 501                      Analog input 1 value
' 502                      Analog input 2 value

' ------------------------------------------------------------------------------
' INIT: Version handling
' ------------------------------------------------------------------------------

 DIM VERS$(15) ' string
 DIM anap3     ' holds a/d value for analog input 3
 DIM anap4     ' holds a/d value for analog input 4
 DIM delay3    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay4    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM stateA3   ' State machine variable for Analog Input 3
 DIM stateA4   ' State machine variable for Analog Input 4
 DIM msnow     ' Holds current time in milliseconds, rolls over every 49 days
               ' Note: currently do not have a roll over condition handler

 VERS$="01.0e 20160429"   ' Version of Main Application
 SYSLOG "Analog "+VERS$, 1

'===============================================================================
' INIT: Initialize
'===============================================================================

 DELAY 250            ' Quarter seconds delay on boot-up
 IOCTL 2, 1           ' Set RELAY 2 = ON
 IOCTL 211, 0         ' Set Barix virtual IO register 211 = 0
 IOCTL 212, 0         ' Set Barix virtual IO register 212 = 0
 IOCTL 213, 0         ' Set Barix virtual IO register 213 = 0
 IOCTL 214, 0         ' Set Barix virtual IO register 214 = 0

 
'===============================================================================
' MAIN: Main program loop
'===============================================================================

100 'Main Program
  anap3=IOSTATE(503) ' Read analog input #3
  anap4=IOSTATE(504) ' Read analog input #4
  msnow=_TMR_(0)     ' Update current time variable
  IF stateA3=0 THEN GOSUB 3000 ELSE GOSUB 3100
  IF stateA4=0 THEN GOSUB 4000 ELSE GOSUB 4100
GOTO 100

'===============================================================================
' 3000: State Machine 3 = 0
'===============================================================================

3000
  IF anap3>750 THEN       ' Check for 5V on the analog input 4
    IOCTL 213, 1          ' Set the virtual digital register HIGH (rec)
    IOCTL 2, 0            ' Set RELAY 2 = OFF
    IF NOT(IOSTATE(205)<>0) THEN
      IOCTL 214, 1        ' Set virtual bit high (send email) 
	  SYSLOG "SEND EMAIL 3"
    ENDIF
    delay3=5000+msnow     ' Add 1 second to delay
    stateA3=1             ' Change the state to 1
    SYSLOG "HI ANALOG IN 3="+STR$(anap3)
  ENDIF
RETURN

'===============================================================================
' 3100: State Machine 3 = 1
'===============================================================================

3100 ' stateA3 = high
  IF AND(anap4<=750,msnow>delay3) THEN  ' Check voltage is low for > 5 seconds
    IOCTL 213, 0              ' Set the virtual digital register LOW
    IOCTL 2, 1                ' Set RELAY 2 = ON
    IOCTL 214, 0
    stateA3=0                 ' Change the state to 0
    SYSLOG "LO ANALOG IN 3="+STR$(anap3)
    delay3=0                  ' Reset the delay timer
  ELSE                        ' Output is hi, but haven't passed hysteresis time
    IF anap3>750 THEN         ' Check to see if input is still high
      delay3=5000+msnow       ' Add another second to the delay
    ENDIF
  ENDIF
RETURN


'===============================================================================
' 4000: State Machine 4 = 0
'===============================================================================

4000
  IF anap4>750 THEN       ' Check for 5V on the analog input 4
    IOCTL 211, 1          ' Set the virtual digital register HIGH
    IF NOT(IOSTATE(205)<>0) THEN
      IOCTL 212, 1
	  SYSLOG "SEND EMAIL 4"
    ENDIF
    delay4=1000+msnow     ' Add 1 second to delay
    stateA4=1             ' Change the state to 1
    SYSLOG "HI ANALOG IN 4="+STR$(anap4)
  ENDIF
RETURN

'===============================================================================
' 4100: State Machine 4 = 1
'===============================================================================

4100 ' stateA4 = high
  IF AND(anap4<=750,msnow>delay4) THEN  ' Check voltage is low for > 1 second
    IOCTL 211, 0          ' Set the virtual digital register LOW
    IOCTL 212, 0          ' Set the virtual digital register LOW
    stateA4=0             ' Change the state to 0
    SYSLOG "LO ANALOG IN 4="+STR$(anap4)
    delay4=0              ' Reset the delay timer
  ELSE                    ' Output is high, but haven't passed hysteresis time
    IF anap4>750 THEN     ' Check to see if input is still high
      delay4=1000+msnow   ' Add another second to the delay
    ENDIF
  ENDIF
RETURN




END 'EOF
