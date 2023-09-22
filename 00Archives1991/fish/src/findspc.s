* findspc.s
* Itagaki Fumihiko 14-Jul-90  Create.

.text

****************************************************************
* find_space - returns first white-space character point
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first white-space character point
*****************************************************************
.xdef find_space

find_space:
		move.w	d0,-(a7)
loop:
		move.b	(a0)+,d0
		beq	done

		bsr	isspace
		bne	loop
done:
		subq.l	#1,a0
		move.w	(a7)+,d0
		rts

.end
