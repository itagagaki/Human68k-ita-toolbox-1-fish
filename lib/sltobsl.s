* sltobsl.s
* Itagaki Fumihiko 20-Aug-91  Create.

.text

****************************************************************
* sltobsl - replace / to \
*
* CALL
*      A0     top address of NUL-terminated string
*
* RETURN
*      none.
*****************************************************************
.xdef sltobsl

sltobsl:
		move.l	a0,-(a7)
loop:
		tst.b	(a0)
		beq	done

		cmpi.b	#'/',(a0)+
		bne	loop

		move.b	#'\',-1(a0)
		bra	loop

done:
		movea.l	(a7)+,a0
		rts

.end
