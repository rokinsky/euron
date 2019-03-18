euron:
	mkdir -p build
	nasm -g -DN=XXX -f elf64 -o build/euron.o src/euron.asm

clean:
	rm -rf build
