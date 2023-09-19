* issjis.s
* Itagaki Fumihiko 30-Jul-90  Create.

.text

****************************************************************
* issjis - is Shift-JIS character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
.xdef issjis

issjis:
		cmp.b	#$80,d0
		blo	return			* ZF=0

		cmp.b	#$a0,d0
		blo	true

		cmp.b	#$e0,d0
		blo	return			* ZF=0
true:
		cmp.b	d0,d0			* ZF=1
return:
		rts

.end
