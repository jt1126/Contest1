INCLUDE Irvine32.inc

ROWS   = 8
COLS   = 8
MINES  = 10
BOARD_SIZE = ROWS*COLS

MINE_MASK      = 00000001b
ADJ_MASK       = 00011110b
REVEALED_MASK  = 00100000b
FLAG_MASK      = 01000000b

.data
board      BYTE BOARD_SIZE DUP(0)
cursorRow  BYTE 0
cursorCol  BYTE 0
cellsRev   WORD 0
gameOver   BYTE 0
won        BYTE 0

titleMsg   BYTE "Minesweeper (WASD=Move, Space=Reveal, F=Flag, N=New, Q=Quit)",0
loseMsg    BYTE "BOOM! You hit a mine. (N)ew or (Q)uit",0
winMsg     BYTE "You cleared the field! (N)ew or (Q)uit",0

.code


NewGameProc PROC
    mov gameOver, 0
    mov won, 0
    mov cellsRev, 0
    mov cursorRow, 0
    mov cursorCol, 0
    call InitBoard
    ret
NewGameProc ENDP

InitBoard PROC
    pushad
    mov ecx, BOARD_SIZE
    mov edi, OFFSET board
    mov al, 0
    rep stosb

    xor ebx, ebx
PlaceLoop:
    cmp ebx, MINES
    je DonePlace
    mov eax, ROWS
    call RandomRange
    mov edx, eax
    mov eax, COLS
    call RandomRange
    mov ecx, edx
    imul ecx, COLS
    add ecx, eax
    mov edi, OFFSET board
    add edi, ecx
    test BYTE PTR [edi], MINE_MASK
    jnz PlaceLoop
    or BYTE PTR [edi], MINE_MASK
    inc ebx
    jmp PlaceLoop
DonePlace:
    call ComputeAdjacency
    popad
    ret

InitBoard ENDP