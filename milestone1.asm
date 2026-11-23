################# CSC258 Assembly Final Project ###################
# Magical Drop - Milestone 1: draw the static scene.
#
# Student 1: Hakan Gokdogan, 1013986359
# Student 2: Name, Student Number
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
# Screen is 32x32 units. Unit (x, y) is at address: base + y*128 + x*4
#
# Layout (in units):
#   walls     : x = 1 and x = 9, y = 1 and y = 16 (grey)
#   grid      : x = 2..8 (7 columns), y = 2..15 (14 rows)
#   character : bottom grid row (y = 15), in column player_col
##############################################################################

    .data
ADDR_DSPL:      .word 0x10008000    # bitmap display
ADDR_KBRD:      .word 0xffff0000    # keyboard (used from milestone 2)

COLOURS:        .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00  # red, green, blue, yellow
WALL_COLOUR:    .word 0x808080      # grey
PLAYER_COLOUR:  .word 0xffffff      # white

# Playfield: 14 rows x 7 columns, one word per cell, row by row.
# Each cell holds the bubble's colour, or 0 if the cell is empty.
grid:           .space 392          # 14 * 7 * 4 bytes, starts as all 0
player_col:     .word 3             # character's column (0..6), starts in the middle

    .text
    .globl main

main:
    jal fill_grid       # put random bubbles in the top rows
    jal draw_walls
    jal draw_grid
    jal draw_player

    li $v0, 10          # exit
    syscall

##############################################################################
# draw_unit: colour one unit on the display.
#   $a0 = x, $a1 = y, $a2 = colour
##############################################################################
draw_unit:
    lw $t0, ADDR_DSPL
    sll $t1, $a1, 7     # y * 128
    sll $t2, $a0, 2     # x * 4
    add $t0, $t0, $t1
    add $t0, $t0, $t2
    sw $a2, 0($t0)
    jr $ra

##############################################################################
# fill_grid: fill the top 5 rows (35 cells) with random colours.
##############################################################################
fill_grid:
    la $t0, grid        # $t0 = pointer to current cell
    li $t1, 0           # $t1 = cell counter
fill_loop:
    beq $t1, 35, fill_done
    li $v0, 42          # random int in [0, 4) -> $a0
    li $a0, 0
    li $a1, 4
    syscall
    sll $a0, $a0, 2     # index * 4 = byte offset
    la $t2, COLOURS
    add $t2, $t2, $a0
    lw $t3, 0($t2)      # $t3 = COLOURS[index]
    sw $t3, 0($t0)      # store colour in grid cell
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j fill_loop
fill_done:
    jr $ra

##############################################################################
# draw_walls: grey border around the grid.
##############################################################################
draw_walls:
    addi $sp, $sp, -8   # save $ra and $s0
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    li $s0, 1           # $s0 = y, from 1 to 16
walls_vert:
    li $a0, 1           # left wall
    move $a1, $s0
    lw $a2, WALL_COLOUR
    jal draw_unit
    li $a0, 9           # right wall
    move $a1, $s0
    lw $a2, WALL_COLOUR
    jal draw_unit
    addi $s0, $s0, 1
    ble $s0, 16, walls_vert

    li $s0, 1           # $s0 = x, from 1 to 9
walls_horiz:
    move $a0, $s0       # top wall
    li $a1, 1
    lw $a2, WALL_COLOUR
    jal draw_unit
    move $a0, $s0       # bottom wall
    li $a1, 16
    lw $a2, WALL_COLOUR
    jal draw_unit
    addi $s0, $s0, 1
    ble $s0, 9, walls_horiz

    lw $ra, 0($sp)      # restore and return
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

##############################################################################
# draw_grid: draw every grid cell (empty cells are drawn black).
##############################################################################
draw_grid:
    addi $sp, $sp, -16  # save $ra, $s0, $s1, $s2
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)

    la $s2, grid        # $s2 = pointer to current cell
    li $s0, 0           # $s0 = row
grid_row:
    beq $s0, 14, grid_done
    li $s1, 0           # $s1 = column
grid_col:
    beq $s1, 7, grid_next_row
    addi $a0, $s1, 2    # x = column + 2
    addi $a1, $s0, 2    # y = row + 2
    lw $a2, 0($s2)      # colour stored in the cell
    jal draw_unit
    addi $s2, $s2, 4
    addi $s1, $s1, 1
    j grid_col
grid_next_row:
    addi $s0, $s0, 1
    j grid_row

grid_done:
    lw $ra, 0($sp)      # restore and return
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

##############################################################################
# draw_player: draw the character in the bottom grid row.
##############################################################################
draw_player:
    lw $t0, player_col
    addi $a0, $t0, 2    # x = column + 2
    li $a1, 15          # y = bottom grid row
    lw $a2, PLAYER_COLOUR
    j draw_unit         # draw_unit returns straight to our caller
