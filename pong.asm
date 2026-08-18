default rel

%define NULL 0

%define SDL_INIT_VIDEO  00000020h
%define SDL_RENDERER_ACCELERATED    00000002h
%define SDL_RENDERER_PRESENTVSYNC   00000004h
%define SDL_QUIT    100h
%define SDL_SCANCODE_S 22
%define SDL_SCANCODE_W 26
%define SDL_SCANCODE_DOWN 81
%define SDL_SCANCODE_UP 82

; --- Configuration ---
%define SCREEN_WIDTH 1024
%define SCREEN_HEIGHT 768
%define PADDLE_WIDTH 15
%define PADDLE_HEIGHT 100
%define BALL_SIZE 15
%define PADDLE_SPEED 8
%define PADDLE_SPEED_AI 6
%define BALL_SPEED_X 7
%define BALL_SPEED_Y 7

PADDLE_Y    equ     (SCREEN_HEIGHT - PADDLE_HEIGHT) / 2
PADDLE2_X   equ     SCREEN_WIDTH - 20 - PADDLE_WIDTH
BALL_X      equ     (SCREEN_WIDTH - BALL_SIZE) / 2
BALL_Y      equ     (SCREEN_HEIGHT - BALL_SIZE) / 2
SCREEN_WIDTH_HALF equ SCREEN_WIDTH / 2
SCREEN_WIDTH_MINUS_50 equ SCREEN_WIDTH - 50
SCREEN_HEIGHT_HALF equ SCREEN_HEIGHT / 2
PADDLE_WIDTH_HALF  equ PADDLE_WIDTH / 2
PADDLE_HEIGHT_HALF  equ PADDLE_HEIGHT / 2
BALL_SIZE_HALF  equ BALL_SIZE / 2
SCREEN_HEIGHT_MINUS_BALL_SIZE equ SCREEN_HEIGHT - BALL_SIZE

section .rodata
    message     db 'Pong.ASM',0
    init_fail   db 'SDL fail: %s',0
    font_path   db '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',0
    int_format  db '%d',0

section .data
    isRunning   db  1
    window      dq NULL
    renderer    dq NULL
    paddle1AI   db 1
    paddle2AI   db 0

section .bss
    paddle1 resd    4 ; SDL_Rect for paddle left
    paddle2 resd    4 ; SDL_Rect for paddle right
    ball    resd    4 ; SDL_Rect for ball

    ; Game variables
    ballDirX    resd    1
    ballDirY    resd    1
    score1      resd    1
    score2      resd    1

        

section .text

;extern printf
extern snprintf
extern time
extern srand
extern rand
extern SDL_Init
extern SDL_CreateWindow
extern SDL_CreateRenderer
extern SDL_Log
extern SDL_GetError
extern SDL_PollEvent
extern SDL_DestroyRenderer
extern SDL_DestroyWindow
extern SDL_Quit
extern SDL_SetRenderDrawColor
extern SDL_RenderClear
extern SDL_RenderPresent
extern SDL_RenderFillRect
extern SDL_RenderCopy
extern SDL_DestroyTexture
extern SDL_DestroySurface
extern SDL_Delay
extern TTF_Init
extern TTF_Quit
extern TTF_OpenFont
extern TTF_RenderText_Solid
extern TTF_CloseFont
extern SDL_CreateTextureFromSurface
extern SDL_FreeSurface
extern SDL_GetKeyboardState
extern SDL_HasIntersection

process_events:
    push rbp
    mov rbp, rsp

    sub rsp, 64        ; enough for SDL_Event

.loop:
    lea rdi, [rbp-56]
    call SDL_PollEvent wrt ..plt

    test eax, eax
    jz .done           ; no more events

    cmp DWORD [rbp-56], SDL_QUIT
    jne .loop

    mov BYTE [rel isRunning], 0
    jmp .loop

.done:
    add rsp, 64
    pop rbp
    ret

