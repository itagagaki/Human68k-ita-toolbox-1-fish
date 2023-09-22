* getenv.s
* Itagaki Fumihiko 15-Jul-90  Create.

****************************************************************
* getenv - get environment variable address
*
* CALL
*      A0     top point of environment
*      A1     name point
*
* RETURN
*      A0     name point of environment   (no mean if not found)
*      D0.L   value point of environment  (0L if not found)
*      CCR    TST.L D0
*****************************************************************
.xdef getenv

getenv:
		movem.l	d1/a2-a3,-(a7)
		addq.l	#4,a0
getenv_loop1:
		tst.b	(a0)
		beq	getenv_fail

		movea.l	a0,a2
		movea.l	a1,a3
getenv_loop2:
		move.b	(a0)+,d1
		move.b	(a3)+,d0
		beq	getenv_term

		cmp.b	d0,d1
		beq	getenv_loop2

		bra	getenv_next
getenv_term:
		cmp.b	#'=',d1
		beq	env_found
getenv_next:
		subq.l	#1,a0
getenv_next_loop:
		tst.b	(a0)+
		bne	getenv_next_loop
		bra	getenv_loop1

getenv_fail:
		clr.l	a0
env_found:
		move.l	a0,d0
		movea.l	a2,a0
		movem.l	(a7)+,d1/a2-a3
		rts

.end
