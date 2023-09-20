* b_getopt.s
* This contains built-in command 'getopt'.
*
* Itagaki Fumihiko 02-Sep-93  Create.

.include ../src/fish.h

.xref issjis
.xref jstrchr
.xref strlen
.xref strmove
.xref strfor1
.xref isopt
.xref eputc
.xref eputs
.xref eput_newline
.xref set_status
.xref find_shellvar
.xref get_var_value
.xref set_shellvar
.xref too_many_args
.xref too_long_line
.xref too_many_words
.xref undefined
.xref word_argv

.xref tmpline

.text

****************************************************************
*  Name
*       getopt - 引数並びからオプションとコマンド引数とを分離する
*
*  Synopsis
*       getopt オプション文字列
****************************************************************
.xdef cmd_getopt

cmd_getopt:
		subq.w	#1,d0
		bhi	too_many_args
		beq	cmd_getopt_1

		lea	str_nul,a0
cmd_getopt_1:
		movea.l	a0,a3				*  A3 : オプション文字列
		lea	word_argv,a0
		movea.l	a0,a1
		bsr	find_shellvar
		movea.l	a1,a0
		beq	undefined

		bsr	get_var_value
		movea.l	a0,a1				*  A1 : $argv
		move.l	d0,d1				*  D1.W : $#argv
		lea	tmpline(a5),a2			*  A2 <- $options
		moveq	#0,d2				*  D2.W <- $#options
		move.l	#MAXWORDLISTSIZE,d3		*  D3.L : バッファ容量
		sf	d5				*  D5.B : エラーフラグ
loop1:
		exg	a0,a1
		exg	d0,d1
		bsr	isopt
		exg	d0,d1
		exg	a0,a1
		bne	decode_done
loop2:
		moveq	#0,d0
		move.b	(a1)+,d0
		beq	loop1

		cmp.b	#'-',d0
		beq	invalid

		cmp.b	#':',d0
		beq	invalid

		jsr	issjis
		bne	check

		tst.b	(a1)
		beq	invalid

		lsl.w	#8,d0
		move.b	(a1)+,d0
check:
		movea.l	a3,a0
		bsr	jstrchr
		beq	invalid

		cmp.w	#$100,d0
		blo	check_1

		addq.l	#1,a0
check_1:
		addq.l	#1,a0
		cmpi.b	#':',(a0)
		seq	d4
		bne	store

		tst.b	(a1)
		bne	store

		lea	msg_optarg_requied,a0
		tst.w	d1
		beq	bad

		addq.l	#1,a1
		subq.w	#1,d1
store:
		cmp.w	#MAXWORDS,d2
		bhs	too_many_words

		cmp.w	#$100,d0
		blo	store_1

		subq.l	#1,d3
		blo	too_long_line

		move.w	d0,-(a7)
		lsr.w	#8,d0
		move.b	d0,(a2)+
		move.w	(a7)+,d0
store_1:
		subq.l	#2,d3
		blo	too_long_line

		move.b	d0,(a2)+
		clr.b	(a2)+
		addq.w	#1,d2
		tst.b	d4
		beq	loop2

		movea.l	a1,a0
		jsr	strlen
		addq.l	#1,d0
		sub.l	d0,d3
		blo	too_long_line

		cmp.w	#MAXWORDS,d2
		bhs	too_many_words

		exg	a0,a2
		bsr	strmove
		exg	a0,a2
		addq.w	#1,d2
		bra	loop1

invalid:
		lea	msg_invalid,a0
bad:
		bsr	eputs
		cmp.w	#$100,d0
		blo	bad_1

		move.w	d0,-(a7)
		lsr.w	#8,d0
		bsr	eputc
		move.w	(a7)+,d0
bad_1:
		bsr	eputc
		bsr	eput_newline
		st	d5
		moveq	#'-',d0
		sf	d4
		bra	store

decode_done:
		*  A1 : コマンド引数並び
		*  D1.W : コマンド引数の数
		*  D2.W : $#options
		movea.l	a1,a3
		move.w	d1,d3
		lea	word_options,a0
		lea	tmpline(a5),a1
		move.w	d2,d0
		sf	d1				*  exportしない
		bsr	set_shellvar
		bne	return

		lea	word_argv,a0
		movea.l	a3,a1
		move.w	d3,d0
		bsr	set_shellvar
		bne	return

		tst.b	d5
		beq	success

		moveq	#1,d0
		jsr	set_status
success:
		moveq	#0,d0
return:
		rts
****************************************************************
.data

msg_invalid:		dc.b	'無効なオプション -- ',0
msg_optarg_requied:	dc.b	'オプション引数が必要です -- ',0

word_options:		dc.b	'options'
str_nul:		dc.b	0

.end
