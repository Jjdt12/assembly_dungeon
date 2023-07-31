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
            jmp     .begin                          ; If xp not >= 25, begin normal game loop
    .next_level:
            inc     byte[level_num]                 ; Increment level number by one
            jmp     _level_print                    ; Print new level. 
    .begin:
            call    _no_enter                       ; Don't wait for 'enter' key on input
                                                    ; Check for input
            cmp     byte[rsi], "p"                  ; Check if input = "p"
            je      .potion                         ; If input = "p", jump to .potion
            jmp     .not_potion                     ; Else if input != "p", jump to .not_potion
    .potion:
            cmp     byte[potions], 0x00             ; Check if "potions" = 0
            je      .not_potion                     ; If "potions" = 0, jump to .not_potion
            mov     byte[hitpoints], 0x09           ; Else, if "potions" = 0, move 9 into "hitpoints", raising HP back to max (9). 
            dec     byte[potions]                   ; Decrement (decrease) "potions", reducing by 1.
    .not_potion:
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
            cmp     byte[r9], "X"                   ; Check if the position the player is moving into = "X", an exit 
            je      .ending                         ; If the poisition the player is moving into = "X", jump to .ending
            jmp     .not_ending                     ; Else, if the poisition the player is moving into != "X", jump to .not_ending
    .not_ending:
            cmp     byte[r9],"$"                    ; Check if the position the player is moving into = "$"
            jne     .no_treasure                    ; If the position the player is moving into != "$", jump to .no_treasure
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "$", replace the "$" with " ". 
            inc     byte[treasure]                  ; and increment (increase) treasure count by one. 
            ret                                     ; Return from _move subroutine back to
    .no_treasure:
            cmp     byte[r9],"K"                    ; Check if the position the player is moving into = "K"
            jne     .no_key                         ; If the position the player is moving into != "K", jump to .no_key
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "K", replace the "K" with " ". 
            inc     byte[keys]                      ; and increment (increase) key count by one. 
            ret                                     ; Return from _move subroutine 
    .no_key:
            cmp     byte[r9], 0x7c                  ; Check if the position the player is moving into = "|", a door. 
            jne     .no_door                        ; If the position the player is moving into != "|", jump to .no_door
            cmp     byte[keys], 0x00                ; Else, if the position the player is moving into = "|", check if "keys" = 0
            je      .wall                           ; If "keys" = 0, jump to .wall, treating the door as a wall. 
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "|", replace the "|" with " ". 
            dec     byte[keys]                      ; and decrement (decrease) "keys" count, reducing it by one. 
            ret                                     ; Return from _move subroutine 
    .no_door:
            cmp     byte[r9],"F"                    ; Check if the position the player is moving into = "F"
            jne     .no_food                        ; If the position the player is moving into != "F", jump to .no_food
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "F", replace the "F" with " ". 
            mov     byte[hitpoints], 0x09           ; and change the players hitpoints to maximum (9). 
            ret                                     ; Return from _move subroutine 
    .no_food:
            cmp     byte[r9],"P"                    ; Check if the position the player is moving into = "P"
            jne     .no_potion                      ; If the position the player is moving into != "P", jump to .no_portion
            mov     byte[r9], 0x20                  ; Else, if the poisition the player is moving into = "P", replace the "P" with " ". 
            inc     byte[potions]                   ; and increment (increase) the players potion count by 1. 
            ret                                     ; Return from _move subroutine 
    .no_potion:
            mov     byte[r13], 0x20                 ; Replace the players current position ("@") with " "
            mov     r13, r9                         ; Move player into new position
    .wall:
            mov     byte[r13], 0x40                 ; If the player hits a wall, move "@" into original position, keeping player still 
            ret                                     ; Return from the _move subroutine
    .fight:
            mov     byte[r9], "$"                   ; Replace "E" with "$", indicating the player has killed an enemy
            call    _roll_d20                       ; Call _roll_d20,which stores a (very)pseudo random number between 0-20 stored in RDX
            cmp     rdx, 5                          ; Compare the dice roll to 5
            jle     .no_enemy_hit                   ; If the number <= 5, jumpt to .no_enemy_hit, the enemy does not hit the player
            dec     byte[hitpoints]                 ; Else, if the number > 5, decrement "hitpoints", the enemy hits the player
            cmp     byte[hitpoints], 0x00           ; Compare hitpoints to 0
            je      .slain                          ; If "hitpoints" = 0, jump to .slain, the player is killed
            jmp     .no_enemy_hit                   ; Else if "hitpoints" != 0, jump to .no_enemy_hit
    .slain:
            call    _slain                          ; If hitpoints = 0, call _slain, the player has been killed
            call    _exit                           ; Call _exit
    .no_enemy_hit:
            mov     byte[r13], 0x40                 ; If player has killed an enemy, move "@" into original position,keeping player still
            mov     r12b, [xp]                      ; Move the value of xp into the lower byte of r12
            mov     byte[xp_string + r12], 0x3d     ; Replace the next " " in the XP bar with "="
            add     byte[xp], 0x01                  ; Add 0x01 to the value in "xp"
            ret 
    .ending:
            call    _ending                         ; Call _ending
            call    _exit                           ; Call _exit

    _roll_d20:
            rdtsc                                   ; Store the processor’s time-stamp counter in EDX:EAX
            xor     rdx, rdx                        ; Clear rdx
            mov     rcx, 20                         ; Move 20 into rcxl the divisor
            div     rcx                             ; Div rax by rcx, storing the remainder in rdx
            ret                                     ; Return from _roll_d20 back to the line (instruction) after "call _roll_d20"

    _print_dungeon:
            call    _print_title                    ; Call _print_title to print the title string
            call    _print_level                    ; Call _print_level to print the level string and level number
            call    _print_map                      ; Call _print_map to print the dungeon map
            call    _print_hitpoints                ; Call _print_hitpoints to print the hitpoints string and hitpoints number
            call    _print_xp                       ; Call _print_xp to print the xp string and xp number
            call    _print_treasure                 ; Call _print_treasure to print the treasure string and treasure number
            call    _print_keys                     ; Call _print_keys to print the keys string and keys number
            call    _print_potions                  ; Call _print_potions to print the potions string and potions number
            call    _print_blanks                   ; Call _print_blanks to print blank lines
            ret                                     ; Return from _print_dungeon to the line (instruction) after "call _print_dungeon"

    _ending:
            call    _clear_screen                   ; Call _clearn_screen to clear the terminal
            call    _print_ending                   ; Call _print_ending to print the ending string 
            call    _print_level                    ; Call _print_level to print the level string and level number
            call    _print_map                      ; Call _print_map to print the dungeon map
            call    _print_hitpoints                ; Call _print_hitpoints to print the hitpoints string and hitpoints number
            call    _print_xp                       ; Call _print_xp to print the xp string and xp number
            call    _print_treasure                 ; Call _print_treasure to print the treasure string and treasure number
            call    _print_keys                     ; Call _print_keys to print the keys string and keys number
            call    _print_potions                  ; Call _print_potions to print the potions string and potions number
            call    _print_blanks                   ; Call _print_blanks to print blank lines
            ret                                     ; Return from _print_dungeon to the line (instruction) after "call _print_dungeon"

    _slain:
            call    _clear_screen                   ; Call _clearn_screen to clear the terminal
            call    _print_slain                    ; Call _print_ending to print the ending string 
            call    _print_level                    ; Call _print_level to print the level string and level number
            call    _print_map                      ; Call _print_map to print the dungeon map
            call    _print_hitpoints                ; Call _print_hitpoints to print the hitpoints string and hitpoints number
            call    _print_xp                       ; Call _print_xp to print the xp string and xp number
            call    _print_treasure                 ; Call _print_treasure to print the treasure string and treasure number
            call    _print_keys                     ; Call _print_keys to print the keys string and keys number
            call    _print_potions                  ; Call _print_potions to print the potions string and potions number
            call    _print_blanks                   ; Call _print_blanks to print blank lines
            ret                                     ; Return from _print_dungeon to the line (instruction) after "call _print_dungeon"

    _print_ending:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, ending                     ; Move "ending" string into rsi
            mov     rdx, ending_len                 ; Move "ending_len" the length of the "ending" string into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from _print_ending subroutine

    _print_slain:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, slain                      ; Move "slain" string into rsi
            mov     rdx, slain_len                  ; Move "slain_len" the length of the "ending" string into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from _print_ending subroutine

    _print_title:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, title                      ; Move "title" string into rsi
            mov     rdx, title_len                  ; Move "title_len", the length of the "title" string into rdx
            syscall                                 ; call sys_write
            ret                                     ; Return from _print_title subroutine
    
    _print_level:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, level_string               ; Move "level_string" string into rsi
            mov     rdx, level_string_len           ; Move "level_string_len", the length of the "level_string" string into rdx
            syscall                                 ; Call sys_write
            xor     rax, rax                        ; Clear rax
            mov     rax, [level_num]                ; Move "level_num", the current player level, into rax for use in _print_num
            call    _print_num                      ; Call _print_num
            ret                                     ; Return from the _print_level subroutine

    _print_map:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, map                        ; Move "map" string into rsi
            mov     rdx, map_len                    ; Move "map_len", the length of the "map" string, into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from the _print_map subroutine
            
    _print_hitpoints:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, hitpoints_string           ; Move "hitpoints_string" string into rsi
            mov     rdx, hitpoints_string_len       ; Move "hitpoints_string_len", the length of the "hitpoints_string" string into rdx
            syscall                                 ; Call sys_write
            xor     rax, rax                        ; Clear rax
            mov     rax, [hitpoints]                ; Move "hitpoints", the current player hitpoints, into rax for use in _print_num
            call    _print_num                      ; Call _print_num
            ret                                     ; Return from the _print_hitpoints subroutine

    _print_xp:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, xp_string                  ; Move "xp_string" string into rsi
            mov     rdx, xp_string_len              ; Move "xp_string_len", the length of the "xp_string" string into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from the _print_xp subroutine

    _print_treasure:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, treasure_string            ; Move "treasure_string" string into rsi
            mov     rdx, treasure_string_len        ; Move "treasure_string_len", the length of the "treasure_string" string into rdx
            syscall                                 ; Call sys_write
            xor     rax, rax                        ; Clear rax
            mov     rax, [treasure]                 ; Move "treasure", the current player treasure amount, into rax for use in _print_num
            call    _print_num                      ; Call _print_num
            ret                                     ; Return from the _print_treasure subroutine

    _print_keys:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, keys_string                ; Move "keys_string" string into rsi
            mov     rdx, keys_string_len            ; Move "keys_string_len", the length of the "keys_string" string into rdx
            syscall                                 ; Call sys_write
            xor     rax, rax                        ; Clear rax
            mov     rax, [keys]                     ; Move "keys", the current player keys amount, into rax for use in _print_num
            call    _print_num                      ; Call _print_num
            ret                                     ; Return from the _print_keys subroutine

    _print_potions:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, potions_string             ; Move "potions_string" string into rsi
            mov     rdx, potions_string_len         ; Move "potions_string_len", the length of the "potions_string" string into rdx
            syscall                                 ; Call sys_write
            xor     rax, rax                        ; Clear rax
            mov     rax, [potions]                  ; Move "potions", the current player potions amount, into rax for use in _print_num
            call    _print_num                      ; Call _print_num
            ret                                     ; Return from the _print_potions subroutine
        
    _print_blanks:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, nothing                    ; Move "nothing" string into rsi
            mov     rdx, nothing_len                ; Move "nothing_len", the lengths of the "nothing" string into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from the _print_blanks subroutine
            
    _enemy_attacks:
            mov     rax, 1                          ; Move 1 into rax, setting sys_write
            mov     rdi, 1                          ; Move 1 into rdi, setting std_out
            mov     rsi, enemy_attacks_string       ; Move "enemy_attacks_string" into rsi
            mov     rdx, enemy_attacks_string_len   ; Move "enemy_attacks_string_len", the length of "enemy_attacks_string" into rdx
            syscall                                 ; Call sys_write
            ret                                     ; Return from the _enemy_attacks subroutine

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
            ret                                     ; Return from the _clear_screen subroutine 

    _print_num:
                                                    ; rax has our number value to be converted to ascii and printed 
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
        mov     qword[output_buffer], 0x00
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
