* memmoved.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* memmovd - move memory block decrease
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
.xdef memmovd

memmovd:
		move.l	d0,-(a7)
		beq	done
loop:
		move.b	-(a1),-(a0)
		subq.l	#1,d0
		bne	loop
done:
		move.l	(a7)+,d0
		rts

.end
