* b_unset.s
* This contains built-in command 'unalias', 'unset'.
*
* Itagaki Fumihiko 15-Jul-90  Create.

.xref for1str
.xref memmovi
.xref strcmp
.xref strpcmp
.xref escape_quoted
.xref flagvarptr
.xref too_few_args
.xref word_histchars
.xref tmpword1

.xref alias
.xref shellvar
.xref histchar1
.xref histchar2

.text

****************************************************************
* unset_var - 変数を削除する
*
* CALL
*      A0     変数領域の先頭アドレス
*      A1     削除する変数名パターンを指す
*      D0.B   0 : シェル変数である
*
* RETURN
*      none
****************************************************************
unset_var:
		movem.l	d0-d1/a0-a2,-(a7)
		move.b	d0,d1
		movea.l	a0,a2			* A2 : 変数領域の先頭アドレス
		addq.l	#8,a0
unset_var_loop:
		tst.w	(a0)			* この変数が占めるバイト数
		beq	unset_var_return	* 0ならおしまい

		addq.l	#4,a0
		moveq	#0,d0
		bsr	strpcmp
		subq.l	#4,a0
		tst.l	d0
		bne	nomatch
****************
		movem.l	a0-a1,-(a7)
		addq.l	#4,a0
		tst.b	d1
		bne	delete_entry

		bsr	flagvarptr
		tst.l	d0
		beq	not_flagvar

		movea.l	d0,a1
		sf	(a1)
		bra	delete_entry

not_flagvar:
		lea	word_histchars,a1
		bsr	strcmp
		bne	delete_entry

		move.w	#'!',histchar1(a5)
		move.w	#'^',histchar2(a5)
delete_entry:
		subq.l	#4,a0
		movea.l	a0,a1
		adda.w	(a1),a1			* A1 : 次の変数のアドレス　（正しい）
		move.l	a2,d0
		add.l	4(a2),d0		* 最後の変数の次のアドレス
		sub.l	a1,d0
		bsr	memmovi
		clr.w	(a0)
		suba.l	a2,a0
		move.l	a0,4(a2)
		movem.l	(a7)+,a0-a1
		bra	unset_var_loop
****************
nomatch:
		adda.w	(a0),a0			* 次の変数のアドレスをセット　（正しい）
		bra	unset_var_loop		* 繰り返す
****************
unset_var_return:
		movem.l	(a7)+,d0-d1/a0-a2
		rts
****************************************************************
*  Name
*       unalias - 別名の定義を解除する
*       unset - シェル変数の定義を解除する
*
*  Synopsis
*       unalias pattern ...
*       unset pattern ...
****************************************************************
.xdef cmd_unalias
.xdef cmd_unset

cmd_unalias:
		movea.l	alias(a5),a2
		moveq	#1,d1
		bra	start

cmd_unset:
		movea.l	shellvar(a5),a2
		moveq	#0,d1
start:
		move.w	d0,d2
		subq.w	#1,d2
		blo	too_few_args
loop:
		lea	tmpword1,a1
		bsr	escape_quoted		* A1 : クオートをエスケープに代えた検索文字列
		exg	a0,a2
		move.b	d1,d0
		bsr	unset_var
		exg	a0,a2
		bsr	for1str
		dbra	d2,loop

		moveq	#0,d0
		rts

.end
