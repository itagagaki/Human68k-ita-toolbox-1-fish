* foreach.s
* This contains foreach/while/end statement.
*
* Itagaki Fumihiko 19-Apr-91  Create.

.include limits.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/loop.h

.xref strforn
.xref strmove
.xref wordlistlen
.xref copy_wordlist
.xref skip_varname
.xref subst_var_wordlist
.xref expand_wordlist
.xref set_svar
.xref expression
.xref find_history
.xref delete_old_history
.xref xmallocp
.xref xfreep
.xref command_error
.xref syntax_error
.xref too_many_args
.xref expression_syntax_error
.xref cannot_because_no_memory

.xref save_sourceptr
.xref tmpargs

.xref loop_status	*  -2:end待ち(偽), -1:end待ち(真), 1:実行中, 2:実行開始, 3:continue
.xref loop_level
.xref forward_loop_level
.xref loop_stack
.xref if_status
.xref switch_status
.xref in_history_ptr
.xref current_source
.xref exitflag
.xref current_eventno
.xref loop_top_eventno
.xref keep_loop
.xref loop_fail

*****************************************************************
* foreach
*
* loop_status
*	-2		ループの深さのチェックのみ
*	-1		ループの深さのチェックのみ
*	 0		引数を解釈して dup する
*	 1		引数を解釈して dup する
*	 2		最初の単語を set し，loop_status を 1 にする
*	 3		次の単語が無ければ break, あれば set して，loop_status を 1 にする．
*****************************************************************
.xdef state_foreach

state_foreach:
		tst.b	loop_status(a5)
		bmi	continue_read_loops

		cmpi.b	#2,loop_status(a5)
		bhs	continue_foreach

		bsr	while_foreach_init
		bne	return

		movea.l	a0,a2				*  A2 : 変数名の先頭
		bsr	skip_varname
		move.l	a0,d2
		sub.l	a2,d2				*  D2.L : 変数名の長さ
		beq	bad_varname

		tst.b	(a0)+
		bne	bad_varname

		subq.w	#3,d7
		bcs	word_not_parened

		cmpi.b	#'(',(a0)+
		bne	word_not_parened

		tst.b	(a0)+
		bne	word_not_parened

		movea.l	a0,a1				*  A1 : 単語並び（展開前）の先頭
		move.w	d7,d0
		bsr	strforn
		cmpi.b	#')',(a0)+
		bne	word_not_parened

		tst.b	(a0)
		bne	word_not_parened

		lea	tmpargs,a0
		bsr	expand_wordlist
		bmi	return

		move.w	d0,d7
		movea.l	a0,a3
		bsr	wordlistlen
		add.l	d0,d2
		addq.l	#5,d2

		moveq	#0,d0
		move.w	d7,d0
		bsr	set_next_loop
		tst.w	d7
		beq	start_read_loop

		move.l	d2,d0
		bsr	xmallocp
		beq	cannot_alloc_foreach_memory

		movea.l	d0,a0
		move.w	d7,(a0)+
		clr.w	(a0)+
		movea.l	a2,a1
		bsr	strmove
		movea.l	a3,a1
		move.w	d7,d0
		bsr	copy_wordlist
		bra	start_read_loop

continue_foreach:
		bsr	loop_stack_p
		movea.l	LOOPINFO_STORE(a1),a0
		subq.w	#1,(a0)+
		bcs	break_loop

		move.b	#1,loop_status(a5)
		addq.w	#1,(a0)
		move.w	(a0)+,d0
		movea.l	a0,a1
		bsr	strforn
		exg	a0,a1
		moveq	#1,d0
		st	d1
		bra	set_svar

cannot_alloc_foreach_memory:
		lea	msg_cannot_foreach,a0
		bra	cannot_because_no_memory

bad_varname:
		lea	msg_bad_varname,a0
		bra	command_error

word_not_parened:
		lea	msg_word_not_parened,a0
		bra	command_error
