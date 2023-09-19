* mulul.s
* Itagaki Fumihiko 03-Nov-90  Create.

.text

****************************************************************
* mulul
*
* CALL
*      D0.L   unsigned long word a
*      D1.L   unsigned long word b
*
* RETURN
*      D0.L   a*b ÇÃâ∫à 
*      D1.L   a*b ÇÃè„à 
****************************************************************
.xdef mulul

mulul:
		movem.l	d2-d4,-(a7)
		*  D0  | A | B |
		*  D1  | C | D |
		move.l	d0,d2
		move.l	d1,d3
		swap	d2
		swap	d3
		move.l	d0,d4
		*  D0  | A | B |
		*  D1  | C | D |
		*  D2  | B | A |
		*  D3  | D | C |
		*  D4  | A | B |
		mulu	d1,d4		*  D4  |  BD   |
		mulu	d2,d1		*  D1  |  AD   |
		mulu	d3,d2		*  D2  |  AC   |
		mulu	d0,d3		*  D3  |  BC   |
		add.l	d1,d3		*  D3  |AD + BC|
		clr.l	d0
		clr.l	d1
		move.w	d3,d0
		swap	d0		*  D0  |(AD+BC)L|0|
		swap	d3
		move.w	d3,d1		*  D1  |0|(AD+BC)H|
		add.l	d4,d0		*  D0: lower word of result
		addx.l	d2,d1		*  D1: upper word of result
		movem.l	(a7)+,d2-d4
		rts

.end
