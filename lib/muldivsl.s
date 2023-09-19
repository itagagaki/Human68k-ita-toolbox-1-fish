* muldivsl.s
* Itagaki Fumihiko 03-Nov-90  Create.

.xref mulul
.xref divul

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
		jsr	mulul
		tst.b	d2
		beq	mulsl_done

		neg.l	d0
		negx.l	d1
mulsl_done:
		move.l	(a7)+,d2
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
*      b が 0 でないことのチェックはしない
****************************************************************
.xdef divsl

divsl:
		movem.l	d2-d3,-(a7)
		move.l	d0,d3
		bsr	muldivs
		jsr	divul
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

.end
