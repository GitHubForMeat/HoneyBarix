'===============================================================================
' BARIX Barionet BCL Application (C)2018, Written by ME v1.2
'===============================================================================

' Register Mapping
' Barionet 100  Milestone  Description           Application usage
' ------------  ---------  --------------------- -------------------------------
' 001           Output 5   Barix relay 1         DW PIR De-bounced output
' 107           Output 7   Virtual IO bit        Motion on camera 11 hardwired PIR 
' 111           Output 11  Virtual IO Bit        Camera 1 HIK Motion Start
' 112           Output 12  Virtual IO Bit        Camera 1 HIK Motion Start
' 119           Output 19  Virtual IO Bit        Camera 5 HIK Motion Start
' 120           Output 20  Virtual IO Bit        Camera 5 HIK Motion Start
' 131           Output 31  Virtual IO Bit        Camera 11 HIK Motion Start
' 132           Output 32  Virtual IO Bit        Camera 11 HIK Motion Start
' 133           Output 33  Virtual IO Bit        Camera 12 HIK Motion Start
' 134           Output 34  Virtual IO Bit        Camera 12 HIK Motion Start
' 205                      Digital Input 5       Perimeter Door Open (1 = open)
' 206                      Digital Input 6       Armed Stay/Away (1 = armed)
' 211           Input 11   Virtual IO bit        camera 1 record
' 212           Input 12   Virtual IO bit        camera 1 record + send email
' 213           Input 13   Virtual IO bit        camera 5 record
' 214           Input 14   Virtual IO bit        camera 5 record + send email
' 215           Input 15   Virtual IO bit        camera 11 record
' 216           Input 16   Virtual IO bit        camera 11 record + send email
' 217           Input 17   Virtual IO bit        camera 12 record
' 218           Input 18   Virtual IO bit        camera 12 record + send email
' 502                      Analog input 2 value  Driveway Optex Beam Sensor
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

' ------------------------------------------------------------------------------
' INIT: Version handling
' ------------------------------------------------------------------------------

 DIM VERS$(15) ' string
 DIM anap2     ' holds a/d value for analog input 2
 DIM anap3     ' holds a/d value for analog input 3
 DIM anap4     ' holds a/d value for analog input 4
 DIM delay0    ' Dubug delay
 DIM delay2    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay3    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay4    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay5    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM stateA2   ' State machine variable for Analog Input 2
 DIM stateA3   ' State machine variable for Analog Input 3
 DIM stateA4   ' State machine variable for Analog Input 4
 DIM stateA5   ' State machine variable for Virtual Input 7
 DIM camera1   ' Motion Started = 1, motion stopped = 001 - porte cochere
 DIM camera5   ' Motion Started = 1, motion stopped = 001 - Driveway & parking spot
 DIM camera11  ' Motion Started = 1, motion stopped = 001 - patio camera
 DIM camera12  ' Motion Started = 1, motion stopped = 001 - driveway camera

 DIM msnow     ' Holds current time in milliseconds, rolls over every 49 days
               ' Note: currently do not have a roll over condition handler

 VERS$="01.2 20180106"   ' Version of Main Application
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
 IOCTL 215, 0         ' Set Barix virtual IO register 215 = 0
 IOCTL 216, 0         ' Set Barix virtual IO register 216 = 0
 IOCTL 217, 0         ' Set Barix virtual IO register 217 = 0
 IOCTL 218, 0         ' Set Barix virtual IO register 218 = 0
 delay0=5000+msnow

'===============================================================================
' MAIN: Main program loop
'===============================================================================

100 'Main Program

  anap2=IOSTATE(502) ' Read analog input #2
  anap3=IOSTATE(503) ' Read analog input #3
  anap4=IOSTATE(504) ' Read analog input #4
  msnow=_TMR_(0)     ' Update current time variable
  IF stateA2=0 THEN GOSUB 2000 ELSE GOSUB 2100
  IF stateA3=0 THEN GOSUB 3000 ELSE GOSUB 3100
  IF stateA4=0 THEN GOSUB 4000 ELSE GOSUB 4100
  IF stateA5=0 THEN GOSUB 5000 ELSE GOSUB 5100
  if msnow>delay0 THEN GOSUB 900
  GOSUB 800
GOTO 100

'===============================================================================
' 800: CHECK MOTIONS
'===============================================================================