*****************************************************************
* while
*
* loop_status
*	-2		ループの深さのチェックのみ
*	-1		ループの深さのチェックのみ
*	 0		引数を評価し，end 待ちモードに
*	 1		引数を評価し，end 待ちモードに
*	 2		何もせず，loop_status を 1 にするのみ
*	 3		引数を評価し，偽なら break，真ならば loop_status を 1 にする
*****************************************************************
.xdef state_while

state_while:
		tst.b	loop_status(a5)
		bmi	continue_read_loops

		cmpi.b	#2,loop_status(a5)
		beq	start_while

		bsr	while_foreach_init
		bne	return

		bsr	expression
		bne	return

		tst.w	d7
		bne	expression_syntax_error

		cmpi.b	#3,loop_status(a5)
		beq	continue_while

		move.l	d1,d0
		bsr	set_next_loop
		bra	start_read_loop

continue_while:
		tst.l	d1
		beq	break_loop
start_while:
		move.b	#1,loop_status(a5)
		bra	success_return
*****************************************************************
while_foreach_init:
		exg	a0,a1
		bsr	subst_var_wordlist
		bmi	return

		move.w	d0,d7
		beq	syntax_error
success_return:
		moveq	#0,d0
return:
		rts
*****************************************************************
set_next_loop:
		addq.w	#1,loop_level(a5)
		tst.b	loop_status(a5)
		bne	set_next_loop_level_ok

		clr.w	loop_level(a5)
set_next_loop_level_ok:
		move.b	#-1,loop_status(a5)
		tst.l	d0
		bne	set_condition_ok

		move.b	#-2,loop_status(a5)
set_condition_ok:
free_loop_store:
		bsr	loop_stack_p
		lea	LOOPINFO_STORE(a1),a0
		bra	xfreep
*****************************************************************
start_read_loop:
		move.w	loop_level(a5),forward_loop_level(a5)
		move.l	current_source(a5),d0
		bne	start_read_loop_source

		tst.l	in_history_ptr(a5)
		bne	start_read_loop_static

		move.l	current_eventno(a5),d0
		subq.l	#1,d0
		move.l	d0,loop_top_eventno(a5)
		tst.w	loop_level(a5)
		beq	success_return

		st	keep_loop(a5)
		sf	loop_fail(a5)
		bra	success_return

start_read_loop_source:
		movea.l	d0,a0
		move.l	SOURCE_LINENO(a0),d0
		subq.l	#1,d0
start_read_loop_static:
		bsr	loop_stack_p
		move.l	save_sourceptr,LOOPINFO_TOPPTR(a1)
		move.l	d0,LOOPINFO_TOPLINENO(a1)
		bra	success_return
*****************************************************************
continue_read_loops:
		lea	msg_too_many_loops,a0
		cmpi.w	#MAXLOOPLEVEL,forward_loop_level(a5)
		beq	command_error

		addq.w	#1,forward_loop_level(a5)
		bra	success_return
*****************************************************************
.xdef state_end

state_end:
		tst.b	loop_status(a5)
		bmi	state_end_just_loop_read
		bne	continue_loop

		tst.b	if_status(a5)
		bne	success_return

		tst.b	switch_status(a5)
		bne	success_return
not_in_loop:
		lea	msg_not_in_while_or_foreach,a0
		bra	command_error

state_end_just_loop_read:
		sf	keep_loop(a5)
		move.w	forward_loop_level(a5),d0
		cmp.w	loop_level(a5),d0
		bhi	state_end_continue_reading

		cmpi.b	#-1,loop_status(a5)
		bne	state_end_not_continue

		bsr	loop_stack_p
		tst.l	current_source(a5)
		beq	state_end_terminal

		movea.l	current_source(a5),a0
		move.l	SOURCE_POINTER(a0),LOOPINFO_BOTPTR(a1)
		move.l	SOURCE_LINENO(a0),LOOPINFO_BOTLINENO(a1)
		bra	start_loop

