.MODEL SMALL
.STACK 200h

.DATA

    clr             DB 0
    selectedOption  DB 0

    title_str       DB "BRICK BREAKER", 0
    prompt_home     DB "Press any key to continue", 0

    playerName      DB 16 DUP(0)
    nameLen         DB 0
    prompt_name     DB "Enter Your Name:", 0
    hint_name       DB "ENTER=confirm  BACKSPACE=delete", 0

    str_menu_title  DB "BRICK BREAKER", 0
    str_start       DB "Start Game", 0
    str_instr       DB "Instructions", 0
    str_high        DB "High Scores", 0
    str_exit        DB "Exit", 0
    str_arrow       DB ">", 0

    title_hs        DB "HIGH SCORES", 0
    col_rank        DB "RANK", 0
    col_name_lbl    DB "NAME", 0
    col_score_lbl   DB "SCORE", 0
    prompt_hs       DB "Press any key to return", 0
    rank1           DB "#1", 0
    name1           DB "Shaheer", 0
    hscore1         DB "9500", 0
    rank2           DB "#2", 0
    name2           DB "Sulaim", 0
    hscore2         DB "8200", 0
    rank3           DB "#3", 0
    name3           DB "Eiman", 0
    hscore3         DB "7100", 0

    str_inst_title  DB "INSTRUCTIONS", 0
    str_ctrlhdr     DB "CONTROLS:", 0
    str_leftk       DB "A/LEFT  = Move paddle left", 0
    str_rightk      DB "D/RIGHT = Move paddle right", 0
    str_ruleshdr    DB "RULES:", 0
    str_r1          DB "Break ALL bricks to win", 0
    str_r2          DB "You start with 3 lives", 0
    str_r3          DB "Ball falls = 1 life lost", 0
    str_back        DB "Press any key to return", 0

    score           DW 0
    lives           DB 3
    gameOver        DB 0
    currentLevel    DB 1

    ballX           DW 157
    ballY           DW 170
    ballDX          DW 1
    ballDY          DW -1
    ballSpeed       DB 1

    paddleX         DW 116
    paddleW         DW 88
    paddleY         EQU 182
    PADDLE_SPEED    EQU 6
    ORIG_PAD_W      EQU 88
    WIDE_PAD_W      EQU 130

    brickActive     DB 50 DUP(1)

    scoreStr        DB "Score:0      ", 0
    livesStr        DB "Lives:3  ", 0
    lev_str         DB "Level:1", 0

    go_title        DB "GAME  OVER", 0
    go_win_title    DB "YOU  WIN!", 0
    go_score_lbl    DB "Final Score:", 0
    go_name_lbl     DB "Player:", 0
    go_prompt       DB "R=Restart  M=Menu  Q=Quit", 0
    go_scoreStr     DB "0000000", 0
    win_sub         DB "All 3 levels cleared!", 0

    ; File handling
    scoreFile       DB "SCORES.DAT", 0
    fileHandle      DW 0
    ; Score records: each is score(2 bytes) + name(16 bytes) = 18 bytes, 3 records = 54 bytes
    hs_score1       DW 0
    hs_name1        DB 16 DUP(0)
    hs_score2       DW 0
    hs_name2        DB 16 DUP(0)
    hs_score3       DW 0
    hs_name3        DB 16 DUP(0)

    lev2_str        DB "LEVEL 2", 0
    lev3_str        DB "LEVEL 3", 0
    lev_ready       DB "Get Ready!", 0
    lev_faster      DB "Ball is faster!", 0

    paddleDir       DB 0
    paused          DB 0
    ballFlash       DB 0        ; frames to draw ball red after paddle hit
    str_paused      DB "== PAUSED == Press P to resume", 0

    ; Level 2 layout — diamond/X pattern (0=empty 1=active)
    ; Row0: _XX_XX_XX_
    ; Row1: X_X_X_X_X_  wait — simpler: edges only
    layout2         DB 1,0,1,0,1,0,1,0,1,0   ; row 0
                    DB 0,1,0,1,0,1,0,1,0,1   ; row 1
                    DB 1,0,1,0,1,0,1,0,1,0   ; row 2
                    DB 0,1,0,1,0,1,0,1,0,1   ; row 3
                    DB 1,0,1,0,1,0,1,0,1,0   ; row 4

    ; Level 3 layout — V shape / fortress
    layout3         DB 1,1,1,1,1,1,1,1,1,1   ; row 0 full
                    DB 1,0,0,0,0,0,0,0,0,1   ; row 1 edges
                    DB 1,0,1,1,1,1,1,1,0,1   ; row 2 inner walls
                    DB 1,0,1,0,0,0,1,0,0,1   ; row 3 inner gaps
                    DB 1,1,1,0,0,0,1,1,1,1   ; row 4 base

    ; Power-up system
    bonusActive     DB 0        ; 0=none 1=falling
    bonusX          DW 0
    bonusY          DW 0
    bonusType       DB 0        ; 1=life 2=wide 3=slow
    bonusTimer      DB 0        ; frames before auto-despawn
    slowTimer       DB 0        ; frames of slow remaining
    wideTimer       DB 0        ; frames of wide remaining
    frameCounter    DB 0        ; increments every frame

    ; Pseudo random seed
    randSeed        DW 5A3Ch

    ; Bonus label strings
    bon_life        DB "+LIF", 0
    bon_wide        DB "WIDE", 0
    bon_slow        DB "SLOW", 0

    brickClr1       DB 4, 2, 3, 5, 14
    brickClr2       DB 12, 10, 11, 13, 6
    brickClr3       DB 4, 14, 15, 10, 12

.CODE

FILL_RECT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES

    PUSH AX
    MOV AX, 0A000h
    MOV ES, AX
    POP AX

    PUSH DX
    MOV DX, 320
    MUL DX
    POP DX
    ADD AX, BX
    MOV DI, AX
    MOV AL, clr

FR_ROW:
    PUSH CX
    PUSH DI
    REP STOSB
    POP DI
    POP CX
    ADD DI, 320
    DEC DX
    JNZ FR_ROW

    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
FILL_RECT ENDP

DRAW_CHAR_F PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    PUSH BP

    MOV CH, AL
    MOV CL, AH
    MOV SI, BX
    MOV DI, DX

    PUSH DS
    XOR AX, AX
    MOV DS, AX
    MOV BX, WORD PTR DS:[010Ch]
    MOV AX, WORD PTR DS:[010Eh]
    POP DS

    MOV DX, AX
    MOV AL, CH
    MOV AH, 0
    SHL AX, 1
    SHL AX, 1
    SHL AX, 1
    ADD BX, AX
    MOV AX, DX
    MOV DS, AX
    MOV AX, 0A000h
    MOV ES, AX
    MOV AX, DI
    MOV DX, 320
    MUL DX
    ADD AX, SI
    MOV DI, AX
    MOV DX, 8

DCF_ROW:
    MOV AL, DS:[BX]
    INC BX
    MOV BP, 8
DCF_COL:
    ROL AL, 1
    JNC DCF_SKIP
    MOV ES:[DI], CL
