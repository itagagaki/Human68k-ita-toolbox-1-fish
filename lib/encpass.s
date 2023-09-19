* encpass.s
* Itagaki Fumihiko 25-Aug-91  Create.

.xref cryptchars

.text

****************************************************************
* encpass - encrypt password
*
* CALL
*      A0     encript buffer (13B)
*      A1     password (8B)
*      D1.B   key 1
*      D2.B   key 2
*
* RETURN
*      none.
****************************************************************
.xdef encpass

encpass:
		movem.l	d0/d3-d7/a0/a2,-(a7)
		lea	cryptchars,a2
		move.b	d1,(a0)+
		move.b	d2,(a0)+
		eor.b	d2,d1
		moveq	#65,d4
		moveq	#10,d7
loop1:
		moveq	#0,d3
		moveq	#5,d6
loop2:
		lsl.b	#1,d3
		move.w	d4,d0
		lsr.w	#3,d0
		move.b	(a1,d0.w),d0
		eor.b	d2,d0
		move.w	d4,d5
		and.w	#7,d5
		sub.w	#7,d5
		neg.w	d5
		btst	d5,d0
		bne	notset

		bset	#0,d3
notset:
		sub.w	#11,d4
		bcc	bitp_ok

		add.w	#65,d4
bitp_ok:
		dbra	d6,loop2

		eor.b	d1,d3
		move.b	(a2,d3.w),(a0)+
		dbra	d7,loop1

		movem.l	(a7)+,d0/d3-d7/a0/a2
		rts

.end
