* b_xargs.s
* This contains built-in command xargs.
*
* Itagaki Fumihiko 30-Apr-92  Create.

.include doscall.h
.include chrcode.h
.include ../src/fish.h

.xref issjis
.xref atou
.xref strlen
.xref strcmp
.xref strfor1
.xref memmovi
.xref wordlistlen
.xref eputs
.xref enputs
.xref enputs1
.xref ecputs
.xref eput_newline
.xref echo
.xref getline_stdin
.xref xmalloc
.xref free_current_argbuf
.xref DoSimpleCommand_recurse
.xref perror
.xref perror_command_name
.xref bad_arg
.xref too_long_line
.xref too_long_word
.xref too_many_words
.xref cannot_because_no_memory
.xref usage

.xref mainjmp
.xref stackp
.xref current_argbuf
.xref simple_args
.xref argc
.xref command_name

.text

****************************************************************
*  Name
*       xargs - construct argument list(s) and execute command
*
*  Synopsis
*       xargs [flags] [ command [initial-arguments] ]
*
*       -lnumber
*       -ireplstr
*       -nnumber
*       -t
*       -p
*       -x
*       -ssize
*       -eeofstr
****************************************************************
.xdef cmd_xargs

save_mainjmp = -4
save_stackp = save_mainjmp-4
initial_args = save_stackp-4
initial_args_size = initial_args-4
eofstr = initial_args_size-4
input = eofstr-2
leadargc = input-2
nargs = leadargc-2
eof = nargs-1
trace_mode = eof-1
prompt_mode = trace_mode-1
pad = prompt_mode-1

cmd_xargs:
		link	a6,#pad
		movea.l	a0,a1
		move.w	d0,d2				*  D2.W : 引数の数
		bsr	wordlistlen
		move.l	d0,d3
		addq.l	#4,d0
		bsr	xmalloc
		beq	cannot_xargs_because_no_memory

		movea.l	d0,a0
		move.l	current_argbuf(a5),(a0)
		move.l	a0,current_argbuf(a5)
		addq.l	#4,a0
		move.l	d3,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0

		sf	trace_mode(a6)
		sf	prompt_mode(a6)
		lea	default_eofstr,a1
		move.l	a1,eofstr(a6)
		move.w	#MAXWORDS,nargs(a6)
parse_option_loop:
		subq.w	#1,d2
		bcs	parse_option_done

		cmpi.b	#'-',(a0)
		bne	parse_option_done

		addq.l	#1,a0
		move.b	(a0)+,d0
		cmp.b	#'t',d0
		beq	option_t

		cmp.b	#'p',d0
		beq	option_p

		cmp.b	#'n',d0
		beq	option_n

		cmp.b	#'e',d0
		beq	option_e

		bra	xargs_bad_arg

option_e:
		move.l	a0,eofstr(a6)
		bsr	strfor1
		bra	parse_option_loop

option_n:
		bsr	atou
		bmi	option_n_error
		bne	option_n_error

		tst.b	(a0)+
		bne	xargs_bad_arg

		tst.l	d1
		beq	option_n_error

		cmp.l	#MAXWORDS,d1
		bhi	option_n_error

		move.w	d1,nargs(a6)
		bra	parse_option_loop

option_n_error:
		lea	msg_usage,a0
		bsr	usage
		lea	msg_nargs,a0
		bsr	enputs1
		bra	xargs_return

option_p:
		st	prompt_mode(a6)
option_t:
		st	trace_mode(a6)
		tst.b	(a0)+
		beq	parse_option_loop
xargs_bad_arg:
		bsr	bad_arg
		lea	msg_usage,a0
		bsr	usage
		bra	xargs_return

cannot_xargs_because_no_memory:
		lea	msg_xargs,a0
		bsr	cannot_because_no_memory
		bra	xargs_return

parse_option_done:
		move.w	d2,d0
		addq.w	#1,d0
		bne	command_ok

		lea	default_command,a0
		moveq	#2,d0
command_ok:
		move.w	d0,leadargc(a6)
		move.l	a0,initial_args(a6)
		bsr	wordlistlen
		move.l	d0,initial_args_size(a6)
		sf	eof(a6)
*		clr.w	-(a7)
*		DOS	_DUP
*		addq.l	#2,a7
*		tst.l	d0
*		bmi	xargs_perror

