* cmdgoto.s
* This contains built-in commnd 'goto' and 'onintr'
*
* Itagaki Fumihiko 23-Dec-90  Create.

*****************************************************************
*								*
*	goto label						*
*								*
*****************************************************************

.include chrcode.h
.include ../src/fish.h
.include ../src/source.h

.xref strlen
.xref memcmp
.xref skip_space
.xref find_space
.xref crlf_skip
.xref enputs1
.xref pre_perror
.xref command_error
.xref too_few_args
.xref too_many_args
.xref current_source
.xref onintr_pointer

.text

*****************************************************************
*								*
*	goto command entry					*
*								*
*****************************************************************
.xdef cmd_goto

cmd_goto:
		cmp.w	#1,d0
		blo	too_few_args
		bhi	too_many_args

		tst.l	current_source
		beq	no_label_0

		movea.l	a1,a0
		bsr	search_label
		bne	return

		movea.l	current_source,a2
		move.l	a0,SOURCE_POINTER(a2)
return:
		rts
*****************************************************************
.xdef cmd_onintr

cmd_onintr:
		cmp.w	#1,d0
		bhi	too_many_args

		movea.l	a0,a1
		lea	msg_cant_from_terminal,a0
		tst.l	current_source
		beq	command_error

		suba.l	a0,a0
		tst.w	d0
		beq	set_onintr

		cmpi.b	#'-',(a1)
		bne	onintr_label

		tst.b	1(a1)
		bne	onintr_label

		subq.l	#1,a0
		bra	set_onintr

onintr_label:
		bsr	search_label
		bne	return
set_onintr:
		move.l	a0,onintr_pointer
		moveq	#0,d0
		rts
*****************************************************************
*
*	search label
*
search_label:
		movea.l	a1,a0
		bsr	strlen
		move.l	d0,d1

		movea.l	current_source,a0
		add.l	#SOURCE_HEADER_SIZE,a0
search_label_loop:
		move.b	(a0),d0
		beq	no_label_1

		cmp.b	#EOT,d0
		beq	no_label_1

		bsr	skip_space
		movea.l	a0,a2
		bsr	find_space
		cmpa.l	a2,a0
		beq	search_label_continue

		cmpi.b	#':',-(a0)
		bne	search_label_continue

		exg	a0,a2
		move.l	a2,d0
		sub.l	a0,d0
		cmp.l	d1,d0
		bne	search_label_continue

		bsr	memcmp
		bne	search_label_continue

		lea	2(a0,d1.l),a0
		rts

search_label_continue:
		bsr	crlf_skip
		bra	search_label_loop

no_label_1:
		movea.l	a1,a0
no_label_0:
		bsr	pre_perror
		lea	msg_nolabel,a0
		bra	enputs1
*****************************************************************
.data

msg_nolabel:			dc.b	'ÉâÉxÉãÇ™Ç†ÇËÇ‹ÇπÇÒ',0
msg_cant_from_terminal:		dc.b	'í[ññÇ©ÇÁÇÕêßå‰Ç≈Ç´Ç‹ÇπÇÒ',0

.end
