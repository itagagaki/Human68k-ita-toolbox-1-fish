* memset.s
* Itagaki Fumihiko 16-Apr-91  Create.

.text

****************************************************************
* memset - fill memory block with constant byte.
*
* CALL
*      A0     top address of memory block
*      D0.B   constant byte
*      D1.L   length of memory block (byte)
*
* RETURN
*      none
*****************************************************************
.xdef memset

memset:
		movem.l	d1/a0,-(a7)
		bra	low_continue

high_loop:
		swap	d1
low_loop:
		move.b	d0,(a0)+
low_continue:
		dbra	d1,low_loop

		swap	d1
		dbra	d1,high_loop

		movem.l	(a7)+,d1/a0
		rts

.end
