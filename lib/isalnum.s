* isalnum.s
* Itagaki Fumihiko 15-Feb-91  Create.

.xref isalpha
.xref isdigit

.text

****************************************************************
* isalnum - •¶š‚Í‰p”š‚©
*
* CALL
*      D0.B   •¶š
*
* RETURN
*      ZF     ^‚È‚ç‚Î 1
*****************************************************************
.xdef isalnum

isalnum:
		jsr	isalpha
		beq	return

		jmp	isdigit

return:
		rts

.end
