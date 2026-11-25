################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Hakan Gokdogan, 1013986359
# Student 2: Bryan Chen, 1009307554
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
# Decisions:
# - 10 key strokes trigger a new row
# - Sleep each frame 16 ms (gives us about 60 fps).
# - A keystroke that results in bumping against the wall does not count towards the counter
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

# Background music settings
MUSIC_INSTRUMENT: .word 80
MUSIC_VOLUME:     .word 50

MELODY:
    .word 0,3250, 66,250, 69,250, 66,250    # bar 1
    .word 64,250, 66,1000, 66,250, 69,250, 66,250, 64,1250, 66,250, 69,250, 66,250    # bar 2
    .word 64,250, 66,1000, 69,250, 69,250, 66,250, 64,250, 62,1000, 69,250, 69,250, 66,250    # bar 3
    .word 64,250, 62,1000, 69,250, 69,250, 66,250, 64,1250, 62,250, 62,250, 64,250    # bar 4
    .word 64,250, 66,250, 64,250, 66,250, 64,250, 66,250, 64,250, 66,250, 64,1250, 69,250, 69,250, 66,250    # bar 5
    .word 64,250, 66,1250, 69,250, 66,250, 64,250, 62,1250, 69,500    # bar 6
    .word 64,250, 66,1000, 62,250, 62,250, 62,250, 64,250, 62,1000, 62,250, 62,250, 64,250    # bar 7
    .word 67,250, 66,500, 62,250, 62,250, 62,250, 62,250, 64,250, 62,1250, 62,250, 62,250, 64,250    # bar 8
    .word 64,500, 64,250, 64,250, 64,250, 64,250, 64,250, 66,500, 64,500, 64,250, 64,250, 66,250, 64,500    # bar 9
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1000, 66,500    # bar 10 
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 71,1000, 66,500    # bar 11
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1500    # bar 12
    .word 66,250, 64,250, 66,500, 66,250, 64,250, 66,250, 64,250, 66,250, 64,500, 64,250, 62,1000    # bar 13
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1000, 66,500    # bar 10
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 71,1000, 66,500    # bar 11
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1500    # bar 12
    .word 66,250, 64,250, 66,500, 66,250, 64,250, 66,250, 64,250, 66,250, 64,500, 64,250, 62,250, 66,500, 64,250    # bar 14
    .word 66,500, 64,250, 62,250, 0,500, 62,250, 64,250, 66,500, 66,500, 0,500, 62,250, 64,250    # bar 15
    .word 66,250, 66,250, 64,250, 62,250, 66,250, 66,250, 64,250, 62,250, 64,500, 64,250, 62,1000, 62,250    # bar 16
    .word 62,250, 64,250, 66,750, 62,500, 57,750, 55,250, 54,500, 62,250, 62,250, 64,250    # bar 17
    .word 66,500, 64,250, 66,500, 66,250, 66,500, 66,250, 64,250, 64,250, 62,250, 64,250, 62,250, 62,250, 64,250    # bar 18
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1000, 66,500    # bar 10
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 71,1000, 66,500    # bar 11
    .word 66,500, 64,500, 66,500, 64,250, 66,500, 64,250, 69,1500    # bar 12
    .word 66,250, 64,250, 66,500, 66,250, 64,250, 66,250, 64,250, 66,250, 64,500, 64,250, 62,1000    # bar 13
    .word -1, 0    # end of song: loop back to the start

##############################################################################
# Mutable Data
##############################################################################

# 14 rows * 7 columns * 4 bytes = 392 bytes for the playing field
grid:           .space 392

# The character starts in the middle column
player_col:     .word 3

# The colour of the bubbles the character is holding (0 = none)
held_colour:    .word 0

# How many bubbles are currently held
held_count:     .word 0

# The keystrokes since the last new row
key_count:      .word 0

# The current music state (offset of the next note)
music_offset:   .word 0

# The time when the next note is due
next_note_time: .word 0

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.

main:
    jal fill_grid
    li $v0, 30          # store 30 for syscall
    syscall             # get system time (syscall 30)
    sw $a0, next_note_time # store the next_note_time in $a0 (first note is right now)
    j game_loop
    
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
    addi $sp, $sp, 16   # move stack pointer back to before
    jr $ra              # jump back to main

