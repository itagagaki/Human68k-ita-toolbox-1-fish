* mf.s
*
* Itagaki Fumihiko 22-Oct-90  Create.
****************************************************************
*  Name
*       mf - print memory free
*
*  Synopsis
*       mf
****************************************************************

.include doscall.h
.include chrcode.h

.text

start:
		move.l	8(a0),d1			*  このメモリブロックの終わり＋１
		sub.l	a0,d1
		sub.l	#16,d1				*  D1 : 最大の空きメモリの大きさ
		move.l	d1,d2				*  D2 : 空きメモリの総量
get_size_loop:
		move.l	#$00ffffff,-(a7)		*  こん限り
		DOS	_MALLOC				*  確保してみる
		addq.l	#4,a7
		sub.l	#$81000000,d0
		cmp.l	#$01000000,d0
		bcc	nomore				*  もうこれ以上確保できない

		move.l	d0,d3				*  D3 : 確保可能な大きさ
		move.l	d0,-(a7)			*  それを
		DOS	_MALLOC				*  確保してみる
		addq.l	#4,a7
		tst.l	d0
		bmi	get_size_loop			*  失敗したなら再挑戦

		add.l	d3,d2				*  今確保した大きさを D2 に加える
		cmp.l	d3,d1				*  今確保したブロックが
		bhs	get_size_loop			*  D1 よりも大きければ

		move.l	d3,d1				*  D1 を更新
		bra	get_size_loop

nomore:
		lea	msg_max(pc),a0
		bsr	printd
		move.l	d2,d1
		lea	msg_total(pc),a0
		bsr	printd
		clr.w	-(a7)
		DOS	_EXIT2
*****************************************************************
printd:
		bsr	puts
		lea	itoawork(pc),a0
		lea	itoa_tbl(pc),a1
		moveq	#0,d5
		moveq	#8,d4
itoa_lp10:
		move.l	(a1)+,d3
		move.b	#'0',d0
itoa_lp20:
		addq.b	#1,d0
		sub.l	d3,d1
		bhs	itoa_lp20

		add.l	d3,d1
		subq.b	#1,d0
		tst.b	d5
		bne	itoa_set_digit

		cmp.b	#'0',d0
		beq	itoa_set_blank

		moveq	#1,d5
		bra	itoa_set_digit

itoa_set_blank:
		move.b	#' ',d0
itoa_set_digit:
		move.b	d0,(a0)+
		dbra	d4,itoa_lp10

		add.b	#'0',d1
		move.b	d1,(a0)+
		clr.b	(a0)
		lea	itoawork(pc),a0
		bsr	puts
		lea	msg_newline(pc),a0
puts:
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		rts
*****************************************************************
.data

itoa_tbl:
		dc.l	1000000000
		dc.l	100000000
		dc.l	10000000
		dc.l	1000000
		dc.l	100000
		dc.l	10000
		dc.l	1000
		dc.l	100
		dc.l	10

msg_max:	dc.b	'最大',HT,0
msg_total:	dc.b	'総計',HT,0
msg_newline:	dc.b	CR,LF,0
*****************************************************************
.bss

itoawork:	ds.b	11

.end start
