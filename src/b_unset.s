* b_unset.s
* This contains built-in command 'unalias', 'unset'.
*
* Itagaki Fumihiko 15-Jul-90  Create.

.include ../src/var.h

.xref strcmp
.xref strpcmp
.xref strfor1
.xref free
.xref escape_quoted
.xref flagvarptr
.xref too_few_args

.xref default_wordchars

.xref tmpword1

.xref word_histchars
.xref word_wordchars

.xref alias_top
.xref shellvar_top
.xref histchar1
.xref histchar2
.xref wordchars

.text

****************************************************************
* unsetvar - 変数を削除する
*
* CALL
*      A0     変数リストの根ポインタのアドレス
*      A1     削除する変数名パターンを指す
*      D0.B   0 : シェル変数である
*
* RETURN
*      none
****************************************************************
unsetvar:
		movem.l	d0-d1/a0/a2-a3,-(a7)
		move.b	d0,d1
		movea.l	a0,a3
unsetvar_loop:
		tst.l	(a3)
		beq	unsetvar_return

		movea.l	(a3),a2
		lea	var_body(a2),a0
		moveq	#0,d0
		bsr	strpcmp
		bne	notmatch
****************
		move.l	a1,-(a7)
		tst.b	d1
		bne	delete_entry

		bsr	flagvarptr
		beq	not_flagvar

		movea.l	d0,a0
		sf	(a0)
		bra	delete_entry

not_flagvar:
		lea	word_histchars,a1
		bsr	strcmp
		bne	not_histchars

		move.w	#'!',histchar1(a5)
		move.w	#'^',histchar2(a5)
		bra	delete_entry

not_histchars:
		lea	word_wordchars,a1
		bsr	strcmp
		bne	not_wordchars

		lea	default_wordchars,a1
		move.l	a1,wordchars(a5)
not_wordchars:
delete_entry:
		movea.l	(a7)+,a1
		move.l	var_next(a2),(a3)
		move.l	a2,d0
		bsr	free
		bra	unsetvar_loop
****************
notmatch:
		lea	var_next(a2),a3
		bra	unsetvar_loop
****************
unsetvar_return:
		movem.l	(a7)+,d0-d1/a0/a2-a3
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
		lea	alias_top(a5),a2
		moveq	#1,d1
		bra	start

cmd_unset:
		lea	shellvar_top(a5),a2
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
		bsr	unsetvar
		exg	a0,a2
		bsr	strfor1
		dbra	d2,loop

		moveq	#0,d0
		rts

.end
