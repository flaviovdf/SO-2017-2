# Paginador xv6

1. Entrega no domingo após a segunda prova
1. Pode ser feito em dupla

Parte deste material foi adaptado do material do
[Remzi H. Arpaci-Dusseau](http://www.cs.wisc.edu/~remzi).

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

### Adicionando uma nova syscall e um novo comando

Agora vou mostrar um passo a passo como adicionar uma nova syscall no xv6. Use
este passo a passo como base para seu TP. Vamos adicionar uma syscall para
desligar o xv6 e um comando shutdown que usa a syscall. No momento, única forma
de desligar o xv6 é com o Control-a-x. Após adicionar a syscall teremos um
comando do sistema chamado `shutdown`.

**Passo 1: Código da syscall**

Para adicionar uma syscall vamos precisar alterar alguns arquivos do xv6.

1. user.h: This contains the user-side function prototypes of system calls as
   well as utility library functions (stat, strcpy, printf, etc.).

1. syscall.h: This file contains symbolic definitions of system call numbers.
   You need to define a unique number for your system call. Be sure that the
   numbers are consecutive. That is, there are no missing number in the
   sequence. These numbers are indices into a table of pointers defined in
   syscall.c (see next item).

1. syscall.c: This file contains entry code for system call processing. The
   syscall(void) function is the entry function for all system calls. Each
   system call is identified by a unique integer, which is placed in the
   processor’s eax register. The syscall function checks the integer to ensure
   that it is in the appropriate range and then calls the corresponding
   function that implements that call by making an indirect funciton call to a
   function in the syscalls[] table. You need to ensure that the kernel
   function that implements your system call is in the proper sequence in the
   syscalls array.

1. usys.S: This file contains macros for the assembler code for each system
   call. This is user code (it will be part of a user-level program) that is
   used to make a system call. The macro simply places the system call number
   into the eax register and then invokes the system call. You need to add a
   macro entry for your system call here.

1. sysproc.c: This is a collection of process-related system calls. The
   functions in this file are called from syscall. You can add your new
   function to this file.

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
através do valor do registrador `eax`. Lembre-se que syscalls são tratadas por
traps, então não podemos simplesmente passar o valor

**Passo 2: Tabela de syscalls**

**Passo 3: Novo Comando shutdown**

**Passo 4: Testando tudo**

## Parte 1: Syscall para pegar o endereço real de uma página

## Parte 2: Copy-on-write pages
