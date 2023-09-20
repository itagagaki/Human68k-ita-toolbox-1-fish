* b_time.s
* This contains built-in command 'time', 'noabort' and 'cmd'.
*
* Itagaki Fumihiko 22-Dec-90  Create.

.include chrcode.h

.xref strfor1
.xref memmovi
.xref isopt
.xref copy_wordlist
.xref report_time
.xref alloc_new_argbuf
.xref free_current_argbuf
.xref DoSimpleCommand_recurse_2
.xref cannot_run_command_because_no_memory
.xref too_few_args
.xref bad_arg
.xref usage

.xref shell_timer_high
.xref shell_timer_low
.xref argc
.xref simple_args

.text

****************************************************************
*  Name
*       time - report timer
*
*  Synopsis
*       time time [command]
****************************************************************
.xdef cmd_time

cmd_time:
		move.l	shell_timer_high(a5),d3
		move.l	shell_timer_low(a5),d2
		tst.w	d0
		bne	cmd_time_recurse

		jmp	report_time			*  0 で帰る

cmd_time_recurse:
		moveq	#1,d1
recurse2:
		movea.l	a0,a1
recurse3:
		jsr	DoSimpleCommand_recurse_2	*** 再帰 ***
		moveq	#0,d0
		rts
****************************************************************
*  Name
*       noabort
*
*  Synopsis
*       noabort command
****************************************************************
.xdef cmd_noabort

cmd_noabort:
		tst.w	d0
		beq	cmd_noabort_too_few_args

		moveq	#2,d1
		bra	recurse2

cmd_noabort_too_few_args:
		bsr	too_few_args
		lea	msg_noabort_usage,a0
		bra	usage
****************************************************************
*  Name
*       cmd
*
*  Synopsis
*       cmd [-a|-f|-i[<str>]] [-dert] [--] command
****************************************************************
.xdef cmd_cmd

cmd_cmd:
		move.b	#$80,d1
		moveq	#0,d3
cmd_cmd_parse_option_loop1:
		bsr	isopt
		bne	cmd_cmd_parse_option_done
cmd_cmd_parse_option_loop2:
		move.b	(a0)+,d2
		beq	cmd_cmd_parse_option_loop1

		moveq	#5,d4
		cmp.b	#'d',d2
		beq	cmd_cmd_set_option

		moveq	#6,d4
		cmp.b	#'e',d2
		beq	cmd_cmd_set_option

		moveq	#2,d4
		cmp.b	#'r',d2
		beq	cmd_cmd_set_option

		moveq	#0,d4
		cmp.b	#'t',d2
		beq	cmd_cmd_set_option

		cmp.b	#'a',d2
		beq	cmd_cmd_option_a

		cmp.b	#'f',d2
		beq	cmd_cmd_option_f

		cmp.b	#'i',d2
		beq	cmd_cmd_option_i

		bsr	bad_arg
		bra	cmd_cmd_usage

cmd_cmd_option_a:	*  abort
		bset	#3,d1
		bset	#4,d1
		moveq	#0,d3
		bra	cmd_cmd_parse_option_loop2

cmd_cmd_option_f:	*  force
		bset	#3,d1
		bclr	#4,d1
		moveq	#0,d3
		bra	cmd_cmd_parse_option_loop2

cmd_cmd_option_i:	*  indirect
		bclr	#3,d1
		bset	#4,d1
		move.l	a0,d3
		bsr	strfor1
		bra	cmd_cmd_parse_option_loop1

cmd_cmd_set_option:
		bset	d4,d1
		bra	cmd_cmd_parse_option_loop2

cmd_cmd_parse_option_done:
		tst.w	d0
		beq	cmd_cmd_too_few_args

		tst.l	d3
		beq	recurse2

		move.w	d0,d7
		move.b	d1,d6
		movea.l	a0,a3

		movea.l	d3,a0
		moveq	#1,d0
		bsr	alloc_new_argbuf
		beq	cannot_run_command_because_no_memory

		move.l	a0,-(a7)
		move.l	d1,d0
		jsr	memmovi
		movea.l	(a7)+,a2

		move.w	d7,d0
		move.b	d6,d1
		movea.l	a3,a1
		bsr	recurse3
		jmp	free_current_argbuf

cmd_cmd_too_few_args:
		bsr	too_few_args
cmd_cmd_usage:
		lea	msg_cmd_usage,a0
		bra	usage

.data

msg_noabort_usage:
	dc.b	'<コマンド名> [<引数リスト>]',0

msg_cmd_usage:
	dc.b	'[-a|-f|-i[<文字列>]] [-rdet] [--] <コマンド名> [<引数リスト>]',CR,LF
	dc.b	'     -a             unset hugearg の場合と同等',CR,LF
	dc.b	'     -f             set hugearg=force の場合と同等',CR,LF
	dc.b	'     -i[<文字列>]   set hugearg=(indirect <文字列>) の場合と同等',CR,LF
	dc.b	'     -r             引数リストをHUPAIRエンコードしない',CR,LF
	dc.b	'     -d             作業ディレクトリの変更を受け入れる',CR,LF
	dc.b	'     -e             環境変数の変更を受け入れる',CR,LF
	dc.b	'     -t[<N>]        コマンドが消費した時間を報告する',CR,LF,0

.end
