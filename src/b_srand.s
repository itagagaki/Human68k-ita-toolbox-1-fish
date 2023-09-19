* b_srand.s
* Itagaki Fumihiko 19-Oct-91  Create.

.include iocscall.h
.include irandom.h
.include ../src/fish.h

.xref atou
.xref init_irandom
.xref too_many_args
.xref badly_formed_number
.xref too_large_number

.xref irandom_struct


.text

.xdef cmd_srand

cmd_srand:
		cmp.w	#1,d0
		blo	with_timer
		bhi	too_many_args

		jsr	atou
		bmi	badly_formed_number

		tst.b	(a0)
		bne	badly_formed_number

		tst.l	d0
		bne	too_large_number

		cmp.l	#IRANDOM_MAX,d1
		bhi	too_large_number

		move.l	d1,d0
		bra	do_srand

with_timer:
		IOCS	_ONTIME
do_srand:
		moveq	#RND_POOLSIZE,d1
		lea	irandom_struct(a5),a0
		bsr	init_irandom
		moveq	#0,d0
		rts

.end
