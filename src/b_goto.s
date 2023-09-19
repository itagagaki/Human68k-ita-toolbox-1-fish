* b_goto.s
* This contains built-in commnd 'goto' and 'onintr'
*
* Itagaki Fumihiko 23-Dec-90  Create.

.include limits.h
.include chrcode.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/loop.h

.xref isspace
.xref strlen
.xref strspc
.xref memcmp
.xref skip_space
.xref enputs1
.xref loop_stack_p
.xref abort_loops
.xref pre_perror
.xref command_error
.xref too_few_args
.xref too_many_args

.xref current_source
.xref exitflag
.xref loop_status

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

		tst.l	current_source(a5)
		beq	cannot_goto_on_terminal

		bsr	search_label
		bne	return

		move.l	a0,d0
		movea.l	current_source(a5),a0
		move.l	d1,SOURCE_LINENO(a0)
check_goto:
		move.l	d0,SOURCE_POINTER(a0)
		tst.b	loop_status(a5)
		beq	goto_success

		bsr	loop_stack_p
		cmp.l	LOOPINFO_TOPPTR(a1),d0
		bls	goto_abort_loops

		cmp.l	LOOPINFO_BOTPTR(a1),d0
		blo	goto_success
goto_abort_loops:
		bsr	abort_loops
goto_success:
		sf	exitflag(a5)
success:
		moveq	#0,d0
return:
		rts


cannot_goto_on_terminal:
		lea	msg_cannot_goto_on_terminal,a0
		bra	command_error
*****************************************************************
.xdef source_goto_onintr

source_goto_onintr:
		movea.l	current_source(a5),a0
		move.l	SOURCE_ONINTR_LINENO(a0),SOURCE_LINENO(a0)
		move.l	SOURCE_ONINTR_POINTER(a0),d0
		bra	check_goto
*****************************************************************
.xdef cmd_onintr

cmd_onintr:
		cmp.w	#1,d0
		bhi	too_many_args

		tst.l	current_source(a5)
		beq	cant_from_terminal

		movea.l	a0,a1
		suba.l	a0,a0
		moveq	#0,d1
		tst.w	d0
		beq	set_onintr

		cmpi.b	#'-',(a1)
		bne	onintr_label

		tst.b	1(a1)
		bne	onintr_label

		subq.l	#1,a0
		bra	set_onintr

onintr_label:
		movea.l	a1,a0
		bsr	search_label
		bne	return
set_onintr:
		movea.l	current_source(a5),a1
		move.l	a0,SOURCE_ONINTR_POINTER(a1)
		move.l	d1,SOURCE_ONINTR_LINENO(a1)
		bra	success


cant_from_terminal:
		lea	msg_cant_from_terminal,a0
		bra	command_error
*****************************************************************
search_label:
		* D2 := 探すラベル名の長さ
		move.l	#MAXLABELLEN,d2
		bsr	strlen
		cmp.l	d2,d0
		bhs	search_label_1

		move.l	d0,d2
search_label_1:
		movea.l	a0,a1
		movea.l	current_source(a5),a0
		movea.l	a0,a3
		adda.l	SOURCE_SIZE(a0),a3
		lea	SOURCE_HEADER_SIZE(a0),a0
		moveq	#0,d1				*  D1 : 行番号
search_label_loop:
search_label_skip_space:
		cmpa.l	a3,a0
		bhs	no_label

		move.b	(a0)+,d0
		cmp.b	#LF,d0
		bne	search_label_skip_space_1

		addq.l	#1,d1
search_label_skip_space_1:
		bsr	isspace
		beq	search_label_skip_space

		subq.l	#1,a0
		movea.l	a0,a2
		bsr	strspc
		exg	a0,a2
		cmpa.l	a0,a2
		beq	search_label_continue

		cmpi.b	#':',-(a2)
		bne	search_label_continue

		move.l	a2,d0
		sub.l	a0,d0				*  D0 : このラベル名の長さ
		cmp.l	#MAXLABELLEN,d0
		bls	search_label_compare

		move.l	#MAXLABELLEN,d0
search_label_compare:
		cmp.l	d2,d0
		bne	search_label_continue

		bsr	memcmp
		beq	success
search_label_continue:
		cmpa.l	a3,a0
		bhs	no_label

		cmpi.b	#LF,(a0)+
		bne	search_label_continue

		addq.l	#1,d1
		bra	search_label_loop

no_label:
		movea.l	a1,a0
label_not_found:
		bsr	pre_perror
		lea	msg_nolabel,a0
		bra	enputs1
*****************************************************************
.data

msg_nolabel:			dc.b	'ラベルがありません',0
msg_cant_from_terminal:		dc.b	'標準入力からは制御できません',0
msg_cannot_goto_on_terminal:	dc.b	'標準入力モードでは goto は実行できません',0

.end
