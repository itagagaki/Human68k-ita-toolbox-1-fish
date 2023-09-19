* bsltosl.s
* Itagaki Fumihiko 20-Aug-91  Create.

.xref issjis

.text

****************************************************************
* bsltosl - replace \ to /
*
* CALL
*      A0     top address of NUL-terminated string
*
* RETURN
*      none.
*****************************************************************
.xdef bsltosl

bsltosl:
		movem.l	d0/a0,-(a7)
loop:
		move.b	(a0)+,d0
		beq	done

		jsr	issjis
		beq	skip_sjis

		cmp.b	#'\',d0
		bne	loop

		move.b	#'/',-1(a0)
		bra	loop

skip_sjis:
		tst.b	(a0)+
		bne	loop
done:
		movem.l	(a7)+,d0/a0
		rts

.end
