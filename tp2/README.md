# Paginador xv6

1. Entrega no domingo após a segunda prova
1. Pode ser feito em dupla

Parte deste material foi adaptado do material do
[Remzi H. Arpaci-Dusseau](http://www.cs.wisc.edu/~remzi).

Neste TP vamos explorar alguns conceitos da segunda parte da disciplina.  Em
particular, vamos rever os conceitos de memória virtual e páginas copy on
write.

## xv6

Antes de iniciar o ambiente xv6 você precisa instalar alguns programas no seu
ambiente Linux Ubuntu. Para usuários Windows, ou macOSx recomendo o uso de uma
VM com Linux. Talvez seja possível usar o Linux Subsystem for Windows, veja
como [aqui](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide).
No macOSx você deve precisar do [Homebrew](https://brew.sh). Após instalar as
ferramentas no seu Windows/macOSx, veja as instruções para ter um ambiente xv6
[aqui](https://gcallah.github.io/OperatingSystems/xv6Install.html).

**Ubuntu**

No Ubuntu, rode os seguintes comandos para instalar o gcc, qemu, git e o
build-essentials.

```shell
$ sudo apt-get update
$ sudo apt-get install build-essential
$ sudo apt-get install gcc
$ sudo apt-get install gcc-multilib
$ sudo apt-get install qemu
$ sudo apt-get install git
$ sudo apt-get install nasm
```

**Clonando**

### Compilando xv6

### Rodando xv6

### Saindo do xv6

### Adicionando uma nova syscall e um novo comando

## Syscall para pegar o endereço real de uma página

## Copy-on-write pages
