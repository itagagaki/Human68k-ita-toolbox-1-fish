* iscsymf.s
* Itagaki Fumihiko 30-Sep-90  Create.

.text

****************************************************************
* iscsymf - is allowed character for first character of C symbol
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef iscsymf

iscsymf:
		bsr	isalpha
		beq	return

		cmp.b	#'_',d0
return:
		rts

.end
