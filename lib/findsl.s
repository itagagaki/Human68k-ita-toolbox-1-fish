* findsl.s
* Itagaki Fumihiko 27-Mar-93  Create.

.xref issjis

.text

****************************************************************
* find_slashes - / ‚© \ ‚ğ’T‚·
*
* CALL
*      A0     •¶š—ñ
*
* RETURN
*      A0     Å‰‚Ì / ‚© \ ‚© NUL ‚ÌˆÊ’u
*      D0.B   Å‰‚Ì / ‚© \ ‚© NUL
*      CCR    TST.B D0
*****************************************************************
.xdef find_slashes

find_slashes:
		move.b	(a0)+,d0
		beq	done

		cmp.b	#'/',d0
		beq	done

		cmp.b	#'\',d0
		beq	done

		jsr	issjis
		bne	find_slashes

		move.b	(a0)+,d0
		bne	find_slashes
done:
		subq.l	#1,a0
		tst.b	d0
		rts

.end
