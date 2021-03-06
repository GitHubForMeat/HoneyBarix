CoB1+"U   barionet v1.1c.basR/�"  barionet.bas��Q  barionet.tok
��Z  errors.hlp '===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by ME
'===============================================================================

' Register Mapping
' Barionet 100  Milestone  Description           Application usage
' ------------  ---------  --------------------- -------------------------------
' 001           Output 5   Barix relay 1         DW PIR De-bounced output
' 107           Output 7   Virtual IO bit        Motion on camera 11 hardwired PIR 
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
 DIM msnow     ' Holds current time in milliseconds, rolls over every 49 days
               ' Note: currently do not have a roll over condition handler

 VERS$="01.1c 20160501"   ' Version of Main Application
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
 delay0=60000+msnow
 
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
GOTO 100

'===============================================================================
' 900: DEBUG OUTPUT
'===============================================================================

900
  SYSLOG "PERIMETER  = "+STR$(IOSTATE(205))
  SYSLOG "ARMED      = "+STR$(IOSTATE(204))  
  SYSLOG "ANALOG IN 3= "+STR$(anap3)
  SYSLOG "ANALOG IN 4= "+STR$(anap4)
  delay0=60000+msnow
RETURN

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
TBW ��       �      # �      ' �      + �      /       3       7       ;       ? $      C ,      G 4      K <      O E      S K    � 	01.2E 20160501 ?Analog  � +� <<� <� <� <� <� <� `	�``	;�`	;�`	` `		  SE  �`		  3E  �`			  E  x``  � $� `	7 H;w	;x	 `	?CAM 5 Hik Start  �E4 H;w	;x	 `	?CAM 5 Hik Stop  �F`
	7 H;o	;p	 `
	?CAM 1 Hik Start  �E4 H;o	;p	 `
	?CAM 1 Hik Stop  -F`	: H;� 	;� 	 `	?CAM 11 Hik Start  gE7 H;� 	;� 	 `	?CAM 11 Hik Stop  �F!I`	`	$ ?CAM 5 RECORDING Start <� F!H`	`	# ?CAM 5 RECORDING Stop <� F!I`
	`	$ ?CAM 1 RECORDING Start <� F!H`
	`	# ?CAM 1 RECORDING Stop <� F!I`	`		% ?CAM 11 RECORDING Start <� F!H`	`		$ ?CAM 11 RECORDING Stop <� F!?PERIMETER  =  X;� ?ARMED      =  X;� ?CAM1 ANALOG=  X`?CAM5 ANALOG=  X`?CAM11 PIR  =  X;k?camera1    =  X`