process_input:
    push rbp
    mov rbp, rsp

    
    mov rdi, NULL
    call SDL_GetKeyboardState wrt ..plt

    ; paddle1
    mov BYTE dl, [rel paddle1AI]
    test dl, dl
    jnz .skipPaddle1
    
    mov BYTE dl, [rax + SDL_SCANCODE_W]
    test dl, dl
    jz .skipW
    mov edi, [rel paddle1 + 4] ; paddle1.y
    sub edi, PADDLE_SPEED
    mov [rel paddle1 + 4], edi ; paddle1.y
.skipW:

    mov BYTE dl, [rax + SDL_SCANCODE_S]
    test dl, dl
    jz .skipS
    mov edi, [rel paddle1 + 4] ; paddle1.y
    add edi, PADDLE_SPEED
    mov [rel paddle1 + 4], edi, ; paddle1.y
.skipS:

.skipPaddle1:

    ; paddle2
    mov BYTE dl, [rel paddle2AI]
    test dl, dl
    jnz .skipPaddle2
    
    mov BYTE dl, [rax + SDL_SCANCODE_UP]
    test dl, dl
    jz .skipUP
    mov edi, [rel paddle2 + 4] ; paddle2.y
    sub edi, PADDLE_SPEED
    mov [rel paddle2 + 4], edi ; paddle2.y
.skipUP:

    mov BYTE dl, [rax + SDL_SCANCODE_DOWN]
    test dl, dl
    jz .skipDOWN
    mov edi, [rel paddle2 + 4] ; paddle2.y
    add edi, PADDLE_SPEED
    mov [rel paddle2 + 4], edi, ; paddle2.y
.skipDOWN:

.skipPaddle2:

    pop rbp
    ret

play_ai:

    ; paddle1
    mov BYTE dl, [rel paddle1AI]
    test dl, dl
    jz .skipPaddle1

    mov edi, [rel paddle1 + 4] ; paddle1.y
    add edi, PADDLE_HEIGHT_HALF

    mov eax, [rel ballDirX]
    cmp eax, 0
    jge .ballMovesAwayFromPaddle1

    mov esi, [rel ball + 4] ;ball.y
    add esi, BALL_SIZE_HALF

    cmp edi, esi
    jge .paddle1NotAboveBall

    mov eax, [rel paddle1 + 4] ;paddle1.y
    add eax, PADDLE_SPEED_AI
    mov [rel paddle1 + 4], eax ;paddle1.y
.paddle1NotAboveBall:
    cmp edi, esi
    jle .paddle1NotBelowBall

    mov eax, [rel paddle1 + 4] ;paddle1.y
    sub eax, PADDLE_SPEED_AI
    mov [rel paddle1 + 4], eax ;paddle1.y

.paddle1NotBelowBall:
    jmp .skipPaddle1

.ballMovesAwayFromPaddle1:
    mov edx, SCREEN_HEIGHT_HALF
    sub edx, PADDLE_HEIGHT_HALF ; centerY

    cmp edi, edx
    jle .paddle1NotAboveBallAway

    mov eax, [rel paddle1 + 4] ;paddle1.y
    sub eax, PADDLE_SPEED_AI
    mov [rel paddle1 + 4], eax ;paddle1.y
.paddle1NotAboveBallAway:
    cmp edi, edx
    jge .paddle1NotBelowBallAway

    mov eax, [rel paddle1 + 4] ;paddle1.y
    add eax, PADDLE_SPEED_AI
    mov [rel paddle1 + 4], eax ;paddle1.y

.paddle1NotBelowBallAway:
.skipPaddle1:

    ; paddle2
    mov BYTE dl, [rel paddle2AI]
    test dl, dl
    jz .skipPaddle2

    mov edi, [rel paddle2 + 4] ; paddle2.y
    add edi, PADDLE_HEIGHT_HALF

    mov eax, [rel ballDirX]
    cmp eax, 0
    jle .ballMovesAwayFromPaddle2

    mov esi, [rel ball + 4] ;ball.y
    add esi, BALL_SIZE_HALF

    cmp edi, esi
    jge .paddle2NotAboveBall

    mov eax, [rel paddle2 + 4] ;paddle1.y
    add eax, PADDLE_SPEED_AI
    mov [rel paddle2 + 4], eax ;paddle1.y
