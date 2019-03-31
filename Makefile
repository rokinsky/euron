euron:
	mkdir -p build
	nasm -DN=100000 -f elf64 -o build/euron.o src/euron.asm
	gcc -c -Wall -O2 -o build/euron_test.o src/euron_test.c
	gcc -o build/euron_test build/euron.o -pthread  build/euron_test.o

clean:
	rm -rf build
