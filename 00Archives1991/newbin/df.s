* df.s
*
* Itagaki Fumihiko 11-Nov-90  Create.
****************************************************************
*  Name
*       df - print disk free
*
*  Synopsis
*       df [ -a | <drive>: ]
****************************************************************

.include doscall.h
.include chrcode.h

DFBUF_FREE_CLUSTER	equ	0
DFBUF_TOTAL_CLUSTER	equ	2
DFBUF_SECTOR_CLUSTER	equ	4
DFBUF_BYTE_SECTOR	equ	6

.text

****************************************************************
start:
		DOS	_CURDRV
		move.w	d0,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		move.l	d0,d7				*  D7 : LASTDRIVE
****************
		lea	msg_header(pc),a0
		bsr	puts
		move.b	(a2)+,d2			*  A2はパラメータ。D2はその長さ
		moveq	#0,d6				*  D6 : 終了コード
		bsr	skip_space
		bne	next_arg

		DOS	_CURDRV
		bsr	df_one
all_done:
		move.w	d6,-(a7)
		DOS	_EXIT2
****************************************************************
next_arg:
		bsr	skip_space
		beq	all_done

		cmp.b	#2,d2
		blo	bad_arg
		beq	try_one_drive

		move.b	2(a2),d0
		bsr	isspace
		beq	try_one_drive

		cmp.b	#3,d2
		beq	try_all_drive

		move.b	3(a2),d0
		bsr	isspace
		beq	try_all_drive
****************
bad_arg:
		lea	msg_bad_arg(pc),a0
****************
arg_error:
		subq.b	#1,d2
		move.b	(a2)+,d0
		beq	arg_error_1

		bsr	isspace
		beq	arg_error_1

		bsr	putc
		tst.b	d2
		bne	arg_error
arg_error_1:
		bsr	puts
		moveq	#1,d6
		bra	next_arg
****************
bad_drive_name:
		lea	msg_bad_drive_name(pc),a0
		bra	arg_error
********************************
try_all_drive:
		cmpi.b	#'a',(a2)
		bne	bad_arg

		cmpi.b	#'l',1(a2)
		bne	bad_arg

		cmpi.b	#'l',2(a2)
		bne	bad_arg

		moveq	#0,d1
do_all_drive_loop:
		move.w	d1,d0
		addq.w	#1,d0
		move.w	d0,-(a7)
		DOS	_DRVCTRL
		addq.l	#2,a7
		and.b	#%00000111,d0
		cmp.b	#%00000010,d0
		bne	do_all_drive_next

		move.w	d1,d0
		move.w	d1,-(a7)
		bsr	df_one
		move.w	(a7)+,d1
do_all_drive_next:
		addq.w	#1,d1
		cmp.w	d7,d1
		blo	do_all_drive_loop

		addq.l	#3,a2
		subq.b	#3,d2
		bra	next_arg
********************************
try_one_drive:
		cmpi.b	#':',1(a2)
		bne	bad_arg

		moveq	#0,d0
		move.b	(a2),d0
		cmp.b	#'a',d0
		bcs	try_one_drive_1

		sub.b	#'a',d0
		bra	try_one_drive_2
try_one_drive_1:
		sub.b	#'A',d0
try_one_drive_2:
		blo	bad_drive_name			* Bad drive name

		cmp.b	#26,d0
		bhi	bad_drive_name

		bsr	df_one

		addq.l	#2,a2
		subq.b	#2,d2
		bra	next_arg
****************************************************************
*   Drive Volume-name              kbytes    used   avail capacity Mounted-on
*   A:    123456789012345678123   1234567 1234567 1234567   100%   A:/
df_one:
	* Drive
		move.w	d0,d3
		add.b	#'A',d0
		move.w	d0,-(a7)
		bsr	putc
		move.b	#':',d0
		bsr	putc
		bsr	put_space
		bsr	put_space
		bsr	put_space
		bsr	put_space
	* Volume-name
		lea	tmpbuf(pc),a0
		move.w	(a7),d0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		move.b	#'/',(a0)+
		move.b	#'*',(a0)+
		move.b	#'.',(a0)+
		move.b	#'*',(a0)+
		clr.b	(a0)
		move.w	#$08,-(a7)
		pea	tmpbuf(pc)
		pea	filebuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		lea	filebuf+30(pc),a0
		tst.l	d0
		bpl	volume_name_ok

		clr.b	(a0)
volume_name_ok:
		move.w	#22,d1
		moveq	#0,d0
vol_prlp:
		tst.w	d1
		beq	vol_p2

		move.b	(a0)+,d0
		beq	vol_pr1

		cmp.b	#'.',d0
		beq	vol_prx

		bsr	putc
vol_prx:
		dbra	d1,vol_prlp

vol_pr0:
		bsr	put_space
vol_pr1:
		dbra	d1,vol_pr0
vol_p2:
		bsr	put_space
		bsr	put_space
	* kbytes
		pea	dfbuf(pc)
		addq.b	#1,d3
		move.w	d3,-(a7)
		DOS	_DSKFRE
		addq.l	#6,a7
		lsr.l	#7,d0
		move.l	d0,d3				* D3.L : free (x128 bytes)
		lea	dfbuf(pc),a0
		move.w	DFBUF_SECTOR_CLUSTER(a0),d0
		move.w	DFBUF_BYTE_SECTOR(a0),d1
		mulu	d1,d0
		move.w	DFBUF_TOTAL_CLUSTER(a0),d1
		bsr	mulul
		lsr.l	#7,d0
		move.l	d0,d4				* D4.L : total (x128 bytes)
		bsr	print_kb
		bsr	put_space
	* used
		move.l	d4,d0
		sub.l	d3,d0
		move.l	d0,d5				* D5.L : used (x128 bytes)
		bsr	print_kb
		bsr	put_space
	* avail
		move.l	d3,d0
		bsr	print_kb
		bsr	put_space
		bsr	put_space
		bsr	put_space
	* capacity
		move.l	d5,d0
		move.l	#100,d1
		bsr	mulul
		move.l	d4,d1
		bsr	divul
		bsr	print_3d
		move.b	#'%',d0
		bsr	putc
		bsr	put_space
		bsr	put_space
		bsr	put_space
	* Mounted-on
		move.w	(a7)+,d0
		bsr	putc
		move.b	#':',d0
		bsr	putc
		move.b	#'/',d0
		bsr	putc

		lea	msg_newline(pc),a0
		bra	puts