.paddle2NotAboveBall:
    cmp edi, esi
    jle .paddle2NotBelowBall

    mov eax, [rel paddle2 + 4] ;paddle2.y
    sub eax, PADDLE_SPEED_AI
    mov [rel paddle2 + 4], eax ;paddle2.y

.paddle2NotBelowBall:
    jmp .skipPaddle2

.ballMovesAwayFromPaddle2:
    mov edx, SCREEN_HEIGHT_HALF
    sub edx, PADDLE_HEIGHT_HALF ; centerY

    cmp edi, edx
    jle .paddle2NotAboveBallAway

    mov eax, [rel paddle2 + 4] ;paddle2.y
    sub eax, PADDLE_SPEED_AI
    mov [rel paddle2 + 4], eax ;paddle2.y
.paddle2NotAboveBallAway:
    cmp edi, edx
    jge .paddle2NotBelowBallAway

    mov eax, [rel paddle2 + 4] ;paddle2.y
    add eax, PADDLE_SPEED_AI
    mov [rel paddle2 + 4], eax ;paddle2.y

.paddle2NotBelowBallAway:
.skipPaddle2:
ret

clamp_pad:
    mov eax, [rdi] ; y

    cmp eax, 0
    jge .geZero
    mov eax, 0
    mov [rdi], eax
.geZero:

    add eax, PADDLE_HEIGHT
    cmp eax, SCREEN_HEIGHT
    jle .leSCREEN_HEIGHT
    mov eax, SCREEN_HEIGHT
    sub eax, PADDLE_HEIGHT
    mov [rdi], eax
.leSCREEN_HEIGHT:
    
    ret

update:
    push rbp
    mov rbp, rsp

    lea rdi, [rel paddle1 + 4]
    call clamp_pad

    lea rdi, [rel paddle2 + 4]
    call clamp_pad

    ; ball.x += BALL_SPEED_X * ballDirX
    mov eax, BALL_SPEED_X
    imul eax, [rel ballDirX]
    add eax, [rel ball + 0]
    mov [rel ball + 0], eax

    ; ball.y += BALL_SPEED_Y * ballDirY
    mov eax, BALL_SPEED_Y
    imul eax, [rel ballDirY]
    add eax, [rel ball + 4]
    mov [rel ball + 4], eax

    ; limit ball movment in screen height direction 
    cmp eax, 0
    jge .geZero
    mov edi, [rel ballDirY]
    neg edi
    mov [rel ballDirY], edi
    mov [rel ball + 4], eax
.geZero:

    add eax, BALL_SIZE
    cmp eax, SCREEN_HEIGHT
    jle .leSCREEN_HEIGHT
    mov edi, [rel ballDirY]
    neg edi
    mov [rel ballDirY], edi
    mov eax, SCREEN_HEIGHT
    sub eax, BALL_SIZE
    mov [rel ball + 4], eax
.leSCREEN_HEIGHT:


   ; ball hits left paddle1?
   lea rdi, [rel ball]
   lea rsi, [rel paddle1]
   call SDL_HasIntersection wrt ..plt
   test eax, eax
   jz .paddle1NotHit

   mov eax, [rel paddle1 + 0] ; paddle1.x
   add eax, PADDLE_WIDTH
   mov [rel ball + 0], eax

   mov eax, [rel ballDirX]
   neg eax
   mov [rel ballDirX], eax

   mov eax, [rel ball + 4] ; ball.y
   add eax, BALL_SIZE_HALF ; eax = ball_center

   mov edi, [rel paddle1 + 4] ; paddle1.y
   add edi, PADDLE_HEIGHT_HALF ; edi = paddle_center
   sub eax, edi
   sar eax, 5
   
   mov [rel ballDirY], eax
