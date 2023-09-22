* utoa.s
* Itagaki Fumihiko 02-Nov-90  Create.

.text

****************************************************************
* utoa - convert unsigned long word to ascii decimal
*
* CALL
*      A0     buffer (12B)
*      D0.L   unsigned 32bit value
*
* RETURN
*      none.
*****************************************************************
.xdef utoa

utoa:
		movem.l	d0-d3/a0-a1,-(a7)
		move.b	#' ',(a0)+
		lea	itoa_tbl(pc),a1
		moveq	#0,d3
utoa_loop1:
		move.l	(a1)+,d1
		tst.l	(a1)
		beq	utoa_last

		moveq	#0,d2
utoa_loop2:
		addq.b	#1,d2
		sub.l	d1,d0
		bcc	utoa_loop2

		subq.b	#1,d2
		add.l	d1,d0
		tst.b	d3
		bne	utoa_set_digit

		tst.b	d2
		beq	utoa_set_blank

		moveq	#1,d3
		bra	utoa_set_digit

utoa_set_blank:
		move.b	#' ',(a0)+
		bra	utoa_loop1

utoa_set_digit:
		add.b	#'0',d2
		move.b	d2,(a0)+
		bra	utoa_loop1

utoa_last:
		add.b	#'0',d0
		move.b	d0,(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d3/a0-a1
		rts

.end