DCF_SKIP:
    INC DI
    DEC BP
    JNZ DCF_COL
    ADD DI, 312
    DEC DX
    JNZ DCF_ROW

    MOV AX, @DATA
    MOV DS, AX

    POP BP
    POP ES
    POP DS
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_CHAR_F ENDP

DRAW_STRING PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    MOV CL, AH
GS_LP:
    MOV AL, [SI]
    CMP AL, 0
    JE GS_DN
    MOV AH, CL
    CALL DRAW_CHAR_F
    ADD BX, 8
    INC SI
    JMP GS_LP
GS_DN:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
DRAW_STRING ENDP

SHOW_HOME_SCREEN PROC NEAR
    MOV clr, 1
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 192
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 0
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 314
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 70
    MOV BX, 20
    MOV CX, 280
    MOV DX, 20
    CALL FILL_RECT

    MOV clr, 14
    MOV AX, 100
    MOV BX, 40
    MOV CX, 30
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 3
    MOV AX, 100
    MOV BX, 75
    MOV CX, 30
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 2
    MOV AX, 100
    MOV BX, 110
    MOV CX, 30
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 5
    MOV AX, 100
    MOV BX, 145
    MOV CX, 30
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 8
    MOV AX, 160
    MOV BX, 20
    MOV CX, 280
    MOV DX, 12
    CALL FILL_RECT

    MOV SI, OFFSET title_str
    MOV BX, 56
    MOV DX, 74
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET prompt_home
    MOV BX, 36
    MOV DX, 163
    MOV AH, 15
    CALL DRAW_STRING

    MOV AH, 00h
    INT 16h
    RET
SHOW_HOME_SCREEN ENDP

SHOW_NAME_INPUT PROC NEAR
    MOV clr, 0
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 192
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 0
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 314
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 20
    MOV BX, 20
    MOV CX, 280
    MOV DX, 20
    CALL FILL_RECT

    MOV SI, OFFSET title_str
    MOV BX, 56
    MOV DX, 24
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET prompt_name
    MOV BX, 88
    MOV DX, 80
    MOV AH, 14
    CALL DRAW_STRING

    MOV clr, 8
    MOV AX, 95
    MOV BX, 80
    MOV CX, 160
    MOV DX, 16
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, 93
    MOV BX, 78
    MOV CX, 164
    MOV DX, 2
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, 111
    MOV BX, 78
    MOV CX, 164
    MOV DX, 2
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, 93
    MOV BX, 78
    MOV CX, 2
    MOV DX, 20
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, 93
    MOV BX, 240
    MOV CX, 2
    MOV DX, 20
    CALL FILL_RECT

    MOV SI, OFFSET hint_name
    MOV BX, 36
    MOV DX, 140
    MOV AH, 7
    CALL DRAW_STRING

    MOV nameLen, 0
    MOV SI, OFFSET playerName
    MOV CX, 16
NI_CLR:
    MOV BYTE PTR [SI], 0
    INC SI
    LOOP NI_CLR

NI_LP:
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE NI_DONE
    CMP AL, 08h
    JE NI_BS
    CMP AL, 'A'
    JB NI_CKL
    CMP AL, 'Z'
    JBE NI_ST
NI_CKL:
    CMP AL, 'a'
    JB NI_CKS
    CMP AL, 'z'
    JBE NI_ST
NI_CKS:
    CMP AL, ' '
    JE NI_ST
    JMP NI_LP

NI_ST:
    MOV BL, nameLen
    CMP BL, 15
    JAE NI_LP
    MOV BH, 0
    MOV SI, OFFSET playerName
    ADD SI, BX
    MOV [SI], AL
    INC nameLen
    INC SI
    MOV BYTE PTR [SI], 0
    CALL NI_RDW
    JMP NI_LP

NI_BS:
    MOV BL, nameLen
    CMP BL, 0
    JE NI_LP
    DEC nameLen
    MOV BH, 0
    MOV BL, nameLen
    MOV SI, OFFSET playerName
    ADD SI, BX
    MOV BYTE PTR [SI], 0
    CALL NI_RDW
    JMP NI_LP

NI_DONE:
    CMP nameLen, 0
    JE NI_LP
    MOV BH, 0
    MOV BL, nameLen
    MOV SI, OFFSET playerName
    ADD SI, BX
    MOV BYTE PTR [SI], 0
    RET
SHOW_NAME_INPUT ENDP

NI_RDW PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    MOV clr, 8
    MOV AX, 95
    MOV BX, 82
    MOV CX, 156
    MOV DX, 12
    CALL FILL_RECT
    MOV SI, OFFSET playerName
    MOV BX, 84
    MOV DX, 98
    MOV AH, 15
    CALL DRAW_STRING
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
NI_RDW ENDP

DRAW_MENU_OPTIONS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV clr, 1
    MOV AX, 70
    MOV BX, 60
    MOV CX, 200
    MOV DX, 100
    CALL FILL_RECT

    MOV AL, selectedOption
    CMP AL, 0
    JNE D0N
    MOV clr, 9
    JMP D0D
D0N: MOV clr, 1
D0D:
    MOV AX, 72
    MOV BX, 62
    MOV CX, 196
    MOV DX, 14
    CALL FILL_RECT
    MOV SI, OFFSET str_start
    MOV BX, 100
    MOV DX, 75
    MOV AH, 15
    CALL DRAW_STRING

    MOV AL, selectedOption
    CMP AL, 1
    JNE D1N
    MOV clr, 9
    JMP D1D
D1N: MOV clr, 1
D1D:
    MOV AX, 88
    MOV BX, 62
    MOV CX, 196
    MOV DX, 14
    CALL FILL_RECT
    MOV SI, OFFSET str_instr
    MOV BX, 100
    MOV DX, 91
    MOV AH, 15
    CALL DRAW_STRING

    MOV AL, selectedOption
    CMP AL, 2
    JNE D2N
    MOV clr, 9
    JMP D2D
D2N: MOV clr, 1
D2D:
    MOV AX, 104
    MOV BX, 62
    MOV CX, 196
    MOV DX, 14
    CALL FILL_RECT
    MOV SI, OFFSET str_high
    MOV BX, 100
    MOV DX, 107
    MOV AH, 15
    CALL DRAW_STRING

    MOV AL, selectedOption
    CMP AL, 3
    JNE D3N
    MOV clr, 9
    JMP D3D
D3N: MOV clr, 1
D3D:
    MOV AX, 120
    MOV BX, 62
    MOV CX, 196
    MOV DX, 14
    CALL FILL_RECT
    MOV SI, OFFSET str_exit
    MOV BX, 100
    MOV DX, 123
    MOV AH, 15
    CALL DRAW_STRING

    MOV AL, selectedOption
    MOV AH, 0
    MOV BX, 70
    MOV DX, 75
    MOV CL, 4
    SHL AX, CL
    ADD DX, AX
    MOV SI, OFFSET str_arrow
    MOV AH, 14
    CALL DRAW_STRING

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_MENU_OPTIONS ENDP