##############################################################################
# draw_player: draw the character under the grid.
##############################################################################
draw_player:
    lw $t0, player_col
    addi $a0, $t0, 2    # x = column + 2
    li $a1, 17          # y = row just below the bottom wall
    lw $a2, PLAYER_COLOUR # load the colour for the player
    j draw_unit         # draw_unit returns straight to our caller


##############################################################################
# clear_player_area: paint all the units outside the grid black.
##############################################################################
clear_player_area:
    addi $sp, $sp, -12  # make room in stack for 3 words
    sw $ra, 0($sp)      # store $ra in the first position in the stack
    sw $s0, 4($sp)      # store $s0 in the stack
    sw $s1, 8($sp)      # store $s1 in the stack

    li $s1, 17          # y = 17
clear_row:
    li $s0, 2           # x = 2

clear_col:
    move $a0, $s0       # moving x into $a0
    move $a1, $s1       # moving y into $a1
    li $a2, 0           # move the colour 0 (which is just black) into $a2
    jal draw_unit       # draw the unit (black)
    addi $s0, $s0, 1         # increment x by 1
    ble $s0, 8, clear_col # jump to clear_col if x <= 8

    addi $s1, $s1, 1    # increment y by 1
    ble $s1, 31, clear_row # jump to clear_row if y <= 31

clear_done:
    # restore previous saved values
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    # restore the stack pointer to before
    addi $sp, $sp, 12

    jr $ra # jump back to caller

##############################################################################
# draw_held: draw the held units
##############################################################################
draw_held:    
    addi $sp, $sp, -12  # make room in stack for 3 words
    sw $ra, 0($sp)      # store $ra in the first position in the stack
    sw $s0, 4($sp)      # store $s0 (current y) in the stack
    sw $s1, 8($sp)      # store $s1 (ending y) in the stack

    li $s0, 18          # set $s0 (y) to 18
    lw $t0, held_count  # load the count of held balls into $t0
    addi $s1, $t0, 18    # load $t0 (the held balls) + 18 into $s1
    ble $s1, 32, held_loop # if $s1 (the ending y) is less than 32, go to the loop
    li $s1, 32          # load 32 into the y

held_loop:
    beq $s0, $s1, held_done # if the current y equals to balls + 18, we're done
    lw $t1, player_col
    addi $a0, $t1, 2    # Add 2 to the current position of the player
    move $a1, $s0       # Move $s0 (y) into $a1
    lw $a2, held_colour # load the colour of the held balls into $a2
    jal draw_unit       # draw the held bubble
    addi $s0, $s0, 1    # increment y by 1
    j held_loop         # loop back up

held_done:
    # restore previous saved values
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    # restore the stack pointer to before
    addi $sp, $sp, 12

    jr $ra # jump back to caller

##############################################################################
# handle_input: handle keyboard inputs
##############################################################################
handle_input:
    addi $sp, $sp, -4   # make room in the stack for $ra
    sw $ra, 0($sp)      # store $ra in the stack

    lw $t0, ADDR_KBRD   # load the base address of the keyboard into $t0
    lw $t1, 0($t0)      # load the word at offset 0 of $t0 into $t1
    bne $t1, 1, input_done # if the word isn't 1, that means no key was pressed, 
                        # so we don't need to do anything
    lw $t2, 4($t0)      # load the word at offset 4 of $t0 into $t2 (the key's
                        # ASCII code)
    beq $t2, 0x61, key_a  # if the key is a, then go to key_a
    beq $t2, 0x64, key_d  # if the key is d, then go to key_d
    beq $t2, 0x73, key_s  # if the key is s, then go to key_s
    beq $t2, 0x71, key_q  # if the key is q, then go to key_q
    beq $t2, 0x77, key_w  # if the key is w, then go to key_w
    j input_done

key_w:
    jal throw             # go to throw
    bltz $v0, input_done  # if nothing was thrown, then we're done
    move $a1, $v0         # set $a1 to $v0
    lw $a0, player_col    # set $a0 to player_col
    jal check_match       # go to check_match
    jal check_game_over   # go to check_game_over
    bne $v0, $zero, game_over # if game over then go to game over
    j count_key           # go to count_key
    
key_a:
    lw $t3, player_col    # load the current player column into $t3
    blez $t3, input_done  # if we're already at the very left, just skip to input_done
    addi $t3, $t3, -1     # decrement $t3 (current player column) by 1
    sw $t3, player_col    # save the updated column back into player_col
    j count_key

