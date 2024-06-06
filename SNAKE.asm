name "snake"

org     100h

; jump over data section:
jmp     start

; ------ data section ------     

; -----MENSAJE INICIO-----

draw_new db "           /^\/^\     ", 0dh,0ah
db "         _|__|  O|  ", 0dh,0ah
db "\/     /~     \_/ \  ", 0dh,0ah
db " \____|__________/  \   ", 0dh,0ah
db "        \_______      \    ", 0dh,0ah
db "                `\     \                 \   ", 0dh,0ah
db "                  |     |                  \    ", 0dh,0ah
db "                 /      /                    \     ", 0dh,0ah
db "                /     /                       \\   ", 0dh,0ah
db "              /      /                         \ \   ", 0dh,0ah
db "             /     /                            \  \    ", 0dh,0ah
db "           /     /             _----_            \   \   ", 0dh,0ah
db "          /     /           _-~      ~-_         |   |   ", 0dh,0ah
db "         (      (        _-~    _--_    ~-_     _/   |    ", 0dh,0ah
db "          \      ~-____-~    _-~    ~-_    ~-_-~    /    ", 0dh,0ah
db "            ~-_           _-~          ~-_       _-~   ", 0dh,0ah
db "               ~--______-~                ~-___-~    ", 0dh,0ah,0ah   

db "                  _", 0dh,0ah             
db "  ___ _ __   __ _| | _____ ", 0dh,0ah 
db " / __| '_ \ / _` | |/ / _ \  ", 0dh,0ah
db " \__ \ | | | (_| |   <  __/  ", 0dh,0ah
db " |___/_| |_|\__,_|_|\_\___|", 0dh,0ah,13d,10d, '$'  

msg_new db "Presiona cualquier tecla para empezar el juego!", '$'      

g_over db "GAME OVER!", '$'

;-----SNAKE-----

s_size  equ     4  
score dw 0

; the snake coordinates
; (from head to tail)
; low byte is left, high byte
; is top - [top, left]  

posX db 14
posY db 8
snake dw 100 dup(0)

tail    dw      ?

; direction constants
;          (key codes):
left    equ     4bh
right   equ     4dh
up      equ     48h
down    equ     50h

; current snake direction:
cur_dir db      right

wait_time dw    0          
              
              
              
;-----FRUTA-----   
random_seed dw 1234 ; valor inicial de seed
 
posFX db 23
posFY db 8 


; campo de juego
game_field 	db "==============================", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah                                            
	db "|                            |", 0dh,0ah 
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah  
	db "|                            |", 0dh,0ah
	db "|                            |", 0dh,0ah
	db "==============================$"        
	
	
;-----LIMITES-----
limX db 29
limY db 16	

; ------ Seccion de Codigo ------

start: 
;imprimir mensaje de bienvenida
mov dx, offset draw_new
mov ah, 9 
int 21h

mov dx, offset msg_new
mov ah, 9 
int 21h  

;esperar hasta presionar una tecla
mov ah, 00h
int 16h    

;limpiar la pantalla
mov ah, 6h
mov al, 0
mov bh,7
mov cx,0
mov dl,80
mov dh,25
int 10h    

;volver el cursor a la [0,0]
mov ah,2h
mov bh,0
mov dh,bl
mov dl,bl
int 10h

; imprimir campo de juego:
mov dx, offset game_field
mov ah, 9 
int 21h


; wait for any key:
mov ah, 00h
int 16h


; hide text cursor:
mov     ah, 1
mov     ch, 2bh
mov     cl, 0bh
int     10h           


game_loop:

; === select first video page
mov     al, 0  ; page number.
mov     ah, 05h     
int     10h


  
; === mostrar ubicacion cabezon:   
mov dl, posX
mov dh, posY   

;=== comparar posicion con los limites
; del juego 
cmp dl, limX 
ja game_over
cmp dh, limY
ja game_over
cmp dl, 0
jb game_over
cmp dh, 0 
jb game_over

; === asignar las posiciones snake
mov snake, dx
mov dx, snake  

; set cursor at dl,dh 
mov     ah, 02h
int     10h

; print '*' en la posicion:
mov     al, '*'
mov     ah, 09h
mov     bl, 2ah ; change color
mov     cx, 1   ; single char.  

int     10h 
             
check_snake_comio: 
    cmp dl, posFX
    je comioY?  
    cmp dl, posFY 
    je comioX? 
    jmp continua
    
    comioY?: 
    cmp dh, posFY
    je new_pos_fruta  
    jmp continua   
    
    comioX?: 
    cmp dh, posFX
    je new_pos_fruta  
    jmp continua
        
