* isalnum.s
* Itagaki Fumihiko 15-Feb-91  Create.

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
		bsr	isalpha
		bne	isdigit
		rts

.end
