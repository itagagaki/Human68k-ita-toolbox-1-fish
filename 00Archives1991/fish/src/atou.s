* atou.s
* Itagaki Fumihiko 11-Jul-90  Create.

.text

****************************************************************
* atou - convert integer ascii decimal digits to unsigned long word
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first non-digit point
*      D0.L   0:success, 1:overflow, -1:no digits
*      D1.L   ílÅDD0.L==-1ÇÃÇ∆Ç´Ç…ÇÕ0ÅD
*      CCR    TST.L D0
*****************************************************************
.xdef atou

atou:
		movem.l	d2-d3,-(a7)
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		move.b	(a0)+,d0
		bsr	isdigit
		beq	loop

		moveq	#-1,d2
		bra	return

loop:
		sub.b	#'0',d0

		*  D1.L *= 10;
		move.l	d1,d3
		swap	d3
		mulu	#10,d3
		swap	d3
		tst.w	d3
		beq	check1ok

		moveq	#1,d2
check1ok:
		mulu	#10,d1
		add.l	d3,d1
		bcc	check2ok

		moveq	#1,d2
check2ok:
		add.l	d0,d1
		bcc	check3ok

		moveq	#1,d2
check3ok:
		move.b	(a0)+,d0
		bsr	isdigit
		beq	loop
return:
		subq.l	#1,a0
		move.l	d2,d0
		movem.l	(a7)+,d2-d3
		rts

.end
