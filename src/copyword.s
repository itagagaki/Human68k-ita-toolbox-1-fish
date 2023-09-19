* copyword.s
* Itagaki Fumihiko 13-Jul-90  Create.

.text

****************************************************************
* copy_word - copy a blank-terminated word.
*
* CALL
*      A0     destination
*      A1     source
*
* RETURN
*      A1     next word point
*      D0.L   length of copied word
*****************************************************************
.xdef copy_word

copy_word:
		move.l	a2,-(a7)
		movea.l	a0,a2
loop:
		move.b	(a1)+,d0
		beq	done

		bsr	isspace
		beq	done

		move.b	d0,(a2)+
		bra	loop

done:
		clr.b	(a2)
		subq.l	#1,a1
		bsr	skip_space
		move.l	a2,d0
		sub.l	a0,d0
		movea.l	(a7)+,a2
		rts

.end
