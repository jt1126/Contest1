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

ComputeAdjacency PROC
    pushad
    mov esi, 0
NextCell:
    cmp esi, BOARD_SIZE
    jge DoneAdj
    mov edi, OFFSET board
    add edi, esi
    test BYTE PTR [edi], MINE_MASK
    jz NotMine
    mov eax, esi
    xor edx, edx
    mov ebx, COLS
    div ebx
    push edx
    push eax
    call BumpNeighbors
    add esp, 8
NotMine:
    inc esi
    jmp NextCell
DoneAdj:
    popad
    ret
ComputeAdjacency ENDP

BumpNeighbors PROC
    pushad
    mov ebp, [esp+36]  ; get r from stack
    mov ebx, [esp+40]  ; get c from stack
    
    ; Check all 8 neighbors
    mov eax, ebp
    dec eax
    mov edx, ebx
    dec edx
    call BumpOne
    
    mov eax, ebp
    dec eax
    mov edx, ebx
    call BumpOne
    
    mov eax, ebp
    dec eax
    mov edx, ebx
    inc edx
    call BumpOne
        
    mov eax, ebp
    mov edx, ebx
    dec edx
    call BumpOne
    
    mov eax, ebp
    mov edx, ebx
    inc edx
    call BumpOne
    
    mov eax, ebp
    inc eax
    mov edx, ebx
    dec edx
    call BumpOne
    
    mov eax, ebp
    inc eax
    mov edx, ebx
    call BumpOne
    
    mov eax, ebp
    inc eax
    mov edx, ebx
    inc edx
    call BumpOne
    
    popad
    ret
BumpNeighbors ENDP

BumpOne PROC
    cmp eax, 0
    jl BumpRet
    cmp eax, ROWS
    jge BumpRet
    cmp edx, 0
    jl BumpRet
    cmp edx, COLS
    jge BumpRet
    mov ecx, eax
    imul ecx, COLS
    add ecx, edx
    mov edi, OFFSET board
    add edi, ecx
    test BYTE PTR [edi], MINE_MASK
    jnz BumpRet
    mov al, [edi]
    mov ah, al
    and ah, ADJ_MASK
    shr ah, 1
    cmp ah, 8
    jae BumpRet
    inc ah
    shl ah, 1
    and al, NOT ADJ_MASK
    or al, ah
    mov [edi], al
BumpRet:
    ret
BumpOne ENDP

DrawScreen PROC
    pushad
    call Clrscr
    mov dh, 0
    mov dl, 0
    call Gotoxy
    mov edx, OFFSET titleMsg
    call WriteString
    call Crlf
    call Crlf

    ; draw grid with proper row/column tracking
    mov esi, 0
    mov ecx, 0  ; row counter
DrawRows:
    cmp ecx, ROWS
    jge DoneDrawing
    mov ebx, 0  ; col counter
    
DrawCols:
    cmp ebx, COLS
    jge NextRow
    
    ; Calculate current position in board
    mov eax, ecx
    imul eax, COLS
    add eax, ebx
    mov edi, OFFSET board
    add edi, eax
    mov al, [edi]
    
    ; Check if this is cursor position
    mov dl, cursorRow
    mov dh, cursorCol
    cmp dl, cl
    jne NoCursor
    cmp dh, bl
    jne NoCursor
    ; Set cursor color - FIXED REGISTER USAGE
    push eax
    mov eax, yellow + (black SHL 4)
    call SetTextColor
    pop eax