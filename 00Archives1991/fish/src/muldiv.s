* muldiv.s
* Itagaki Fumihiko 03-Nov-90  Create.

.text

****************************************************************
muldivs:
		moveq	#0,d2
		tst.l	d0
		bpl	muldivs_1

		neg.l	d0
		not.b	d2
muldivs_1:
		tst.l	d1
		bpl	muldivs_2

		neg.l	d1
		not.b	d2
muldivs_2:
		rts
****************************************************************
* mulsl
*
* CALL
*      D0.L   signed long word a
*      D1.L   signed long word b
*
* RETURN
*      D0.L   a*b の下位
*      D1.L   a*b の上位
****************************************************************
.xdef mulsl

mulsl:
		move.l	d2,-(a7)
		bsr	muldivs
		bsr	mulul
		tst.b	d2
		beq	mulsl_done

		neg.l	d0
		negx.l	d1
mulsl_done:
		move.l	(a7)+,d2
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
.xdef mulul

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
* divsl
*
* CALL
*      D0.L   signed long word a
*      D1.L   signed long word b
*
* RETURN
*      D0.L   a/b
*      D1.L   a%b
*
* NOTE
*      b が０でないことをチェックしない
****************************************************************
.xdef divsl

divsl:
		movem.l	d2-d3,-(a7)
		move.l	d0,d3
		bsr	muldivs
		bsr	divul
		tst.b	d2
		beq	divsl_1

		neg.l	d0
divsl_1:
		tst.l	d3
		bpl	divsl_2

		neg.l	d1
divsl_2:
		movem.l	(a7)+,d2-d3
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

.end
