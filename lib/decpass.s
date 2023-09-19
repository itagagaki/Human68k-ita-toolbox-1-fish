* decpass.s
* Itagaki Fumihiko 25-Aug-91  Create.

.xref cryptchars

.text

****************************************************************
* decpass - decrypt password
*
* CALL
*      A0     encript buffer (13B)
*      A1     password (8B)
*
* RETURN
*      none.
****************************************************************
.xdef decpass

decpass:
		movem.l	d0-d7/a0/a2,-(a7)
		movea.l	a0,a2
		movea.l	a1,a0
		moveq	#9,d0
clear_loop:
		clr.b	(a0)+
		dbra	d0,clear_loop

		bsr	get1
		move.b	d0,d1
		bsr	get1
		move.b	d2,d2
		eor.b	d2,d1
		moveq	#65,d4
		moveq	#10,d7
loop1:
		bsr	get1
		move.b	d0,d3
		eor.b	d1,d3
		moveq	#5,d6
loop2:
		btst	#5,d3
		sne	d0
		eor.b	d2,d0
		move.w	d4,d5
		and.w	#7,d5
		sub.w	#7,d5
		neg.w	d5
		btst	d5,d0
		bne	notset

		move.w	d4,d0
		lsr.w	#3,d0
		or.b	d5,(a1,d0.w)
notset:
		lsl.w	#1,d3
		sub.w	#11,d4
		bcc	bitp_ok

		add.w	#65,d4
bitp_ok:
		dbra	d6,loop2
		dbra	d7,loop1

		movem.l	(a7)+,d0-d7/a0/a2
		rts


get1:
		move.b	(a2)+,d0
		lea	cryptchars,a0
		move.l	d1,-(a7)
		moveq	#63,d1
findch:
		cmp.b	(a0)+,d0
		dbeq	d1,findch

		sub.w	#62,d1
		neg.w	d1
		move.b	d1,d0
		move.l	(a7)+,d1
		rts

.end
