* minmaxul.s
* Itagaki Fumihiko 01-Jul-91  Create.

.text

****************************************************************
* minmaxul - minimum/maximum (unsigned long)
*
* CALL
*      D0.L   unsigned long word a
*      D1.L   unsigned long word b
*
* RETURN
*      D0.L   min(a,b)
*      D1.L   max(a,b)
****************************************************************
.xdef minmaxul

minmaxul:
		cmp.l	d0,d1
		bhs	minmaxul_return

		exg	d0,d1
minmaxul_return:
		rts

.end
