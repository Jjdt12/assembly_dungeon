;=============================
;===== ASSEMBLY DUNGEON
;=============================

		global _start

    %include "data.asm"

;=============================
;===== BLASTOFF
;=============================
        section	.text
;=============================

    _start:	

    _initialize_map:
            mov     r13, map + 0x9E5                ; Move an address into r13 for the players starting position
            mov     byte[r13], 0x40                 ; Move the "@" character into that address
            ;mov     byte[keys], 0x30                ; Put 0x00 (decimal 0) into keys, initializing keys to 0
    _level_print:
            mov     byte[xp], 0x10                  ; Put 0x10 (decimal 16) into xp
            call    _clear_xp_bar                   ; Clear the XP bar


;----------------------------------
;----- Start of Main Game Loop 
;----------------------------------

    _game_loop:
            call    _clear_screen                   ; Call _clear_screen to clear the terminal
            call    _print_dungeon                  ; Print the dungeon
            cmp     byte[xp], 0x1f                  ; Check if xp >= 25
            je      .next_level                     ; If xp >= 25 jump to _next_level
            jmp     .begin                          ; If treasure not >= 25, begin normal game loop
    .next_level:
            inc     byte[level_num]                 ; Increment level number by one
            jmp     _level_print                    ; Print new level. 
    .begin:
            call    _no_enter                       ; Don't wait for 'enter' key on input
                                                    ; Check for movement input - WASD
            cmp     byte[rsi], "w"                  ; Check if input = "w"
            lea     r9, byte[r13-0xb4]              ; Load address of the space above current player position into r9
            je      .up                             ; If input = "w", jump to .up
            jmp     .not_up                         ; Else if input != "w" jump to .not_up
    .up:
            call    _move                           ; Call _move                          
    .not_up:
            cmp     byte[rsi], "s"                  ; Check if input = "s"
            lea     r9, byte[r13+0xb4]              ; Load address of the space bellow current player position into r9
            je      .down                           ; If input = "s", jump to .down
            jmp     .not_down                       ; Else if input != "s", jump to .not_down
    .down:
            call    _move                           ; Call _move
    .not_down:
            cmp     byte[rsi], "a"                  ; Check if input = "a" 
            lea     r9, byte[r13-0x01]              ; Load address of the space to the left of current player position into r9
            je      .left                           ; If input = "a", jump to .left
            jmp     .not_left                       ; Else if input != "a", jump to .not_left
    .left:
            call    _move                           ; Call _move
    .not_left:
            cmp     byte[rsi], "d"                  ; Check if input = "d" 
            lea     r9, byte[r13+0x01]              ; Load address of the space to the right of current player position into r9
            je      .right                          ; If input = "d", jump to .right
            jmp     .not_right                      ; Else, if input != "d", jump to .not_right
    .right:
            call    _move                           ; Call _move 
    .not_right:
            jmp     _game_loop                      ; Jump to _game_loop, restart main game loop 

;----------------------------------
;----- End of Main Game Loop
;----------------------------------

;=============================
;===== SEE YA
;=============================

    _exit:
            mov     rax, 60                         ; Move 60 into rax, the exit system call
            xor     rdi, rdi                        ; Make rdi 0, setting the exit code to 0. 
            syscall                                 ; Call exit

