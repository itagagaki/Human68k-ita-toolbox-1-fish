* cmdunset.s
* This contains built-in command 'unalias', 'unset'.
*
* Itagaki Fumihiko 15-Jul-90  Create.

.xref for1str
.xref unset_var
.xref too_few_args
.xref alias
.xref shellvar

.text

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
		movea.l	alias,a1
		moveq	#1,d1
		bra	start

cmd_unset:
		movea.l	shellvar,a1
		moveq	#0,d1
start:
		move.w	d0,d2
		subq.w	#1,d2
		blo	too_few_args
loop:
		move.b	d1,d0
		exg	a0,a1
		bsr	unset_var
		exg	a0,a1
		bsr	for1str
		dbra	d2,loop

		moveq	#0,d0
		rts

.end
