CoB1t<   barionet.bas#�  barionet.tok
��  errors.hlp '===============================================================================
' BARIX Barionet BCL Application (C)2015, Written by ME
'===============================================================================

' Register Mapping
' Barionet 100  Milestone  Description           Application usage
' ------------  ---------  --------------------- -------------------------------
' 001           Output 5   Barix relay 1         DW PIR Debounced output
' 205                      Digital Input 5       Garage Door Open
' 206                      Digital Input 6       Armed Away
' 211           Input 11   Virtual IO bit        camera 1 record
' 212           Input 12   Virtual IO bit        camera 1 record + send email
' 213           Input 13   Virtual IO bit        camera 5 record
' 214           Input 14   Virtual IO bit        camera 5 record + send email
' 503                      Analog input 3 value  DW PIR
' 504                      Analog input 4 value  PC PIR

' Unused Barionet 100 IO

' Barionet 100  Milestone  Description
' ------------  ---------  ---------------------
' 002           Output 6   Barix relay 2
' 101                      Digital Output 1
' 102                      Digital Ouput 2
' 103                      Digital Ouput 3
' 104                      Digital Ouput 4
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

 VERS$="01.0B 20160109"   ' Version of Main Application
 SYSLOG "Analog "+VERS$, 1

'===============================================================================
' INIT: Initialize
'===============================================================================

 DELAY 250            ' Quarter seconds delay on bootup
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
    IOCTL 1, 1            ' Set RELAY 1 = ON
    if AND(NOT(IOSTATE(205)<>0),IOSTATE(206)<>0) THEN
      IOCTL 214, 1        ' Set virtual bit high (send email) 
    ENDIF
    delay3=5000+msnow     ' Add 1 second to delay
        stateA3=1         ' Change the state to 1
    SYSLOG "HI ANALOG IN 3="+STR$(anap3)
  ENDIF
RETURN

'===============================================================================
' 3100: State Machine 3 = 1
'===============================================================================

3100 ' stateA3 = high
  IF AND(anap4<=750,msnow>delay3) THEN  ' Check voltage is low for > 5 seconds
    IOCTL 213, 0              ' Set the virtual digital register LOW
    IOCTL 1, 1                 ' Set RELAY 1 = OFF
    IOCTL 214, 0
    stateA3=0                 ' Change the state to 0
    SYSLOG "LO ANALOG IN 3="+STR$(anap3)
        delay3=0              ' Reset the delay timer
  ELSE                        ' Output is hi, but haven't passed hysteresis time
    IF anap3>750 THEN         ' Check to see if input is still high
          delay3=5000+msnow   ' Add another second to the delay
        ENDIF
  ENDIF
RETURN


'===============================================================================
' 4000: State Machine 4 = 0
'===============================================================================

4000
  IF anap4>750 THEN       ' Check for 5V on the analog input 4
    IOCTL 211, 1          ' Set the virtual digital register HIGH
    if AND(NOT(IOSTATE(205)<>0),IOSTATE(206)<>0) THEN
      IOCTL 212, 1
    ENDIF
    delay4=1000+msnow     ' Add 1 second to delay
        stateA4=1         ' Change the state to 1
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
        delay4=0          ' Reset the delay timer
  ELSE                    ' Output is high, but haven't passed hysteresis time
    IF anap4>750 THEN     ' Check to see if input is still high
          delay4=1000+msnow   ' Add another second to the delay
        ENDIF
  ENDIF
RETURN

END 'EOF
TB? �       �      # �      ' �      + �      / �      3 �      7 �      ; �    � 	01.0B 20160109 ?Analog  � +� <� <� <� <� `	;�`	;�`	` `		  � E  ?`		  �E  | `�_ <� <HG;� ;�  <� F`	�``	?HI ANALOG IN 3= X`F!H`	�``< <� <<� `	?LO ANALOG IN 3= X``	E `� `	�`FF!`�Z <� HG;� ;�  <� F`	�``	?HI ANALOG IN 4= X`F!H`	�``7 <� <� `	?LO ANALOG IN 4= X``	E `� `	�`FF!"_TMR_ ANAP3 ANAP4 DELAY3 DELAY4 STATEA3 STATEA4 MSNOW VERS$ 0  BCL file not exisiting or invalid tokencode version (use correct tokenizer version)
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