*****************************************************************
print_kb:
		lsr.l	#3,d0
		lea	itoa_tbl_7(pc),a0
		bra	printd

print_3d:
		lea	itoa_tbl_3(pc),a0
printd:
		movem.l	d1-d3/a1,-(a7)
		lea	itoa_buf(pc),a1
		moveq	#0,d3
itoa_lp10:
		move.l	(a0)+,d1
		beq	itoa_set_digit_last

		move.b	#'0',d2
itoa_lp20:
		addq.b	#1,d2
		sub.l	d1,d0
		bhs	itoa_lp20

		add.l	d1,d0
		subq.b	#1,d2
		tst.b	d3
		bne	itoa_set_digit

		cmp.b	#'0',d2
		beq	itoa_set_blank

		moveq	#1,d3
		bra	itoa_set_digit

itoa_set_blank:
		move.b	#' ',d2
itoa_set_digit:
		move.b	d2,(a1)+
		bra	itoa_lp10

itoa_set_digit_last:
		add.b	#'0',d0
		move.b	d0,(a1)+
		clr.b	(a1)
		lea	itoa_buf(pc),a0
		bsr	puts
		movem.l	(a7)+,d1-d3/a1
		rts
****************************************************************
puts:
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		rts
****************************************************************
putc:
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
****************************************************************
put_space:
		move.w	d0,-(a7)
		move.b	#' ',d0
		bsr	putc
		move.w	(a7)+,d0
		rts
****************************************************************
isspace:
		cmp.b	#' ',d0
		beq	isspace_return

		cmp.b	#HT,d0
		beq	isspace_return

		cmp.b	#CR,d0
		beq	isspace_return

		cmp.b	#LF,d0
		beq	isspace_return

		cmp.b	#VT,d0
isspace_return:
		rts
****************************************************************
skip_space:
		tst.b	d2
		beq	skip_space_return

		move.b	(a2),d0
		bsr	isspace
		bne	skip_space_return

		addq.l	#1,a2
		subq.w	#1,d2
		bne	skip_space
skip_space_return:
		rts
****************************************************************
* mulul
*
* CALL
*      D0.L   unsigned long word a
*      D1.L   unsigned long word b
*
* RETURN
*      D0.L   a*b の下位
*      D1.L   a*b の上位
****************************************************************
mulul:
		movem.l	d2-d4,-(a7)
		*  D0  | A | B |
		*  D1  | C | D |
		move.l	d0,d2
		move.l	d1,d3
		swap	d2
		swap	d3
		move.l	d0,d4
		*  D0  | A | B |
		*  D1  | C | D |
		*  D2  | B | A |
		*  D3  | D | C |
		*  D4  | A | B |
		mulu	d1,d4		*  D4  |  BD   |
		mulu	d2,d1		*  D1  |  AD   |
		mulu	d3,d2		*  D2  |  AC   |
		mulu	d0,d3		*  D3  |  BC   |
		add.l	d1,d3		*  D3  |AD + BC|
		clr.l	d0
		clr.l	d1
		move.w	d3,d0
		swap	d0		*  D0  |(AD+BC)L|0|
		swap	d3
		move.w	d3,d1		*  D1  |0|(AD+BC)H|
		add.l	d4,d0		*  D0: lower word of result
		addx.l	d2,d1		*  D1: upper word of result
		movem.l	(a7)+,d2-d4
		rts
****************************************************************
* divul
*
* CALL
*      D0.L   unsigned long word a
*      D1.L   unsigned long word b
*
* RETURN
*      D0.L   a/b
*      D1.L   a%b
*
* NOTE
*      b が０でないことをチェックしない
****************************************************************
.xdef divul

divul:
		movem.l	d2-d3,-(a7)
		move.l	d1,d2
		moveq	#0,d1
		moveq	#31,d3
divul_loop:
		lsl.l	#1,d0
		roxl.l	#1,d1
		cmp.l	d2,d1
		bcs	divul_next

		bset.l	#0,d0
		sub.l	d2,d1
divul_next:
		dbra	d3,divul_loop

		movem.l	(a7)+,d2-d3
		rts
****************************************************************
.data

.even
itoa_tbl_7:
		dc.l	1000000
		dc.l	100000
		dc.l	10000
		dc.l	1000
itoa_tbl_3:
		dc.l	100
		dc.l	10
		dc.l	0

msg_header:		dc.b	'Drive Volume-name              kbytes    used   avail capacity Mounted-on'
msg_newline:		dc.b	CR,LF,0
msg_bad_arg:		dc.b	'  ** 引数が無効です',CR,LF,0
msg_bad_drive_name:	dc.b	'  ** ドライブ名が無効です',CR,LF,0
*****************************************************************
.bss

.even
dfbuf:		ds.w	4
filebuf:	ds.b	53
itoa_buf:	ds.b	11
tmpbuf:		ds.b	7

.end start
