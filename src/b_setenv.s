* b_setenv.s
* This contains built-in command 'setenv'.
*
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strcmp
.xref strfor1
.xref nputs
.xref strip_quotes
.xref expand_wordlist
.xref fish_setenv
.xref inport_path
.xref rehash
.xref too_many_args
.xref ambiguous
.xref word_path
.xref str_nul

.xref tmpargs

.xref envwork

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
		tst.w	d0			* 引数がなければ
		beq	printenv		* 環境変数を表示する

		lea	str_nul,a1
		cmp.w	#2,d0
		blo	cmd_setenv_set
		bhi	too_many_args		* エラー

		movea.l	a0,a2			* A2 : 変数名
		bsr	strfor1
		movea.l	a0,a1			* A1 : 値
		move.l	a1,-(a7)
		lea	tmpargs,a0		* tmpargs に
		moveq	#1,d0
		bsr	expand_wordlist		* 値を置換展開する
		movea.l	(a7)+,a1
		bmi	cmd_setenv_return

		cmp.w	#1,d0
		bhi	setenv_ambiguous

		movea.l	a0,a1			* A1 : 置換展開された値
		movea.l	a2,a0			* A0 : 変数名
cmd_setenv_set:
		bsr	strip_quotes
		bsr	fish_setenv
		bne	cmd_setenv_return
		*
		*  環境変数 path が再設定されたのならば
		*  シェル変数 path も再設定して rehash する
		*
		lea	word_path,a1
		bsr	strcmp
		bne	cmd_setenv_success_return

		jsr	inport_path
		bne	cmd_setenv_return

		bsr	rehash
		bra	cmd_setenv_success_return
****************
printenv:
		movea.l	envwork(a5),a0
		addq.l	#4,a0
printenv_loop:
		tst.b	(a0)				* 最初の文字がNULならば
		beq	cmd_setenv_success_return	* 終わり

		bsr	nputs
		bsr	strfor1
		bra	printenv_loop

cmd_setenv_success_return:
		moveq	#0,d0
cmd_setenv_return:
		rts


setenv_ambiguous:
		movea.l	a1,a0
		bra	ambiguous

.end
