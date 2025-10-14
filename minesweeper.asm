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
main PROC
    call Randomize
    call NewGameProc
    mov eax, 1000        ; 1 second pause
    call Delay
    call DrawScreen            ; draw once at start
    
GameLoop:
    call HandleInput           ; AL=1 if state changed
    test al, al
    jz   GameLoop              ; no input skip redraw

    ; if a move caused game over, reveal all mines
    cmp gameOver, 1
    jne  CheckWinState
    call RevealAll             
    mov eax, 1000        ; 1 second pause
    call Delay
    call DrawScreen


    jmp  GameLoop
    
    CheckWinState:
    cmp won, 1
    jne  Redraw
    call RevealAll             ; optionally reveal entire field on win too
    mov eax, 1000        ; 1 second pause
    call Delay
    call DrawScreen
    jmp  GameLoop

Redraw:
    mov eax,150        
    call Delay
    call DrawScreen            ; normal event-driven redraw
    jmp  GameLoop
main ENDP

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
    ; Set cursor color
    push eax
    mov eax, yellow + (black SHL 4)
    call SetTextColor
    pop eax
    
NoCursor:
    ; Display the cell content
    test al, REVEALED_MASK
    jz NotRevealed
    
    ; Revealed cell
    test al, MINE_MASK
    jz NotMineDisplay
    mov al, '*'
    call WriteChar
    jmp AfterDisplay
    
NotMineDisplay:
    mov ah, al
    and ah, ADJ_MASK
    shr ah, 1
    cmp ah, 0
    jne HasNumber
    mov al, '.'
    call WriteChar
    jmp AfterDisplay
    
HasNumber:
    add ah, '0'
    mov al, ah
    call WriteChar
    jmp AfterDisplay
    
NotRevealed:
    test al, FLAG_MASK
    jz HiddenCell
    mov al, 'F'
    call WriteChar
    jmp AfterDisplay
    
HiddenCell:
    mov al, '#'
    call WriteChar
    
AfterDisplay:
    ; Reset color and add space
    push eax
    mov eax, white + (black SHL 4)
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop eax
    
    inc ebx
    jmp DrawCols

NextRow:
    call Crlf
    inc ecx
    jmp DrawRows

DoneDrawing:
    call Crlf
    
    ; Display game status
    cmp gameOver, 1
    jne CheckWin
    mov edx, OFFSET loseMsg
    call WriteString
    jmp StatusDone
        
CheckWin:
    cmp won, 1
    jne StatusDone
    mov edx, OFFSET winMsg
    call WriteString
    
StatusDone:
    call Crlf
    popad
    ret
DrawScreen ENDP

HandleInput PROC
    pushad
    xor eax, eax              ; AL=0 -> default: no redraw

    call ReadKey          ; Otherwise, read it


    ; quit
    cmp al,'q'
    je  QuitProg

    ; new game
    cmp al,'n'
    jne CheckW
    call NewGameProc
    mov  al,1
    jmp  InputDone

CheckW:
    cmp al,'w'
    jne CheckS
    cmp cursorRow,0
    jle NoMove
    dec cursorRow
    mov al,1
    jmp InputDone
CheckS:
    cmp al,'s'
    jne CheckA
    cmp cursorRow,ROWS-1
    jge NoMove
    inc cursorRow
    mov al,1
    jmp InputDone
CheckA:
    cmp al,'a'
    jne CheckD
    cmp cursorCol,0
    jle NoMove
    dec cursorCol
    mov al,1
    jmp InputDone
CheckD:
    cmp al,'d'
    jne CheckFlag
    cmp cursorCol,COLS-1
    jge NoMove
    inc cursorCol
    mov al,1
    jmp InputDone

CheckFlag:
    cmp al,'f'
    jne CheckReveal
    cmp gameOver,1
    je  NoMove
    cmp won,1
    je  NoMove
    call ToggleFlagAtCursor
    mov  al,1
    jmp  InputDone

CheckReveal:
    cmp al,13
    je  DoReveal
    cmp al,' '
    jne NoMove
    
DoReveal:
    cmp gameOver,1
    je  NoMove
    cmp won,1
    je  NoMove
    call RevealAtCursorProc     ; may set gameOver
    mov  al,1                   ; changed (also covers win/lose)
    jmp  InputDone

QuitProg:
    INVOKE ExitProcess,0

NoMove:
    ; state unchanged -> AL remains 0
InputDone:
    popad
    ret
HandleInput ENDP

ToggleFlagAtCursor PROC
    pushad
    movzx eax, cursorRow
    movzx ebx, cursorCol
    imul eax, COLS
    add eax, ebx
    mov edi, OFFSET board
    add edi, eax
    test BYTE PTR [edi], REVEALED_MASK
    jnz ToggleRet
    xor BYTE PTR [edi], FLAG_MASK
ToggleRet:
    popad
    ret
ToggleFlagAtCursor ENDP

RevealAtCursorProc PROC
    pushad
    movzx eax, cursorRow
    movzx ebx, cursorCol
    call RevealCellRecursive  
    popad
    ret
RevealAtCursorProc ENDP

RevealAll PROC
    pushad
    mov ecx, BOARD_SIZE
    mov edi, OFFSET board
RevealLoop:
    test BYTE PTR [edi], REVEALED_MASK
    jnz AlreadyRev
    or   BYTE PTR [edi], REVEALED_MASK
AlreadyRev:
    inc edi
    loop RevealLoop
    popad
    ret
RevealAll ENDP

RevealCellRecursive PROC
    ; Input: eax = row, ebx = col
    ; Check bounds
    cmp eax, 0
    jl RevealRet
    cmp eax, ROWS
    jge RevealRet
    cmp ebx, 0
    jl RevealRet
    cmp ebx, COLS
    jge RevealRet
    
    ; Calculate index
    mov ecx, eax
    imul ecx, COLS
    add ecx, ebx
    mov edi, OFFSET board
    add edi, ecx
    
    ; Check if already revealed or flagged
    test BYTE PTR [edi], REVEALED_MASK
    jnz RevealRet
    test BYTE PTR [edi], FLAG_MASK
    jnz RevealRet
    
    ; Reveal cell
    or BYTE PTR [edi], REVEALED_MASK
    inc cellsRev
    
    ; If mine, game over
    test BYTE PTR [edi], MINE_MASK
    jnz MineRevealed

     ; If no adjacent mines, reveal neighbors recursively
    mov dl, [edi]
    and dl, ADJ_MASK
    shr dl, 1
    cmp dl, 0
    jne RevealRet

    ; Recursively reveal all 8 neighbors
    push eax
    push ebx
    dec eax
    dec ebx
    call RevealCellRecursive
    inc ebx
    call RevealCellRecursive
    inc ebx
    call RevealCellRecursive
    inc eax
    call RevealCellRecursive
    inc eax
    call RevealCellRecursive
    dec ebx
    call RevealCellRecursive
    dec ebx
    call RevealCellRecursive
    dec eax
    call RevealCellRecursive
    pop ebx
    pop eax

RevealRet:
    ret
    
MineRevealed:
    mov gameOver, 1
    ret
RevealCellRecursive ENDP
END main