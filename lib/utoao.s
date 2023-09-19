* utoao.s
* Itagaki Fumihiko 16-Sep-91  Create.

.text

****************************************************************
* utoao - convert unsigned long word to ascii octal
*
* CALL
*      A0     buffer (12B maximum)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none
*****************************************************************
.xdef utoao

utoao:
		movem.l	d0-d4/a0,-(a7)
		sf	d2
		moveq	#30,d3				*  shift value
		moveq	#9,d4				*  loop counter
loop:
		move.l	d0,d1
		lsr.l	d3,d1
		and.b	#7,d1
		tst.b	d2
		bne	set_digit

		tst.b	d1
		beq	continue

		st	d2
set_digit:
		add.b	#'0',d1
		move.b	d1,(a0)+
continue:
		subq.w	#3,d3
		dbra	d4,loop

		and.b	#7,d0
		add.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d4/a0
		rts

.end
