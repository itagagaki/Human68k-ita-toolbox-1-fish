* b_printf.s
* This contains built-in command printf.
*
* Itagaki Fumihiko 11-Jul-91  Create.

.xref itoa
.xref putc
.xref put_newline
.xref printfi
.xref expression2
.xref expression_syntax_error

.text

****************************************************************
*  Name
*       printf - print with formatting
*
*  Synopsis
*       printf expression
****************************************************************
.xdef cmd_printf

cmd_printf:
		move.w	d0,d7
		bsr	expression2
		bne	return

		tst.w	d7
		bne	expression_syntax_error

		move.l	d1,d0
		moveq	#0,d1
		moveq	#1,d2
		lea	itoa(pc),a0
		lea	putc(pc),a1
		bsr	printfi
		bsr	put_newline
		moveq	#0,d0
return:
		rts

.end
