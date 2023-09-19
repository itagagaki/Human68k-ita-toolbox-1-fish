* strspc.s
* Itagaki Fumihiko 14-Jul-90  Create.

.xref isspace

.text

****************************************************************
* strspc - returns first white-space character point in string
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first white-space character point
*****************************************************************
.xdef strspc

strspc:
		move.w	d0,-(a7)
loop:
		move.b	(a0)+,d0
		beq	done

		jsr	isspace
		bne	loop
done:
		subq.l	#1,a0
		move.w	(a7)+,d0
		rts

.end