state_end_terminal:
		tst.l	in_history_ptr(a5)
		bne	state_end_terminal_static

		tst.b	loop_fail(a5)
		bne	loop_too_large

		move.l	loop_top_eventno(a5),d0
		bsr	find_history
		beq	loop_too_large

		move.l	a0,LOOPINFO_TOPPTR(a1)
		clr.l	LOOPINFO_BOTPTR(a1)
		bra	start_loop

state_end_terminal_static:
		move.l	in_history_ptr(a5),LOOPINFO_BOTPTR(a1)
start_loop:
		move.b	#2,loop_status(a5)
		bra	continue_loop_1

state_end_not_continue:
		bsr	not_continue
		bra	success_return

state_end_continue_reading:
		subq.w	#1,forward_loop_level(a5)
		bra	success_return

loop_too_large:
		bsr	abort_loops
		lea	msg_cannot_while_foreach,a0
		bra	cannot_because_no_memory
*****************************************************************
.xdef loop_stack_p

loop_stack_p:
		move.w	loop_level(a5),d1
		mulu	#LOOPINFOSIZE,d1
		lea	loop_stack(a5),a1
		adda.l	d1,a1
		rts
*****************************************************************
continue_loop:
		move.b	#3,loop_status(a5)
continue_loop_1:
		bsr	loop_stack_p
		move.l	LOOPINFO_TOPPTR(a1),d1
		move.l	LOOPINFO_TOPLINENO(a1),d2
set_point:
		moveq	#0,d0
		clr.b	if_status(a5)
		clr.b	switch_status(a5)
		tst.l	current_source(a5)
		beq	set_point_terminal

		movea.l	current_source(a5),a0
		move.l	d1,SOURCE_POINTER(a0)
		move.l	d2,SOURCE_LINENO(a0)
		rts

set_point_terminal:
		move.l	d1,in_history_ptr(a5)
		rts
*****************************************************************
break_loop:
		bsr	free_loop_store
		bsr	not_continue
		move.l	LOOPINFO_BOTPTR(a1),d1
		move.l	LOOPINFO_BOTLINENO(a1),d2
		bra	set_point
*****************************************************************
not_continue:
		tst.w	loop_level(a5)
		beq	clear_status

		subq.w	#1,loop_level(a5)
		move.b	#1,loop_status(a5)
		rts

clear_status:
		clr.l	in_history_ptr(a5)
		clr.b	loop_status(a5)
		sf	keep_loop(a5)
		bra	delete_old_history
*****************************************************************
.xdef cmd_continue

cmd_continue:
		lea	continue_loop(pc),a0
cmd_continue_break:
		tst.w	d0
		bne	too_many_args

		tst.b	loop_status(a5)
		beq	not_in_loop

		sf	exitflag(a5)
		moveq	#0,d0
		jmp	(a0)
*****************************************************************
.xdef cmd_break

cmd_break:
		lea	break_loop(pc),a0
		bra	cmd_continue_break
*****************************************************************
.xdef abort_loops

abort_loops:
		movem.l	d0-d1/a0,-(a7)
		bsr	clear_status
		lea	loop_stack(a5),a0
		addq.l	#8,a0
		moveq	#MAXLOOPLEVEL,d1
clear_loop_stack:
		bsr	xfreep
		lea	LOOPINFOSIZE(a0),a0
		dbra	d1,clear_loop_stack

		movem.l	(a7)+,d0-d1/a0
		rts
*****************************************************************
.data

msg_too_many_loops:		dc.b	'while/foreach のネストが深過ぎます',0
msg_not_in_while_or_foreach:	dc.b	'while/foreach は開始していません',0
msg_bad_varname:		dc.b	'変数名が無効です',0
msg_word_not_parened:		dc.b	'単語並びが()で囲われていません',0
msg_cannot_while_foreach:	dc.b	'while/'
msg_cannot_foreach:		dc.b	'foreach を実行できません',0

.end
