* strcmp.s
* Itagaki Fumihiko 16-Jul-90  Create.
*
* This contains string/memory compare functions.

.text

****************************************************************
* memcmp - compare memory
*
* CALL
*      A0     compared
*      A1     reference
*      D0.L   length
*
* RETURN
*      D0.B   (A0)-(A1)   è„à ÇÕ0
*      CCR    result of SUB.B (A1),(A0)
*****************************************************************
.xdef memcmp

memcmp:
		movem.l	a0-a1,-(a7)
		tst.l	d0
		beq	memcmp_done
memcmp_loop:
		cmpm.b	(a0)+,(a1)+
		bne	memcmp_not_equal

		subq.l	#1,d0
		bne	memcmp_loop
memcmp_equal:
		moveq	#0,d0
		bra	memcmp_done

memcmp_not_equal:
		moveq	#0,d0
		move.b	-(a0),d0
		sub.b	-(a1),d0
memcmp_done:
		movem.l	(a7)+,a0-a1
		rts
****************************************************************
* strcmp - compare two strings
*
* CALL
*      A0     points string 1
*      A1     points string 2
*
* RETURN
*      D0.B   (A0)-(A1)   è„à ÇÕ0
*      CCR    result of SUB.B (A1),(A0)
****************************************************************
.xdef strcmp

strcmp:
		movem.l	a0-a1,-(a7)
strcmp_loop:
		cmpm.b	(a0)+,(a1)+
		bne	memcmp_not_equal

		tst.b	-1(a0)
		bne	strcmp_loop

		bra	memcmp_equal

.end