.paddle1NotHit:

   ; ball hits left paddle2?
   lea rdi, [rel ball]
   lea rsi, [rel paddle2]
   call SDL_HasIntersection wrt ..plt
   test eax, eax
   jz .paddle2NotHit

   mov eax, [rel paddle2 + 0] ; paddle2.x
   sub eax, BALL_SIZE
   mov [rel ball + 0], eax

   mov eax, [rel ballDirX]
   neg eax
   mov [rel ballDirX], eax

   mov eax, [rel ball + 4] ; ball.y
   add eax, BALL_SIZE_HALF ; eax = ball_center

   mov edi, [rel paddle2 + 4] ; paddle2.y
   add edi, PADDLE_HEIGHT_HALF ; edi = paddle_center
   sub eax, edi
   sar eax, 5
   mov [rel ballDirY], eax
.paddle2NotHit:

    ; let dirY never be zero
    mov eax, [rel ballDirY]
    test eax, eax
    jnz .dirYNotZero

    call ball_dir
    mov [rel ballDirY], eax
.dirYNotZero:

    mov eax, [rel ball + 0] ; ball.x
    cmp eax, 0
    jge .notOutLeft
    
    mov eax, [rel score2]
    inc eax
    mov [rel score2], eax

    call reset_ball
.notOutLeft:

    mov eax, [rel ball + 0] ; ball.x
    cmp eax, SCREEN_WIDTH
    jle .notOutRight
    
    mov eax, [rel score1]
    inc eax
    mov [rel score1], eax

    call reset_ball
.notOutRight:

    pop rbp
    ret

; locals stack
; void render_text(char* text /*(rdi)*/, int x /*(esi)/*, int y /*(edx)*/, int ptSize /*(ecx)*/);
; char* text           // 8
; int x                // 4
; int y                // 4
; int ptSize           // 4
; {
; TTF_Font* font;      // 8
; TTF_Surface* surface // 8
; SDL_Texture* texture // 8
; SDL_Color color      // 4
; SDL_Rect rect       // 16
;                     //------
;                     // 64
; ....
; }
render_text:
    push rbp
    mov rbp, rsp

    sub rsp, 64

    ; move input params to stack vars
    mov [rbp - 8], rdi ; text
    mov [rbp - 12], esi ; x
    mov [rbp - 16], edx ; y
    mov [rbp - 20], ecx ; ptSize

    lea rdi, [rel font_path]
    mov esi, [rbp - 20] ; ptSize
    call TTF_OpenFont wrt ..plt
    test rax, rax
    jz .end
    mov [rbp -28], rax ; store font

    ;SDL_Color color
    mov byte [rbp - 48], 255 ; R
    mov byte [rbp - 47], 255 ; G
    mov byte [rbp - 46], 255 ; B
    mov byte [rbp - 45], 255 ; A

    ; TTF_RenderText_Solid
    mov rdi, [rbp - 28] ; *font
    mov rsi, [rbp - 8] ; *text
    mov edx, [rbp - 48] ; color
    call TTF_RenderText_Solid wrt ..plt
    test rax, rax
    jnz .skip0
    call print_sdl_err
    jmp .end_fnt
.skip0:
    mov [rbp - 36], rax ; *surface

    ; SDL_CreateTextureFromSurface
    mov rdi, [rel renderer]
    mov rsi, [rbp - 36] ; *surface
    call SDL_CreateTextureFromSurface wrt ..plt
    test rax, rax
    jnz .skip1
    call print_sdl_err
    jmp .end_srf
.skip1:
    mov [rbp - 44], rax ; *texture

    ; set rect
    mov eax, [rbp - 12] ; eax = x
    mov [rbp - 64], eax ; rect.x = eax = x

    mov eax, [rbp - 16] ; eax = y
    mov [rbp - 60], eax ; rect.y = eax = y

    mov rax, [rbp - 36] ; *surface
    mov ecx, [rax + 16] ; ecx = surface->w
    mov edx, [rax + 20] ; edx = surface->h

    mov [rbp - 56], ecx ; rect.w = ecx = surface->w
    mov [rbp - 52], edx ; rect.h  = edx = surface->h

    ; SDL_RenderCopy(renderer, texture, NULL, &rect);
    mov rdi, [rel renderer]
    mov rsi, [rbp - 44] ; *texture
    mov rdx, NULL
    lea rcx, [rbp - 64] ; &rect
    call SDL_RenderCopy wrt ..plt


.end_text:
    mov rdi, [rbp - 44] ; texture
    call SDL_DestroyTexture wrt ..plt