800
  IF camera1=0 THEN
    IF AND(IOSTATE(111)=1,IOSTATE(112)=0) THEN
	  camera1=1
	  SYSLOG "Camera 1 Motion Start"
	  IOCTL 211, 1          ' Set the virtual digital register HIGH
	ENDIF
  ELSE
    IF AND(IOSTATE(111)=0,IOSTATE(112)=1) THEN 
	  camera1=0 
	  SYSLOG "Camera 1 Motion Stop"
	  IOCTL 211, 0          ' Set the virtual digital register LOW
	ENDIF
  ENDIF  
  
  IF camera5=0 THEN
    IF AND(IOSTATE(119)=1,IOSTATE(120)=0) THEN 
	  camera5=1
	  SYSLOG "Camera 5 Motion Start"
      IOCTL 213, 1          ' Set the virtual digital register HIGH
	ENDIF
  ELSE
    IF AND(IOSTATE(119)=0,IOSTATE(120)=1) THEN
	  camera5=0 
	  SYSLOG "Camera 5 Motion Stop"
	  IOCTL 211, 0          ' Set the virtual digital register LOW
    ENDIF
  ENDIF  
  
  IF camera11=0 THEN
    IF AND(IOSTATE(131)=1,IOSTATE(132)=0) THEN 
	  camera11=1
	  SYSLOG "Camera 11 Motion Start"
	  IOCTL 215, 1          ' Set the virtual digital register HIGH
	ENDIF
  ELSE
    IF AND(IOSTATE(131)=0,IOSTATE(132)=1) THEN 
	  camera11=0 
	  SYSLOG "Camera 11 Motion Stop"
	  IOCTL 215, 0          ' Set the virtual digital register LOW
	ENDIF
  ENDIF
  
  IF camera12=0 THEN
    IF AND(IOSTATE(133)=1,IOSTATE(134)=0) THEN
	  camera12=1
	  SYSLOG "Camera 12 Motion Start"
	  IOCTL 217, 1          ' Set the virtual digital register HIGH
	ENDIF
  ELSE
    IF AND(IOSTATE(133)=0,IOSTATE(134)=1) THEN
	  camera12=0
	  SYSLOG "Camera 12 Motion Stop"
	  IOCTL 217, 0          ' Set the virtual digital register LOW
	ENDIF
  ENDIF

RETURN

'===============================================================================
' 900: DEBUG OUTPUT
'===============================================================================

900
  SYSLOG "PERIMETER  = "+STR$(IOSTATE(205))
  SYSLOG "ARMED      = "+STR$(IOSTATE(204))
  SYSLOG "ANALOG IN 2= "+STR$(anap2)
  SYSLOG "ANALOG IN 3= "+STR$(anap3)
  SYSLOG "ANALOG IN 4= "+STR$(anap4)
  SYSLOG "camera1    = "+STR$(camera1)
  SYSLOG "camera5    = "+STR$(camera5)
  SYSLOG "camera11   = "+STR$(camera11)
  SYSLOG "camera12   = "+STR$(camera12)
  delay0=60000+msnow
RETURN

'===============================================================================
' 2000: State Machine 2 = 0
'===============================================================================

2000
  IF anap2>750 THEN       ' Check for 5V on the analog input 2
    IOCTL 217, 1          ' Set the virtual digital register HIGH (rec)
    IF NOT(IOSTATE(205)<>0) THEN ' If permieter is secure
      IOCTL 218, 1        ' Set virtual bit high (send email)
	  SYSLOG "SEND EMAIL 2"
    ENDIF
    delay2=5000+msnow     ' Add 5 second to delay
    stateA2=1             ' Change the state to 1
    SYSLOG "HI ANALOG IN 2="+STR$(anap7)
  ENDIF
RETURN

'===============================================================================
' 2100: State Machine 2 = 1
'===============================================================================

2100 ' stateA2 = high
  IF AND(anap2<=750,msnow>delay2) THEN  ' Check voltage is low for > 1 second
    IOCTL 217, 0          ' Set the virtual digital register LOW
    IOCTL 218, 0          ' Set the virtual digital register LOW
    stateA2=0             ' Change the state to 0
    SYSLOG "LO ANALOG IN 2="+STR$(anap2)
    delay2=0              ' Reset the delay timer
  ELSE                    ' Output is high, but haven't passed hysteresis time
    IF anap2>750 THEN     ' Check to see if input is still high
      delay2=1000+msnow   ' Add another second to the delay
    ENDIF
  ENDIF
RETURN

'===============================================================================
' 3000: State Machine 3 = 0
'===============================================================================

3000
  IF anap3>750 THEN       ' Check for 5V on the analog input 3
    IOCTL 213, 1          ' Set the virtual digital register HIGH (rec)
    IOCTL 2, 0            ' Set RELAY 2 = OFF
    IF NOT(IOSTATE(205)<>0) THEN
      IOCTL 214, 1        ' Set virtual bit high (send email)
	  SYSLOG "SEND EMAIL 3"
    ENDIF
    delay3=5000+msnow     ' Add 5 second to delay
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
      delay3=5000+msnow       ' Add another 5 seconds to the delay
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


'===============================================================================
' 5000: State Machine 5 = 0
'===============================================================================

5000
  IF IOSTATE(107)<>0 THEN ' Check change of IO state 107
    IOCTL 215, 1          ' Set the virtual digital register HIGH
      IF NOT(IOSTATE(205)<>0) THEN 
        IOCTL 216, 1
	    SYSLOG "SEND EMAIL CAMERA 11"
      ENDIF	
    delay5=5000+msnow     ' Add 5 seconds to delay
    stateA5=1             ' Change the state to 1
  ENDIF
RETURN

'===============================================================================
' 5100: State Machine 5 = 1
'===============================================================================

5100 ' stateA3 = high
  IF AND(IOSTATE(107)=0,msnow>delay5) THEN  ' Check INPUT is low for > 5 seconds
    IOCTL 215,0
	IOCTL 216,0 
    stateA5=0                 ' Change the state to 0
    delay5=0                  ' Reset the delay timer
  ELSE                        ' Output is hi, but haven't passed hysteresis time
    IF IOSTATE(107)<>0 THEN   ' Check to see if input is still high
      delay5=5000+msnow       ' Add another 5 seconds to the delay
    ENDIF
  ENDIF
RETURN

END 'EOF
