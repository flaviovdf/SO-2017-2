#!/bin/bash

set -e
set -u

# Setup colors output
green=`tput setaf 2`
red=`tput setaf 1`
blue=`tput setaf 4`
reset=`tput sgr0`

# [IMPORTANTE] Sete o local onde você vai montar as imagens.
basepath=/mnt/tp3

_10MB=10240
_100MB=102400

for size in $_10MB $_100MB; do
  fname=fs-0x00dcc605-ext2-$size.img
  echo "${blue} ====== Creating ext2 on $fname ${reset}"
  dd if=/dev/zero of=$fname bs=1024 count=$size
  mkfs.ext2 $fname

  # Prepare mount point
  mkdir -p $basepath/$size
  mount $fname $basepath/$size
  chmod a+w $basepath $basepath/$size

  # Create 10 files
  for i in {1..10}; do echo "this is file$i" > $basepath/$size/file$i.txt ; done
  echo "${green} ====== 10 txt files created on $basepath/$size ${reset}"

  # Find device was used to mount img
  mounted_device=`findmnt -n -o SOURCE --target $basepath/$size`

  # Find superblock backup
  sbbackup=`dumpe2fs $mounted_device | awk '/superblock at / {print $4}' | grep -oE '^\s*[0-9]+' | awk 'NR==2'`

  echo "${green} ====== Device is mounted on: $mounted_device ${reset}"
  echo "${green} ====== First SuperBlock Backup address: $sbbackup ${reset}"

  # Fun1: Attack super block
  echo "${red} ====== Fun1: Attacking super block ...${reset}"
  dd if=/dev/zero of=$mounted_device count=1 bs=1024 seek=1
  echo "${green} ====== Fun1 Checking: trying to unmount and mount again, no FS or similar error expected ${reset}"
  umount $mounted_device
  mount $fname $basepath/$size || true

  # Mount back again using superblock backup to perform other fun actions, from now on,
  # superblock backup should be used to mount, as primary block is corrupted
  mount -o sb=$sbbackup $fname $basepath/$size

  # Fun2: Multiply owned blocked
  # sudo debugfs -s $sbbackup -b 1024 $mounted_device -w
  echo "${red} ====== Fun2: Multiply owned blocks ${reset}"
  # Create a temp file with debugfs command
  echo "stat file1.txt" > /tmp/fun2_cmd.tmp
  debugfs -s $sbbackup -b 1024 -w -f /tmp/fun2_cmd.tmp $mounted_device > /tmp/fun2_result.tmp
  block1_of_first_file=`cat /tmp/fun2_result.tmp | sed -n '12p' | cut -d : -f2`
  echo "${green} ====== Fun2: Block[0] value of file1.txt is: $block1_of_first_file, will set it as block vale of file2.txt as well"
  echo "set_inode_field file2.txt block[0] $block1_of_first_file" > /tmp/fun2_cmd2.tmp
  debugfs -s $sbbackup -b 1024 -w -f /tmp/fun2_cmd2.tmp $mounted_device

  echo "${green} ====== Fun2: Trying to unmount and mount back to check if command worked"
  umount $mounted_device
  mount -o sb=$sbbackup $fname $basepath/$size
  echo "${green} ====== Fun2: Both files should now point to the same file content${reset}"
  cat $basepath/$size/file1.txt $basepath/$size/file2.txt
  rm /tmp/fun2_cmd.tmp /tmp/fun2_result.tmp /tmp/fun2_cmd2.tmp

  # Fun3: Corrupt permission/type
  echo "${red} ====== Fun3: Corrupt permission/type ${reset}"
  echo "${green} ====== Fun3: Setting inode field 'mode' to 0 on file3.txt"
  #Create temp file with debugfs command
  echo "set_inode_field file3.txt mode 0" > /tmp/fun3_cmd.tmp
  debugfs -s $sbbackup -b 1024 -w -f /tmp/fun3_cmd.tmp $mounted_device
  rm /tmp/fun3_cmd.tmp
  ls $basepath/$size/file3.txt || true

  # Fun4: Sad, Orphaned inodes
  echo "${red} ====== Fun4: Sad, Orphaned inodes ${reset}"
  echo "${green} ====== Fun4 Preparing: Creating a new dir 'dir1' and two files 'a' and 'b' ${reset}"
  mkdir -p $basepath/$size/dir1
  echo "this is file-a" > $basepath/$size/dir1/a
  echo "this is file-b" > $basepath/$size/dir1/b
  
  # Create temp file with debugfs command  
  echo "clri dir1" > /tmp/fun4_cmd.tmp
  echo "${green} ====== Fun4: Executing debugfs clri dir1 ...  ${reset}"
  debugfs -s $sbbackup -b 1024 -w -f /tmp/fun4_cmd.tmp $mounted_device
  rm /tmp/fun4_cmd.tmp
  echo "${green} ====== Fun4 Checking: trying to unmount, mount back again and ls dir1, expect 'structure needs cleaning 'error ${reset}" 
  umount $mounted_device
  mount -o sb=$sbbackup $fname $basepath/$size
  ls $basepath/$size/dir1 || true

  echo -e "${blue}=== Script complete - $fname ================================= ${reset}\n\n\n"

done