?camera5    =  X`?camera11   =  X`?CAM 1 211  =  X;� ?CAM 1 212  =  X;� ?CAM 5 213  =  X;� ?CAM 5 214  =  X;� ?CAM 11 215 =  X;� ?CAM 11 216 =  X;� `	�'	 `!`�_ `	?CAM 5 PIR ON = X` �<G;�  <� ?CAM 5 EMAIL F`	�`F!H`	�``; `	<<� ?CAM 5 PIR OFF = X``	 �E `� `	�`FF!`�Y `	?CAM 1 PIR ON = X` �G;�  <� ?CAM 1 EMAIL F`	�`F!H`	�``6 `	<� ?CAM 1 PIR OFF =  X``	 -E `� `	�`FF!;k^ `		?CAM 11 PIR ON = X;k gG;�  <� ?CAM 11 EMAIL F`	�`F!H;k	``9 `		<� ?CAM 11 PIR OFF = X;k`	 �E ;k `	�`FF!"_TMR_ ANAP3 ANAP4 DELAY0 DELAY3 DELAY4 DELAY5 STATEA3 STATEA4 STATEA5 CAMERA1 CAMERA5 CAMERA11 MSNOW VERS$ 0  BCL file not exisiting or invalid tokencode version (use correct tokenizer version)
1  PRINT was not last statement in line or wrong delimiter used (allowed ',' or ';')
2  Wrong logical operator in IF statement (allowed '=','>','>=','<','<=','<>')
3  ONLY String VARIABLE can be used as parameter in OPEN,READ,MIDxxx,EXEC
4  Wrong delimiter/parameter is used in list of parameters for this statement/function
5  ON statement must be followed by GOTO/GOSUB statement
6  First parameter of TIMER statement must be 1..4 (# for ON TIMER# GOSUB...)
7  Wrong element is used in this string/numeric expression, maybe a type mismatch
8  Divided by Zero
9  Wrong label is used in GOTO/GOSUB statement (allowed only a numeric constant)
10 Wrong symbol is used in source code, syntax error, tokenization is impossible
11 Wrong size of string/array is used in DIM (allowed only a numeric constant)
12 Wrong type in DIM statement used (only string variable or long variable/array allowed)
13 DIM was not last statement in line or wrong delimiter used (allowed only ',')
14 Missing bracket in expression or missing quote in string constant
15 Maximum nesting of calculations exceeded (too many brackets)
16 Assignment assumed (missing equal sign)
17 Wrong size of external tokenized TOK file (file might be corrupt)
18 Too many labels needed, tokenization is impossible
19 Identical labels in source code found, tokenization is impossible
20 Undefined label in GOTO/GOSUB statement found, tokenization is impossible
21 Missing THEN in IF/THEN statement
22 Missing TO in FOR/TO statement
23 Run-time warning: Possibly, maximum nesting of FOR-NEXT loops exceeded
24 NEXT statement without FOR statement or wrong index variable in NEXT statement
25 Maximum nesting of GOSUB-RETURN calls exceeded
26 RETURN statement without proper GOSUB statement
27 Lack of memory for dynamic memory allocation
28 String variable name conflict or too many string variables used
29 Long variable name conflict or too many long variables used
30 Insufficient space in memory for temp string, variable or program allocation
31 Current Array index bigger then maximal defined index in DIM statement
32 Wrong current number of file/stream handler (allowed only 0..4)
33 Wrong file/stream type/type name or file/stream is already closed
34 This file/stream handler is already used or file/stream already opened
35 Missing AS statement in OPEN AS statement
36 Wrong address in IOCTL or IOSTATE
37 Wrong serial port number in OPEN statement
38 Wrong baudrate parameter for serial port in OPEN statement
39 Wrong parity parameter for serial port in OPEN statement
40 Wrong data bits parameter for serial port in OPEN statement
41 Wrong stop bits parameter for serial port in OPEN statement
42 Wrong serial port type parameter in OPEN statement
43 Run-time warning: You lost data during PLAY -- Please, increase string size
44 For TCP/CIFS file/stream only handler with number 0..5 are allowed
45 Only standard size (256 bytes) string variable allowed for READ and WRITE in STP file
46 Wrong or out of string range parameters in MID$ or MIDxxx
47 Only one STP/F_C file can be opened at a time
48 '&' can be used ONLY at the end of a line
49 Syntax error in multiline IF...ENDIF (maybe wrong nesting)
50 Length of Search Tag must not exceed size of target String Variable for READ
51 DIM string/array variable name already used
52 Wrong user function name or array declaration missing
53 General syntax error: wrong or not allowed delimiter or statement at this position
54 Run-time warning: Lost data during UDP READ -- Please, increase string size
55 Run-time warning: Lost data during UDP receiving -- 1k buffer limit
56 Run-time warning: Impossible to allocate 6 TCP handles, if 6 are needed free up TCP command port and/or serial local ports
57 Run-time warning: Lost data during concatenation of strings -- Please, increase target string size (DIM statement)
58 Run-time warning: Lost data during assignment of string -- Please, increase target string size (DIM statement)
59 Indicated flash page (WEBx) is out of range for this HW
60 COB file (F_C type) exceeds 64k limit
61 Token size too long
62 Unrecognized token type
