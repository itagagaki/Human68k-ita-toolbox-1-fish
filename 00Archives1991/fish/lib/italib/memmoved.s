* memmoved.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* memmove_dec - move memory block for backward
*
* CALL
*      A0     destination
*      A1     source
*      D0.L   size
*
* RETURN
*      A0     A0 - size
*      A1     A1 - size
*****************************************************************
.xdef memmove_dec

memmove_dec:
		move.l	d0,-(a7)
		tst.l	d0
		beq	memmove_dec_done
memmove_dec_loop:
		move.b	-(a1),-(a0)
		subq.l	#1,d0
		bne	memmove_dec_loop
memmove_dec_done:
		move.l	(a7)+,d0
		rts

.end
