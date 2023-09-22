* islower.s
* Itagaki Fumihiko 30-Sep-90  Create.

.text

****************************************************************
* islower - is lower case alphabet character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef islower

islower:
		cmp.b	#'a',d0
		blo	return			* ZF=0

		cmp.b	#'z',d0
		bhi	return			* ZF=0

		cmp.b	d0,d0			* ZF=1
return:
		rts

.end