*		move.w	d0,input(a6)
*		clr.w	-(a7)
*		DOS	_CLOSE
*		move.w	#2,(a7)
*		DOS	_DUP
*		addq.l	#2,a7
		move.l	mainjmp(a5),d0
		move.l	d0,save_mainjmp(a6)
		move.l	stackp(a5),d0
		move.l	d0,save_stackp(a6)
		lea	xargs_interrupted(pc),a0
		move.l	a0,mainjmp(a5)
		move.l	a6,-(a7)
		move.l	a7,stackp(a5)
xargs_loop:
		tst.b	eof(a6)
		bne	xargs_success_return

		lea	simple_args(a5),a0
		move.w	#MAXLINELEN,d1
		movea.l	initial_args(a6),a1
		move.l	initial_args_size(a6),d0
		sub.w	d0,d1
		bsr	memmovi
		clr.w	argc(a5)
		move.w	nargs(a6),d5
		bra	xargs_ln_get_continue

xargs_ln_get_loop:
		movea.l	a0,a1
*		move.w	input(a6),d0
		moveq	#0,d0
		bsr	getarg
		bmi	xargs_error_return
		beq	xargs_ln_get_done

		exg	a0,a1
		bsr	strlen
		exg	a0,a1
		cmp.l	#MAXWORDLEN,d0
		bhi	xargs_too_long_word

		movea.l	eofstr(a6),a2
		tst.b	(a2)
		beq	xargs_ln_get_not_eof

		exg	a0,a2
		bsr	strcmp
		exg	a0,a2
		bne	xargs_ln_get_not_eof

		st	eof(a6)
		bra	xargs_ln_get_done

xargs_ln_get_not_eof:
		addq.w	#1,argc(a5)
		cmpi.w	#MAXWORDS,argc(a5)
		bhi	xargs_too_many_words
xargs_ln_get_continue:
		dbra	d5,xargs_ln_get_loop
xargs_ln_get_done:
		tst.w	argc(a5)
		beq	xargs_success_return

		move.w	leadargc(a6),d0
		add.w	d0,argc(a5)
		cmpi.w	#MAXWORDS,argc(a5)
		bhi	xargs_too_many_words

		tst.b	trace_mode(a6)
		beq	not_prompt

		lea	simple_args(a5),a0
		lea	ecputs(pc),a1
		move.w	argc(a5),d0
		bsr	echo
		tst.b	prompt_mode(a6)
		bne	do_prompt

		bsr	eput_newline
		bra	not_prompt

do_prompt:
		bsr	ask_yes
		bmi	xargs_success_return
		bne	xargs_loop
not_prompt:
		move.l	command_name(a5),-(a7)
		lea	simple_args(a5),a0
		moveq	#0,d1
		jsr	DoSimpleCommand_recurse		*!! 再帰 !!*
		move.l	(a7)+,command_name(a5)
		bra	xargs_loop

xargs_success_return:
		moveq	#0,d0
xargs_done:
		addq.l	#4,a7
		move.l	d0,-(a7)
		bsr	resume_hooks
		jsr	free_current_argbuf
		move.l	(a7)+,d0
xargs_return:
		unlk	a6
		rts

xargs_perror:
		move.l	command_name(a5),a0
		bsr	perror
		moveq	#1,d0
		bra	xargs_return

xargs_too_long_word:
		bsr	too_long_word
		bra	xargs_error_return

xargs_too_many_words:
		bsr	too_many_words
xargs_error_return:
		moveq	#1,d0
		bra	xargs_done

xargs_interrupted:
		move.l	(a7)+,a6
		bsr	resume_hooks
		movea.l	stackp(a5),a7
		movea.l	mainjmp(a5),a0
		jmp	(a0)

resume_hooks:
		move.l	d0,-(a7)
*		clr.w	-(a7)
*		DOS	_CLOSE
*		move.w	input(a6),(a7)
*		DOS	_DUP
*		DOS	_CLOSE
*		addq.l	#2,a7
		move.l	save_mainjmp(a6),d0
		move.l	d0,mainjmp(a5)
		move.l	save_stackp(a6),d0
		move.l	d0,stackp(a5)
		move.l	(a7)+,d0
		rts
****************************************************************
getarg:
		link	a6,#-2
		movem.l	d2-d5/a1,-(a7)
		movea.l	a0,a1
		move.w	d0,d5				*  D5.W : 入力ハンドル
		sf	d2				*  D2.B : 入力有フラグ
		clr.b	d3				*  D3.B : クォートフラグ
		sf	d4				*  D4.b : \ フラグ
