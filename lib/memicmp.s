* memicmp.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains case independent memory compare function.

.xref issjis
.xref toupper

.text

****************************************************************
* memicmp - compare memory (case independent)
*
* CALL
*      A0     compared
*      A1     reference
*      D0.L   length
*
* RETURN
*      D0.B   (A0)-(A1)   è„à ÇÕ0
*      CCR    result of SUB.B (A1),(A0)
****************************************************************
.xdef memicmp

memicmp:
		movem.l	d1-d2/a0-a1,-(a7)
		move.l	d0,d1
		beq	memicmp_break
memicmp_loop:
		move.b	(a1)+,d0
		jsr	issjis
		beq	memicmp_sjis

		jsr	toupper
		move.b	d0,d2
		move.b	(a0)+,d0
		jsr	toupper
		sub.b	d2,d0
		bra	memicmp_continue

memicmp_sjis:
		move.b	d0,d2
		move.b	(a0)+,d0
		sub.b	d2,d0
		bne	memicmp_break

		subq.l	#1,d1
		beq	memicmp_break

		move.b	(a0)+,d0
		sub.b	(a1)+,d0
memicmp_continue:
		bne	memicmp_break

		subq.l	#1,d1
		bne	memicmp_loop
memicmp_break:
		movem.l	(a7)+,d1-d2/a0-a1
		rts

.end
