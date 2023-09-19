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
		tst.l	d1
		beq	memset_done
memset_loop:
		move.b	d0,(a0)+
		subq.l	#1,d1
		bne	memset_loop
memset_done:
		movem.l	(a7)+,d1/a0
		rts

.end
