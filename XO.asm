INCLUDE Irvine32.inc

.data
; Game board (3x3 grid)
board BYTE '1','2','3','4','5','6','7','8','9'
boardSize = ($ - board)

; Game state variables
currentPlayer BYTE 'X'     ; Current player (X or O)
gameOver BYTE 0            ; 0 = game continues, 1 = game over
winner BYTE 0              ; 'X', 'O', or 0 for draw
