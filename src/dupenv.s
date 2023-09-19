* dupenv.s
* Itagaki Fumihiko 8-Aug-91  Create.

.xref strazcpy
.xref xmalloc

****************************************************************
* dupenv - duplicate environment
*
* CALL
*      A0     source environment address
*
* RETURN
*      D0.L   duplicated environment address  (0L if couldn't allocate memory)
*      CCR    TST.L D0
*****************************************************************
.xdef dupenv

dupenv:
		move.l	(a0),d0
		bsr	xmalloc
		beq	dupenv_return

		movem.l	a0-a1,-(a7)
		movea.l	a0,a1
		movea.l	d0,a0
		move.l	(a1)+,(a0)+
		bsr	strazcpy
		movem.l	(a7)+,a0-a1
dupenv_return:
		tst.l	d0
		rts
