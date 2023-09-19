* f_setenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.include ../src/var.h

.xref strlen
.xref xmalloc
.xref allocvar
.xref entervar
.xref fish_getenv
.xref insufficient_memory

.xref env_top

.text

*****************************************************************
* fish_setenv - FISH の環境変数をセットする
*
* CALL
*      A0     変数名の先頭アドレス
*      A1     値の文字列の先頭アドレス
*
* RETURN
*      D0.L   セットした変数の先頭アドレス．
*             ただしメモリが足りないためセットできなかったならば 0．
*      CCR    TST.L D0
*
* NOTE
*      セットする値の語並びのアドレスが変数の現在の値の
*      一部位であるときにも、正しく動作する。
*****************************************************************
.xdef fish_setenv

fish_setenv:
		movem.l	d1-d2/a0-a4,-(a7)
		moveq	#1,d1				*  D1.W : 単語数 = 1
		movea.l	a1,a2				*  A2 : 値
		movea.l	a0,a1				*  A1 : 変数名
		bsr	allocvar			*  A3 : 新変数のアドレス
		beq	fish_setenv_no_space

		movea.l	a1,a0
		bsr	fish_getenv
		lea	env_top(a5),a4
		bsr	entervar
return:
		movem.l	(a7)+,d1-d2/a0-a4
		rts


fish_setenv_no_space:
		bsr	insufficient_memory
		moveq	#0,d0
		bra	return

.end
