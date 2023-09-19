* b_printf.s
* This contains built-in command printf.
*
* Itagaki Fumihiko 11-Jul-91  Create.

.include chrcode.h

.xref isdigit
.xref isodigit
.xref issjis
.xref itoa
.xref utoa
.xref utoao
.xref utoaxl
.xref utoaxu
.xref atou
.xref scan_octal
.xref scan_hexa_decimal
.xref strfor1
.xref expand_wordlist
.xref strip_quotes
.xref words_to_line
.xref putc
.xref eputc
.xref printfi
.xref printfs
.xref expression
.xref basic_escape_sequence
.xref too_few_args
.xref command_error

.xref msg_badly_placed_paren

.xref tmpargs

.text

****************************************************************
* compile_esch - エスケープ文字をコンパイルする
*
* CALL
*      A0     文字列の先頭アドレス（上書きされる）
*
* RETURN
*      D0.L   文字（バイト）数
****************************************************************
.xdef compile_esch

compile_esch:
		movem.l	a0-a1,-(a7)
		movea.l	a0,a1
compile_esch_loop:
		move.b	(a0)+,d0
		beq	compile_esch_done

		cmp.b	#'\',d0
		bne	compile_esch_not_escape

		move.b	(a0)+,d0
		beq	compile_esch_done

		bsr	basic_escape_sequence
		beq	compile_esch_escape_0

		cmp.b	#'x',d0
		beq	compile_esch_escape_hex

		bsr	isodigit
		bne	compile_esch_not_escape

		subq.l	#1,a0
		moveq	#2,d0
		bsr	scan_octal
		bra	compile_esch_dup1

compile_esch_escape_hex:
		moveq	#2,d0
		bsr	scan_hexa_decimal
		bra	compile_esch_dup1

compile_esch_escape_0:
		cmp.b	#LF,d0
		bne	compile_esch_dup1

		move.b	#CR,(a1)+
		bra	compile_esch_dup1

compile_esch_not_escape:
		bsr	issjis
		bne	compile_esch_dup1

		move.b	d0,(a1)+
		move.b	(a0)+,d0
		beq	compile_esch_done
compile_esch_dup1:
		move.b	d0,(a1)+
		bra	compile_esch_loop

compile_esch_done:
		clr.b	(a1)
		move.l	a1,d0
		movem.l	(a7)+,a0-a1
		sub.l	a0,d0
		rts
****************************************************************
* preparse_fmtout - 書式制御文字列の%の次から変換文字までを評価する
*
* CALL
*      D0.B   0ならば最小フィールド幅と精度に‘*’形式を認めない
*      D7.L   下位：書式制御文字列のA0からの残りバイト数
*             上位：引数の数（D0.B != 0 のときのみ）
*      A3     書式制御文字列の、%の次のアドレス
*      A4     引数の先頭アドレス（D0.B != 0 のときのみ）
*
* RETURN
*      D0.L   最下位バイト：変換操作記号．上位は破壊
*      D1.L   フラグ（bit0:'-', bit1:'+', bit2:' '）
*      D2.B   最下位バイト：pad文字．上位は0
*      D3.L   最小フィールド幅．省略=0
*      D4.L   精度．省略=0
*      D5.B   $00:精度指定なし，$FF:精度指定あり
*      D6.B   $00:#フラグなし，$FF:#フラグあり
*      D7.L   下位：書式制御文字列のA0からの残りバイト数
*             上位：残り引数の数（D0.B != 0 のときのみ）
*      A3     書式制御文字列の、変換記号の次のアドレス
*      A4     引数の先頭アドレス（D0.B != 0 のときのみ）
*      CCR    NZならアボート．このときMIならば書式不完全，PLならば引数が不足
****************************************************************
.xdef preparse_fmtout

allow_asterisk = -1
pad = allow_asterisk-1

preparse_fmtout:
		link	a6,#pad
		move.b	d0,allow_asterisk(a6)
		moveq	#0,d1				*  D1.L : flags - 右詰め, 正数に符号なし
		moveq	#' ',d2				*  D2.B : pad character - ' '
		moveq	#0,d3				*  D3.L : minimum field width
		moveq	#0,d4				*  D4.L : 精度
		sf	d5				*  D5.B : 精度指定の有無
		sf	d6				*  D6.B : #フラグの有無
	*
	*  optional flag character
	*
