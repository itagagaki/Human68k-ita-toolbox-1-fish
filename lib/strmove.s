* strmove.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

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
*****************************************************************
.xdef strmove

strmove:
strmove_loop:
		move.b	(a1)+,(a0)+
		bne	strmove_loop

		rts

.end