getarg_loop:
		move.l	#1,-(a7)
		pea	-2(a6)
		move.w	d5,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	getarg_eof
		beq	getarg_eof

		move.b	-2(a6),d0
getarg_cmp:
		cmp.b	#CR,d0
		beq	getarg_CR

		tst.b	d4
		bne	getarg_insert

		cmp.b	#LF,d0
		beq	getarg_LF

		tst.b	d3
		bne	getarg_in_quote

		cmp.b	#$20,d0
		beq	getarg_blank

		cmp.b	#HT,d0
		beq	getarg_blank

		cmp.b	#'"',d0
		beq	getarg_quote

		cmp.b	#"'",d0
		beq	getarg_quote

		cmp.b	#'\',d0
		bne	getarg_insert

		st	d4
		bra	getarg_loop

getarg_in_quote:
		cmp.b	d3,d0
		bne	getarg_insert
getarg_quote:
		eor.b	d0,d3
		bra	getarg_inserted

getarg_insert:
		subq.w	#1,d1
		bcs	getarg_over

		move.b	d0,(a0)+
		bsr	issjis
		bne	getarg_inserted

		move.l	#1,-(a7)
		pea	-2(a6)
		move.w	d5,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	getarg_eof
		beq	getarg_eof

		subq.w	#1,d1
		bcs	getarg_over

		move.b	-2(a6),d0
		move.b	d0,(a0)+
getarg_inserted:
		st	d2
		sf	d4
		bra	getarg_loop

getarg_CR:
		move.l	#1,-(a7)
		pea	-2(a6)
		move.w	d5,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	getarg_eof
		beq	getarg_eof

		move.b	-2(a6),d0
		cmp.b	#LF,d0
		beq	getarg_CRLF

		subq.w	#1,d1
		bcs	getarg_over

		move.b	#CR,(a0)+
		st	d2
		sf	d4
		bra	getarg_cmp

getarg_CRLF:
		tst.b	d4
		beq	getarg_LF

		subq.w	#1,d1
		bcs	getarg_over

		move.b	#CR,(a0)+
		bra	getarg_insert

getarg_LF:
		tst.b	d3
		bne	getarg_missing_quote
getarg_blank:
		tst.b	d2
		beq	getarg_loop

		subq.w	#1,d1
		bcs	getarg_over

		clr.b	(a0)+
getarg_return:
		movem.l	(a7)+,d2-d5/a1
		unlk	a6
		tst.b	d0
		rts

getarg_eof:
		moveq	#0,d0
		bra	getarg_return

getarg_over:
		bsr	too_long_line
		bra	getarg_error_return

getarg_missing_quote:
		bsr	perror_command_name
		move.l	a0,-(a7)
		lea	msg_missing_quote,a0
		bsr	eputs
		movea.l	(a7)+,a0
		move.l	a0,d0
		sub.l	a1,d0
		move.l	d0,-(a7)
		move.l	a1,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		bsr	eput_newline
getarg_error_return:
		moveq	#-1,d0
		bra	getarg_return
****************************************************************
.xdef ask_yes

ASKBUFSIZE = 32
askbuf = -ASKBUFSIZE

ask_yes:
		link	a6,#askbuf
		movem.l	d1/a0-a1,-(a7)
		lea	str_xarg_prompt,a0
		bsr	eputs
		lea	askbuf(a6),a0
		moveq	#ASKBUFSIZE-1,d1
		suba.l	a1,a1
		bsr	getline_stdin
		bne	ask_yes_return

		cmpi.b	#'y',askbuf(a6)
		beq	ask_yes_return

		moveq	#1,d0
ask_yes_return:
		movem.l	(a7)+,d1/a0-a1
		unlk	a6
		rts
****************************************************************
.data

default_command:	dc.b	'~~/echo',0,'-',0
default_eofstr:		dc.b	'_',0
msg_usage:		dc.b	'[ <オプション> ] [ <コマンド> [ <引数並び> ] ]',0
msg_nargs:		dc.b	'単語数の指定は1以上2048以下でなければなりません',0
msg_xargs:		dc.b	'xargsを実行できません',0
msg_missing_quote:	dc.b	'クオートが閉じていない？: ',0
str_xarg_prompt:	dc.b	' ?... ',0

.end
裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹裹