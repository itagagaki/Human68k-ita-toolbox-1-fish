* itoa.s
* Itagaki Fumihiko 02-Nov-90  Create.

.xref utoa

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
		jsr	utoa
		movem.l	(a7)+,d0/d2/a0
		rts

.end