SHOW_MAIN_MENU PROC NEAR
    MOV selectedOption, 0

    MOV clr, 1
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 192
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 0
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 8
    MOV BX, 314
    MOV CX, 6
    MOV DX, 184
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 20
    MOV BX, 20
    MOV CX, 280
    MOV DX, 20
    CALL FILL_RECT

    MOV SI, OFFSET str_menu_title
    MOV BX, 56
    MOV DX, 24
    MOV AH, 15
    CALL DRAW_STRING

    CALL DRAW_MENU_OPTIONS

MN_LP:
    MOV AH, 00h
    INT 16h

    CMP AH, 48h
    JNE MN_CDN
    MOV AL, selectedOption
    CMP AL, 0
    JE MN_LP
    DEC selectedOption
    CALL DRAW_MENU_OPTIONS
    JMP MN_LP

MN_CDN:
    CMP AH, 50h
    JNE MN_CEN
    MOV AL, selectedOption
    CMP AL, 3
    JE MN_LP
    INC selectedOption
    CALL DRAW_MENU_OPTIONS
    JMP MN_LP

MN_CEN:
    CMP AH, 1Ch
    JNE MN_LP

    MOV AL, selectedOption
    CMP AL, 0
    JE MN_ST
    CMP AL, 1
    JE MN_INS
    CMP AL, 2
    JE MN_HS
    CMP AL, 3
    JE MN_EX
    JMP MN_LP

MN_ST:
    MOV score, 0
    MOV lives, 3
    MOV gameOver, 0
    MOV currentLevel, 1
    CALL RESET_LEVEL
    CALL SHOW_GAME_SCREEN
    CALL GAME_LOOP
    MOV AL, gameOver
    CMP AL, 2
    JE MN_ST
    JMP SHOW_MAIN_MENU

MN_INS:
    CALL SHOW_INSTRUCTIONS_SCREEN
    JMP SHOW_MAIN_MENU

MN_HS:
    CALL SHOW_HIGH_SCORES
    JMP SHOW_MAIN_MENU

MN_EX:
    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h

SHOW_MAIN_MENU ENDP

RESET_LEVEL PROC NEAR
    PUSH AX
    PUSH SI
    PUSH DI
    PUSH CX

    MOV ballX, 157
    MOV ballY, 170
    MOV ballDX, 1
    MOV ballDY, -1
    MOV paddleX, 116
    MOV AX, ORIG_PAD_W
    MOV paddleW, AX
    MOV paused, 0

    ; Clear power-up state
    MOV bonusActive, 0
    MOV bonusTimer, 0
    MOV slowTimer, 0
    MOV wideTimer, 0

    MOV AL, currentLevel
    MOV ballSpeed, AL

    ; Set brick layout based on level
    MOV AL, currentLevel
    CMP AL, 2
    JE RL_L2
    CMP AL, 3
    JE RL_L3

    ; Level 1 — all bricks active
    MOV SI, OFFSET brickActive
    MOV CX, 50
RL_L1LP:
    MOV BYTE PTR [SI], 1
    INC SI
    LOOP RL_L1LP
    JMP RL_DN

RL_L2:
    ; Level 2 — checkerboard from layout2
    MOV SI, OFFSET brickActive
    MOV DI, OFFSET layout2
    MOV CX, 50
RL_L2LP:
    MOV AL, [DI]
    MOV [SI], AL
    INC SI
    INC DI
    LOOP RL_L2LP
    JMP RL_DN

RL_L3:
    ; Level 3 — fortress from layout3
    MOV SI, OFFSET brickActive
    MOV DI, OFFSET layout3
    MOV CX, 50
RL_L3LP:
    MOV AL, [DI]
    MOV [SI], AL
    INC SI
    INC DI
    LOOP RL_L3LP

RL_DN:
    POP CX
    POP DI
    POP SI
    POP AX
    RET
RESET_LEVEL ENDP

SHOW_LEVEL_TRANSITION PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV clr, 0
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 190
    MOV BX, 0
    MOV CX, 320
    MOV DX, 10
    CALL FILL_RECT

    MOV clr, 1
    MOV AX, 70
    MOV BX, 60
    MOV CX, 200
    MOV DX, 60
    CALL FILL_RECT

    MOV AL, currentLevel
    CMP AL, 2
    JE SLT_L2
    MOV SI, OFFSET lev3_str
    JMP SLT_DRAW
SLT_L2:
    MOV SI, OFFSET lev2_str
SLT_DRAW:
    MOV BX, 112
    MOV DX, 82
    MOV AH, 14
    CALL DRAW_STRING

    MOV SI, OFFSET lev_ready
    MOV BX, 110
    MOV DX, 98
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET lev_faster
    MOV BX, 88
    MOV DX, 112
    MOV AH, 10
    CALL DRAW_STRING

    MOV AH, 86h
    MOV CX, 001Eh
    MOV DX, 8480h
    INT 15h

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_LEVEL_TRANSITION ENDP

SHOW_HIGH_SCORES PROC NEAR
    MOV clr, 0
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 14
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 6
    CALL FILL_RECT

    MOV clr, 1
    MOV AX, 6
    MOV BX, 0
    MOV CX, 320
    MOV DX, 18
    CALL FILL_RECT

    MOV SI, OFFSET title_hs
    MOV BX, 100
    MOV DX, 9
    MOV AH, 15
    CALL DRAW_STRING

    MOV clr, 3
    MOV AX, 30
    MOV BX, 10
    MOV CX, 300
    MOV DX, 12
    CALL FILL_RECT

    MOV SI, OFFSET col_rank
    MOV BX, 20
    MOV DX, 32
    MOV AH, 0
    CALL DRAW_STRING

    MOV SI, OFFSET col_name_lbl
    MOV BX, 120
    MOV DX, 32
    MOV AH, 0
    CALL DRAW_STRING

    MOV SI, OFFSET col_score_lbl
    MOV BX, 230
    MOV DX, 32
    MOV AH, 0
    CALL DRAW_STRING

    MOV SI, OFFSET rank1
    MOV BX, 30
    MOV DX, 55
    MOV AH, 14
    CALL DRAW_STRING
    MOV SI, OFFSET hs_name1
    MOV BX, 115
    MOV DX, 55
    MOV AH, 15
    CALL DRAW_STRING
    ; Show hs_score1
    MOV AX, hs_score1
    CALL GO_BUILD_SCORE_STR
    MOV SI, OFFSET go_scoreStr
    MOV BX, 225
    MOV DX, 55
    MOV AH, 10
    CALL DRAW_STRING

    MOV SI, OFFSET rank2
    MOV BX, 30
    MOV DX, 75
    MOV AH, 14
    CALL DRAW_STRING
    MOV SI, OFFSET hs_name2
    MOV BX, 115
    MOV DX, 75
    MOV AH, 15
    CALL DRAW_STRING
    MOV AX, hs_score2
    CALL GO_BUILD_SCORE_STR
    MOV SI, OFFSET go_scoreStr
    MOV BX, 225
    MOV DX, 75
    MOV AH, 10
    CALL DRAW_STRING

    MOV SI, OFFSET rank3
    MOV BX, 30
    MOV DX, 95
    MOV AH, 14
    CALL DRAW_STRING
    MOV SI, OFFSET hs_name3
    MOV BX, 115
    MOV DX, 95
    MOV AH, 15
    CALL DRAW_STRING
    MOV AX, hs_score3
    CALL GO_BUILD_SCORE_STR
    MOV SI, OFFSET go_scoreStr
    MOV BX, 225
    MOV DX, 95
    MOV AH, 10
    CALL DRAW_STRING

    MOV clr, 8
    MOV AX, 178
    MOV BX, 10
    MOV CX, 300
    MOV DX, 12
    CALL FILL_RECT

    MOV SI, OFFSET prompt_hs
    MOV BX, 48
    MOV DX, 180
    MOV AH, 15
    CALL DRAW_STRING

    MOV AH, 00h
    INT 16h
    RET
