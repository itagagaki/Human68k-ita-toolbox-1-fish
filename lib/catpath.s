* catpath.s
* Itagaki Fumihiko 25-Aug-91  Create.

.include limits.h

.xref issjis
.xref strlen
.xref strcpy
.xref strfor1

****************************************************************
* copyhead
*
* CALL
*      A0     result buffer
*      A1     points head
*      D0.W   buffer size
*
* RETURN
*      A0     next point of buffer
*      D0.L   remain buffer size
*      D1.L   bit0 : / または \ で終わっているならば 1
*             bit1 : ドライブ名のみならば 1
*****************************************************************
.xdef copyhead

copyhead:
		movem.l	d2/a1,-(a7)
		moveq	#0,d2
		move.w	d0,d2
		moveq	#0,d1
		tst.b	(a1)
		beq	copyhead_return

		cmpi.b	#':',1(a1)
		bne	copyhead_1

		tst.b	2(a1)
		bne	copyhead_1
		bset	#1,d1
copyhead_1:
		moveq	#0,d0
copyhead_loop:
		tst.b	(a1)
		beq	copyhead_done

		subq.l	#1,d2
		bcs	copyhead_return

		move.b	(a1)+,d0
		move.b	d0,(a0)+
		jsr	issjis
		bne	copyhead_loop

		tst.b	(a1)
		beq	copyhead_done

		subq.l	#1,d2
		bcs	copyhead_return

		move.b	(a1)+,(a0)+
		bra	copyhead_loop
copyhead_done:
		cmp.b	#'/',d0
		beq	copyhead_slash

		cmp.b	#'\',d0
		bne	copyhead_return
copyhead_slash:
		bset	#0,d1
copyhead_return:
		move.l	d2,d0
		movem.l	(a7)+,d2/a1
		rts
****************************************************************
* cat_pathname - concatinate head and tail
*
* CALL
*      A0     result buffer (MAXPATH+1バイト必要)
*      A1     points head
*      A2     points tail
*
* RETURN
*      A1     next word
*      A3     tail pointer of result buffer
*      D0.L   positive if success.
*      CCR    TST.L D0
*****************************************************************
.xdef cat_pathname

cat_pathname:
		movem.l	d1/a0/a2,-(a7)
		move.w	#MAXPATH,d0
		bsr	copyhead
		exg	a0,a1
		jsr	strfor1
		exg	a0,a1
		tst.l	d0
		bmi	cat_pathname_done

		cmpi.b	#'/',(a2)
		beq	cat_pathname_tail_has_slash

		cmpi.b	#'\',(a2)
		beq	cat_pathname_tail_has_slash

		tst.l	d1
		bne	cat_pathname_add_tail

		subq.l	#1,d0
		bcs	cat_pathname_done

		move.b	#'/',(a0)+
		bra	cat_pathname_add_tail

cat_pathname_tail_has_slash:
		btst	#0,d1
		beq	cat_pathname_add_tail

		subq.l	#1,a0
		addq.l	#1,d0
cat_pathname_add_tail:
		movea.l	a0,a3
		move.l	d0,d1
		exg	a0,a2
		jsr	strlen
		exg	a0,a2
		exg	d0,d1
		sub.l	d1,d0
		bcs	cat_pathname_done

		exg	d0,d1
		exg	a1,a2
		jsr	strcpy
		exg	a1,a2
		exg	d0,d1
cat_pathname_done:
		movem.l	(a7)+,d1/a0/a2
		tst.l	d0
		rts

.end
