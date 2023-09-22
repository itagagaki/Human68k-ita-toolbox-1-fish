* skipcsym.s
* Itagaki Fumihiko 10-Oct-90  Create.

.text

****************************************************************
* skip_csym - returns first non-C-symbol character point
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first non-C-symbol character point
*      D0.B   first non-C-symbol character
*****************************************************************
.xdef skip_csym

skip_csym:
		move.b	(a0)+,d0
		bsr	iscsymf
		bne	done
loop:
		move.b	(a0)+,d0
		bsr	iscsym
		beq	loop
done:
		subq.l	#1,a0
		rts

.end
