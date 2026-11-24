################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Hakan Gokdogan, 1013986359
# Student 2: Bryan Chen, 1009307554
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

COLOURS:        .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00  # red, green, blue, yellow
WALL_COLOUR:    .word 0x808080      # grey
PLAYER_COLOUR:  .word 0xffffff      # white

# 14 rows * 7 columns * 4 bytes = 392 bytes for the playing field
grid:           .space 392

# The character starts in the middle column
player_col:     .word 3

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.

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
    lw $t0, ADDR_DSPL   # $t0 = base address for display
    sll $t1, $a1, 7     # multiply $t1 by 128 for vertical offset
    sll $t2, $a0, 2     # multiply $t2 by 4 for horizontal offset
    add $t0, $t0, $t1   # add vertical offset to $t0 (storing in $t0)
    add $t0, $t0, $t2   # add horizontal offset to $t0 (storing in $t0)
    sw $a2, 0($t0)      # write the colour to the correct location in memory
    jr $ra

##############################################################################
# fill_grid: fill the top 5 rows (35 cells) with random colours.
##############################################################################
fill_grid:
    la $t0, grid        # $t0 = pointer to current cell
    li $t1, 0           # $t1 = how many cells counted so far
fill_loop:
    beq $t1, 35, fill_done # jump to fill done if we've filled the 35 cells
    # generate a random int in [0, 4) and store it in $a0
    li $v0, 42          # selects MARS syscall for random int
    li $a0, 0           # ID of random number generator
    li $a1, 4           # the upper bound
    syscall
    sll $a0, $a0, 2     # index * 4 = byte offset
    la $t2, COLOURS     # load address of COLOURS into $t2
    add $t2, $t2, $a0   # $t2 points at random colour
    lw $t3, 0($t2)      # $t3 = COLOURS[index]
    sw $t3, 0($t0)      # store colour in grid cell
    addi $t0, $t0, 4    # move pointer to next cell
    addi $t1, $t1, 1    # increment the cell counter
    j fill_loop         # jump back to fill_loop
fill_done:
    jr $ra              # return to caller

##############################################################################
# draw_walls: grey border around the grid.
##############################################################################
draw_walls:
    addi $sp, $sp, -8   # make room for $ra and $s0
    sw $ra, 0($sp)      # save $ra at the lowest address in the stack
    sw $s0, 4($sp)      # save $s0

    li $s0, 1           # $s0 = y, from 1 to 16
walls_vert:
    li $a0, 1           # left wall (x = 1)
    move $a1, $s0       # set y to current loop counter
    lw $a2, WALL_COLOUR # load grey (WALL_COUNTER) into colour argument
    jal draw_unit       # paint unit at (1, y)
    li $a0, 9           # right wall (x = 9)
    move $a1, $s0       # set y to current loop counter
    lw $a2, WALL_COLOUR # load grey (WALL_COUNTER) into colour argument
    jal draw_unit       # paints (9, y)
    addi $s0, $s0, 1    # increment y
    ble $s0, 16, walls_vert # branch if y <= 16 (jump back to walls_vert)

    li $s0, 1           # $s0 = x, from 1 to 9
walls_horiz:
    move $a0, $s0       # top wall
    li $a1, 1           # set y = 1 (top wall)
    lw $a2, WALL_COLOUR # load grey (WALL_COUNTER) into colour argument
    jal draw_unit       # draw the cell
    move $a0, $s0       # bottom wall
    li $a1, 16          # set y = 16 (bottom wall)
    lw $a2, WALL_COLOUR # load grey as before
    jal draw_unit       # paint the cell
    addi $s0, $s0, 1    # increment x
    ble $s0, 9, walls_horiz # jump back to walls_horiz if x <= 9

    lw $ra, 0($sp)      # load word at $sp back into $ra
    lw $s0, 4($sp)      # load word at $sp + 4 back into $s0
    addi $sp, $sp, 8    # move stack pointer back to original
    jr $ra              # jump back to caller

##############################################################################
# draw_grid: draw every grid cell (empty cells are drawn black).
##############################################################################
draw_grid:
    addi $sp, $sp, -16  # make room for 4 words (16 bytes) on stack
    sw $ra, 0($sp)      # save return address
    sw $s0, 4($sp)      # save $s0
    sw $s1, 8($sp)      # save $s1
    sw $s2, 12($sp)     # save s2

    la $s2, grid        # $s2 = pointer to current cell
    li $s0, 0           # $s0 = row
grid_row:
    beq $s0, 14, grid_done # if all 14 rows have been drawn, exit (jump to grid_done)
    li $s1, 0           # $s1 = column
grid_col:
    beq $s1, 7, grid_next_row # if all 7 columns are done, jump to next row
    addi $a0, $s1, 2    # x = column + 2
    addi $a1, $s0, 2    # y = row + 2
    lw $a2, 0($s2)      # colour stored in the cell
    jal draw_unit       # draw the unit
    addi $s2, $s2, 4    # increment pointer by one word to next cell
    addi $s1, $s1, 1    # increment the column
    j grid_col          # repeat (back to grid_col)
grid_next_row:
    addi $s0, $s0, 1    # increment the row
    j grid_row          # go back to grid_row

grid_done:
    # restore the previous saved values
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16 # move stack pointer back to before
    jr $ra              # jump back to main

##############################################################################
# draw_player: draw the character in the bottom grid row.
##############################################################################
draw_player:
    lw $t0, player_col
    addi $a0, $t0, 2    # x = column + 2
    li $a1, 15          # y = bottom grid row
    lw $a2, PLAYER_COLOUR # load the colour for the player
    j draw_unit         # draw_unit returns straight to our caller


game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
