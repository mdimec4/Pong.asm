all:
	nasm -g -f elf64 pong.asm 
	gcc -fPIE -pie pong.o -o pong `sdl2-config --libs` `pkg-config --libs SDL2_image` `pkg-config --libs SDL2_ttf`
