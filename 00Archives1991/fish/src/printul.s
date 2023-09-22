* printul.s
* Itagaki Fumihiko 24-Nov-90  Create.

.text

****************************************************************
* print_ul - print unsigned 32bit decimal
*
* CALL
*      D0.L   unsigned 32bit value
*
* RETURN
*      none.
*****************************************************************
.xdef print_ul

print_ul:
		link	a6,#-12
		move.l	a0,-(a7)
		lea	-12(a6),a0
		bsr	utoa
		bsr	skip_space
		bsr	puts
		movea.l	(a7)+,a0
		unlk	a6
		rts

.end
