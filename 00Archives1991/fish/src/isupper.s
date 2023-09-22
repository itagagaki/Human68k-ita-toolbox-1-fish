* isupper.s
* Itagaki Fumihiko 30-Sep-90  Create.

.text

****************************************************************
* isupper - is upper case alphabet character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef isupper

isupper:
		cmp.b	#'A',d0
		blo	return			* ZF=0

		cmp.b	#'Z',d0
		bhi	return			* ZF=0

		cmp.b	d0,d0			* ZF=1
return:
		rts

.end
