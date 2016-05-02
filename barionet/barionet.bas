'===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by ME
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
' 205                      Digital Input 5       Perimeter Door Open (1 = open)
' 206                      Digital Input 6       Armed Stay/Away (1 = armed) 
' 211           Input 11   Virtual IO bit        camera 1 record
' 212           Input 12   Virtual IO bit        camera 1 record + send email
' 213           Input 13   Virtual IO bit        camera 5 record
' 214           Input 14   Virtual IO bit        camera 5 record + send email
' 215           Input 15   Virtual IO bit        camera 11 record
' 216           Input 16   Virtual IO bit        camera 11 record + send email
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
 DIM delay0    ' Dubug delay 
 DIM delay3    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay4    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM delay5    ' Time value for hysteresis, to prevent signal bouncing on output
 DIM stateA3   ' State machine variable for Analog Input 3
 DIM stateA4   ' State machine variable for Analog Input 4
 DIM stateA5   ' State machine variable for virtual input 7
 DIM camera1   ' Motion Started = 1, motion stopped = 001
 DIM camera5   ' Motion Started = 1, motion stopped = 001
 DIM camera11  ' Motion Started = 1, motion stopped = 001
  
 DIM msnow     ' Holds current time in milliseconds, rolls over every 49 days
               ' Note: currently do not have a roll over condition handler

 VERS$="01.2E 20160501"   ' Version of Main Application
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
 delay0=5000+msnow
 
'===============================================================================
' MAIN: Main program loop
'===============================================================================

100 'Main Program

  anap3=IOSTATE(503) ' Read analog input #3
  anap4=IOSTATE(504) ' Read analog input #4
  msnow=_TMR_(0)     ' Update current time variable
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

  IF camera5=0 THEN
    IF AND(IOSTATE(119)=1,IOSTATE(120)=0) THEN camera5=1 SYSLOG "CAM 5 Hik Start" GOSUB 825 
  ELSE
    IF AND(IOSTATE(119)=0,IOSTATE(120)=1) THEN camera5=0 SYSLOG "CAM 5 Hik Stop" GOSUB 826 
  ENDIF  
  
  IF camera1=0 THEN
    IF AND(IOSTATE(111)=1,IOSTATE(112)=0) THEN camera1=1 SYSLOG "CAM 1 Hik Start" GOSUB 830
  ELSE
    IF AND(IOSTATE(111)=0,IOSTATE(112)=1) THEN camera1=0 SYSLOG "CAM 1 Hik Stop" GOSUB 831 
  ENDIF  
  
  IF camera11=0 THEN
    IF AND(IOSTATE(131)=1,IOSTATE(132)=0) THEN camera11=1 SYSLOG "CAM 11 Hik Start" GOSUB 835 
  ELSE
    IF AND(IOSTATE(131)=0,IOSTATE(132)=1) THEN camera11=0 SYSLOG "CAM 11 Hik Stop" GOSUB 836 
  ENDIF    
RETURN

'===============================================================================
' 825/6: EVALUATE CAMERA 5 STOP/RECORD
'===============================================================================

825
  IF OR(camera5=1,stateA3=1) THEN 
	SYSLOG "CAM 5 RECORDING Start"
	IOCTL 213, 1          ' Set the virtual digital register HIGH
  ENDIF
RETURN

826
  IF AND(camera5=0,stateA3=0) THEN 
	SYSLOG "CAM 5 RECORDING Stop"
	IOCTL 213, 0          ' Set the virtual digital register HIGH
  ENDIF  
RETURN  
  
'===============================================================================
' 830/1: EVALUATE CAMERA 1 STOP/RECORD
'===============================================================================

830
  IF OR(camera1=1,stateA4=1) THEN 
	SYSLOG "CAM 1 RECORDING Start"
	IOCTL 211, 1          ' Set the virtual digital register HIGH
  ENDIF
RETURN

831
  IF AND(camera1=0,stateA4=0) THEN 
	SYSLOG "CAM 1 RECORDING Stop"
	IOCTL 211, 0          ' Set the virtual digital register HIGH
  ENDIF 
RETURN

'===============================================================================
' 835/6: EVALUATE CAMERA 11 STOP/RECORD
'===============================================================================
  
835  
  IF OR(camera11=1,stateA5=1) THEN 
	SYSLOG "CAM 11 RECORDING Start"
	IOCTL 215, 1          ' Set the virtual digital register HIGH
  ENDIF
RETURN

836
  IF AND(camera11=0,stateA5=0) THEN 
	SYSLOG "CAM 11 RECORDING Stop"
	IOCTL 215, 0          ' Set the virtual digital register HIGH
  ENDIF 
