* iscsym.s
* Itagaki Fumihiko 30-Sep-90  Create.

.text

****************************************************************
* iscsym - is allowed character for C symbol expect first
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef iscsym

iscsym:
		bsr	iscsymf
		beq	return

		bsr	isdigit
return:
		rts

.end
