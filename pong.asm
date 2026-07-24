default rel

%define SDL_INIT_VIDEO  00000020h
%define SDL_RENDERER_ACCELERATED    00000002h
%define SDL_RENDERER_PRESENTVSYNC   00000004h
%define SDL_QUIT    100h

section .rodata
    message db 'Pong.ASM',0
    init_fail   db 'SDL fail: %s',0

section .data
    isRunning   db  1

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

    mov [rbp-8], rdi ; strore renderer on stack
    sub rsp, 16

    mov rdi, [rbp-8] ; first parameter to this function is renderer
    mov rsi, 64 ; R 
    mov rdx, 127 ; G 
    mov rcx, 0 ; B 
    mov r8, 255 ; A
    call SDL_SetRenderDrawColor wrt ..plt

    mov rdi, [rbp-8] ; first parameter to this function is renderer
    call SDL_RenderClear wrt ..plt

    mov rdi, [rbp-8] ; first parameter to this function is renderer
    call SDL_RenderPresent wrt ..plt

    add rsp, 16
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
    
    ; locals
    sub rsp, 16
    mov rax, 0
    mov QWORD [rbp-8], rax ; window pointer
    mov QWORD [rbp-16], rax ; renderer pointer

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
    mov rcx, 1024
    mov r8, 768
    mov r9, 0
    call SDL_CreateWindow wrt ..plt
    test rax, rax
    jnz .skip2
    ; handle error
    call print_sdl_err
    jmp .main_end
.skip2:
    mov [rbp-8], rax ; store window pointer

    ; Create renderer
    mov rdi, [rbp-8] ; window
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
    mov [rbp-16], rax ; store renderer pointer

.loop1:
    mov al, [rel isRunning]
    cmp al, 1
    jne .main_end
    
    call process_input
    
    mov rdi, [rbp-16] ; renderer as first parameter
    call generate_output
    
    jmp .loop1


.main_end:
    mov rdi, [rbp-16] ; renderer pointer
    call SDL_DestroyRenderer wrt ..plt
    
    mov rdi, [rbp-8] ; window pointer
    call SDL_DestroyWindow wrt ..plt

    call SDL_Quit wrt ..plt

    add rsp, 16
    pop rbp

    xor rax, rax
    ret
