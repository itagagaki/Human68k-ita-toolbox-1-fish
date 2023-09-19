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
.xref set_flagvar
.xref too_few_args

.xref default_wordchars

.xref tmpword1

.xref word_histchars
.xref word_wordchars

.xref alias_top
.xref completion_top
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
*      D1.B   0 : シェル変数である
*
* RETURN
*      D0.L   破壊
****************************************************************
unsetvar:
		movem.l	d1/a0/a2-a3,-(a7)
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

		sf	d0
		bsr	set_flagvar
		bne	delete_entry

		lea	word_histchars,a1
		jsr	strcmp
		bne	not_histchars

		move.w	#'!',histchar1(a5)
		move.w	#'^',histchar2(a5)
		bra	delete_entry

not_histchars:
		lea	word_wordchars,a1
		jsr	strcmp
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
		movem.l	(a7)+,d1/a0/a2-a3
		rts
****************************************************************
*  Name
*       unalias - 別名の定義を解除する
*       unset - シェル変数の定義を解除する
*
*  Synopsis
*       unalias pattern ...
*       uncomplete pattern ...
*       unset pattern ...
****************************************************************
.xdef cmd_unalias
.xdef cmd_uncomplete
.xdef cmd_unset

cmd_unalias:
		lea	alias_top(a5),a2
		bra	unvar_start

cmd_uncomplete:
		lea	completion_top(a5),a2
unvar_start:
		st	d1
		bra	start

cmd_unset:
		lea	shellvar_top(a5),a2
		sf	d1
start:
		move.w	d0,d2
		subq.w	#1,d2
		blo	too_few_args
loop:
		lea	tmpword1,a1
		bsr	escape_quoted		* A1 : クオートをエスケープに代えた検索文字列
		exg	a0,a2
		bsr	unsetvar
		exg	a0,a2
		bsr	strfor1
		dbra	d2,loop

		moveq	#0,d0
		rts

.end
