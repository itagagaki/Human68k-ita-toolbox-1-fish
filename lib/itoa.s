* itoa.s
* Itagaki Fumihiko 02-Nov-90  Create.

.text

****************************************************************
* itoa - convert signed long word to ascii decimal
*
* CALL
*      A0     buffer (12B maximum)
*      D0.L   signed 32bit value
*      D1.L   bit 1 : 1=値が正数の場合符号 '+' を付ける
*             bit 2 : 1=値が正数の場合 ' ' を付ける
*             （bit 1 が優先）
*
* RETURN
*      none
*****************************************************************
.xdef itoa

itoa:
		movem.l	d0/d2/a0,-(a7)
		moveq	#'-',d2
		tst.l	d0
		bmi	itoa_minus

		moveq	#'+',d2
		btst	#1,d1
		bne	itoa_prefix

		btst	#2,d1
		beq	itoa_utoa

		moveq	#' ',d2
		bra	itoa_prefix

itoa_minus:
		neg.l	d0
itoa_prefix:
		move.b	d2,(a0)+
itoa_utoa:
		bsr	utoa
		movem.l	(a7)+,d0/d2/a0
		rts
****************************************************************
* utoa - convert unsigned long word to ascii decimal
*
* CALL
*      A0     buffer (11B maximum)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none
*****************************************************************
.xdef utoa

utoa:
		movem.l	d0-d3/a0-a1,-(a7)
		lea	radix_table,a1
		sf	d3
loop1:
		move.l	(a1)+,d1
		beq	last_digit

		moveq	#0,d2
loop2:
		addq.b	#1,d2
		sub.l	d1,d0
		bcc	loop2

		subq.b	#1,d2
		add.l	d1,d0
		tst.b	d3
		bne	set_digit

		tst.b	d2
		beq	loop1

		st	d3
set_digit:
		add.b	#'0',d2
		move.b	d2,(a0)+
		bra	loop1

last_digit:
		add.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d3/a0-a1
		rts

.data

.even
radix_table:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	0

.end
