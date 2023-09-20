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
.xref memcmp
.xref strmove
.xref memmovi
.xref strfor1
.xref wordlistlen
.xref isopt
.xref eputs
.xref ecputs
.xref eput_newline
.xref echo
.xref getline_stdin
.xref alloc_new_argbuf
.xref free_current_argbuf
.xref DoSimpleCommand_recurse
.xref command_error
.xref perror_command_name
.xref bad_arg
.xref badly_formed_number
.xref too_long_word
.xref too_many_words
.xref cannot_run_command_because_no_memory
.xref usage

.xref simple_args
.xref argc
.xref command_name
.xref undup_input
.xref undup_output
.xref save_stdin
.xref save_stdout

.text

memmovi_near:
		jmp	memmovi

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
*       -eeofword
****************************************************************
.xdef cmd_xargs

save_mainjmp = -4
save_stackp = save_mainjmp-4
input = save_stackp-2
initial_args = input-4
initial_args_size = initial_args-4
max_args_size = initial_args_size-4
getargbuf = max_args_size-4
replstr = getargbuf-4
replstrlen = replstr-4
eofword = replstrlen-4
count = eofword-4
wordlen = count-4
fixed_argc = wordlen-2
initial_argc = fixed_argc-2
remain = initial_argc-1
eof = remain-1
mode = eof-1			*  default=0, -n=1, -l=2, -i=3
flag_x = mode-1
trace_mode = flag_x-1
prompt_mode = trace_mode-1
lastchar = prompt_mode-1
getcharbuf = lastchar-1
pad = getcharbuf-0

cmd_xargs:
		move.l	d0,d3				*  D3.W : 引数の数
		move.l	#MAXWORDLEN+1,d2
		bsr	alloc_new_argbuf
		beq	cannot_run_command_because_no_memory

		link	a6,#pad
		move.l	a0,-(a7)
		move.l	d1,d0
		bsr	memmovi_near
		move.l	a0,getargbuf(a6)
		movea.l	(a7)+,a0

		sf	trace_mode(a6)
		sf	prompt_mode(a6)
		lea	default_eofword,a1
		move.l	a1,eofword(a6)
		move.l	#MAXWORDLISTSIZE,max_args_size(a6)
		move.l	#MAXWORDLISTSIZE/2+1,count(a6)
		clr.b	mode(a6)
		sf	flag_x(a6)
decode_opt_loop1:
		exg	d0,d3
		jsr	isopt
		exg	d0,d3
		bne	decode_opt_done
decode_opt_loop2:
		move.b	(a0)+,d0
		beq	decode_opt_loop1

		cmp.b	#'t',d0
		beq	option_t

		cmp.b	#'p',d0
		beq	option_p

		cmp.b	#'l',d0
		beq	option_l

		cmp.b	#'i',d0
		beq	option_i

		cmp.b	#'n',d0
		beq	option_n

		cmp.b	#'s',d0
		beq	option_s

		cmp.b	#'e',d0
		beq	option_e

		cmp.b	#'x',d0
		beq	option_x
xargs_bad_arg:
		jsr	bad_arg
xargs_usage:
		lea	msg_usage,a0
		jsr	usage
		bra	xargs_done

option_e:
		move.l	a0,eofword(a6)
nextarg:
		jsr	strfor1
		bra	decode_opt_loop1

option_i:
		move.b	#3,mode(a6)
		move.l	#1,count(a6)
		movea.l	a0,a1
		tst.b	(a1)
		bne	set_replstr

		lea	default_replstr,a1
set_replstr:
		move.l	a1,replstr(a6)
		exg	a0,a1
		jsr	strlen
		exg	a0,a1
		move.l	d0,replstrlen(a6)
		bra	nextarg

option_l:
		move.b	#2,mode(a6)
		tst.b	(a0)
		bne	set_count_1

		moveq	#1,d1
		bra	set_count_2

option_n:
		move.b	#1,mode(a6)
		tst.b	(a0)
		beq	xargs_bad_arg
set_count_1:
		jsr	atou
		beq	set_count_2
		bmi	xargs_badly_formed_number

		move.l	#MAXWORDLISTSIZE/2+1,d1
set_count_2:
		tst.b	(a0)+
		bne	xargs_badly_formed_number

		move.l	d1,count(a6)
		beq	xargs_bad_arg
		bra	decode_opt_loop1