;=============================
;===== SUBROUTINES
;=============================

    _move:
            call    _clear_screen                   ; Call _clear_screen to clear the terminal
            cmp     byte[r9],"["                    ; Check if the position the player is moving into = "["
            je      .wall                           ; If the position the player is moving into = "[", jump to .wall
            cmp     byte[r9],"]"                    ; Else, check if the position the player is moving into = "]"
            je      .wall                           ; If the position the player is moving into = "]", jump to .wall
            cmp     byte[r9],"E"                    ; Check if the position the player is moving into = "E"
            je      .yes_fight                      ; If the poisition the player is moving into = "E", jump to .yes_fight
            jmp     .no_fight                       ; Else, if the poisition the player is moving into != "E", jump to .no_fight
    .yes_fight:
            jmp     .fight                          ; Jump to .fight
    .no_fight:
            cmp     byte[r9],"$"                    ; Check if the position the player is moving into = "$"
            jne     .no_treasure                    ; If the position the player is moving into != "$", jump to .no_treasure
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "$", replace the "$" with " ". 
            inc     byte[treasure]                  ; and increment (increase) treasure count by one. 
            ret                                     ; Return from _move subroutine back to _game_loop (the main game loop) 
    .no_treasure:
            cmp     byte[r9],"K"                    ; Check if the position the player is moving into = "K"
            jne     .no_key                         ; If the position the player is moving into != "K", jump to .no_key
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "K", replace the "K" with " ". 
            inc     byte[keys]                      ; and increment (increase) key count by one. 
            ret                                     ; Return from _move subroutine back to _game_loop (the main game loop) 
    .no_key:
            cmp     byte[r9], 0x7c                  ; Check if the position the player is moving into = "|", a door. 
            jne     .no_door                        ; If the position the player is moving into != "|", jump to .no_door
            cmp     byte[keys], 0x30                ; Else, if the position the player is moving into = "|", check if "keys" = 0
            je      .wall                           ; If "keys" = 0, jump to .wall, treating the door as a wall. 
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "|", replace the "|" with " ". 
            dec     byte[keys]                      ; and decrement (decrease) "keys" count, reducing it by one. 
            ret                                     ; Return from _move subroutine back to _game_loop (the main game loop) 
    .no_door:
            cmp     byte[r9],"F"                    ; Check if the position the player is moving into = "F"
            jne     .no_food                        ; If the position the player is moving into != "F", jump to .no_food
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "F", replace the "F" with " ". 
            mov     byte[hitpoints], 0x39           ; and change the players hitpoints to maximum (9). 
            ret                                     ; Return from _move subroutine back to _game_loop (the main game loop) 
    .no_food:
            mov     byte[r13], 0x20                 ; Replace the players current position ("@") with " "
            mov     r13, r9                         ; Move player into new position
    .wall:
            mov     byte[r13], 0x40                 ; If the player hits a wall, move "@" into original position, keeping player still 
            ret                                     ; Return from the _move subroutine back to the _game_loop (the main game loop)
    .fight:
            mov     byte[r9], "$"                   ; Replace "E" with "$", indicating the player has killed an enemy
            mov     byte[r13], 0x40                 ; If player has killed an enemy, move "@" into original position,keeping player still
            mov     r12b, [xp]                      ; Move the value of xp into the lower byte of r12
            mov     byte[xp_string + r12], 0x3d     ; Replace the next " " in the XP bar with "="
            add     byte[xp], 0x01                  ; Add 0x01 to the value in "xp"
            dec     byte[hitpoints]
            ret 
            
    _print_dungeon:
            push    treasure_string_len             ; Push "treasure_string_len",the size of the "treasure_string" string, onto the stack
            push    treasure_string                 ; Push the address pointing to the string "treasure_string" onto the stack
            push    xp_string_len                   ; Push "xp_string_len",the size of the "treasure_string" string, onto the stack
            push    xp_string                       ; Push the address pointing to the string "xp_string" onto the stack
            push    hitpoints_len                   ; Push "hitpoints_len", the size of the "hitpoints" string, onto the stack
            push    hitpoints                       ; Push the address pointing to the string "hitpoints" onto the stack
            push    hitpoints_string_len            ; Push "hitpoints_string_len",the size of the "hitpoints_string" string, onto the stack
            push    hitpoints_string                ; Push the address pointing to the string "hitpoints_string" onto the stack
            push    map_len                         ; Push "map_len", the size of the "map" string, onto the stack   
            push    map                             ; Push the address pointing to the string "map" onto the stack
            push    level_num_len                   ; Push "level_num_len", the size of the "level_num" string, onto the stack
            push    level_num                       ; Push the address pointing to the string "level_num" onto the stack
            push    level_string_len                ; Push "level_string_len", the size of the "level_string" string, onto the stack
            push    level_string                    ; Push the address pointing to the string "level_string" onto the stack
            push    title_len                       ; Push "title_len", the size of the "title" string, onto the stack  
            push    title                           ; Push the address pointing to the string "title" onto the stack
            mov     r12, 8                          ; Move 6 into r12, r12 will be the loop counter
    .sys_write_loop_1:                              ; Loop to print the dungeon to the screen 
                mov     rax, 1                          ; Move 1 into rax, setting sys_write
                mov     rdi, 1                          ; Move 1 into rdi, setting std_out
                pop     rsi                             ; Pop an address off of the stack that points to the string to print
                pop     rdx                             ; Pop an address off of the stack that points to the length of the string to print
                syscall                                 ; Call sys_write
                dec     r12                             ; Decrement (decreat) r12, our loop interation counter, reducing it by one.
                jnz     .sys_write_loop_1               ; Jump to .sys_write_loop, the begining of our printing loop
            call    _print_num                      ; Print the treasure value after translating to ASCII
            push    nothing_len                     ; Push "nothing_len", the size of the "nothing", string onto the stack
            push    nothing                         ; Push the address pointing to the string "nothing" onto the stack
            push    keys_len                        ; Push "keys_len", the size of the "keys" string, onto the stack
            push    keys                            ; Push the address pointing to the string "keys" onto the stack
            push    keys_string_len                 ; Push "keys_string_len", the size of the "keys_string" string, onto the stack
            push    keys_string                     ; Push the address pointing to the string "keys_string" onto the stack
            mov     r12, 3
    .sys_write_loop_2:                              ; Loop to print the dungeon to the screen 
                mov     rax, 1                          ; Move 1 into rax, setting sys_write
                mov     rdi, 1                          ; Move 1 into rdi, setting std_out
                pop     rsi                             ; Pop an address off of the stack that points to the string to print
                pop     rdx                             ; Pop an address off of the stack that points to the length of the string to print
                syscall                                 ; Call sys_write
                dec     r12                             ; Decrement (decreat) r12, our loop interation counter, reducing it by one.
                jnz     .sys_write_loop_2               ; Jump to .sys_write_loop, the begining of our printing loop
            ret                                     ; Return from _print_dungeon subroutine back to _game_loop (the main game loop)

    _clear_xp_bar:                  
            mov     rcx, 15                         ; Move 15 into rcx, rcx will be our loop counter
            mov     r12, 16                         ; Move 16 into r12, the offset location of the first "=" we will erase
    .clear_chars:
            mov     byte[xp_string + r12], 0x20     ; Replace the "=" at the offset with " "
            dec     rcx                             ; Decrement (decrease) rcx, our loop iteration counter, reducing it by one 
            inc     r12                             ; Increment (increase) r12, our offset location, increasing it by one
            cmp     rcx, 0                          ; Check if rcx = 0
            jnz     .clear_chars                    ; If rcx != 0, jump to .clear_chars, the start of our loop  
            ret                                     ; If rcx = 0, return from subroutine

    _clear_screen:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov	    rsi, clear_screen               ; Move the address pointing to the string clear_screen into rsi
            mov	    rdx, clear_screen_len           ; Move clear_screen_len, the size of the string, into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from the _clear_screen subroutine back to _game_loop (the main game loop)

    _print_num:
        mov     rax, [treasure]                     ; Move the current number into rax
        mov     r9, 2                               ; Set r9 to 2 for indexing into output_buffer
    .each_digit_loop:
            mov     rdx, 0                          ; Clear rdx to hold the remainder of division
            mov     rcx, 10                         ; Set rcx to 10, the quotiant for division
            div     rcx                             ; Divide rax by rcx (current digit/10) and put the remainder in rdx
            add     rdx, 0x30                       ; Add 0x30 to the digit, converting it to it's ascii value
            mov     [output_buffer+r9], dl          ; Store digit in the output_buffer, from left to right
            dec     r9                              ; Move offset back one
            cmp     rax, 0                          ; Check if there are more digits
            jnz     .each_digit_loop                ; If there are no more digits, loop again
        xor     rsi, rsi
        mov     rax, 1                              ; Move 1 into rax, setting the write system call
        mov     rdi, 1                              ; Move 1 into rdi, setting std out
        mov     rsi, output_buffer                  ; Move 'output_buffer' into rsi, the pointer to the string to be printed
        mov     rdx, 3                              ; Move the length of the string into rdx
        syscall                                     ; Call write
        ret                                         ; Return from subroutine

                                                    ; Disable canonical mode in the terminal
    _no_enter:
            mov     eax, 16                         ; syscall number: SYS_ioctl
            mov     edi, 0                          ; fd:      STDIN_FILENO
            mov     esi, 0x5401                     ; request: TCGETS
            mov     rdx, termios                    ; request data
            syscall
                                                    ; Modify flags
            and     byte [c_lflag], 0FDh            ; Clear ICANON to disable canonical mode

            mov     eax, 16                         ; syscall number: SYS_ioctl
            mov     edi, 0                          ; fd:      STDIN_FILENO
            mov     esi, 0x5402                     ; request: TCSETS
            mov     rdx, termios                    ; request data
            syscall
            mov     rax, 0                          ; syscall number: SYS_read
            mov     rdi, 0                          ; int    fd:  STDIN_FILENO
            mov     rsi, buf                        ; void*  buf
            mov     rdx, len                        ; size_t count
            syscall
            ret
