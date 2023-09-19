* utoax.s
* Itagaki Fumihiko 16-Sep-91  Create.

.text

****************************************************************
* utoaxl - convert unsigned long word to ascii hexa-decimal in lower case
*
* CALL
*      A0     buffer (9B maximum)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none
*****************************************************************
.xdef utoaxl

utoaxl:
		movem.l	d0-d4/a0-a1,-(a7)
		lea	lower_table,a1
		bra	utoax
****************************************************************
* utoaxu - convert unsigned long word to ascii hexa-decimal in upper case
*
* CALL
*      A0     buffer (9B maximum)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none
*****************************************************************
.xdef utoaxu

utoaxu:
		movem.l	d0-d4/a0-a1,-(a7)
		lea	upper_table,a1
utoax:
		sf	d2
		moveq	#28,d3				*  shift value
		moveq	#6,d4				*  loop counter
loop:
		move.l	d0,d1
		lsr.l	d3,d1
		and.l	#$f,d1
		tst.b	d2
		bne	set_digit

		tst.b	d1
		beq	continue

		st	d2
set_digit:
		move.b	(a1,d1.l),(a0)+
continue:
		subq.w	#4,d3
		dbra	d4,loop

		and.l	#$f,d0
		move.b	(a1,d0.l),(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d4/a0-a1
		rts

.data

lower_table:	dc.b	'0123456789abcdef'
upper_table:	dc.b	'0123456789ABCDEF'

.end