SHOW_HIGH_SCORES ENDP

SHOW_INSTRUCTIONS_SCREEN PROC NEAR
    MOV clr, 1
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 9
    MOV AX, 10
    MOV BX, 10
    MOV CX, 300
    MOV DX, 16
    CALL FILL_RECT

    MOV SI, OFFSET str_inst_title
    MOV BX, 96
    MOV DX, 13
    MOV AH, 15
    CALL DRAW_STRING

    MOV clr, 8
    MOV AX, 34
    MOV BX, 10
    MOV CX, 300
    MOV DX, 12
    CALL FILL_RECT

    MOV SI, OFFSET str_ctrlhdr
    MOV BX, 16
    MOV DX, 37
    MOV AH, 14
    CALL DRAW_STRING

    MOV SI, OFFSET str_leftk
    MOV BX, 16
    MOV DX, 52
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET str_rightk
    MOV BX, 16
    MOV DX, 64
    MOV AH, 15
    CALL DRAW_STRING

    MOV clr, 8
    MOV AX, 78
    MOV BX, 10
    MOV CX, 300
    MOV DX, 12
    CALL FILL_RECT

    MOV SI, OFFSET str_ruleshdr
    MOV BX, 16
    MOV DX, 81
    MOV AH, 14
    CALL DRAW_STRING

    MOV SI, OFFSET str_r1
    MOV BX, 16
    MOV DX, 96
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET str_r2
    MOV BX, 16
    MOV DX, 108
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET str_r3
    MOV BX, 16
    MOV DX, 120
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET str_back
    MOV BX, 48
    MOV DX, 150
    MOV AH, 7
    CALL DRAW_STRING

    MOV AH, 00h
    INT 16h
    RET
SHOW_INSTRUCTIONS_SCREEN ENDP

SHOW_GAME_SCREEN PROC NEAR
    MOV clr, 0
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 7
    MOV AX, 20
    MOV BX, 0
    MOV CX, 4
    MOV DX, 176
    CALL FILL_RECT

    MOV clr, 7
    MOV AX, 20
    MOV BX, 316
    MOV CX, 4
    MOV DX, 176
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, paddleY
    MOV BX, paddleX
    MOV CX, paddleW
    MOV DX, 7
    CALL FILL_RECT

    MOV clr, 14
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    CALL DRAW_BRICKS
    CALL UPDATE_HUD
    RET
SHOW_GAME_SCREEN ENDP

GET_BRICK_CLR PROC NEAR
    PUSH BX
    PUSH DX
    MOV AX, SI
    MOV BX, 10
    MOV DX, 0
    DIV BX
    MOV BX, AX
    MOV AL, currentLevel
    CMP AL, 2
    JE GBC_L2
    CMP AL, 3
    JE GBC_L3
    MOV AL, brickClr1[BX]
    JMP GBC_DN
GBC_L2:
    MOV AL, brickClr2[BX]
    JMP GBC_DN
GBC_L3:
    MOV AL, brickClr3[BX]
GBC_DN:
    POP DX
    POP BX
    RET
GET_BRICK_CLR ENDP

DRAW_ONE_BRICK PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    MOV DL, brickActive[SI]
    CMP DL, 0
    JNE DOB_OK
    MOV DL, clr
    MOV clr, 0
    MOV CX, 28
    MOV DX, 10
    CALL FILL_RECT
    MOV clr, DL
    JMP DOB_DN
DOB_OK:
    PUSH AX
    CALL GET_BRICK_CLR
    MOV clr, AL
    POP AX
    MOV CX, 28
    MOV DX, 10
    CALL FILL_RECT
DOB_DN:
    POP DX
    POP CX
    POP AX
    RET
DRAW_ONE_BRICK ENDP

DRAW_BRICKS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV AX, 26
    MOV SI, 0
DB_ROW:
    MOV BX, 6
    MOV CX, 0
DB_COL:
    CALL DRAW_ONE_BRICK
    ADD BX, 30
    INC SI
    INC CX
    CMP CX, 10
    JL DB_COL
    ADD AX, 12
    CMP SI, 50
    JL DB_ROW

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_BRICKS ENDP

UPDATE_HUD PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV clr, 8
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 18
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, 18
    MOV BX, 0
    MOV CX, 320
    MOV DX, 2
    CALL FILL_RECT

    CALL SCORE_TO_STR
    MOV SI, OFFSET scoreStr
    MOV BX, 4
    MOV DX, 4
    MOV AH, 14
    CALL DRAW_STRING

    CALL LIVES_TO_STR
    MOV SI, OFFSET livesStr
    MOV BX, 120
    MOV DX, 4
    MOV AH, 12
    CALL DRAW_STRING

    CALL LEVEL_TO_STR
    MOV SI, OFFSET lev_str
    MOV BX, 240
    MOV DX, 4
    MOV AH, 10
    CALL DRAW_STRING

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_HUD ENDP

LEVEL_TO_STR PROC NEAR
    PUSH AX
    PUSH DI
    MOV DI, OFFSET lev_str
    MOV BYTE PTR [DI],   'L'
    MOV BYTE PTR [DI+1], 'e'
    MOV BYTE PTR [DI+2], 'v'
    MOV BYTE PTR [DI+3], 'e'
    MOV BYTE PTR [DI+4], 'l'
    MOV BYTE PTR [DI+5], ':'
    MOV AL, currentLevel
    ADD AL, '0'
    MOV BYTE PTR [DI+6], AL
    MOV BYTE PTR [DI+7], 0
    POP DI
    POP AX
    RET
LEVEL_TO_STR ENDP

SCORE_TO_STR PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    MOV DI, OFFSET scoreStr
    MOV BYTE PTR [DI],   'S'
    MOV BYTE PTR [DI+1], 'c'
    MOV BYTE PTR [DI+2], 'o'
    MOV BYTE PTR [DI+3], 'r'
    MOV BYTE PTR [DI+4], 'e'
    MOV BYTE PTR [DI+5], ':'
    ADD DI, 6

    MOV AX, score
    CMP AX, 0
    JNE STS_NZ
    MOV BYTE PTR [DI], '0'
    INC DI
    MOV BYTE PTR [DI], 0
    JMP STS_DN
