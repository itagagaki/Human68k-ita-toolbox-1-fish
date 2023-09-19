* isspace.s
* Itagaki Fumihiko 08-Jul-90  Create.

.include chrcode.h

.text

****************************************************************
* isspace - is space character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef isspace

isspace:
		cmp.b	#' ',d0
		beq	return

		cmp.b	#HT,d0
		beq	return

		cmp.b	#LF,d0
		beq	return

		cmp.b	#VT,d0
		beq	return

		cmp.b	#FS,d0
		beq	return

		cmp.b	#CR,d0
return:
		rts

.end
