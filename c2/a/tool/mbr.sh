nasm -o mbr.bin mbr.s && dd if=./mbr.bin of=/home/work/my_workspace/bochs/hd60M.img bs=512 count=1  conv=notrunc
