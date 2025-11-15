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