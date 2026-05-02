.MODEL SMALL
.STACK 200h

.DATA
    playerName      DB  16 DUP(0)      
    nameLen         DB  0              

    titleMsg        DB  'BRICK BREAKER', 0
    promptMsg       DB  'Enter Your Name:', 0
    hintMsg         DB  'Press ENTER to continue | BACKSPACE to delete', 0

 
    BOX_ROW         EQU 13            ; row of the input box
    BOX_COL         EQU 30            ; left column of the box
    BOX_WIDTH       EQU 20            ; inner width (chars)
    PROMPT_ROW      EQU 11            ; row of "Enter Your Name:"
    PROMPT_COL      EQU 32
    TITLE_ROW       EQU 5
    TITLE_COL       EQU 33
    HINT_ROW        EQU 20
    HINT_COL        EQU 17
    MAX_NAME_LEN    EQU 15            ; maximum characters allowed

  
    ATTR_BACKGROUND EQU 01h         
    ATTR_TITLE      EQU 1Eh           
    ATTR_PROMPT     EQU 1Fh           
    ATTR_BOX_BORDER EQU 1Fh          
    ATTR_BOX_TEXT   EQU 1Ah           
    ATTR_HINT       EQU 17h           

.CODE
MAIN PROC
    ; Set up data segment
    MOV  AX, @DATA
    MOV  DS, AX

    MOV  AH, 00h
    MOV  AL, 03h
    INT  10h

    ; Hide cursor during drawing
    CALL HideCursor

  
    CALL FillBackground


    MOV  DH, TITLE_ROW
    MOV  DL, TITLE_COL
    MOV  BL, ATTR_TITLE
    LEA  SI, titleMsg
    CALL PrintString

  
    MOV  DH, PROMPT_ROW
    MOV  DL, PROMPT_COL
    MOV  BL, ATTR_PROMPT
    LEA  SI, promptMsg
    CALL PrintString


    CALL DrawInputBox

    MOV  DH, HINT_ROW
    MOV  DL, HINT_COL
    MOV  BL, ATTR_HINT
    LEA  SI, hintMsg
    CALL PrintString

    ; Show cursor for typing
    CALL ShowCursor

    ; Place cursor at start of input area
    MOV  DH, BOX_ROW
    MOV  DL, BOX_COL + 1
    CALL SetCursor


InputLoop:
    MOV  AH, 00h
    INT  16h
    ; AL = ASCII,  AH = scan code

    ; --- ENTER key (ASCII 13) ---
    CMP  AL, 0Dh
    JE   InputDone

    CMP  AH, 0Eh
    JE   HandleBackspace
    CMP  AL, 08h
    JE   HandleBackspace


    CMP  AL, 20h
    JB   InputLoop

 
    MOV  BL, nameLen
    CMP  BL, MAX_NAME_LEN
    JAE  InputLoop

    
    MOV  BH, 0
    MOV  SI, OFFSET playerName
    ADD  SI, BX
    MOV  [SI], AL
    INC  nameLen

   
    INC  SI
    MOV  BYTE PTR [SI], 0


    CALL RedrawBoxContents

    JMP  InputLoop

HandleBackspace:
    ; Check if buffer is empty
    MOV  BL, nameLen
    CMP  BL, 0
    JE   InputLoop

    ; Decrement length
    DEC  nameLen

    ; Clear the character from buffer
    MOV  BH, 0
    MOV  BL, nameLen
    MOV  SI, OFFSET playerName
    ADD  SI, BX
    MOV  BYTE PTR [SI], 0

    ; Redraw box
    CALL RedrawBoxContents

    JMP  InputLoop


InputDone:
    ; Require at least 1 character
    CMP  nameLen, 0
    JE   InputLoop

    ; Final null terminate
    MOV  BH, 0
    MOV  BL, nameLen
    MOV  SI, OFFSET playerName
    ADD  SI, BX
    MOV  BYTE PTR [SI], 0

 ; Show stored name as proof
    CALL FillBackground
    MOV  DH, 12
    MOV  DL, 30
    MOV  BL, ATTR_TITLE
    LEA  SI, playerName
    CALL PrintString

    ; Wait for any key then exit
    MOV  AH, 00h
    INT  16h

    MOV  AH, 4Ch
    MOV  AL, 0
    INT  21h

MAIN ENDP


