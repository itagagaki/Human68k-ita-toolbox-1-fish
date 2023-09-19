* iscntrl.s
* Itagaki Fumihiko 13-Apr-91  Create.

.text

****************************************************************
* iscntrl - •¶š‚Í§Œä•¶š‚©
*
* CALL
*      D0.B   •¶š
*
* RETURN
*      ZF     ^‚È‚ç‚Î 1
*****************************************************************
.xdef iscntrl

iscntrl:
		cmp.b	#$20,d0
		blo	true

		cmp.b	#$7f,d0
		rts

true:
		cmp.b	d0,d0
		rts

.end
