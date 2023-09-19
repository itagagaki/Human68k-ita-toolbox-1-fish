* stricmp.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains case independent string compare function.

.xref issjis
.xref toupper
.xref memcmp

.text

****************************************************************
* memxcmp - compare memory
*
* CALL
*      A0     compared
*      A1     reference
*      D0.L   length
*      D0.B   0 : case dependent, othwise : case independent
*
* RETURN
*      D0.B   (A0)-(A1)   è„à ÇÕ0
*      CCR    result of SUB.B (A1),(A0)
*
*
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
.xdef memxcmp
.xdef memicmp

memxcmp:
		tst.b	d1
		beq	memcmp
memicmp:
		movem.l	d1-d2/a0-a1,-(a7)
		move.l	d0,d1
		beq	memicmp_break
memicmp_loop:
		move.b	(a1)+,d0
		bsr	issjis
		beq	memicmp_sjis

		bsr	toupper
		move.b	d0,d2
		move.b	(a0)+,d0
		bsr	toupper
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
.xdef stricmp2

stricmp:
		movem.l	a0-a1,-(a7)
		bsr	stricmp2
		movem.l	(a7)+,a0-a1
		rts

stricmp2:
		movem.l	d1,-(a7)
stricmp_loop:
		move.b	(a1)+,d0
		bsr	issjis
		beq	stricmp_sjis

		bsr	toupper
		move.b	d0,d1
		move.b	(a0)+,d0
		bsr	toupper
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
		movem.l	(a7)+,d1
		rts

.end
