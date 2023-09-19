* memxcmp.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains memory compare function.

.xref memcmp
.xref memicmp

.text

****************************************************************
* memxcmp - compare memory
*
* CALL
*      A0     compared
*      A1     reference
*      D0.L   length
*      D1.B   0 : case dependent, otherwise : case independent
*
* RETURN
*      D0.B   (A0)-(A1)   è„à ÇÕ0
*      CCR    result of SUB.B (A1),(A0)
****************************************************************
.xdef memxcmp

memxcmp:
		tst.b	d1
		bne	case_independent

		jmp	memcmp

case_independent:
		jmp	memicmp

.end
