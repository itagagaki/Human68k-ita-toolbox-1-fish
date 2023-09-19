* strazcpy.s
* Itagaki Fumihiko  8-Aug-91  Create.

.text

****************************************************************
* strazcpy - copy NUL-terminated (NUL-terminated string)s.
*
* CALL
*      A0     destination
*      A1     source
*
* RETURN
*      none.
*****************************************************************
.xdef strazcpy

strazcpy:
		movem.l	a0-a1,-(a7)
strazcpy_loop1:
		move.b	(a1)+,(a0)+
		beq	strazcpy_done
strazcpy_loop2:
		move.b	(a1)+,(a0)+
		bne	strazcpy_loop2

		bra	strazcpy_loop1
strazcpy_done:
		movem.l	(a7)+,a0-a1
		rts

.end