FillBackground PROC
    MOV  AH, 06h
    MOV  AL, 0
    MOV  BH, ATTR_BACKGROUND
    MOV  CH, 0
    MOV  CL, 0
    MOV  DH, 24
    MOV  DL, 79
    INT  10h
    RET
FillBackground ENDP


DrawInputBox PROC
    ; ---- Top border ----
    MOV  DH, BOX_ROW - 1
    MOV  DL, BOX_COL
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0C9h
    MOV  BH, 0
    MOV  BL, ATTR_BOX_BORDER
    MOV  CX, 1
    INT  10h

    MOV  DL, BOX_COL + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0CDh
    MOV  CX, BOX_WIDTH
    INT  10h

    MOV  DL, BOX_COL + BOX_WIDTH + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0BBh
    MOV  CX, 1
    INT  10h

    ; ---- Middle row ----
    MOV  DH, BOX_ROW
    MOV  DL, BOX_COL
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0BAh
    MOV  BL, ATTR_BOX_BORDER
    MOV  CX, 1
    INT  10h

    MOV  DL, BOX_COL + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 20h
    MOV  BL, ATTR_BOX_TEXT
    MOV  CX, BOX_WIDTH
    INT  10h

    MOV  DL, BOX_COL + BOX_WIDTH + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0BAh
    MOV  BL, ATTR_BOX_BORDER
    MOV  CX, 1
    INT  10h

    ; ---- Bottom border ----
    MOV  DH, BOX_ROW + 1
    MOV  DL, BOX_COL
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0C8h
    MOV  BL, ATTR_BOX_BORDER
    MOV  CX, 1
    INT  10h

    MOV  DL, BOX_COL + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0CDh
    MOV  CX, BOX_WIDTH
    INT  10h

    MOV  DL, BOX_COL + BOX_WIDTH + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 0BCh
    MOV  CX, 1
    INT  10h

    RET
DrawInputBox ENDP


RedrawBoxContents PROC
    ; Step 1: Clear entire inner area with spaces
    MOV  DH, BOX_ROW
    MOV  DL, BOX_COL + 1
    CALL SetCursor
    MOV  AH, 09h
    MOV  AL, 20h
    MOV  BH, 0
    MOV  BL, ATTR_BOX_TEXT
    MOV  CX, BOX_WIDTH
    INT  10h

    ; Step 2: Reprint name from buffer character by character
    MOV  CL, nameLen       ; use CL as counter
    MOV  CH, 0
    CMP  CX, 0
    JE   PlaceCursor       ; nothing to print

    MOV  DH, BOX_ROW
    MOV  DL, BOX_COL + 1
    LEA  SI, playerName

PrintChar:
    MOV  AL, [SI]
    CMP  AL, 0
    JE   PlaceCursor

    CALL SetCursor
    MOV  AH, 09h
    MOV  BH, 0
    MOV  BL, ATTR_BOX_TEXT
    MOV  CX, 1
    INT  10h

    INC  SI
    INC  DL
    JMP  PrintChar

PlaceCursor:
    ; Step 3: Place cursor at end of text, clamped inside box
    MOV  BH, 0
    MOV  BL, nameLen
    ADD  BL, BOX_COL + 1

    ; Clamp: if BL >= BOX_COL + BOX_WIDTH + 1, set to BOX_COL + BOX_WIDTH
    CMP  BL, BOX_COL + BOX_WIDTH
    JBE  SetPos
    MOV  BL, BOX_COL + BOX_WIDTH

SetPos:
    MOV  DH, BOX_ROW
    MOV  DL, BL
    CALL SetCursor

    RET
RedrawBoxContents ENDP


PrintString PROC
PrintNext:
    MOV  AL, [SI]
    CMP  AL, 0
    JE   PrintDone

    CALL SetCursor
    MOV  AH, 09h
    MOV  BH, 0
    MOV  CX, 1
    INT  10h

    INC  SI
    INC  DL
    JMP  PrintNext

PrintDone:
    RET
PrintString ENDP


SetCursor PROC
    MOV  AH, 02h
    MOV  BH, 0
    INT  10h
    RET
SetCursor ENDP

HideCursor PROC
    MOV  AH, 01h
    MOV  CH, 20h
    MOV  CL, 00h
    INT  10h
    RET
HideCursor ENDP


ShowCursor PROC
    MOV  AH, 01h
    MOV  CH, 06h
    MOV  CL, 07h
    INT  10h
    RET
ShowCursor ENDP

END MAIN


