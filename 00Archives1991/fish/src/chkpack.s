.text

.if 0
****************************************************************
* check_packing - 語が{}でパッキングされた複語であるかどうかを調べる
*
* CALL
*      A0     語 (may be contains ", ', and/or \)
*
* RETURN
*      D0.B   { があれば {．無ければ NUL
*      CCR    TST.B D0
****************************************************************
.xdef check_packing

check_packing:
		movem.l	d1/a0,-(a7)
		moveq	#0,d1
loop:
		move.b	(a0)+,d0
		beq	done

		bsr	issjis
		beq	skip1

		tst.b	d1
		beq	check

		cmp.b	d1,d0
		bne	loop
quote:
		eor.b	d0,d1
		bra	loop

check:
		cmp.b	#'{',d0
		beq	done

		cmp.b	#'"',d0
		beq	quote

		cmp.b	#"'",d0
		beq	quote

		cmp.b	#'\',d0
		bne	loop

		move.b	(a0)+,d0
		beq	done

		bsr	issjis
		bne	loop
skip1:
		move.b	(a0)+,d0
		bne	loop
done:
		movem.l	(a7)+,d1/a0
		tst.b	d0
		rts
.endif

.end
