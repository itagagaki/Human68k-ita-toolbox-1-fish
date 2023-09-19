* f_setenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.include ../src/var.h

.xref strlen
.xref strmove
.xref link_list
.xref xmalloc
.xref free
.xref fish_getenv
.xref insufficient_memory

.xref envtop
.xref envbot

.text

*****************************************************************
* setenv - FISH の環境変数をセットする
*
* CALL
*      A0     変数名の先頭アドレス
*      A1     値の文字列の先頭アドレス
*
* RETURN
*      D0.L   セットした変数の先頭アドレス．
*             ただしメモリが足りないためセットできなかったならば 0．
*      CCR    TST.L D0
*****************************************************************
.xdef fish_setenv

fish_setenv:
		movem.l	d1/a0-a4,-(a7)
		movea.l	envbot(a5),a2
		suba.l	a3,a3
		bsr	fish_getenv
		beq	insert

		movea.l	d0,a3
		movea.l	var_prev(a3),a2
		movea.l	var_next(a3),a3
		bsr	free
insert:
		bsr	strlen
		move.l	d0,d1
		exg	a0,a1
		bsr	strlen
		add.l	d1,d0
		addq.l	#2,d0
		add.l	#VAR_HEADER_SIZE,d0
		bsr	xmalloc
		beq	fish_setenv_no_space

		movea.l	d0,a4
		move.l	a2,var_prev(a4)
		move.l	a3,var_next(a4)
		movem.l	a0-a1,-(a7)
		lea	envtop(a5),a0
		lea	envbot(a5),a1
		bsr	link_list
		movem.l	(a7)+,a0-a1
		move.w	#1,var_nwords(a4)
		move.l	a0,-(a7)
		lea	var_body(a4),a0
		bsr	strmove
		movea.l	(a7)+,a1
		bsr	strmove
		move.l	a4,d0
return:
		movem.l	(a7)+,d1/a0-a4
		rts

fish_setenv_no_space:
		bsr	insufficient_memory
		moveq	#0,d0
		bra	return

.end
