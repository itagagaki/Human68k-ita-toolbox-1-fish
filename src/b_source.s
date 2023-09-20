* b_source.s
* This contains built-in command source.
*
* Itagaki Fumihiko 16-Aug-90  Create.

.include ../src/fish.h
.include ../src/source.h

.xref strfor1
.xref isopt
.xref OpenLoadRun_source
.xref bad_arg
.xref too_few_args
.xref usage

.text

****************************************************************
*  Name
*       source - run shell script on current shell
*
*  Synopsis
*       source [-h] [--] file [arglist]
****************************************************************
.xdef cmd_source

cmd_source:
		moveq	#0,d7			*  D7.B : source flag
		sf	d6			*  D6.B := 0 ... openできなければエラー
decode_opt_loop1:
		jsr	isopt
		bne	decode_opt_done
decode_opt_loop2:
		move.b	(a0)+,d1
		beq	decode_opt_loop1

		cmp.b	#'h',d1
		bne	cmd_source_bad_arg

		moveq	#(1<<SOURCE_FLAGBIT_ONLYLOAD),d7
		st	d6
		bra	decode_opt_loop2

decode_opt_done:
		subq.w	#1,d0
		bcs	cmd_source_too_few_args

		move.w	d0,d1
		movea.l	a0,a1
		jsr	strfor1
		exg	a0,a1
		jsr	OpenLoadRun_source		***!! 再帰 !!***
		moveq	#0,d0
		rts

cmd_source_too_few_args:
		bsr	too_few_args
cmd_source_usage:
		lea	msg_usage,a0
		bra	usage

cmd_source_bad_arg:
		bsr	bad_arg
		bra	cmd_source_usage
****************************************************************
.data

msg_usage:	dc.b	'[-h] [--] {<ファイル名>|-} [<引数リスト>]',0

.end