.end_srf:
    mov rdi, [rbp - 36] ; surface
    call SDL_FreeSurface wrt ..plt
.end_fnt:
    mov rdi, [rbp - 28] ; font
    call TTF_CloseFont wrt ..plt
.end:
    add rsp, 64
    pop rbp
    ret


render:
    push rbp
    mov rbp, rsp

    sub rsp, 48

    ; clear screen with green color
    mov rdi, [rel renderer] ; first parameter to this function is renderer
    mov rsi, 64 ; R 
    mov rdx, 127 ; G 
    mov rcx, 0 ; B 
    mov r8, 255 ; A
    call SDL_SetRenderDrawColor wrt ..plt

    mov rdi, [rel renderer] ; first parameter to this function is renderer
    call SDL_RenderClear wrt ..plt

    mov rdi, [rel renderer] ; first parameter to this function is renderer
    mov rsi, 255 ; R 
    mov rdx, 255 ; G 
    mov rcx, 255 ; B 
    mov r8, 255 ; A
    call SDL_SetRenderDrawColor wrt ..plt

    ; draw Net (center line)
    mov dword [rbp - 4], 0 ; count
.loop:
    ; set rect
    mov dword [rbp - 20], SCREEN_WIDTH_HALF ; rect.x
    mov eax, [rbp - 4]; count
    mov [rbp - 16], eax ; rect.y
    mov dword [rbp - 12], 1 ; rect.w
    mov dword [rbp - 8], 20 ; rect.h

    mov rdi, [rel renderer]
    lea rsi, [rbp - 20]
    call SDL_RenderFillRect wrt ..plt

    mov eax, [rbp - 4] ; count=+40
    add eax, 40
    mov [rbp-4], eax

    cmp eax, SCREEN_HEIGHT
    jl .loop

    ; draw paddle1
    mov rdi, [rel renderer]
    lea rsi, [rel paddle1]
    call SDL_RenderFillRect wrt ..plt

    ; draw paddle2
    mov rdi, [rel renderer]
    lea rsi, [rel paddle2]
    call SDL_RenderFillRect wrt ..plt

    ; draw ball
    mov rdi, [rel renderer]
    lea rsi, [rel ball]
    call SDL_RenderFillRect wrt ..plt

    ; draw score lef player (player 1)
    lea rdi, [rbp - 36] ; char buff[16]
    mov rsi, 16
    lea rdx, [rel int_format]
    mov ecx, [rel score1]
    call snprintf wrt ..plt
    ; void render_text(char* text /*(rdi)*/, int x /*(esi)/*, int y /*(edx)*/, int ptSize /*(ecx)*/);
    lea rdi, [rbp - 36] ; char buff[16]
    mov esi, 50
    mov edx, 20
    mov ecx, 64
    call render_text

    ; draw score right player (player 2)
    lea rdi, [rbp - 36] ; char buff[16]
    mov rsi, 16
    lea rdx, [rel int_format]
    mov ecx, [rel score2]
    call snprintf wrt ..plt
    mov ecx, 45
    imul ecx
    ; void render_text(char* text /*(rdi)*/, int x /*(esi)/*, int y /*(edx)*/, int ptSize /*(ecx)*/);
    lea rdi, [rbp - 36] ; char buff[16]
    mov esi, SCREEN_WIDTH_MINUS_50
    sub esi, eax
    mov edx, 20
    mov ecx, 64
    call render_text


    mov rdi, [rel renderer] ; first parameter to this function is renderer
    call SDL_RenderPresent wrt ..plt

    add rsp, 48
    pop rbp
    ret

print_sdl_err:
    push rbp
    mov rbp, rsp

    call SDL_GetError wrt ..plt
    mov rsi, rax
    lea rdi, [rel init_fail]
    mov rax, 0
    call SDL_Log wrt ..plt
    
    pop rbp
    ret


ball_dir:
    push rbp
    mov rbp, rsp

    call rand wrt ..plt ; result in rax
    mov rcx, 2
    cqo            ; sign-extend RAX into RDX:RAX
    idiv rcx            ; quotient in RAX, remainder in RDX

    test rdx, rdx
    jz .zero
    mov eax, -1
    jmp .end

