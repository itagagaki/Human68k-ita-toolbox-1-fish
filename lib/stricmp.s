* stricmp.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains case independent string compare function.

.xref issjis
.xref toupper

.text

****************************************************************
* stricmp - compare two strings (case independent)
*
* CALL
*      A0     points string 1
*      A1     points string 2
*
* RETURN
*      D0.B   toupper(A0)-toupper(A1)
*      CCR    result of SUB.B toupper(A1),toupper(A0)
****************************************************************
.xdef stricmp

stricmp:
		movem.l	d1/a0-a1,-(a7)
stricmp_loop:
		move.b	(a1)+,d0
		jsr	issjis
		beq	stricmp_sjis

		jsr	toupper
		move.b	d0,d1
		move.b	(a0)+,d0
		jsr	toupper
		sub.b	d1,d0
		bra	stricmp_continue

stricmp_sjis:
		move.b	d0,d1
		move.b	(a0)+,d0
		sub.b	d1,d0
		bne	stricmp_break

		move.b	(a0)+,d0
		sub.b	(a1)+,d0
stricmp_continue:
		bne	stricmp_break

		tst.b	-1(a0)
		bne	stricmp_loop
stricmp_break:
		movem.l	(a7)+,d1/a0-a1
		rts

.end
