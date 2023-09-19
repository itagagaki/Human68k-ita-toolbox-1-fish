* isalpha.s
* Itagaki Fumihiko 04-Jan-90  Create.

.xref islower
.xref isupper

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
		jsr	islower
		beq	return

		jsr	isupper
return:
		rts

.end
