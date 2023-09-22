* strbot.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* strbot - return bottom of string
*
* CALL
*      A0     string
*
* RETURN
*      A0     bottom of string
*****************************************************************
.xdef strbot

strbot:
		bsr	for1str
		subq.l	#1,a0
		rts

.end
