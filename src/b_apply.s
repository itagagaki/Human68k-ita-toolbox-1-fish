* b_apply.s
* This contains built-in command apply.
*
* Itagaki Fumihiko 30-Mar-92  Create.

.include doscall.h
.include chrcode.h
.include ../src/fish.h

.xref atou
.xref strlen
.xref strforn
.xref memmovi
.xref wordlistlen
.xref xmalloc
.xref free_current_argbuf
.xref eput_newline
.xref eputs
.xref enputs1
.xref subst_history
.xref ask_yes
.xref do_line_v
.xref perror_command_name
.xref too_few_args
.xref bad_arg
.xref too_large_number
.xref too_long_line
.xref cannot_because_no_memory
.xref usage

.xref current_argbuf
.xref tmpline
.xref command_name

.text

****************************************************************
*  Name
*       apply - apply a command for set of arguments
*
*  Synopsis
*       apply [ -p ] [ -t ] [ -<n> ] <command> [ <arg> ... ]
****************************************************************
.xdef cmd_apply

command_len = -4
trace_mode = command_len-1
prompt_mode = trace_mode-1
pad = prompt_mode-0

cmd_apply:
		link	a6,#pad
		sf	trace_mode(a6)
		sf	prompt_mode(a6)
		move.w	d0,d2				*  D2.W : 引数の数
		moveq	#1,d3				*  D3.L : コマンドあたりの引数の数
parse_option_loop:
		subq.w	#1,d2
		bcs	apply_too_few_args

		cmpi.b	#'-',(a0)
		bne	parse_option_done

		addq.l	#1,a0
		move.b	(a0)+,d0
		cmp.b	#'t',d0
		beq	option_t

		cmp.b	#'p',d0
		beq	option_p

		subq.l	#1,a0
		bsr	atou				*  D1.L <- コマンドあたりの引数の数
		bmi	apply_bad_arg

		tst.b	(a0)+
		bne	apply_bad_arg

		tst.l	d0
		bne	apply_too_large_number

		cmp.l	#MAXWORDS,d1
		bhi	apply_too_large_number

		move.l	d1,d3
		bra	parse_option_loop

option_p:
		st	prompt_mode(a6)
option_t:
		st	trace_mode(a6)
		tst.b	(a0)+
		beq	parse_option_loop
apply_bad_arg:
		bsr	bad_arg
apply_usage:
		lea	msg_usage,a0
		bsr	usage
		bra	apply_return

apply_too_few_args:
		bsr	too_few_args
		bra	apply_usage

apply_too_large_number:
		bsr	too_large_number
		bra	apply_return

cannot_apply:
		lea	msg_apply,a0
		bsr	cannot_because_no_memory
		bra	apply_return

parse_option_done:
		move.w	d2,d0
		addq.w	#1,d0
		bsr	wordlistlen
		move.l	d0,d5
		addq.l	#4,d0
		bsr	xmalloc
		beq	cannot_apply

		movea.l	a0,a1
		movea.l	d0,a0
		move.l	current_argbuf(a5),(a0)
		move.l	a0,current_argbuf(a5)
		addq.l	#4,a0
		movea.l	a0,a3
		move.l	d5,d0
		bsr	memmovi
		movea.l	a3,a0
		bsr	strlen
		move.l	d0,command_len(a6)
		lea	1(a0,d0.l),a2			*  A2 : 引数ポインタ
apply_loop:
		tst.w	d2
		beq	apply_success_return

		movea.l	a3,a0
		lea	tmpline(a5),a1
		move.w	#MAXLINELEN,d1
		st	d0
		bsr	subst_history
		btst	#5,d0
		bne	apply_expect

		btst	#2,d0
		bne	apply_error_return

		btst	#1,d0
		bne	apply_error_return

		btst	#3,d0
		beq	apply_dup_args

		move.w	d3,d0
		movea.l	a2,a0
		bsr	strforn
		movea.l	a0,a2
		bra	dup_done

apply_dup_args:
		cmp.w	d3,d2
		blo	apply_expect

		movea.l	a2,a0
		move.w	d3,d5
		bra	dup_args_continue

dup_args_loop:
		move.b	#' ',(a1)+
		bsr	strlen
		sub.l	d0,d1
		bcs	apply_too_long_line

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		addq.l	#1,a0
dup_args_continue:
		subq.l	#1,d1
		bcs	apply_too_long_line

		dbra	d5,dup_args_loop

		clr.b	(a1)
		movea.l	a0,a2
		move.w	d3,d0
dup_done:
		sub.w	d3,d2
		tst.w	d3
		bne	do_command

		subq.w	#1,d2
do_command:
		tst.b	trace_mode(a6)
		beq	not_prompt

		lea	tmpline(a5),a0
		bsr	eputs

		tst.b	prompt_mode(a6)
		bne	do_prompt

		bsr	eput_newline
		bra	not_prompt

do_prompt:
		bsr	ask_yes
		bmi	apply_success_return
		bne	apply_loop
not_prompt:
		movem.l	d1-d3/a2-a3,-(a7)
		move.l	command_name(a5),-(a7)
		lea	tmpline(a5),a0
		clr.b	d2
		sf	d7
		jsr	do_line_v			*!! 再帰 !!*
		move.l	(a7)+,command_name(a5)
		movem.l	(a7)+,d1-d3/a2-a3
		bra	apply_loop

apply_expect:
		bsr	perror_command_name
		lea	msg_expect_1,a0
		bsr	eputs
		movea.l	a2,a0
		bsr	eputs
		lea	msg_expect_2,a0
		bsr	enputs1
apply_done:
		move.l	d0,-(a7)
		jsr	free_current_argbuf
		move.l	(a7)+,d0
apply_return:
		unlk	a6
		rts

apply_success_return:
		moveq	#0,d0
		bra	apply_done

apply_error_return:
		moveq	#1,d0
		bra	apply_done

apply_too_long_line:
		bsr	too_long_line
		bra	apply_done
****************************************************************
.data

msg_usage:		dc.b	'[ -p ] [ -t ] [ -<n> ] <コマンド> [ <引数> ... ]',0
msg_apply:		dc.b	'applyを実行できません',0
msg_expect_1:		dc.b	"'",0
msg_expect_2:		dc.b	"' 以降の引数が揃っていません",0

.end