STS_NZ:
    MOV BX, 10
    MOV CX, 0
STS_DV:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE STS_DV
STS_WR:
    POP DX
    ADD DL, '0'
    MOV [DI], DL
    INC DI
    LOOP STS_WR
    MOV BYTE PTR [DI], 0
STS_DN:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SCORE_TO_STR ENDP

LIVES_TO_STR PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH DI
    MOV DI, OFFSET livesStr
    MOV BYTE PTR [DI],   'L'
    MOV BYTE PTR [DI+1], 'i'
    MOV BYTE PTR [DI+2], 'v'
    MOV BYTE PTR [DI+3], 'e'
    MOV BYTE PTR [DI+4], 's'
    MOV BYTE PTR [DI+5], ':'
    ADD DI, 6

    MOV AL, lives
    MOV AH, 0
    MOV BX, 10
    MOV DX, 0
    DIV BX              ; AL = tens, DX = ones
    CMP AL, 0
    JE LTS_ONES         ; skip tens digit if 0
    ADD AL, '0'
    MOV [DI], AL
    INC DI
LTS_ONES:
    MOV AL, DL
    ADD AL, '0'
    MOV [DI], AL
    INC DI
    MOV BYTE PTR [DI], 0

    POP DI
    POP DX
    POP BX
    POP AX
    RET
LIVES_TO_STR ENDP

CHECK_WIN PROC NEAR
    PUSH AX
    PUSH BX
    PUSH SI

    MOV SI, OFFSET brickActive
    MOV BX, 50
CW_LP:
    MOV AL, [SI]
    CMP AL, 0
    JNE CW_NO
    INC SI
    DEC BX
    JNZ CW_LP

    MOV AL, currentLevel
    CMP AL, 3
    JE CW_FULLWIN

    INC currentLevel
    CALL SHOW_LEVEL_TRANSITION
    CALL RESET_LEVEL
    CALL SHOW_GAME_SCREEN
    JMP CW_NO

CW_FULLWIN:
    MOV gameOver, 3

CW_NO:
    POP SI
    POP BX
    POP AX
    RET
CHECK_WIN ENDP

READ_INPUT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    MOV paddleDir, 0

    MOV AH, 01h
    INT 16h
    JZ RI_DN

    MOV AH, 00h
    INT 16h

    CMP AL, 'p'
    JE RI_PAUSE
    CMP AL, 'P'
    JE RI_PAUSE
    CMP AL, 1Bh
    JE RI_ESC
    CMP AL, 00h
    JE RI_EX
    CMP AL, 0E0h
    JE RI_EX
    CMP AL, 'A'
    JE RI_L
    CMP AL, 'a'
    JE RI_L
    CMP AL, 'D'
    JE RI_R
    CMP AL, 'd'
    JE RI_R
    JMP RI_DN

RI_EX:
    CMP AH, 4Bh
    JE RI_L
    CMP AH, 4Dh
    JE RI_R
    JMP RI_DN

RI_L:  MOV paddleDir, 1
    JMP RI_DN
RI_R:  MOV paddleDir, 2
    JMP RI_DN
RI_ESC: MOV gameOver, 1
    JMP RI_DN

RI_PAUSE:
    MOV AL, paused
    XOR AL, 1
    MOV paused, AL
    CMP AL, 1
    JNE RI_UNPAUSE
    ; Show paused text
    MOV clr, 8
    MOV AX, 88
    MOV BX, 20
    MOV CX, 280
    MOV DX, 12
    CALL FILL_RECT
    MOV SI, OFFSET str_paused
    MOV BX, 24
    MOV DX, 90
    MOV AH, 15
    CALL DRAW_STRING
    JMP RI_DN
RI_UNPAUSE:
    ; Erase paused text
    MOV clr, 0
    MOV AX, 88
    MOV BX, 20
    MOV CX, 280
    MOV DX, 12
    CALL FILL_RECT

RI_DN:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
READ_INPUT ENDP

MOVE_PADDLE PROC NEAR
    PUSH AX
    MOV AL, paddleDir
    CMP AL, 1
    JE MP_L
    CMP AL, 2
    JE MP_R
    JMP MP_DN
MP_L:
    MOV AX, paddleX
    SUB AX, PADDLE_SPEED
    CMP AX, 4
    JGE MP_SL
    MOV AX, 4
MP_SL:
    MOV paddleX, AX
    JMP MP_DN
MP_R:
    MOV AX, paddleX
    ADD AX, PADDLE_SPEED
    ; right clamp = 316 - paddleW
    PUSH BX
    MOV BX, 316
    SUB BX, paddleW
    CMP AX, BX
    JLE MP_SR
    MOV AX, BX
MP_SR:
    POP BX
    MOV paddleX, AX
MP_DN:
    POP AX
    RET
MOVE_PADDLE ENDP

DRAW_PADDLE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV clr, 0
    MOV AX, paddleY
    MOV BX, 4
    MOV CX, 312
    MOV DX, 7
    CALL FILL_RECT

    MOV clr, 15
    MOV AX, paddleY
    MOV BX, paddleX
    MOV CX, paddleW
    MOV DX, 7
    CALL FILL_RECT

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_PADDLE ENDP

MOVE_BALL PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV clr, 0
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    MOV AX, ballY
    CMP AX, 83
    JG MB_NO_REPAINT
    MOV AX, ballY
    ADD AX, 5
    CMP AX, 26
    JL MB_NO_REPAINT
    CALL DRAW_BRICKS
MB_NO_REPAINT:

    MOV BL, ballSpeed
    MOV BH, 0
    MOV AX, ballDX
    CMP AX, 0
    JL MB_NEGX
    ADD ballX, BX
    JMP MB_Y
MB_NEGX:
    SUB ballX, BX
MB_Y:
    MOV AX, ballDY
    CMP AX, 0
    JL MB_NEGY
    ADD ballY, BX
    JMP MB_DRAW
MB_NEGY:
    SUB ballY, BX
MB_DRAW:
    ; Ball color: red if flashing, yellow normally
    MOV AL, ballFlash
    CMP AL, 0
    JE MB_YELLOW
    DEC ballFlash
    MOV clr, 12         ; bright red
    JMP MB_DRAWBALL
MB_YELLOW:
    MOV clr, 14         ; yellow
MB_DRAWBALL:
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    POP DX
    POP CX
    POP BX
    POP AX
    RET
MOVE_BALL ENDP

CHECK_WALL PROC NEAR
    PUSH AX

    MOV AX, ballX
    CMP AX, 4
    JGE CWL_R
    NEG ballDX
    MOV ballX, 4
    CALL BEEP_WALL
    JMP CWL_T
CWL_R:
    MOV AX, ballX
    ADD AX, 5
    CMP AX, 315
    JLE CWL_T
    NEG ballDX
    MOV AX, 310
    MOV ballX, AX
    CALL BEEP_WALL
CWL_T:
    MOV AX, ballY
    CMP AX, 20
    JGE CWL_B
    NEG ballDY
    MOV ballY, 20
    CALL BEEP_WALL