.zero:
    mov eax, 1
    
.end:
    pop rbp
    ret

reset_game_state:
    push rbp
    mov rbp, rsp

    ; Init paddls
    mov dword [rel paddle1 + 0], 20 ; paddle1.x
    mov dword [rel paddle1 + 4], PADDLE_Y ; paddle1.y
    mov dword [rel paddle1 + 8], PADDLE_WIDTH ; paddle1.w
    mov dword [rel paddle1 + 12], PADDLE_HEIGHT ; paddle1.h

    mov dword [rel paddle2 + 0], PADDLE2_X ; paddle2.x
    mov dword [rel paddle2 + 4], PADDLE_Y ; paddle2.y
    mov dword [rel paddle2 + 8], PADDLE_WIDTH ; paddle2.w
    mov dword [rel paddle2 + 12], PADDLE_HEIGHT ; paddle2.h

    ; Init ball
    mov dword [rel ball + 0], BALL_X ; ball.x
    mov dword [rel ball + 4], BALL_Y ; ball.y
    mov dword [rel ball + 8], BALL_SIZE ; ball.w
    mov dword [rel ball + 12], BALL_SIZE ; ball.w

    ; init pseudo random gen
    mov rdi, NULL
    call time wrt ..plt
    mov rdi, rax
    call srand wrt ..plt

    call ball_dir
    mov [rel ballDirX], eax

    call ball_dir
    mov [rel ballDirY], eax

    mov dword [rel score1], 0
    mov dword [rel score2], 0

    mov byte [rel isRunning], 1

    pop rbp
    ret

reset_ball:
    push rbp
    mov rbp, rsp

    mov dword [rel ball + 0], BALL_X ; ball.x
    mov dword [rel ball + 4], BALL_Y ; ball.y

    call ball_dir
    mov [rel ballDirX], eax

    call ball_dir
    mov [rel ballDirY], eax

    pop rbp
    ret


    global main
main:
    push rbp
    mov rbp, rsp

    ; SDL_Init
    mov rdi, SDL_INIT_VIDEO
    call SDL_Init wrt ..plt
    test rax, rax
    jz .skip1
    ; handle error
    call print_sdl_err
    jmp .main_end
.skip1:

    ; Create window
    lea rdi, [rel message]    ; pointer to message
    mov rsi, 100
    mov rdx, 100
    mov rcx, SCREEN_WIDTH
    mov r8, SCREEN_HEIGHT
    mov r9, 0
    call SDL_CreateWindow wrt ..plt
    test rax, rax
    jnz .skip2
    ; handle error
    call print_sdl_err
    jmp .main_end
.skip2:
    mov [rel window], rax ; store window pointer

    ; Create renderer
    mov rdi, [rel window] ; window
    mov rsi, -1
    mov rdx, SDL_RENDERER_ACCELERATED
    or rdx, SDL_RENDERER_PRESENTVSYNC
    call SDL_CreateRenderer wrt ..plt
    test rax, rax
    jnz .skip3
    ; handle error
    call print_sdl_err
    jmp .main_end
.skip3:
    mov [rel renderer], rax ; store renderer pointer

    ; init TTF
    call TTF_Init wrt ..plt
    cmp rax, 0
    jge .skip4
    ; handle error
    call print_sdl_err
    jmp .main_end
.skip4:
    
    call reset_game_state

.loop1:
    mov al, [rel isRunning]
    cmp al, 1
    jne .main_end
    
    call process_events

    call process_input

    call play_ai

    call update
    
    call render

    mov rdi, 16 ; ~ 60 fps
    call SDL_Delay wrt ..plt
    
    jmp .loop1


.main_end:
    call TTF_Quit wrt ..plt

    mov rdi, [rel renderer] ; renderer pointer
    call SDL_DestroyRenderer wrt ..plt
    
    mov rdi, [rel window] ; window pointer
    call SDL_DestroyWindow wrt ..plt

    call SDL_Quit wrt ..plt

    pop rbp

    xor rax, rax
    ret
