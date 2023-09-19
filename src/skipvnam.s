* skipvnam.s
* Itagaki Fumihiko 24-Jan-91  Create.

.xref iscsym
.xref iscsymf
.xref issjis

.text

****************************************************************
* skip_varname - returns first non-varname character point
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first non-varname character point
*      D0.B   first non-varname character
*****************************************************************
.xdef skip_varname

skip_varname:
		move.b	(a0)+,d0
		bsr	iscsymf
		beq	loop

		jsr	issjis
		bne	done
loop_sjis:
		move.b	(a0)+,d0
		beq	done
loop:
		move.b	(a0)+,d0
		bsr	iscsym
		beq	loop

		jsr	issjis
		beq	loop_sjis
done:
		subq.l	#1,a0
		rts

.end