CWL_B:
    MOV AX, ballY
    CMP AX, 192
    JL CWL_DN
    DEC lives
    MOV AL, lives
    CMP AL, 0
    JG CWL_RS
    MOV gameOver, 1
    JMP CWL_DN
CWL_RS:
    MOV bonusActive, 0
    CALL RESET_BALL
CWL_DN:
    POP AX
    RET
CHECK_WALL ENDP

CHECK_PADDLE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AX, ballDY
    CMP AX, 0
    JLE CPD_DN

    MOV AX, ballY
    ADD AX, 5
    CMP AX, paddleY
    JL CPD_DN
    CMP AX, paddleY + 7
    JG CPD_DN

    MOV BX, ballX
    MOV AX, paddleX
    ADD AX, paddleW
    CMP BX, AX
    JGE CPD_DN

    MOV AX, ballX
    ADD AX, 5
    MOV BX, paddleX
    CMP AX, BX
    JLE CPD_DN

    MOV clr, 0
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    MOV AX, paddleY
    SUB AX, 6
    MOV ballY, AX
    MOV ballDY, -1
    MOV ballFlash, 10   ; flash red for 10 frames

    MOV clr, 14
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

CPD_DN:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_PADDLE ENDP

CHECK_BRICK PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV SI, 0
    MOV DX, 26

CB_RW:
    MOV CX, 0
CB_CL:
    MOV AL, brickActive[SI]
    CMP AL, 0
    JE CB_NX

    PUSH DX
    PUSH AX
    MOV AX, CX
    MOV BX, 30
    MUL BX
    ADD AX, 6
    MOV DI, AX
    POP AX
    POP DX

    MOV AX, ballX
    ADD AX, 5
    CMP AX, DI
    JL CB_NX

    MOV AX, ballX
    MOV BX, DI
    ADD BX, 27
    CMP AX, BX
    JG CB_NX

    MOV AX, ballY
    ADD AX, 5
    CMP AX, DX
    JL CB_NX

    MOV AX, ballY
    MOV BX, DX
    ADD BX, 9
    CMP AX, BX
    JG CB_NX

    MOV brickActive[SI], 0
    ADD score, 100
    CALL BEEP_BRICK

    ; Erase brick cleanly
    PUSH DX
    PUSH DI
    MOV AX, DX
    MOV BX, DI
    MOV CX, 28
    MOV DX, 10
    MOV clr, 0
    CALL FILL_RECT
    POP DI
    POP DX

    ; Try to spawn a power-up at this brick position
    CALL SPAWN_BONUS

    MOV AX, ballX
    ADD AX, 5
    SUB AX, DI
    MOV BX, AX

    MOV AX, DI
    ADD AX, 28
    SUB AX, ballX
    CMP AX, BX
    JAE CB_HMO
    MOV BX, AX
CB_HMO:
    MOV AX, ballY
    ADD AX, 5
    SUB AX, DX
    MOV CX, AX

    MOV AX, DX
    ADD AX, 10
    SUB AX, ballY
    CMP AX, CX
    JAE CB_VMO
    MOV CX, AX
CB_VMO:
    CMP BX, CX
    JB CB_SIDE
    NEG ballDY
    JMP CB_DONE
CB_SIDE:
    NEG ballDX

CB_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

CB_NX:
    INC SI
    INC CX
    CMP CX, 10
    JL CB_CL
    ADD DX, 12
    CMP SI, 50
    JL CB_RW

CB_DN:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_BRICK ENDP

RESET_BALL PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV clr, 0
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    MOV clr, 0
    MOV AX, 160
    MOV BX, ballX
    MOV CX, 12
    MOV DX, 32
    CALL FILL_RECT

    MOV ballX, 157
    MOV ballY, 170
    MOV ballDX, 1
    MOV ballDY, -1

    CALL UPDATE_HUD

    MOV AH, 86h
    MOV CX, 000Fh
    MOV DX, 4240h
    INT 15h

    MOV clr, 14
    MOV AX, ballY
    MOV BX, ballX
    MOV CX, 6
    MOV DX, 6
    CALL FILL_RECT

    POP DX
    POP CX
    POP BX
    POP AX
    RET
RESET_BALL ENDP

GO_BUILD_SCORE_STR PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    MOV DI, OFFSET go_scoreStr
    ; AX already has the score value
    CMP AX, 0
    JNE GB_NZ
    MOV BYTE PTR [DI], '0'
    INC DI
    MOV BYTE PTR [DI], 0
    JMP GB_DN
GB_NZ:
    MOV BX, 10
    MOV CX, 0
GB_DV:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE GB_DV
GB_WR:
    POP DX
    ADD DL, '0'
    MOV [DI], DL
    INC DI
    LOOP GB_WR
    MOV BYTE PTR [DI], 0
GB_DN:
    POP DI
    POP DX
    POP CX
    POP BX
    RET
GO_BUILD_SCORE_STR ENDP

GAME_OVER_SCREEN PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Save score to file
    CALL SAVE_SCORES

    MOV clr, 0
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 200
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 0
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 4
    MOV AX, 192
    MOV BX, 0
    MOV CX, 320
    MOV DX, 8
    CALL FILL_RECT

    MOV clr, 8
    MOV AX, 60
    MOV BX, 40
    MOV CX, 240
    MOV DX, 22
    CALL FILL_RECT

    MOV AL, gameOver
    CMP AL, 3
    JE GOS_WIN
    MOV SI, OFFSET go_title
    JMP GOS_DT
GOS_WIN:
    MOV SI, OFFSET go_win_title
GOS_DT:
    MOV BX, 80
    MOV DX, 64
    MOV AH, 12
    CALL DRAW_STRING

    MOV AL, gameOver
    CMP AL, 3
    JNE GOS_SKW
    MOV SI, OFFSET win_sub
    MOV BX, 52
    MOV DX, 76
    MOV AH, 14
    CALL DRAW_STRING
GOS_SKW:

    MOV clr, 14
    MOV AX, 84
    MOV BX, 40
    MOV CX, 240
    MOV DX, 2
    CALL FILL_RECT

    MOV SI, OFFSET go_name_lbl
    MOV BX, 56
    MOV DX, 96
    MOV AH, 14
    CALL DRAW_STRING

    MOV SI, OFFSET playerName
    MOV BX, 116
    MOV DX, 96
    MOV AH, 15
    CALL DRAW_STRING

    MOV SI, OFFSET go_score_lbl
    MOV BX, 56
    MOV DX, 114
    MOV AH, 14
    CALL DRAW_STRING

    MOV AX, score
    CALL GO_BUILD_SCORE_STR

    MOV SI, OFFSET go_scoreStr
    MOV BX, 156
    MOV DX, 114
    MOV AH, 10
    CALL DRAW_STRING

    MOV clr, 1
    MOV AX, 156
    MOV BX, 20
    MOV CX, 280
    MOV DX, 14
    CALL FILL_RECT

    MOV SI, OFFSET go_prompt
    MOV BX, 24
    MOV DX, 159
    MOV AH, 15
    CALL DRAW_STRING