key_d:
    lw $t3, player_col    # load the current player column into $t3
    bge $t3, 6, input_done  # if we're already at the very right, just skip to input_done
    addi $t3, $t3, 1      # increment $t3 (current player column) by 1
    sw $t3, player_col    # save the updated column back into player_col
    j count_key

key_s:
    jal grab              # go to grab
    j count_key

key_q:
    li $v0, 10            # load 10 into $v0
    syscall               # quit (since q)
    j count_key

count_key:
    lw $t0, key_count     # load the key_count into $t0
    addi $t0, $t0, 1      # increment $t0 by 1
    sw $t0, key_count     # store $t0 in key_count
    blt $t0, 10, input_done # if we're less than 10 keystrokes, we're done
    sw $zero, key_count   # reset counter to 0, since we're at 10 key strokes
    jal push_row
    jal check_game_over   # check if the game is over
    bne $v0, $zero, game_over # if $v0 is 0, then game over

input_done:
    # restore previous saved values
    lw $ra, 0($sp) 
    addi $sp, $sp, 4      # restore stack pointer to before
    jr $ra                # jump back to 

##############################################################################
# grab: grabbing a bubble
##############################################################################
grab:
    lw $t0, player_col  # load player column into $t0
    sll $t0, $t0, 2     # multiply the column by 4 (the byte offset)
    la $t1, grid        # load grid into $t1
    add $t1, $t1, $t0   # add $t0 and $t1 (start of the grid + the player's column)
    addi $t1, $t1, 364  # add 364 to $t1 (which is now row 13 of the character's column)
    li $t2, 13          # set $t2 to 13 (the row)

grab_find:
    bltz $t2, grab_done # if the row is 0, then we're done
    lw $t3, 0($t1)      # load the word at offset 0 of $t1 into $t3
    bne $t3, $zero, grab_check # if $t3 isn't 0, then we found a bubble, so we check
    addi $t1, $t1, -28       # decrement $t1 by 28 (move up a row)
    addi $t2, $t2, -1        # decrement $t2 by 1 (move up a row)
    j grab_find         # loop back

grab_check:
    lw $t4, held_count  # load held_count into $t4
    beq $t4, $zero, grab_take # if we're not holding anything, then it doesn't matter
                        # what colour it is, so just take
    lw $t5, held_colour # load the held_colour into $t5
    bne $t3, $t5, grab_done # if we're holding a different colour, then we're done (don't grab)

grab_take:
    sw $t3, held_colour   # set the held COLOURS

grab_loop:
    bltz $t2, grab_save   # stop if we've gone past the top row
    lw $t6, 0($t1)        # load the word at $t1 into $t6 
    bne $t6, $t3, grab_save # if the colour changes, then stop
    sw $zero, 0($t1)      # remove the bubble from the grid
    addi $t4, $t4, 1           # increment $t4 (the held count) by 1
    addi $t1, $t1, -28         # decrement $t1 (the grid position) by 28 to move up a row
    addi $t2, $t2, -1          # decrement $t2 by 1
    j grab_loop           # loop back

grab_save:
    sw $t4, held_count    # load $t4 into held_count

grab_done:
    jr $ra                # jump back to caller


##############################################################################
# fill_row: given a row number in $a0, fill the row's 7 cells with random COLOURS
##############################################################################
fill_row:
    li $t1, 28          # store 28 in $t1
    mul $t0, $a0, $t1   # the row * 28 (which is the byte offset of the row)
    la $t2, grid        # load grid into $t2
    add $t0, $t0, $t2   # add $t2 to $t0 (which is now column 0 of the row)
    li $t1, 0           # now set $t0 to 0 (the cell counter)

fill_row_loop:
    beq $t1, 7, fill_row_done # if $t1 is 7, that means we're done filling the row
    # grab a random colour like before
    li $v0, 42          # selects MARS syscall for random int
    li $a0, 0           # ID of random number generator
    li $a1, 4           # the upper bound
    syscall
    sll $a0, $a0, 2     # index * 4 = byte offset
    la $t2, COLOURS     # load address of COLOURS into $t2
    add $t2, $t2, $a0   # $t2 points at random colour
    lw $t3, 0($t2)      # $t3 = COLOURS[index]
    sw $t3, 0($t0)      # store colour in grid cell
    addi $t0, $t0, 4    # move to next cell
    addi $t1, $t1, 1    # increment cell counter by 1
    j fill_row_loop     # loop back

fill_row_done:
    jr $ra

