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
.xdef isspace3
.xdef isspace2
.xdef isspace1

isspace:
		cmp.b	#VT,d0		*  $0b
		beq	return

		cmp.b	#FS,d0		*  $0c
		beq	return
isspace3:
		cmp.b	#CR,d0		*  $0d
		beq	return

		cmp.b	#LF,d0		*  $0a
		beq	return
isspace2:
		cmp.b	#HT,d0		*  $09
		beq	return
isspace1:
		cmp.b	#' ',d0		*  $20
return:
		rts

.end