fmtout_flag_loop:
		subq.w	#1,d7
		bcs	preparse_abort

		move.b	(a3)+,d0
		cmp.b	#'-',d0
		beq	fmtout_minus

		cmp.b	#'+',d0
		beq	fmtout_plus

		cmp.b	#' ',d0
		beq	fmtout_space

		cmp.b	#'0',d0
		beq	fmtout_zero

		cmp.b	#'#',d0
		bne	fmtout_flag_ok

		st	d6
		bra	fmtout_flag_loop

fmtout_space:
		bset	#2,d1
		bra	fmtout_flag_loop

fmtout_plus:
		bset	#1,d1
		bra	fmtout_flag_loop

fmtout_minus:
		bset	#0,d1
		bra	fmtout_flag_loop

fmtout_zero:
		move.b	d0,d2
		bra	fmtout_flag_loop

fmtout_flag_ok:
	*
	*  optional minimum field width
	*
		tst.b	allow_asterisk(a6)
		beq	not_asterisk_width

		cmp.b	#'*',d0
		bne	not_asterisk_width

		swap	d7
		tst.w	d7
		beq	preparse_too_few_args

		bsr	fmtout_expression
		bne	preparse_abort

		swap	d7
		move.l	d0,d3
		bra	test_width

not_asterisk_width:
		bsr	isdigit
		bne	fmtout_no_width

		lea	-1(a3),a0
		exg	d1,d3
		bsr	atou
		exg	d1,d3
		move.l	a0,d0
		sub.l	a3,d0
		sub.w	d0,d7
		movea.l	a0,a3
test_width:
		tst.l	d3
		bpl	test_width_ok

		moveq	#0,d3
test_width_ok:
		subq.w	#1,d7
		bcs	preparse_abort

		move.b	(a3)+,d0
fmtout_no_width:
	*
	*  optional precision
	*
		cmp.b	#'.',d0
		bne	precision_ok

		st	d5

		subq.w	#1,d7
		bcs	preparse_abort

		move.b	(a3)+,d0
		tst.b	allow_asterisk(a6)
		beq	precision_not_asterisk

		cmp.b	#'*',d0
		bne	precision_not_asterisk

		swap	d7
		tst.w	d7
		beq	preparse_too_few_args

		bsr	fmtout_expression
		bne	preparse_abort

		swap	d7
		move.l	d0,d4
		bra	test_precision

precision_not_asterisk:
		bsr	isdigit
		bne	precision_ok

		lea	-1(a3),a0
		exg	d1,d4
		bsr	atou
		exg	d1,d4
		move.l	a0,d0
		sub.l	a3,d0
		sub.w	d0,d7
		movea.l	a3,a0
test_precision:
		tst.l	d4
		bpl	test_precision_ok

		moveq	#0,d4
test_precision_ok:
		subq.w	#1,d7
		bcs	preparse_abort

		move.b	(a3)+,d0
precision_ok:
		cmp.b	d0,d0
preparse_return:
		unlk	a6
		rts

preparse_too_few_args:
		bsr	too_few_args
		bra	preparse_return

preparse_abort:
		moveq	#-1,d0
		bra	preparse_return
****************
fmtout_expression:
		movem.l	d1,-(a7)
		exg	a0,a4
		bsr	expression
		exg	a0,a4
		exg	d0,d1
		movem.l	(a7)+,d1
		rts
****************************************************************
*  Name
*       printf - print with formatting
*
*  Synopsis
*       printf [ -2 ] [ - ] format [ word | ( expression ) ] ...
****************************************************************
.xdef cmd_printf

cmd_printf:
		lea	putc(pc),a1
decode_opt_loop1:
		subq.w	#1,d0
		bcs	too_few_args

		movea.l	a0,a3
		cmpi.b	#'-',(a0)+
		bne	decode_opt_done

		tst.b	(a0)+
		beq	decode_opt_done0

		subq.l	#1,a0
decode_opt_loop2:
		move.b	(a0)+,d7
		beq	decode_opt_loop1

		cmp.b	#'2',d7
		bne	decode_opt_done

		lea	eputc(pc),a1
		bra	decode_opt_loop2

