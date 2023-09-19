* atoi.s
* Itagaki Fumihiko 11-Jul-90  Create.

.xref atou

.text

****************************************************************
* atoi - convert integer ascii decimal digits to signed long word
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
.xdef atoi

atoi:
		move.l	a0,-(a7)
		move.b	(a0)+,d0
		cmpi.b	#'+',d0
		beq	atoi_plus

		cmpi.b	#'-',d0
		beq	atoi_minus

		subq.l	#1,a0
atoi_plus:
		jsr	atou
atoi_return:
		movea.l	(a7)+,a0
		tst.l	d0
		rts
****************
atoi_minus:
		jsr	atou
		neg.l	d1
		bra	atoi_return
****************

.end
