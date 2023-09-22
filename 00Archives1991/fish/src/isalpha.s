* isalpha.s
* Itagaki Fumihiko 04-Jan-90  Create.

.text

****************************************************************
* isalpha - •¶š‚Í‰p•¶š‚©
*
* CALL
*      D0.B   •¶š
*
* RETURN
*      ZF     ^‚È‚ç‚Î 1
*****************************************************************
.xdef isalpha

isalpha:
		bsr	islower
		bne	isupper
		rts

.end
