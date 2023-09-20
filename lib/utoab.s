* utoab.s
* Itagaki Fumihiko 18-Jan-94  Create.

.text

****************************************************************
* utoab - convert unsigned long word to ascii binary
*
* CALL
*      A0     result buffer (33B maximum)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none
*****************************************************************
.xdef utoab

utoab:
		movem.l	d0-d4/a0,-(a7)
		sf	d2
		moveq	#31,d3				*  shift value
		moveq	#30,d4				*  loop counter
loop:
		move.l	d0,d1
		lsr.l	d3,d1
		and.b	#1,d1
		tst.b	d2
		bne	set_digit

		tst.b	d1
		beq	continue

		st	d2
set_digit:
		add.b	#'0',d1
		move.b	d1,(a0)+
continue:
		subq.w	#1,d3
		dbra	d4,loop

		and.b	#1,d0
		add.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d4/a0
		rts

.end
