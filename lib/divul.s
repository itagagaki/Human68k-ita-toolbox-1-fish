* divul.s
* Itagaki Fumihiko 03-Nov-90  Create.

.text

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
*      b が 0 でないことのチェックはしない
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

.end