option_s:
		tst.b	(a0)
		beq	xargs_bad_arg

		jsr	atou
		bmi	xargs_badly_formed_number

		tst.b	(a0)+
		bne	xargs_badly_formed_number

		tst.l	d0
		bne	bad_size

		cmp.l	#MAXWORDLISTSIZE,d1
		bhi	bad_size

		move.l	d1,max_args_size(a6)
		bra	decode_opt_loop1

bad_size:
		lea	msg_bad_size,a0
		jsr	command_error
		bra	xargs_usage

xargs_badly_formed_number:
		jsr	badly_formed_number
		bra	xargs_usage

option_p:
		st	prompt_mode(a6)
option_t:
		st	trace_mode(a6)
		bra	decode_opt_loop2

option_x:
		st	flag_x(a6)
		bra	decode_opt_loop2

decode_opt_done:
		move.w	d3,d0
		bne	command_ok

		lea	default_command,a0
		moveq	#2,d0
command_ok:
		cmpi.b	#1,mode(a6)
		bls	flag_x_ok

		st	flag_x(a6)
flag_x_ok:
		move.w	d0,initial_argc(a6)
		move.l	a0,initial_args(a6)
		jsr	wordlistlen
		move.l	d0,initial_args_size(a6)
		sf	remain(a6)
		sf	eof(a6)

		clr.w	input(a6)
		move.l	undup_input(a5),d0
		bmi	xargs_loop_2

		move.w	d0,input(a6)
xargs_loop_1:
		clr.w	-(a7)				*  標準入力は
		DOS	_CLOSE				*  クローズしておく．
		addq.l	#2,a7				*  そうしないと ^C や ^S が効かない．
xargs_loop_2:
		clr.w	argc(a5)
		clr.w	fixed_argc(a6)
		move.l	max_args_size(a6),d1
		cmpi.b	#3,mode(a6)
		beq	get_args_start

		move.l	initial_args_size(a6),d0
		sub.l	d0,d1
		blo	xargs_size_over

		lea	simple_args(a5),a0
		movea.l	initial_args(a6),a1
		bsr	memmovi_near
		move.l	count(a6),d5
get_args_start:
get_args_loop:
		movea.l	getargbuf(a6),a1
		tst.b	remain(a6)
		bne	add_remain_arg

		tst.b	eof(a6)
		bne	get_args_eof

		sf	d2				*  D2.B : 入力有フラグ
		clr.b	d3				*  D3.B : クォートフラグ
		sf	d4				*  D4.B : \ フラグ
		move.l	#MAXWORDLEN,d6
getarg_loop:
		bsr	getarg_getchar
		bmi	getarg_eof
getarg_cmp:
		tst.b	d0
		beq	getarg_nul

		cmp.b	#CR,d0
		beq	getarg_CR

		tst.b	d4
		bne	getarg_store

		cmp.b	#LF,d0
		beq	getarg_eol

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
		bne	getarg_store

		st	d4
		bra	getarg_loop

getarg_in_quote:
		cmp.b	d3,d0
		bne	getarg_store
getarg_quote:
		eor.b	d0,d3
		bra	getarg_loop

getarg_CR:
		bsr	getarg_getchar
		bmi	getarg_CR_1

		cmp.b	#LF,d0
		beq	getarg_CRLF
getarg_CR_1:
		subq.l	#1,d6
		bcs	xargs_too_long_word

		move.b	#CR,(a1)+
		tst.l	d0
		bmi	getarg_eof

		st	d2
		sf	d4
		bra	getarg_cmp

getarg_CRLF:
		tst.b	d4
		beq	getarg_eol

		subq.l	#1,d6
		bcs	xargs_too_long_word

		move.b	#CR,(a1)+
getarg_store:
		subq.l	#1,d6
		bcs	xargs_too_long_word

		move.b	d0,(a1)+
		jsr	issjis
		bne	getarg_store_1

		bsr	getarg_getchar
		bmi	getarg_eof

		tst.b	d0
		beq	getarg_nul

		subq.l	#1,d6
		bcs	xargs_too_long_word

		move.b	d0,(a1)+
getarg_store_1:
		st	d2
		sf	d4
		bra	getarg_loop

getarg_blank:
		cmpi.b	#3,mode(a6)
		bne	getarg_word_separator

		tst.b	d2
		beq	getarg_loop
		bra	getarg_store

