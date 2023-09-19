* isodigit.s
* Itagaki Fumihiko 16-Sep-91  Create.

.text

****************************************************************
* isodigit - is octal digit character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef isodigit

isodigit:
		cmp.b	#'0',d0
		blo	return			* ZF=0

		cmp.b	#'7',d0
		bhi	return			* ZF=0

		cmp.b	d0,d0			* ZF=1
return:
		rts

.end
