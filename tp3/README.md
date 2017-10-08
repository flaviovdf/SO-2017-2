# DCC605 File System Checker (DCC-FSCK).

Neste trabalho você vai implementar um FSCK para o sistema ext2. Para
realizar seu TP recomendo um bom entendimento do
[Fast File System](http://pages.cs.wisc.edu/~remzi/OSTEP/file-ffs.pdf). O mesmo
é a base do ext2.

## Sobre o ext2

O Extended File System 2 (ext2) é um sistema de arquivos criados para sistemas
Linux em meados de 1993. Visando corrigir alguns problemas da primeira versão
do Extended File System (simplesmente ext), o sistema de arquivos ext2 tem um
esquema de implementação mais próximo ao Berkley Fast File System (FFS).

Embora já tenha caído um pouco em desuso, o ext2 é um sistema de arquivos com
bastante influência. O desenvolvimento do ext2 teve como um dos principais
objetivos a extensibilidade do sistema, sendo assim o mesmo serviu como base
para o ext3 e ext4 que são mais populares hoje em dia.

**Layout dos inodes, grupos e blocos**

Seguindo o modelo do FFS, um disco formatado com um sistema de arquivos ext2
terá um layout de blocos similar ao da figura abaixo (note que existem
problemas de escala na mesma, é apenas um esquema):

```
Layout geral:
  * Bloco de Boot         --> Utilizado para iniciar o sistema, sempre ocupa
                              uma posição fixa no ínicio do disco.
  * Grupo de Blocos i     --> Cada grupo de blocos é utilizado para guardar
                              arquivos. Fazemos uso de mais de um grupo pois
                              discos tem vários cílindros. Então guardar
                              artigos relacionados em um mesmo bloco ajuda.

  1-bloco
 +-------+-------+-------+-------+-------+-------+-------+-------+-------+-----
 | bloco |                               |                               |
 | de    |       grupo de blocos 0       |       grupo de blocos 1       | ...
 | boot  |                               |                               |
 +-------+-------+-------+-------+-------+-------+-------+-------+-------+-----
        /                                 \
       /                                   \
      /                                     \
     /                                       \
    /                                         \
   /                                           \
  /                                             \
 /               grupo de blocos i               \
+-------+-------+-------+-------+-------+-------+-------+-------+-------+------
| super |  descritores  |       |       | tabela        |
| bloco |      do       |d-bmap |i-bmap | de inode      |  blocos de dados...
| const |     grupo     |       |       | inodes        |
+-------+-------+-------+-------+-------+-------+-------+-------+-------+------
 1-bloco    n-blocos     1-bloco 1-bloco     n-blocos          n-blocos

Layout de um grupo:
  * Super Bloco           -->
  * Descritores do Grupo  -->
  * Data Bitmap (d-bmap)  -->
  * Inode Bitmap (i-bmap) -->
  * Tabela de Inodes      -->
  * Bloco de Dados        -->
```

**Blocos**

**Grupos de Blocos**

**Super Blocos**

**INodes**

**Diretórios**

**Arquivos**

**Links**

## Criando imagens

**Comando dd**

```
$ filename=fs-0x00dcc605-ext2-10240.img
$ dd if=/dev/zero of=$filename bs=1024 count=10240
```

```
1024+0 records in
1024+0 records out
1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.0242941 s, 43.2 MB/s
```

**Comando mkfs.ext2**

```
$ mkfs.ext2 fs-0x00dcc605-ext2-10240.img
```

```
mke2fs 1.42.13 (17-May-2015)
Creating filesystem with 10240 1k blocks and 2560 inodes
Filesystem UUID: 24c464b5-2e6c-4b6f-8309-d3454d683858
Superblock backups stored on blocks:
	8193

Allocating group tables: done
Writing inode tables: done
Writing superblocks and filesystem accounting information: done
```

**Falar do superblock backup**

## Fazendo uso das imagens

## Casos de teste

## Entrega