GO_WT:
    MOV AH, 00h
    INT 16h
    CMP AL, 'r'
    JE GO_RS
    CMP AL, 'R'
    JE GO_RS
    CMP AL, 'm'
    JE GO_MN
    CMP AL, 'M'
    JE GO_MN
    CMP AL, 'q'
    JE GO_QT
    CMP AL, 'Q'
    JE GO_QT
    CMP AL, 1Bh
    JE GO_QT
    JMP GO_WT

GO_RS:
    MOV gameOver, 2
    JMP GO_DN
GO_MN:
    MOV gameOver, 0
    JMP GO_DN
GO_QT:
    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h
GO_DN:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GAME_OVER_SCREEN ENDP

; ============================================================
; GET_RAND — simple LCG, returns value in AX
; ============================================================
GET_RAND PROC NEAR
    PUSH BX
    MOV AX, randSeed
    MOV BX, 8405h
    MUL BX
    INC AX
    MOV randSeed, AX
    POP BX
    RET
GET_RAND ENDP

; ============================================================
; SPAWN_BONUS
;   Called when brick at (DI=X, DX=Y) is destroyed
;   25% chance to spawn, only if no bonus active
; ============================================================
SPAWN_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    ; Skip if bonus already active
    MOV AL, bonusActive
    CMP AL, 1
    JE SB_DN

    ; Save brick position BEFORE GET_RAND corrupts DX
    MOV AX, DI
    ADD AX, 6
    MOV bonusX, AX      ; save X now
    ; Start bonus BELOW brick area (bricks end at Y=84)
    ; so it's never hidden by DRAW_BRICKS repaints
    MOV bonusY, 90

    ; 50% chance: rand & 1 == 0
    CALL GET_RAND       ; DX now corrupted by MUL inside, but we already saved
    AND AX, 1
    CMP AX, 0
    JNE SB_DN

    MOV bonusActive, 1
    MOV bonusTimer, 250

    ; Pick type randomly - equal chance for all 3
    CALL GET_RAND
    AND AX, 3
    CMP AX, 0
    JE SB_T1            ; 0 -> life
    CMP AX, 1
    JE SB_T2            ; 1 -> wide
    CMP AX, 2
    JE SB_T3            ; 2 -> slow
    JMP SB_T1           ; 3 -> life (remap)
SB_T1:
    MOV bonusType, 1
    JMP SB_DN
SB_T2:
    MOV bonusType, 2
    JMP SB_DN
SB_T3:
    MOV bonusType, 3

SB_DN:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SPAWN_BONUS ENDP

; ============================================================
; UPDATE_BONUS — move bonus down, check collection/despawn
; ============================================================
UPDATE_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV AL, bonusActive
    CMP AL, 1
    JNE UB_DN

    ; Erase bonus at current pos
    MOV clr, 0
    MOV AX, bonusY
    MOV BX, bonusX
    MOV CX, 24
    MOV DX, 10
    CALL FILL_RECT

    ; Tick timer
    DEC bonusTimer
    MOV AL, bonusTimer
    CMP AL, 0
    JE UB_DESPAWN

    ; Move down 2px
    ADD bonusY, 2

    ; Check fell off screen
    MOV AX, bonusY
    CMP AX, 196
    JGE UB_DESPAWN

    ; Check paddle collision
    ; bonus bottom = bonusY+8, paddle top = paddleY
    MOV AX, bonusY
    ADD AX, 8
    CMP AX, paddleY
    JL UB_DRAW
    CMP AX, paddleY+7
    JG UB_DRAW

    ; Check X overlap
    MOV AX, bonusX
    ADD AX, 16          ; bonus right
    MOV BX, paddleX
    CMP AX, BX
    JLE UB_DRAW

    MOV AX, bonusX      ; bonus left
    MOV BX, paddleX
    ADD BX, paddleW     ; paddle right
    CMP AX, BX
    JGE UB_DRAW

    ; Collected!
    CALL BEEP_BONUS
    CALL APPLY_BONUS
    MOV bonusActive, 0
    JMP UB_DN

UB_DESPAWN:
    MOV bonusActive, 0
    JMP UB_DN

UB_DRAW:
    ; Draw coloured pill based on type
    MOV AL, bonusType
    CMP AL, 1
    JE UB_CLR_LIFE
    CMP AL, 2
    JE UB_CLR_WIDE
    MOV clr, 11         ; slow = bright cyan (visible!)
    JMP UB_DRAWPILL
UB_CLR_LIFE:
    MOV clr, 12         ; life = bright red
    JMP UB_DRAWPILL
UB_CLR_WIDE:
    MOV clr, 10         ; wide = bright green
UB_DRAWPILL:
    MOV AX, bonusY
    MOV BX, bonusX
    MOV CX, 24
    MOV DX, 10
    CALL FILL_RECT

    ; Draw label text
    MOV AL, bonusType
    CMP AL, 1
    JE UB_STR_LIFE
    CMP AL, 2
    JE UB_STR_WIDE
    MOV SI, OFFSET bon_slow
    JMP UB_DRAWSTR
UB_STR_LIFE:
    MOV SI, OFFSET bon_life
    JMP UB_DRAWSTR
UB_STR_WIDE:
    MOV SI, OFFSET bon_wide
UB_DRAWSTR:
    MOV BX, bonusX
    MOV DX, bonusY
    MOV AH, 0           ; black text on coloured bg
    CALL DRAW_STRING

UB_DN:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_BONUS ENDP

; ============================================================
; APPLY_BONUS — apply effect of collected bonus
; ============================================================
APPLY_BONUS PROC NEAR
    PUSH AX

    MOV AL, bonusType
    CMP AL, 1
    JE AB_LIFE
    CMP AL, 2
    JE AB_WIDE

    ; Slow ball — force speed to 1 regardless of level
    MOV ballSpeed, 1
    MOV slowTimer, 240  ; 4 seconds
    JMP AB_DN

AB_LIFE:
    INC lives
    JMP AB_DN

AB_WIDE:
    MOV AX, WIDE_PAD_W
    MOV paddleW, AX
    MOV wideTimer, 240  ; 4 seconds

AB_DN:
    POP AX
    RET
APPLY_BONUS ENDP

; ============================================================
; UPDATE_POWER_TIMERS — tick slow/wide timers each frame
; ============================================================
UPDATE_POWER_TIMERS PROC NEAR
    PUSH AX

    ; Slow timer
    MOV AL, slowTimer
    CMP AL, 0
    JE UPT_WIDE
    DEC slowTimer
    CMP slowTimer, 0
    JNE UPT_WIDE
    ; Expired — restore speed to current level speed
    MOV AL, currentLevel
    MOV ballSpeed, AL

UPT_WIDE:
    MOV AL, wideTimer
    CMP AL, 0
    JE UPT_DN
    DEC wideTimer
    CMP wideTimer, 0
    JNE UPT_DN
    ; Expired — restore paddle width
    MOV AX, ORIG_PAD_W
    MOV paddleW, AX

UPT_DN:
    POP AX
    RET
UPDATE_POWER_TIMERS ENDP

