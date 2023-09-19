* iscsym.s
* Itagaki Fumihiko 30-Sep-90  Create.

.xref isalpha
.xref isdigit

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

		jmp	isdigit
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
		jsr	isalpha
		beq	return

		cmp.b	#'_',d0
return:
		rts

.end
