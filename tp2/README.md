# Paginador xv6

1. Entrega no domingo após a segunda prova
1. Pode ser feito em dupla

Parte deste material foi adaptado do material do
[Remzi H. Arpaci-Dusseau](http://www.cs.wisc.edu/~remzi). Outra parte foi
adaptada do material do
[MIT](https://pdos.csail.mit.edu/6.828/2016/index.html).

Neste TP vamos explorar alguns conceitos da segunda parte da disciplina.  Em
particular, vamos rever os conceitos de memória virtual e páginas copy on
write.

## Tutorial xv6

Antes de iniciar o ambiente xv6 você precisa instalar alguns programas no seu
ambiente Linux Ubuntu. Como nos outros trabalhos, recomendo **fortemente** que
use um ambiente Linux ou uma VM. De qualquer forma, coloquei instruções de como
configurar o xv6 no Windows/macOSx mais abaixo.

### Configurando o ambiente

**Ubuntu**

No Ubuntu, rode os seguintes comandos para instalar o gcc, qemu, git e o
build-essentials.

```
$ sudo apt-get update
$ sudo apt-get install build-essential
$ sudo apt-get install gcc-multilib
$ sudo apt-get install qemu
$ sudo apt-get install git
$ sudo apt-get install nasm
```

**Windows/macOSx**

Para usuários Windows instaler o Linux Subsystem for Windows, veja
como [aqui](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide).
No macOSx você deve precisar do [Homebrew](https://brew.sh). Após instalar as
ferramentas no seu Windows/macOSx, veja as instruções para ter um ambiente xv6
[aqui](https://gcallah.github.io/OperatingSystems/xv6Install.html).

**Clonando**

Rode o comando:

```
$ git clone https://github.com/mit-pdos/xv6-public.git
```

Depois entre na pasta xv6-public.

### Compilando e Rodando o xv6

Após entrar na pasta `xv6-public` digite:

```
$ make
```

Para executar digite:

```
$ make qemu-nox
```

Se sua saída for algo como a abaixo, então você fez tudo corretamente:

```
$ make qemu-nox
qemu-system-i386 -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512
xv6...
cpu1: starting 1
cpu0: starting 0
sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
init: starting sh
```

O xv6 vem com alguns comandos como ls, cat, echo. Teste alguns

```
$ ls
.              1 1 512
..             1 1 512
README         2 2 2632
cat            2 3 13004
echo           2 4 12096
forktest       2 5 7780
grep           2 6 14612
init           2 7 12652
kill           2 8 12140
ln             2 9 12012
ls             2 10 14168
mkdir          2 11 12188
rm             2 12 12164
sh             2 13 22460
stressfs       2 14 12844
usertests      2 15 54992
wc             2 16 13536
zombie         2 17 11844
console        3 18 0
```

### Controlando a VM

Provavelmente você vai utilizar só o comando **quit**, mas seguem uma lista de
alguns outros.

* Control-a-c
  1. **info registers** to show CPU registers
  1. **x/10i $eip** show the next 10 instructions at the current instruction pointer
  1. **system-reset** reset & reboot the system
  1. **quit** exit the emulator (quit xv6)

```
qemu-system-i386 -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512
xv6...
cpu1: starting 1
cpu0: starting 0
sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
init: starting sh
$ QEMU 2.3.0 monitor - type 'help' for more information
(qemu)
```

* Control-a-x
  1. Desliga a VM

```
qemu-system-i386 -nographic -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp 2 -m 512
xv6...
cpu1: starting 1
cpu0: starting 0
sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
init: starting sh
$ QEMU: Terminated
```

### Adicionando um esqueleto de uma nova syscall e um novo comando

Agora vou mostrar um passo a passo como adicionar uma nova syscall no xv6. Use
este passo a passo como base para seu TP. Vamos adicionar uma syscall retornar
a data do sistema. Após adicionar a syscall teremos um comando do sistema
chamado `date`.

**Passo 0: Entendendo o Código xv6**

Para adicionar uma syscall vamos precisar alterar alguns arquivos do xv6.

1. `user.h:` Define as chamadas que são vísiveis ao usuário.
   (stat, strcpy, printf, etc.).
1. `syscall.h:` Define os números de cada syscall. Para implementar uma
   nova você precisa adicionar uma nova entrada neste arquivo. Garanta
   que os números são contíguos. Tal número vai ser usado no `syscall.c`
1. `syscall.c:` Este arquivo tem as funções responsáveis por realmente
   chamar o código da nova syscall. Em particular vamos estudar a função
   `void syscall(void)`.
1. `usys.S:` Macros assembly para chamar cada syscall. O código no
   `usys.S` simplesmente coloca o número da syscall no registrador `eax`
   e invoca o `void syscall(void)` do `syscall.c`. Você vai precisar
   adicionar uma linha neste arquivo.
1. `sysproc.c:` Sua nova chamada do sistema vai ser implementada neste
   arquivo. O mesmo contém o código das system calls que o sistema oferece
   para seus processos.

Vamos iniciar dando uma olhada no `syscall.c` do xv6. Em particular, dê uma
olhada na função `void syscall(void)`.

```c
void
syscall(void)
{
  int num;
  struct proc *curproc = myproc();

  num = curproc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
```

Note que na linha `curproc->tf->eax` o número da syscall é identificado
através do valor do registrador `eax`.

Estude struct do processo definido no arquivo `proc.h`. Pode lhe ajudar
a entender como o xv6 gerencia processos e trata traps. Em particular,
note o campo `trapframe`. O mesmo pode ser encontrado no `x86.h`.

```c
enum procstate { UNUSED, EMBRYO, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  uint sz;                     // Size of process memory (bytes)
  pde_t* pgdir;                // Page table
  char *kstack;                // Bottom of kernel stack for this process
  enum procstate state;        // Process state
  int pid;                     // Process ID
  struct proc *parent;         // Parent process
  struct trapframe *tf;        // Trap frame for current syscall
  struct context *context;     // swtch() here to run process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};
```

**Passo 1: Esqueleto da syscall**

Suas syscalls vão morar no arquivo `sysproc.c`. Então, você pode usar o
esqueleto abaixo para implementar a mesma.

```c
int
sys_date(void)
{
  char *ptr;
  argptr(0, &ptr, sizeof(struct rtcdate*));
  // seu código aqui
  return 0;
}
```

O passo mais importante aqui é a chamada `argptr`. Toda syscall no xv6 recebe
void como entrada. Parece esquisito, mas lembre-se que estamos no meio do
tratamento de um trap. Além disso, cada chamada do sistema vai ter parâmetros
diferentes e precisamos de uma forma comum de chamar toda e qualquer chamada de
sistema. Por isso, o xv6 tem as chamas `argptr`, `argint` e `argstr` para pegar
da pilha parâmetros do tipo: ponteiro para qualquer coisa (que vem como char,
faça cast), inteiros e strings.

```c
// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip);

// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int argptr(int n, char **pp, int size);

// Fetch the nth word-sized system call argument as a string pointer.
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int argstr(int n, char **pp);
```

**Passo 2: Adicionando sua system call no vetor de tratamentos**

Para que seu código seja chamado você deve alterar alguns arquivos do kernel.
Em particular você deve alterar os arquivos:

1. `syscall.h:` adicionar o número da nova chamada
1. `syscall.c:` ver o vetor de tratamentos
1. `user.h:` adicionar a chamada que vai ser visível para o usuário. Note que
    essa chamada não é implementada, é só o esqueleto que o usuário vê.
    Eu usei: `int date(void*);` No fim, o usys.S quem trata tais chamadas.
1. `usys.S`: adicionar 1 linha para a chamada. Esse é o código assembly que
    chaveia do `user.h` para a sua chamada do passo 0.

**Passo 3: Novo Comando**

Agora crie um arquivo `date.c` com o seguinte conteúdo:

```c
#include "types.h"
#include "user.h"
#include "date.h"

int stdout = 1;
int stderr = 2;

int
main(int argc, char *argv[])
{
  struct rtcdate r;

  if (date(&r)) {
    printf(stderr, "Erro na syscall\n");
    exit();
  }

  // Imprima a data aqui

  exit();
}
```

Depois, no `Makefile` coloque uma linha para que seu novo comando faça parte
do sistema. Para isto basta colocar uma linha `_date` (ver abaixo).

```make
UPROGS=\
	_cat\
	_date\
	_echo\
	_forktest\
	_grep\
	_init\
	_kill\
	_ln\
	_ls\
	_mkdir\
	_rm\
	_sh\
	_stressfs\
	_usertests\
	_wc\
	_zombie\
```

**Passo 4: Compilando e Testando**

Assumindo que tudo foi feito corretamente, compile seu sistema operacional.

```
$ make
```

Se tudo deu certo execute o mesmo.

```
$ make qemu-nox
```

E teste seu comando date:

```
$ date
```

Se nada for impresso, sem problemas, o comando ainda está incompleto. Se algum
erro ocorrer em algum dos passos acima, você deve ter cometido algum erro.

## Parte 1: Termine o código da syscall de data

Só isso, pode imprimir a data da forma que quiser.

## Parte 2: Syscall para pegar o endereço real de uma página

## Parte 3: Copy-on-write pages