; ============================================================
; BEEP_BRICK — short high beep when brick is hit
; ============================================================
BEEP_BRICK PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX

    ; Set frequency ~800Hz
    MOV AL, 0B6h
    OUT 43h, AL
    MOV AX, 05D3h
    OUT 42h, AL
    MOV AL, AH
    OUT 42h, AL

    ; Turn speaker on
    IN AL, 61h
    OR AL, 03h
    OUT 61h, AL

    ; Delay using INT 15h ~30ms
    MOV AH, 86h
    MOV CX, 0
    MOV DX, 7500h
    INT 15h

    ; Turn speaker off
    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL

    POP CX
    POP BX
    POP AX
    RET
BEEP_BRICK ENDP

; ============================================================
; BEEP_BONUS — lower beep when bonus collected
; ============================================================
BEEP_BONUS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX

    ; ~400Hz
    MOV AL, 0B6h
    OUT 43h, AL
    MOV AX, 0BA6h
    OUT 42h, AL
    MOV AL, AH
    OUT 42h, AL

    IN AL, 61h
    OR AL, 03h
    OUT 61h, AL

    MOV AH, 86h
    MOV CX, 0
    MOV DX, 0F000h
    INT 15h

    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL

    POP CX
    POP BX
    POP AX
    RET
BEEP_BONUS ENDP

; ============================================================
; BEEP_WALL — low thud when ball hits wall
; ============================================================
BEEP_WALL PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX

    ; ~200Hz
    MOV AL, 0B6h
    OUT 43h, AL
    MOV AX, 174Dh
    OUT 42h, AL
    MOV AL, AH
    OUT 42h, AL

    IN AL, 61h
    OR AL, 03h
    OUT 61h, AL

    MOV AH, 86h
    MOV CX, 0
    MOV DX, 5000h
    INT 15h

    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL

    POP CX
    POP BX
    POP AX
    RET
BEEP_WALL ENDP

; ============================================================
; LOAD_SCORES — load top 3 scores from SCORES.DAT
; ============================================================
LOAD_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Open file for reading (INT 21h AH=3Dh AL=0)
    MOV AH, 3Dh
    MOV AL, 0
    MOV DX, OFFSET scoreFile
    INT 21h
    JC LS_DN            ; file not found - skip

    MOV fileHandle, AX
    MOV BX, AX

    ; Read 54 bytes into hs_score1
    MOV AH, 3Fh
    MOV CX, 54
    MOV DX, OFFSET hs_score1
    INT 21h

    ; Close file
    MOV AH, 3Eh
    MOV BX, fileHandle
    INT 21h

LS_DN:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LOAD_SCORES ENDP

; ============================================================
; SAVE_SCORES — update top 3 and save to SCORES.DAT
; ============================================================
SAVE_SCORES PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV AX, score

    CMP AX, hs_score1
    JBE SS_CHK2
    ; Shift #2 -> #3
    MOV BX, hs_score2
    MOV hs_score3, BX
    MOV SI, OFFSET hs_name2
    MOV DI, OFFSET hs_name3
    CALL COPY_NAME
    ; Shift #1 -> #2
    MOV BX, hs_score1
    MOV hs_score2, BX
    MOV SI, OFFSET hs_name1
    MOV DI, OFFSET hs_name2
    CALL COPY_NAME
    ; New #1
    MOV hs_score1, AX
    MOV SI, OFFSET playerName
    MOV DI, OFFSET hs_name1
    CALL COPY_NAME
    JMP SS_WRITE

SS_CHK2:
    CMP AX, hs_score2
    JBE SS_CHK3
    ; Shift #2 -> #3
    MOV BX, hs_score2
    MOV hs_score3, BX
    MOV SI, OFFSET hs_name2
    MOV DI, OFFSET hs_name3
    CALL COPY_NAME
    ; New #2
    MOV hs_score2, AX
    MOV SI, OFFSET playerName
    MOV DI, OFFSET hs_name2
    CALL COPY_NAME
    JMP SS_WRITE

SS_CHK3:
    CMP AX, hs_score3
    JBE SS_WRITE
    MOV hs_score3, AX
    MOV SI, OFFSET playerName
    MOV DI, OFFSET hs_name3
    CALL COPY_NAME

SS_WRITE:
    MOV AH, 3Ch
    MOV CX, 0
    MOV DX, OFFSET scoreFile
    INT 21h
    JC SS_DN

    MOV fileHandle, AX
    MOV BX, AX

    MOV AH, 40h
    MOV CX, 54
    MOV DX, OFFSET hs_score1
    INT 21h

    MOV AH, 3Eh
    MOV BX, fileHandle
    INT 21h

SS_DN:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVE_SCORES ENDP

; ============================================================
; COPY_NAME — copies 16 bytes from DS:SI to DS:DI
; ============================================================
COPY_NAME PROC NEAR
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    MOV CX, 16
CN_LP:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP CN_LP
    POP DI
    POP SI
    POP CX
    POP AX
    RET
COPY_NAME ENDP

GAME_DELAY PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    MOV AH, 86h
    MOV CX, 0000h
    MOV DX, 4000h
    INT 15h
    POP DX
    POP CX
    POP AX
    RET
GAME_DELAY ENDP

GAME_LOOP PROC NEAR
    PUSH AX

GL_FR:
    CALL READ_INPUT

    ; If paused just loop doing nothing
    MOV AL, paused
    CMP AL, 1
    JE GL_PAUSEWAIT

    MOV AL, gameOver
    CMP AL, 0
    JNE GL_EX

    INC frameCounter

    CALL MOVE_PADDLE
    CALL DRAW_PADDLE

    ; If slow is active, only move ball every 3rd frame
    MOV AL, slowTimer
    CMP AL, 0
    JE GL_MOVEBALL      ; no slow — always move
    MOV AL, frameCounter
    MOV BL, 3
    DIV BL              ; AH = frameCounter mod 3
    CMP AH, 0
    JNE GL_SKIPBALL     ; skip unless frame divisible by 3
GL_MOVEBALL:
    CALL MOVE_BALL
    CALL CHECK_WALL

    MOV AL, gameOver
    CMP AL, 0
    JNE GL_EX

    CALL CHECK_PADDLE
    CALL CHECK_BRICK
GL_SKIPBALL:
    CALL UPDATE_POWER_TIMERS
    CALL CHECK_WIN

    MOV AL, gameOver
    CMP AL, 0
    JNE GL_EX

    CALL UPDATE_HUD
    CALL UPDATE_BONUS
    CALL GAME_DELAY
    JMP GL_FR

GL_PAUSEWAIT:
    CALL GAME_DELAY
    JMP GL_FR

GL_EX:
    CALL GAME_OVER_SCREEN
    POP AX
    RET
GAME_LOOP ENDP

main PROC
    MOV AX, @DATA
    MOV DS, AX

    MOV AX, 0013h
    INT 10h

    MOV AX, 0A000h
    MOV ES, AX

    CALL LOAD_SCORES

    CALL SHOW_HOME_SCREEN
    CALL SHOW_NAME_INPUT
    CALL SHOW_MAIN_MENU

    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h
main ENDP

END main