decode_opt_done:
		movea.l	a3,a0
		addq.w	#1,d0
decode_opt_done0:
		move.w	d0,d7
		beq	too_few_args

		movea.l	a0,a3				*  A3 : format
		bsr	strfor1
		movea.l	a0,a4				*  A4 : args
		movea.l	a3,a0
		bsr	strip_quotes
		bsr	compile_esch
		subq.w	#1,d7
		swap	d7				*  upper D7 : 残りの引数の数
		move.w	d0,d7				*  lower D7 : format の長さ
********************************
printf_loop:
		subq.w	#1,d7
		bcs	printf_done

		move.b	(a3)+,d0
		cmp.b	#'%',d0
		beq	printf_fmtout

		jsr	(a1)
		bra	printf_loop

printf_fmtout:
		st	d0				*  最小フィールド幅，精度に‘*’形式あり
		bsr	preparse_fmtout
		bmi	printf_done
		bne	printf_return

		swap	d7
		cmp.b	#'%',d0
		beq	fmtout_character_d0

		cmp.b	#'c',d0
		beq	fmtout_character

		cmp.b	#'s',d0
		beq	fmtout_string

		suba.l	a2,a2				*  prefixなし
		lea	itoa(pc),a0
		cmp.b	#'d',d0
		beq	fmtout_integral

		cmp.b	#'i',d0
		beq	fmtout_integral

		lea	utoa(pc),a0
		cmp.b	#'u',d0
		beq	fmtout_integral

		lea	prefix_octal,a2
		lea	utoao(pc),a0
		cmp.b	#'o',d0
		beq	fmtout_integral

		lea	prefix_hex_lower,a2
		lea	utoaxl(pc),a0
		cmp.b	#'x',d0
		beq	fmtout_integral

		lea	prefix_hex_upper,a2
		lea	utoaxu(pc),a0
		cmp.b	#'X',d0
		beq	fmtout_integral
printf_continue:
		swap	d7
		bra	printf_loop
****************
fmtout_integral:
		tst.w	d7
		beq	too_few_args

		bsr	fmtout_expression
		bne	printf_return

		tst.b	d5
		bne	fmtout_integral_prec_ok

		moveq	#1,d4
fmtout_integral_prec_ok:
		tst.b	d6
		bne	fmtout_integral_prefix_ok

		suba.l	a2,a2
fmtout_integral_prefix_ok:
		bsr	printfi
		bra	printf_continue
****************
fmtout_character:
		tst.w	d7
		beq	too_few_args

		bsr	fmtout_expression
		bne	printf_return
fmtout_character_d0:
		link	a6,#-2
		lea	-2(a6),a0
		move.b	d0,(a0)
		clr.b	1(a0)
		moveq	#-1,d4
		bsr	printfs
		unlk	a6
		bra	printf_continue
****************
fmtout_string:
		tst.w	d7
		beq	too_few_args

		move.b	(a4),d0
		beq	fmtout_string_ok

		tst.b	1(a4)
		bne	fmtout_string_ok

		cmp.b	#'(',d0
		beq	fmtout_string_bad

		cmp.b	#')',d0
		beq	fmtout_string_bad
fmtout_string_ok:
		move.l	a1,-(a7)
		movea.l	a4,a1
		lea	tmpargs,a0		*  tmpargs に
		moveq	#1,d0
		bsr	expand_wordlist		*  単語を置換展開する
		movea.l	(a7)+,a1
		bmi	printf_return

		bsr	words_to_line
		tst.b	d5
		bne	do_fmtout_string

		moveq	#-1,d4
do_fmtout_string:
		bsr	printfs
		movea.l	a4,a0
		bsr	strfor1
		movea.l	a0,a4
		subq.w	#1,d7
		bra	printf_continue

fmtout_string_bad:
		lea	msg_badly_placed_paren,a0
		bra	command_error

printf_done:
		moveq	#0,d0
printf_return:
		rts
****************************************************************
.data

prefix_octal:		dc.b	'0',0
prefix_hex_lower:	dc.b	'0x',0
prefix_hex_upper:	dc.b	'0X',0

.end
