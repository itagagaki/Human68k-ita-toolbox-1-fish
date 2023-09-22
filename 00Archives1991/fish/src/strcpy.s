* strcpy.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains string/memory processing routines.

.text

****************************************************************
* strcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      D0.L   copied length (not counts NUL)
*****************************************************************
.xdef strcpy

strcpy:
		movem.l	a0-a1,-(a7)
strcpy_loop:
		move.b	(a1)+,(a0)+
		bne	strcpy_loop

		move.l	a0,d0
		movem.l	(a7)+,a0-a1
		sub.l	a0,d0
		subq.l	#1,d0
		rts
****************************************************************
* stpcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      A0     points copied NUL of destination
*      D0.L   copied length (not counts NUL)
*****************************************************************
.xdef stpcpy

stpcpy:
		bsr	strcpy
		adda.l	d0,a0
		rts
****************************************************************
* strmove - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      A0     points next of copied NUL of destination
*      A1     points next of NUL of source
*      D0.L   copied length (counts NUL)
*****************************************************************
.xdef strmove

strmove:
		bsr	strcpy
		addq.l	#1,d0
		adda.l	d0,a0
		adda.l	d0,a1
		rts

.end
