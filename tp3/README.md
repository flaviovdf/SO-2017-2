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
  * Super Bloco           --> Contém meta-dados do sistema de arquivos. Uma
                              cópia em cada grupo.
  * Descritores do Grupo  --> Meta-dados do grupo.
  * Data Bitmap (d-bmap)  --> Mapa de bits de dados livres
  * Inode Bitmap (i-bmap) --> Mapa de bits de inodes livres
  * Tabela de Inodes      --> Contém os inodes (metadados) do sistema de
                              arquivos. Cada arquivo tem 1 apenas 1 inode.
                              Através de links, um mesmo inode pode aparecer
                              mapear para 2 caminhos.
  * Bloco de Dados        --> Os dados do arquivos e diretórios em si.
```

The le32 and le16 datatypes specify little-endian 32-bit and 16-bit integers (unsigned)

## Structs úteis

Para entender melhor o ext2, vamos dar uma olhada no cabeçalho do Linux
que descreve o sistema de arquivos. O mesmo pode ser encontrado
[aqui](http://github.com/torvalds/linux/blob/master/fs/ext2/ext2.h).

Antes de iniciar, temos que entender os tipos `__le32` e `__le16`. Como o Linux
é cross-platform, tipos genéricos para qualquer arquitetura são necessários.
Esses dois em particular são *unsigned ints* de 32 e 16 bits. Os mesmos sempre
vão ser representados em *little endian*.

**Super bloco**

```c
struct ext2_super_block {
  __le32 s_inodes_count;          /* Inodes count */
  __le32 s_blocks_count;          /* Blocks count */
  __le32 s_r_blocks_count;        /* Reserved blocks count */
  __le32 s_free_blocks_count;     /* Free blocks count */
  __le32 s_free_inodes_count;     /* Free inodes count */
  __le32 s_first_data_block;      /* First Data Block */
  __le32 s_log_block_size;        /* Block size */
  // . . .
  __le32 s_blocks_per_group;      /* # Blocks per group */
  // . . .
  __le32 s_inodes_per_group;      /* # Inodes per group */
  // . . .
  __le16 s_magic;                 /* Magic signature */
  __le32 s_first_ino;             /* First non-reserved inode */
  __le16 s_inode_size;            /* size of inode structure */
  // . . .
}
```

**Descritores de Grupo**

```c
struct ext2_group_desc
{
  __le32 bg_block_bitmap;         /* Blocks bitmap block */
  __le32 bg_inode_bitmap;         /* Inodes bitmap block */
  __le32 bg_inode_table;          /* Inodes table block */
  __le16 bg_free_blocks_count;    /* Free blocks count */
  __le16 bg_free_inodes_count;    /* Free inodes count */
  __le16 bg_used_dirs_count;      /* Directories count */
  __le16 bg_pad;
  __le32 bg_reserved[3];
};
```

Para saber o número de grupos no ext2 usamos a seguinte abordagem. A mesma faz
uso dos campos do superbloco.

```c
/* calculate number of block groups on the disk */
unsigned int group_count = 1 + (super.s_blocks_count-1) / super.s_blocks_per_group;

/* calculate size of the group descriptor list in bytes */
unsigned int descr_list_size = group_count * sizeof(struct ext2_group_descr);
```

Para ler os descritores do grupo, primeiramente você deve calcular o offset do
inicio do disco. Como o disco tem 1024 bytes reservados no inicio e o primeiro
bloco é um superbloco, o código é para ler o descrito é tal como:

```c
struct ext2_group_descr group_descr;
/* position head above the group descriptor block */
lseek(sd, 1024 + block_size, SEEK_SET);
read(sd, &group_descr, sizeof(group_descr));
```

O descritor do grupo vai conter meta-dados para identificar o data e inode
bitmap daquele grupo. Uma macro boa de se ter indica qual o local do disco de
um dado bloco:

```c
/* location of the super-block in the first group */
#define BASE_OFFSET 1024
#define BLOCK_OFFSET(block) (BASE_OFFSET + (block-1)*block_size)
```

**Blocos**

**INodes**

**Diretórios**

```c
struct ext2_dir_entry_2 {
  __le32  inode;         /* Inode number */
  __le16  rec_len;       /* Directory entry length */
  __u8    name_len;      /* Name length */
  __u8    file_type;
  char    name[];        /* File name, up to EXT2_NAME_LEN */
};
```

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

## Erros que vamos causar:

Extend  your  tool  to checks  for the  specific  file system  errors  l
isted  below.   Your  tool  should  make  four
“passes”,  checking for the specified errors in each pass.  Whe
n an error is found,  you should print a de-
scription of the error to
stdout
and automatically fix the error. Your tool must only generate
output when
detecting and repairing errors—in other words, it should ge
nerate no output for a correct file system.

Pass 1: Directory pointers
(see McKusick & Kowalski, section 3.7). Verify for each dire
ctory:  that
the  first  directory  entry  is  “.”   and  self-references,  and  tha
t  the  second  directory  entry  is “..”   and
references its parent inode. If you find an error, notify the u
ser and correct the entry.

Pass 2:  Unreferenced inodes
(section 3.5).  Check to make sure all allocated inodes are re
ferenced
in a directory entry somewhere.  If you find an unreferenced in
ode, place it in the
/lost+found
directory—make the new filename the same as the inode number.
(I.e., if the unreferenced inode is
#1074, make it the file or directory
/lost+found/#1074
.)

Pass 3: Inode link count
(section 3.5). Count the number of directory entries that po
int to each inode
(e.g., the number of hard links) and compare that to the inode
link counter. If you find a discrepancy,
notify the user and update the inode link counter.

Pass 4:  Block allocation  bitmap
(section  3.3).   Walk the directory  tree and verify that the bl
ock
bitmap is correct.  If you find a block that should (or should no
t) be marked in the bitmap, notify the
user and correct the bitmap.
2
For this part, running the following command should fix disk e
rrors on the specified partition.
./myfsck -f
<
partition number
>
-i
<
disk image file
>
If the user specifies
-f 0
, your tool should correct disk errors on every ext2 partitio
n contained in the disk
image.
If you run your tool against the file systems on partitions 3 an
d 6, you should find one of each error (two on
one file system, two on the other). To formally test your tool,
use it to fix the errors and then run the version
of fsck provided by the system on the image (See the Resources
section). If no errors are returned, your tool
works.  This part will be graded by penalizing 10 points for ev
ery error the system fsck finds, for a total of
50 points.

## Entrega

Um .c e um .h (caso precise) que roda o fsck corrigindo os 5 casos
acima. Chame seu programa de `dcc_os_fsck`.

A entrega será pelo moodle. Desta vez como é um único arquivo faz
menos sentido um repositório no git. Porém, caso deseje utilizar, pode
fazer a entrega pelo git.