##############################################################################
# push_row: move every row down one, then fill row 0 with new bubbles
##############################################################################
push_row:
    addi $sp, $sp, -4    # make room in stack
    sw $ra, 0($sp)      # store $ra in stack
    la $t2, grid        # store the grid in $t2
    addi $t0, $t2, 388 # store the very last word of grid in $t0
    addi $t3, $t2, 28  # store the first word of row 1 of grid in $t3

shift_loop:
    blt $t0, $t3, shift_done # if we get to row 1, every row has been copied
    lw $t1, -28($t0)    # store the word 28 bytes before $t0 (a row up)
    sw $t1, 0($t0)      # store $t1 into the word at $t0
    addi $t0, $t0, -4   # decrement $t0 by 4 (go to the previous word)
    j shift_loop        # loop back

shift_done:
    li $a0, 0           # set $a0 to 0
    jal fill_row        # fill the top row again

    # restore previous stored values
    lw $ra, 0($sp)
    addi $sp, $sp, 4        # move stack pointer back to before
    jr $ra

##############################################################################
# check_game_over: if any cells of grid row 13 non
##############################################################################
check_game_over:
    la $t0, grid
    addi $t0, $t0, 364  # add 364 to $t0
    li $t1, 0           # set the cell counter to 0

game_over_loop:
    beq $t1, 7, game_over_safe # if all 7 cells empty, not game over
    lw $t2, 0($t0)      # load the word at $t0 into $t2
    bne $t2, $zero, game_over_over # if a bubble has reached here, then game over
    addi $t0, $t0, 4    # move to the next cell
    addi $t1, $t1, 1    # increment counter by 1
    j game_over_loop    # loop back

game_over_over:
    li $v0, 1           # set $v0 to 1
    jr $ra

game_over_safe:
    li $v0, 0           # set $v0 to 0
    jr $ra

##############################################################################
# throw: throw the bubble
##############################################################################
throw:
    lw $t0, held_count  # store held_count in $t0
    beq $t0, $zero, throw_none # if we're not holding anything, leave
    
    lw $t3, player_col  # load player column into $t3
    sll $t3, $t3, 2     # multiply the column by 4 (the byte offset)
    la $t1, grid        # load grid into $t1
    add $t1, $t1, $t3   # add $t3 and $t1 (start of the grid + the player's column)
    addi $t1, $t1, 364  # add 364 to $t1 (which is now row 13 of the character's column)
    li $t2, 13          # set $t2 to 13 (the row)

bubble_search_loop:
    bltz $t2, bubble_place      # if $t2 is below 0, then stop (off the top)
    lw $t3, 0($t1)      # store the word at $t1 in $t3
    bne $t3, $zero, bubble_place # if $t3 is not 0, then place below here (found bubble)
    addi $t1, $t1, -28  # decrement $t1 by 28
    addi $t2, $t2, -1   # decrement $t2 by 1 (row number)
    j bubble_search_loop             # loop back

bubble_place:
    addi $t5, $t2, 1    # increment $t2 by 1 and store in $t5 (the landing row)
    add $t6, $t5, $t0   # add $t0 and $t5 and place in $t6 (add on the column)
    bgt $t6, 14, throw_none # if $t6 is greater than 14 (out of the grid), throw none
    addi $t1, $t1, 28   # increment $t1 by 28 

    lw $t4, held_colour # place the held_colour in $t4
    
bubble_place_loop:
    beq $t0, $zero, throw_done # if $t0 is 0 (the bubbles held is 0) then we're done
    sw $t4, 0($t1)      # store $t4 in the first word of $t1
    addi $t1, $t1, 28   # increment $t1 by 28
    addi $t0, $t0, -1   # decrement $t0 by 1
    j bubble_place_loop

throw_done:
    addi $v0, $t6, -1   # set $v0 to $t6 - 1 (the bottom row)
    sw $zero, held_count # set the held_count to 0
    sw $zero, held_colour #set the held_colour to 0
    jr $ra              # return to caller

throw_none:
    li $v0, -1          # set $v0 to -1
    jr $ra
    
