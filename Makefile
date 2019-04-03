euron:
	mkdir -p build
	nasm -DN=100000 -f elf64 -o build/euron.o src/euron.asm
	gcc -c -Wall -O2 -o build/test_euron.o src/test_euron.c
	gcc -o build/test_euron build/euron.o -pthread  build/test_euron.o

clean:
	rm -rf build