getarg_eof:
		cmpi.b	#2,mode(a6)
		bhs	xargs_done_0

		st	eof(a6)
		tst.b	d2
		beq	get_args_eof
getarg_nul:
getarg_eol:
		tst.b	d3
		bne	missing_quote
getarg_word_separator:
		tst.b	d2
		beq	getarg_loop

		clr.b	(a1)+
		move.b	d0,lastchar(a6)
		move.l	a1,d6
		movea.l	getargbuf(a6),a1
		sub.l	a1,d6
		movea.l	eofword(a6),a2
		tst.b	(a2)
		beq	check_add_one_arg

		exg	a0,a2
		jsr	strcmp
		exg	a0,a2
		bne	check_add_one_arg

		*  CON対策
		move.b	lastchar(a6),d0
getarg_drop_inpline:
		cmp.b	#LF,d0
		beq	getarg_drop_inpline_done

		bsr	getarg_getchar
		bpl	getarg_drop_inpline
getarg_drop_inpline_done:
		cmpi.b	#2,mode(a6)
		bhs	xargs_done_0

		st	eof(a6)
get_args_eof:
		tst.w	fixed_argc(a6)
		beq	xargs_done_0
		bra	get_args_done

check_add_one_arg:
		*cmpi.b	#2,mode(a6)
		*bhs	add_one_arg
		*  mode(a6)>=2 なら必ず flag_x(a6)!=0

		tst.b	flag_x(a6)
		bne	add_one_arg

		cmp.l	d6,d1
		bhs	add_one_arg

		tst.w	fixed_argc(a6)
		beq	add_one_arg

		st	remain(a6)
		move.l	d6,wordlen(a6)
		bra	get_args_done

insert_arg:
		subq.l	#1,d6
		lea	simple_args(a5),a2
		movea.l	initial_args(a6),a1
		move.w	initial_argc(a6),d2
		move.w	d2,argc(a5)
		bra	insert_arg_continue

insert_arg_loop:
		movea.l	replstr(a6),a0
		move.l	replstrlen(a6),d0
		jsr	memcmp
		bne	insert_arg_dup

		sub.l	d6,d1
		blo	xargs_size_over

		move.l	a1,-(a7)
		movea.l	getargbuf(a6),a1
		move.l	d6,d0
		movea.l	a2,a0
		bsr	memmovi_near
		movea.l	a0,a2
		movea.l	(a7)+,a1
		adda.l	replstrlen(a6),a1
		bra	insert_arg_loop

insert_arg_dup:
		subq.l	#1,d1
		blo	xargs_size_over

		move.b	(a1)+,d0
		move.b	d0,(a2)+
		beq	insert_arg_continue

		jsr	issjis
		bne	insert_arg_loop

		subq.l	#1,d1
		blo	xargs_size_over

		move.b	(a1)+,d0
		move.b	d0,(a2)+
		bne	insert_arg_loop
insert_arg_continue:
		dbra	d2,insert_arg_loop
		bra	compound_args_ok

add_remain_arg:
		move.l	wordlen(a6),d6
add_one_arg:
		cmpi.b	#3,mode(a6)
		beq	insert_arg

		sub.l	d6,d1
		blo	xargs_size_over

		jsr	strmove
		addq.w	#1,argc(a5)
		sf	remain(a6)
		cmpi.w	#MAXWORDS,argc(a5)
		bhi	xargs_too_many_words

		cmpi.b	#1,mode(a6)
		bls	get_args_continue

		cmpi.b	#LF,lastchar(a6)
		bne	get_args_loop
get_args_continue:
		move.w	argc(a5),fixed_argc(a6)
		subq.l	#1,d5
		bne	get_args_loop
get_args_done:
		move.w	fixed_argc(a6),argc(a5)
		move.w	initial_argc(a6),d0
		add.w	d0,argc(a5)
		cmpi.w	#MAXWORDS,argc(a5)
		bhi	xargs_too_many_words
compound_args_ok:
		tst.b	trace_mode(a6)
		beq	not_prompt

		lea	simple_args(a5),a0
		move.w	argc(a5),d0
		move.b	prompt_mode(a6),d1
		bsr	ask_yes
		bmi	xargs_done_error
		bne	xargs_loop_2
