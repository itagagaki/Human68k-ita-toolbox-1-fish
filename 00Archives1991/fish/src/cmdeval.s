* cmdeval.s
* This contains built-in command eval.
*
* Itagaki Fumihiko 28-Nov-90  Create.

.include ../src/fish.h

.xref make_wordlist
.xref wordlistlen
.xref memmove_inc
.xref for1str
.xref do_line
.xref too_many_words
.xref too_long_line
.xref line
.xref tmpline

.text

****************************************************************
*  Name
*       eval - execute argument on current shell
*
*  Synopsis
*       eval words
****************************************************************
.xdef cmd_eval

cmd_eval:
		move.w	d0,d1			* D1.W : ˆø”‚Ì”
		beq	return_0

		moveq	#0,d2			* D2.W : ¶¬‚³‚ê‚½’PŒê•À‚Ñ‚ÌŒê”
		moveq	#0,d3			* D3.W : ¶¬‚³‚ê‚½’PŒê•À‚Ñ‚Ì’·‚³
		lea	line,a2
		bra	continue

loop:
		lea	tmpline,a1
		bsr	make_wordlist
		tst.l	d0
		bmi	return_1

		add.w	d0,d2
		cmp.w	#MAXWORDS,d2
		bhi	too_many_words

		exg	a0,a1
		bsr	wordlistlen
		exg	a0,a1
		add.w	d0,d3
		cmp.w	#MAXWORDLISTSIZE,d3
		bhi	too_long_line

		exg	a0,a2
		bsr	memmove_inc
		exg	a0,a2
		bsr	for1str
continue:
		dbra	d1,loop

		lea	line,a0
		move.w	d2,d0
		bsr	do_line		*!! Ä‹A !!*
return_0:
		moveq	#0,d0
		rts

return_1:
		moveq	#1,d0
		rts

.end