RETURN
  
'===============================================================================
' 900: DEBUG OUTPUT
'===============================================================================

900
  SYSLOG "PERIMETER  = "+STR$(IOSTATE(205))
  SYSLOG "ARMED      = "+STR$(IOSTATE(204))  
  SYSLOG "CAM1 ANALOG= "+STR$(anap4)
  SYSLOG "CAM5 ANALOG= "+STR$(anap3)
  SYSLOG "CAM11 PIR  = "+STR$(IOSTATE(107))  
  SYSLOG "camera1    = "+STR$(camera1) 
  SYSLOG "camera5    = "+STR$(camera5) 
  SYSLOG "camera11   = "+STR$(camera11) 
  SYSLOG "CAM 1 211  = "+STR$(IOSTATE(211))
  SYSLOG "CAM 1 212  = "+STR$(IOSTATE(212))  
  SYSLOG "CAM 5 213  = "+STR$(IOSTATE(213))
  SYSLOG "CAM 5 214  = "+STR$(IOSTATE(214))  
  SYSLOG "CAM 11 215 = "+STR$(IOSTATE(215))
  SYSLOG "CAM 11 216 = "+STR$(IOSTATE(216))    
  delay0=600000+msnow
RETURN

'===============================================================================
' 3000: State Machine 3 = 0
'===============================================================================

3000
  IF anap3>750 THEN       ' Check for 5V on the analog input 3
    stateA3=1             ' Change the state to 1
	SYSLOG "CAM 5 PIR ON ="+STR$(anap3)
	GOSUB 825
    IOCTL 2, 0            ' Set RELAY 2 = OFF
    IF NOT(IOSTATE(205)<>0) THEN
      IOCTL 214, 1        ' Set virtual bit high (send email) 
	  SYSLOG "CAM 5 EMAIL"
    ENDIF
    delay3=5000+msnow     ' Add 5 second to delay
  ENDIF
RETURN

'===============================================================================
' 3100: State Machine 3 = 1
'===============================================================================

3100 ' stateA3 = high
  IF AND(anap3<=750,msnow>delay3) THEN  ' Check voltage is low for > 5 seconds
    stateA3=0                 ' Change the state to 0
    IOCTL 2, 1                ' Set RELAY 2 = ON
    IOCTL 214, 0
    SYSLOG "CAM 5 PIR OFF ="+STR$(anap3)
    delay3=0                  ' Reset the delay timer
	GOSUB 826
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
    stateA4=1             ' Change the state to 1
    SYSLOG "CAM 1 PIR ON ="+STR$(anap4)
	GOSUB 830
    IF NOT(IOSTATE(205)<>0) THEN
      IOCTL 212, 1
	  SYSLOG "CAM 1 EMAIL"
    ENDIF
    delay4=1000+msnow     ' Add 1 second to delay
  ENDIF
RETURN

'===============================================================================
' 4100: State Machine 4 = 1
'===============================================================================

4100 ' stateA4 = high
  IF AND(anap4<=750,msnow>delay4) THEN  ' Check voltage is low for > 1 second
    stateA4=0             ' Change the state to 0
    IOCTL 212, 0          ' Set the virtual digital register LOW
    SYSLOG "CAM 1 PIR OFF = "+STR$(anap4)
    delay4=0              ' Reset the delay timer
	GOSUB 831
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
    stateA5=1             ' Change the state to 1
	SYSLOG "CAM 11 PIR ON ="+STR$(IOSTATE(107))
	GOSUB 835
    IF NOT(IOSTATE(205)<>0) THEN 
      IOCTL 216, 1
	  SYSLOG "CAM 11 EMAIL"
    ENDIF	
    delay5=5000+msnow     ' Add 5 seconds to delay
  ENDIF
RETURN

'===============================================================================
' 5100: State Machine 5 = 1
'===============================================================================

5100 ' stateA5 = high
  IF AND(IOSTATE(107)=0,msnow>delay5) THEN  ' Check INPUT is low for > 5 seconds
    stateA5=0                 ' Change the state to 0
    IOCTL 216,0 
    SYSLOG "CAM 11 PIR OFF ="+STR$(IOSTATE(107))
    delay5=0                  ' Reset the delay timer
	GOSUB 836
  ELSE                        ' Output is hi, but haven't passed hysteresis time
    IF IOSTATE(107)<>0 THEN   ' Check to see if input is still high
      delay5=5000+msnow       ' Add another 5 seconds to the delay
    ENDIF
  ENDIF
RETURN

END 'EOF
