.PHONY: all clean

all:
	gcc -shared -fPIC printer.c -o libprinter.so
	gcc main-loadtime.c -o main-loadtime ./libprinter.so
	gcc main-runtime.c -o main-runtime ./libprinter.so

clean:
	rm *.a *.o main-loadtime main-runtime
