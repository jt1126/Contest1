INCLUDE Irvine32.inc

.data
; Game board (3x3 grid)
board BYTE '1','2','3','4','5','6','7','8','9'
boardSize = ($ - board)

; Game state variables
currentPlayer BYTE 'X'     ; Current player (X or O)
gameOver BYTE 0            ; 0 = game continues, 1 = game over
winner BYTE 0              ; 'X', 'O', or 0 for draw

; Messages
msgTitle BYTE "TIC-TAC-TOE GAME",0
msgInstructions BYTE "Players take turns. Enter 1-9 to place your mark.",0
msgPlayerTurn BYTE "Player X's turn. Enter position (1-9): ",0
msgPlayerX BYTE "Player X's turn. Enter position (1-9): ",0
msgPlayerO BYTE "Player O's turn. Enter position (1-9): ",0
msgInvalid BYTE "Invalid move! Try again.",0
msgXWins BYTE "Player X wins!",0
msgOWins BYTE "Player O wins!",0
msgDraw BYTE "It's a draw!",0
msgPlayAgain BYTE "Play again? (Y/N): ",0
msgNewLine BYTE 0Dh, 0Ah, 0

; Board display strings
lineSeparator BYTE "---+---+---",0
verticalLine BYTE " | ",0
emptyCell BYTE "   ",0

.code

; Main procedure
main PROC
    call Randomize          ; Initialize random number generator
    
GameLoop:
    call InitializeGame
    call DisplayBoard
    call PlayGame
    call DisplayResult
    call AskPlayAgain
    cmp eax, 0
    jne GameLoop
    
    INVOKE ExitProcess, 0
main ENDP

; Initialize game variables
InitializeGame PROC
    ; Reset board positions to '1'..'9'
    mov ecx, boardSize      ; 9 cells
    mov esi, 0
    mov al, '1'             ; starting character

ResetBoard:
    mov board[esi], al      ; store '1','2',...,'9'
    inc al                  ; next character
    inc esi
    loop ResetBoard

    ; Reset game state
    mov currentPlayer, 'X'
    mov gameOver, 0
    mov winner, 0
    
    ret
InitializeGame ENDP

DisplayBoard PROC
    call Clrscr
    
    ; Display title
    mov edx, OFFSET msgTitle
    call WriteString
    call Crlf
    call Crlf
    
    ; Display instructions
    mov edx, OFFSET msgInstructions
    call WriteString
    call Crlf
    call Crlf
    
    ; Display board
    mov ecx, 3            ; 3 rows
    mov esi, 0            ; board index
RowLoop:
    ; Display first row of cells
    push ecx
    mov ecx, 3            ; 3 columns
    
ColLoop1:
    mov al, ' '
    call WriteChar
    mov al, board[esi]
    call WriteChar
    mov al, ' '
    call WriteChar
    
    inc esi
    cmp ecx, 1
    je SkipSeparator1
    
    mov al, '|'
    call WriteChar
   
SkipSeparator1:
    loop ColLoop1
    
    call Crlf
    
    ; Display separator line (except after last row)
    pop ecx
    cmp ecx, 1
    je SkipSeparator
    
    push ecx
    mov edx, OFFSET lineSeparator
    call WriteString
    call Crlf
    pop ecx
      
SkipSeparator:
    loop RowLoop
    
    call Crlf
    ret
DisplayBoard ENDP
; Main game loop
PlayGame PROC
GameTurn:
    cmp gameOver, 1
    je GameEnd
    
    ; Display current player's turn
    call DisplayPlayerPrompt
    
    ; Get player input
    call GetPlayerMove
    
    ; Update board
    call UpdateBoard
    
    ; Check for win or draw
    call CheckWin
    call CheckDraw
        
    ; Switch player
    call SwitchPlayer
    
    ; Redisplay board
    call DisplayBoard
    
    jmp GameTurn
    
GameEnd:
    ret
PlayGame ENDP

; Display appropriate player prompt
DisplayPlayerPrompt PROC
    cmp currentPlayer, 'X'
    jne DisplayO
    
    mov edx, OFFSET msgPlayerX
    jmp DisplayPrompt
    
DisplayO:
    mov edx, OFFSET msgPlayerO
    
DisplayPrompt:
    call WriteString
    ret
DisplayPlayerPrompt ENDP

; Get valid player move (1-9)
GetPlayerMove PROC
GetInput:
    call ReadInt          ; Read integer input
    
    ; Validate input (1-9)
    cmp eax, 1
    jl InvalidInput
    cmp eax, 9
    jg InvalidInput
    
    ; Check if position is available
    dec eax               ; Convert to 0-based index
    mov esi, eax
    mov al, board[esi]
    
    ; Check if cell contains a digit (available)
    cmp al, '9'
    ja InvalidInput
    cmp al, '1'
    jb InvalidInput
    
    ; Valid input
    ret
InvalidInput:
    mov edx, OFFSET msgInvalid
    call WriteString
    call Crlf
    call DisplayPlayerPrompt
    jmp GetInput
GetPlayerMove ENDP

; Update board with player's move
UpdateBoard PROC
    ; esi already contains board index from GetPlayerMove
    mov al, currentPlayer
    mov board[esi], al
    ret
UpdateBoard ENDP

;