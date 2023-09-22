*****************************************************************
*								*
*	verify switch set command				*
*								*
*	VERIFY <mode>						*
*								*
*	mode list						*
*		ON	verify mode on				*
*		OFF	verify mode off				*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

.text

start:
		clr.w	d2
		move.b	(a2)+,d2
		bsr	skip_space
		beq	show

		movem.l	d2/a2,-(a7)
		bra	tolower_2
tolower_1:
		ori.b	#$20,(a2)+
tolower_2:
		dbra	d2,tolower_1

		movem.l	(a7)+,d2/a2

		lea	msg_off(pc),a3
		moveq	#3,d3
		moveq	#0,d1
		bsr	memcmpx
		beq	set

		lea	msg_on(pc),a3
		moveq	#2,d3
		moveq	#1,d1
		bsr	memcmpx
		bne	error
****************
set:
		move.w	d1,-(a7)
		DOS	_VERIFY
		addq.l	#2,a7
		bra	done
****************
show:
		pea	msg_1(pc)
		DOS	_PRINT
		add.l	#4,a7
		DOS	_VERIFYG
		lea	msg_off(pc),a0
		tst.l	d0
		beq	show_1

		lea	msg_on(pc),a0
show_1:
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		pea	msg_2(pc)
		DOS	_PRINT
		addq.l	#4,a7
done:
		clr.w	-(a7)
		DOS	_EXIT2

error:
		move.l	#22,-(a7)	* length
		pea	msg_bad_arg(pc)
		move.w	#2,-(a7)
		DOS	_WRITE
		move.w	#1,(a7)
		DOS	_EXIT2
****************************************************************
memcmpx:
		movem.l	d2/a2,-(a7)
		sub.w	d3,d2
		blo	memcmpx_done

		subq.w	#1,d3
memcmpx_loop:
		cmpm.b	(a2)+,(a3)+
		bne	memcmpx_done

		dbra	d3,memcmpx_loop

		bsr	skip_space
memcmpx_done:
		movem.l	(a7)+,d2/a2
		rts
****************************************************************
skip_space:
		tst.w	d2
		beq	skip_space_return

		cmpi.b	#' ',(a2)
		beq	skip_space_continue

		cmp.b	#HT,(a2)
		beq	skip_space_continue

		cmpi.b	#CR,(a2)
		beq	skip_space_continue

		cmpi.b	#LF,(a2)
		beq	skip_space_continue

		cmpi.b	#VT,(a2)
		bne	skip_space_return
skip_space_continue:
		addq.l	#1,a2
		subq.w	#1,d2
		bne	skip_space
skip_space_return:
		rts

.data

msg_off:	dc.b	'off',NUL
msg_on:		dc.b	'on',NUL
msg_1:		dc.b	'verify ÇÕ <',NUL
msg_2:		dc.b	'> Ç≈Ç∑',CR,LF,NUL
msg_bad_arg:	dc.b	'ÉpÉâÉÅÅ|É^Ç™ñ≥å¯Ç≈Ç∑',CR,LF

.end start
