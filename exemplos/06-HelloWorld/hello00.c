#include <stdio.h>
typedef struct {
  char type:4,
       ola:16;
} elf;

int main(void) {
  printf("Hello World\n");
  return 0;
}
