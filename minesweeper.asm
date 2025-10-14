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