continua:             
;print ubicacion fruta:
   
mov ah, 13h
mov al, '@' 
mov bh, 0    
mov bl, 44h ; change color
mov cx, 1   ; single char. 
mov dl, posFX  ;goto-xy
mov dh, posFY  
int 10h       


; === keep the tail: 
mov ax, snake[di]
mov ax, score  
mov bx, s_size * 2 - 2  
add bx, ax
mov ax, snake[di-bx]
cmp score, 1
je comio      
mov tail, ax

comio:
call move_snake


; === hide old tail:
mov     dx, tail

; set cursor at dl,dh
mov     ah, 02h
int     10h

; print ' ' at the location:
mov     al, ' '
mov     ah, 09h
mov     bl, 0eh ; attribute.
mov     cx, 1   ; single char.
int     10h



check_for_key:

; === check for player commands:
mov     ah, 01h
int     16h
jz      no_key

mov     ah, 00h
int     16h

cmp     al, 1bh    ; esc - key?
je      stop_game  ;

mov     cur_dir, ah

no_key:



; === wait a few moments here:
; get number of clock ticks
; (about 18 per second)
; since midnight into cx:dx
mov     ah, 00h
int     1ah
cmp     dx, wait_time
jb      check_for_key
add     dx, 4
mov     wait_time, dx



; === eternal game loop:
jmp     game_loop


stop_game:

; show cursor back:
mov     ah, 1
mov     ch, 0bh
mov     cl, 0bh
int     10h

ret

; ------ functions section ------

; this procedure creates the
; animation by moving all snake
; body parts one step to tail,
; the old tail goes away:
; [last part (tail)]-> goes away
; [part i] -> [part i+1]
; ....

move_snake proc near

; set es to bios info segment:  
mov     ax, 40h
mov     es, ax

  ; point di to tail 
  mov ax, score
  mov bx, s_size * 2 - 2
  add bx, ax
  mov   di, bx
  ; move all body parts
  ; (last one simply goes away) 
  mov bx, score
  add bx, s_size-1
  mov   cx, bx
move_array:
  mov   ax, snake[di-2]
  mov   snake[di], ax
  sub   di, 2
  loop  move_array


cmp     cur_dir, left
  je    move_left
cmp     cur_dir, right
  je    move_right
cmp     cur_dir, up
  je    move_up
cmp     cur_dir, down
  je    move_down

jmp     stop_move       ; no direction.


move_left:
  mov   al, b.snake[0]
  dec   al  
  dec posX
  mov   b.snake[0], al
  cmp   al, -1
  jne   stop_move       
  mov   al, es:[4ah]    ; col number.
  dec   al
  mov   b.snake[0], al  ; return to right.
  jmp   stop_move

move_right:
  mov   al, b.snake[0]
  inc   al
  inc posX
  mov   b.snake[0], al
  cmp   al, es:[4ah]    ; col number.   
  jb    stop_move
  mov   b.snake[0], 0   ; return to left.
  jmp   stop_move

move_up:
  mov   al, b.snake[1]
  dec   al 
  dec posY
  mov   b.snake[1], al
  cmp   al, -1
  jne   stop_move
  mov   al, es:[84h]    ; row number -1.
  mov   b.snake[1], al  ; return to bottom.
  jmp   stop_move

move_down:
  mov   al, b.snake[1]
  inc   al 
  inc posY
  mov   b.snake[1], al
  cmp   al, es:[84h]    ; row number -1.
  jbe   stop_move
  mov   b.snake[1], 0   ; return to top.
  jmp   stop_move

stop_move:
  ret
move_snake endp  

new_pos_fruta:
    pos_randomX: 
          
        
        ; Generate a random number
        call generate_random
    
        ; Modulo 30 to get a number in the range 0-29
        mov cx, 29
        xor dx, dx
        div cx
        inc dx
        mov posFX, dl  ; AX now contains the random number between 1 and 29 
        
    
    pos_randomY:   
        
        ; Generate a random number
        call generate_random
    
        ; Modulo 30 to get a number in the range 0-29
        mov cx, 14 
        xor dx, dx
        div cx
        inc dx
        mov posFY, dl  ; AX now contains the random number between 1 and 15 
        mov ax, score
        add ax, 1
        mov score, ax  
    
       
    jmp continua 

generate_random:
    ; Linear Congruential Generator (LCG)
    mov ax, [random_seed]
    mov bx, 75     ; Multiplier
    mul bx
    add ax, 12345  ; Increment       ; Increment
    mov [random_seed], ax
    ret


game_over:     
    mov dx, offset g_over   
    mov ah, 9h
    int 21h
    mov ax, 4c00h