not_prompt:
		move.l	undup_input(a5),d0
		bmi	do_command

		clr.w	-(a7)
		move.w	d0,-(a7)
		DOS	_DUP2
		addq.l	#4,a7
do_command:
		move.l	command_name(a5),-(a7)
		lea	simple_args(a5),a0
		moveq	#0,d1
		jsr	DoSimpleCommand_recurse		*!! 再帰 !!*
		move.l	(a7)+,command_name(a5)
		tst.l	undup_input(a5)
		bmi	xargs_loop_2
		bra	xargs_loop_1

xargs_done_0:
		moveq	#0,d0
xargs_done:
		move.l	d0,-(a7)
		jsr	free_current_argbuf
		move.l	(a7)+,d0
		unlk	a6
		rts

missing_quote:
		jsr	perror_command_name
		lea	msg_missing_quote,a0
		jsr	eputs
		move.l	a1,d0
		movea.l	getargbuf(a6),a1
		sub.l	a1,d0
		move.l	d0,-(a7)
		move.l	a1,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		jsr	eput_newline
xargs_done_error:
		moveq	#1,d0
		bra	xargs_done

xargs_too_long_word:
		jsr	too_long_word
		bra	xargs_done

xargs_size_over:
		lea	msg_size_over,a0
		jsr	command_error
		bra	xargs_done

xargs_too_many_words:
		jsr	too_many_words
		bra	xargs_done
****************************************************************
getarg_getchar:
		move.l	#1,-(a7)
		pea	getcharbuf(a6)
		move.w	input(a6),-(a7)
		DOS	_READ
		lea	10(a7),a7
		neg.l	d0
		bpl	getarg_getchar_eof

		moveq	#0,d0
		move.b	getcharbuf(a6),d0
		tst.l	d0
		rts

getarg_getchar_eof:
		moveq	#-1,d0
		rts
****************************************************************
.xdef ask_yes

ASKBUFSIZE = 32
askbuf = -ASKBUFSIZE

ask_yes:
		link	a6,#askbuf
		movem.l	d1/a0-a2,-(a7)
		lea	ecputs,a1
		jsr	echo
		tst.b	d1
		beq	ask_yes_ok

		tst.l	undup_output(a5)
		bmi	ask_yes_output_ok

		*  標準出力が切り換えられている．
		*  このままだとエコーバックが切り換え先に流れてしまうので，
		*  一時的に unredirect しておく．
		move.l	save_stdout(a5),d0
		move.w	#1,-(a7)
		move.w	d0,-(a7)
		DOS	_DUP2
		addq.l	#4,a7
ask_yes_output_ok:
		lea	ask_yes_prompt,a0
		jsr	eputs
		lea	askbuf(a6),a0
		moveq	#ASKBUFSIZE-1,d1
		suba.l	a1,a1
		movea.l	a0,a2
		bsr	getline_stdin

		move.l	d0,-(a7)
		move.l	undup_output(a5),d0
		bmi	ask_yes_redirect_ok

		*  redirect を元に戻す．
		move.w	#1,-(a7)
		move.w	d0,-(a7)
		DOS	_DUP2
		addq.l	#4,a7
ask_yes_redirect_ok:
		move.l	(a7)+,d0
		bne	ask_yes_return

		cmpi.b	#'y',askbuf(a6)
		beq	ask_yes_return

		moveq	#1,d0
ask_yes_return:
		movem.l	(a7)+,d1/a0-a2
		unlk	a6
		rts

ask_yes_ok:
		jsr	eput_newline
		moveq	#0,d0
		bra	ask_yes_return
****************************************************************
.data

default_command:	dc.b	'~~/echo',0,'--',0
default_replstr:	dc.b	'{}',0
default_eofword:	dc.b	'_',0

msg_usage:	dc.b	'[ -n<単語数> | -l[<行数>] | -i[<被置換文字列>] ]',CR,LF
		dc.b	'          [-tpx] [-s<サイズ>] [-e[<EOF単語>]] [--]',CR,LF
		dc.b	'          [ <コマンド名> [<引数リスト>] ]',CR,LF,0

msg_bad_size:		dc.b	'<サイズ>は4096以下でなければなりません',0
msg_size_over:		dc.b	'コマンド行の長さがサイズの限度を超えました',0
msg_missing_quote:	dc.b	'クオートが閉じていない？: ',0
ask_yes_prompt:		dc.b	' ?... ',0

.end
