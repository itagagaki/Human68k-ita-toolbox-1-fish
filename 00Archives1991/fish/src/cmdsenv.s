* cmdsenv.s
* This contains built-in command 'setenv'.
*
* Itagaki Fumihiko 16-Jul-90  Create.

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
.xdef	cmd_setenv

cmd_setenv:
		tst.w	d0			* 引数がなければ
		beq	printenv		* 環境変数を表示する

		lea	str_nul,a1
		cmp.w	#2,d0
		blo	cmd_setenv_set
		bhi	too_many_args		* エラー

		movea.l	a0,a2			* A2 : 変数名
		bsr	for1str
		movea.l	a0,a1			* A1 : 値
		move.l	a1,-(a7)
		lea	tmpargs,a0		* tmpargs に
		moveq	#1,d0
		bsr	expand_wordlist		* 値を置換展開する
		movea.l	(a7)+,a1
		bmi	return_1

		cmp.w	#1,d0
		bhi	setenv_ambiguous

		movea.l	a0,a1			* A1 : 置換展開された値
		movea.l	a2,a0			* A0 : 変数名
cmd_setenv_set:
		bsr	strip_quotes
		bra	setenv

printenv:
		movea.l	envwork,a0
		addq.l	#4,a0
printenv_loop:
		tst.b	(a0)			* 最初の文字がNULならば
		beq	return_0		* 終わり

		bsr	nputs
		bsr	for1str
		bra	printenv_loop

setenv_ambiguous:
		movea.l	a1,a0
		bra	ambiguous

return_0:
		moveq	#0,d0
		rts

return_1:
		moveq	#1,d0
		rts

.end
