%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

jmp loader_start

;构建gdt以及内部描述符
GDT_BASE:
  dd  0x00000000  ;第0个为空
  dd  0x00000000

CODE_DESC:
  dd  0x0000ffff
  dd  DESC_CODE_HIGH4

DATA_STACK_DESC:
  dd  0x0000ffff
  dd  DESC_DATA_HIGH4

VIDEO_DESC:
  dd  0x80000007; limit=(0xbffff-0xb8000)/4k=0x7 
  dd  DESC_VIDEO_HIGH4; 此时dpl为0

GDT_SIZE  equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1
times 60 dq 0   ;此处预留60个描述符的位置

SELECTOR_CODE   equ (0x0001 << 3) + TI_GDT + RPL0
;相当于（CODE_DESC - GDT_BASE）/8 + TI_GDT + RPL0

SELECTOR_DATA   equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO  equ (0x0003 << 3) + TI_GDT + RPL0

;以下是gdt的指针，前两字节是gdt的界限，后四字节是gdt的起始地址

gdt_ptr   dw GDT_LIMIT
          dd GDT_BASE

loadermsg db '2 loader in real'

loader_start:

;-----------------------------------
;INT 0x10 功能好x013  功能描述：打印字符
;----------------------------------
;输入：
;AH 子功能号=13H
;BH = 页码
;BL = 属性（若AL=00H 或01H）
;CX=字符串长度
;（DH,DL）=坐标（行，列）
;ES：BP = 字符串地址
;AL = 显示输出方式
; 0--字符串中只含显示字符，其显示属性在BL中;显示后光标位置不变
; 1--字符串中只含显示字符，其显示属性在BL中;显示后光标位置改变
; 0--字符串中包含字符和显示属性;显示后光标位置不变
; 0--字符串中包含字符和显示属性;显示后光标位置改变
;
mov sp, LOADER_BASE_ADDR
mov bp, loadermsg     ;ES：BP=字符串长度
mov cx, 17            ;CX=字符串长度
mov ax, 0x1301         ;AH = 13 ，AL=01h
mov bx, 0x001f         ;页号为0（BH = 0）蓝底粉底字（BL =1fh）
mov dx, 0x1800
int 0x10               ;10h中断

;------------准备进入保护模式----------
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1
;

;-----------打开A20----------
in al,0x92
or al,0000_0010b
out 0x92,al

;---------------加载GDT---------
lgdt [gdt_ptr]

;-----------cr0第0位1------------
mov eax,  cr0
or  eax,  0x00000001
mov cr0,eax

jmp dword SELECTOR_CODE:p_mode_start  ;刷新流水线

[bits 32]
p_mode_start:
  mov ax,   SELECTOR_DATA
  mov ds,   ax
  mov es,   ax
  mov ss,   ax
  mov esp,  LOADER_STACK_TOP
  mov ax,   SELECTOR_VIDEO
  mov gs,   ax

  mov byte  [gs:160],'P'

  jmp $