##############################################################################
# check_match: check if the bubbles match (where $a0 is the column and $a1 is
# the bottom row)
##############################################################################    
check_match:
    li $t6, 28          # load 28 into $t6
    mul $t0, $a1, $t6   # the row * 28 (which is the byte offset of the row)
    sll $t7, $a0, 2     # multiply $a0 (the column) by 4
    add $t0, $t0, $t7   # add $t7 to $t0 (row offset + column offset)
    la $t7, grid        # load the grid into $t7
    add $t0, $t0, $t7   # add $t7 and $t0 and store in $t0

    lw $t1, 0($t0)      # load the word at $t0 (the bottom bubble) into $t1 

    move $t2, $t0       # store $t0 in $t2 (the address)
    move $t3, $a1       # store $a1 in $t3 (row number)
    li $t4, 0           # store 0 in $t4 (the count)
    
match_count:
    bltz $t3, match_count_done # if $t3 (row number) less than 0, then we're done
    lw $t5, 0($t2)      # load word at $t2 into $t5
    bne $t5, $t1, match_count_done # if $t5 and $t1 aren't equal, then done (different colour)
    addi $t4, $t4, 1    # increment $t4 (the count) by 1
    addi $t2, $t2, -28  # decrement $t2 by 28 (move up a row)
    addi $t3, $t3, -1   # decrement $t3 by 1 (move up a row)
    j match_count       # loop back

match_count_done:
    blt $t4, 3, no_match # if $t4 less than 3 (matches less than 3), then no match

    move $t2, $t0       # move $t0 into $t2 (put pointer back to bottom)
    move $t3, $t4       # move $t4 into $t3 (how many cells to erase)

match_delete:
    beq $t3, $zero, match_delete_done # if $t3 is 0 (no more cells to erase), then we're done
    sw $zero, 0($t2)    # store 0 in $t2 (write 0 in the cell)
    addi $t2, $t2, -28  # decrement $t2 by 28 (move up a row)
    addi $t3, $t3, -1   # decrement $t3 by 1 (1 less cell to erase)
    j match_delete      # loop back

match_delete_done:
    move $v0, $t4       # store $t4 in $v0 (how many bubbles were cleared)
    jr $ra

no_match:
    li $v0, 0           # store 0 in $v0 (no bubbles were cleared)
    jr $ra
    
    
##############################################################################
# play_music: if the next note is due, start it and schedule
# the one after it.
##############################################################################
play_music:
    li $v0, 30          # store 30 for neext syscall
    syscall             # syscall 30: get the time
    lw $t0, next_note_time # # store next_note_time in $t0
    subu $t1, $a0, $t0  # $t1 = now - due
    bltz $t1, music_done # negative means that it's not time yet
    la $t2, MELODY      # $t2 = start of the melody
    lw $t3, music_offset # $t3 = byte offset of the next note
    add $t2, $t2, $t3   # $t2 = address of the next note
    lw $t4, 0($t2)      # $t4 = the pitch
    bgez $t4, music_play # anything except -1 is a note or a rest
    la $t2, MELODY      # we reached the end marker, so go back to the first note
    li $t3, 0
    lw $t4, 0 ($t2)

music_play:
    lw $t5, 4($t2)      # $t5 = duration in milliseconds
    addu $t0, $t0, $t5  # next note is due "duration" milliseconds after this one was due
    sw $t0, next_note_time
    addi $t3, $t3, 8    # move to the next (pitch, duration) pair
    sw $t3, music_offset
    beq $t4, $zero, music_done # pitch 0 is a rest: wait without playing
    move $a0, $t4       # $a0 = pitch
    move $a1, $t5       # $a1 = duration
    lw $a2, MUSIC_INSTRUMENT
    lw $a3, MUSIC_VOLUME
    li $v0, 31          # syscall 31: MIDI out, returns
    syscall

music_done:
    jr $ra
##############################################################################
# draw_scene: draw the scene for every frame
##############################################################################
draw_scene:
    # save $ra
    addi $sp, $sp, -4   # make room in stack
    sw $ra, 0($sp)      # store $ra in stack
    
    jal draw_walls
    jal draw_grid
    jal clear_player_area   
    jal draw_player
    jal draw_held

    # restore saved values
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # move stack pointer back to before
    
    jr $ra

game_over:
    jal draw_scene
    li $v0, 10          # set $v0 to 10
    syscall             # terminate

game_loop:
    # 0. start the next note if it's due
    jal play_music
    # 1a. Check if key has been pressed
    jal handle_input
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
    jal draw_scene
	# 4. Sleep
    li $v0, 32          # place 32 in $v0
    li $a0, 16          # place 16 in $a0
    syscall             # sleep for 16 ms
    # 5. Go back to Step 1
    j game_loop
