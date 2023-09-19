* isdigit.s
* Itagaki Fumihiko 11-Jul-90  Create.

.text

****************************************************************
* isdigit - is decimal digit character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef isdigit

isdigit:
		cmp.b	#'0',d0
		blo	return			* ZF=0

		cmp.b	#'9',d0
		bhi	return			* ZF=0

		cmp.b	d0,d0			* ZF=1
return:
		rts

.end
