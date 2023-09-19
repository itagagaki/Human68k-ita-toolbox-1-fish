* skipspc.s
* Itagaki Fumihiko 14-Jul-90  Create.

.xref isspace

.text

****************************************************************
* skip_space - returns first non-white-space character point
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first non-white-space character point
*****************************************************************
.xdef skip_space

skip_space:
		move.w	d0,-(a7)
loop:
		move.b	(a0)+,d0
		jsr	isspace
		beq	loop

		subq.l	#1,a0
		move.w	(a7)+,d0
		rts

.end
