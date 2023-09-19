* b_setenv.s
* This contains built-in command 'setenv'.
*
* Itagaki Fumihiko 16-Jul-90  Create.

.include ../src/var.h

.xref strchr
.xref strfor1
.xref putc
.xref cputs
.xref put_newline
.xref strip_quotes
.xref expand_wordlist
.xref fish_setenv
.xref too_many_args
.xref ambiguous
.xref syntax_error

.xref str_nul

.xref env_top
.xref tmpargs

.text

****************************************************************
*  Name
*       setenv - set environment
*
*  Synopsis
*       setenv
*       setenv name
*       setenv name word
****************************************************************
.xdef cmd_setenv

cmd_setenv:
		tst.w	d0				*  引数がなければ
		beq	printenv			*  環境変数を表示する

		lea	str_nul,a1
		subq.w	#2,d0
		bcs	cmd_setenv_set
		bhi	too_many_args			*  エラー

		movea.l	a0,a2				*  A2 : 変数名
		bsr	strfor1
		movea.l	a0,a1				*  A1 : 値
		moveq	#1,d0				*  1単語を
		movea.l	tmpargs(a5),a0			*  tmpargs に
		bsr	expand_wordlist			*  置換展開する
		bmi	cmd_setenv_return

		exg	a0,a1				*  A0 : 置換展開前，A1 : 置換展開後
		subq.w	#1,d0
		bne	ambiguous

		movea.l	a2,a0				*  A0 : 変数名
cmd_setenv_set:
		bsr	strip_quotes
		move.l	a0,-(a7)
		moveq	#'=',d0
		jsr	strchr
		movea.l	(a7)+,a0
		bne	syntax_error

		bsr	fish_setenv
		beq	cmd_setenv_fail
.if 0
	*  これはやめた
		*
		*  環境変数 path が再設定されたのならば
		*  シェル変数 path も再設定して rehash する
		*
		lea	word_path,a1
		bsr	strcmp
		bne	cmd_setenv_success_return

		jsr	import_path
		bne	cmd_setenv_return

		bsr	rehash
.endif
		bra	cmd_setenv_success_return
****************
printenv:
		movea.l	env_top(a5),a1
printenv_loop:
		cmpa.l	#0,a1
		beq	cmd_setenv_success_return

		lea	var_body(a1),a0
		bsr	cputs
		moveq	#'=',d0
		jsr	putc
		bsr	strfor1
		bsr	cputs
		bsr	put_newline
		movea.l	var_next(a1),a1
		bra	printenv_loop

cmd_setenv_success_return:
		moveq	#0,d0
cmd_setenv_return:
		rts

cmd_setenv_fail:
		moveq	#1,d0
		rts

.end
