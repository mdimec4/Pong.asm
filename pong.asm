default rel

NULL equ 0

%define SDL_INIT_VIDEO  00000020h
%define SDL_RENDERER_ACCELERATED    00000002h
%define SDL_RENDERER_PRESENTVSYNC   00000004h
%define SDL_QUIT    100h


; --- Configuration ---
%define SCREEN_WIDTH 1024
%define SCREEN_HEIGHT 768
%define PADDLE_WIDTH 15
%define PADDLE_HEIGHT 100
%define BALL_SIZE 15
%define PADDLE_SPEED 8
%define BALL_SPEED_X 7
%define BALL_SPEED_Y 7

section .rodata
    message db 'Pong.ASM',0
    init_fail   db 'SDL fail: %s',0

section .data
    isRunning   db  1
    window      dq NULL
    renderer    dq NULL
    

section .text

;extern printf
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


process_input:
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

generate_output:
    push rbp
    mov rbp, rsp

    mov rdi, [rel renderer] ; first parameter to this function is renderer
    mov rsi, 64 ; R 
    mov rdx, 127 ; G 
    mov rcx, 0 ; B 
    mov r8, 255 ; A
    call SDL_SetRenderDrawColor wrt ..plt

    mov rdi, [rel renderer] ; first parameter to this function is renderer
    call SDL_RenderClear wrt ..plt

    mov rdi, [rel renderer] ; first parameter to this function is renderer
    call SDL_RenderPresent wrt ..plt

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

.loop1:
    mov al, [rel isRunning]
    cmp al, 1
    jne .main_end
    
    call process_input
    
    call generate_output
    
    jmp .loop1


.main_end:
    mov rdi, [rel renderer] ; renderer pointer
    call SDL_DestroyRenderer wrt ..plt
    
    mov rdi, [rel window] ; window pointer
    call SDL_DestroyWindow wrt ..plt

    call SDL_Quit wrt ..plt

    pop rbp

    xor rax, rax
    ret
