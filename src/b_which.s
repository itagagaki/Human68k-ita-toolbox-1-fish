* b_which.s
* This contains built-in command 'which'.
*
* Itagaki Fumihiko 16-Feb-91  Create.

.include chrcode.h
.include limits.h

.xref strfor1
.xref strlen
.xref strcpy
.xref puts
.xref nputs
.xref cputs
.xref put_space
.xref search_command_0
.xref search_command
.xref findvar
.xref find_function
.xref list_1_function
.xref print_alias_value
.xref usage
.xref too_few_args

.xref word_alias
.xref word_function

.xref alias_top
.xref function_root
.xref flag_noalias

.text

****************************************************************
print_name_is:
		move.l	a0,-(a7)
		movea.l	a1,a0
		bsr	cputs
		lea	msg_is,a0
		bsr	puts
		movea.l	(a7)+,a0
		rts
****************************************************************
*  Name
*       which - コマンドの実体を表示する
*
*  Synopsis
*       which [ -o | -O ] [ -t ] [ -a ] command ...
****************************************************************
.xdef cmd_which

command_name = -(((MAXPATH+1)+1)>>1<<1)

cmd_which:
		move.w	d0,d1
		moveq	#0,d2
		moveq	#0,d3			*  D3 : answer mode
parse_option_loop1:
		subq.w	#1,d1
		bcs	which_too_few_args

		movea.l	a0,a1
		cmpi.b	#'-',(a0)+
		bne	parse_option_done

		tst.b	(a0)
		beq	parse_option_done0
parse_option_loop2:
		move.b	(a0)+,d0
		beq	parse_option_loop1

		cmp.b	#'o',d0
		beq	opt_small_o

		cmp.b	#'O',d0
		beq	opt_large_O

		cmp.b	#'a',d0
		beq	opt_all

		cmp.b	#'t',d0
		beq	opt_type

		cmp.b	#'p',d0
		bne	parse_option_done
opt_path:
		moveq	#-1,d3				*  D3 := -1 ... path or null
		bra	parse_option_loop2

opt_type:
		moveq	#1,d3				*  D3 := 1  ... simple word
		bra	parse_option_loop2

opt_all:
		bset	#2,d2				*  show all
		bra	parse_option_loop2

opt_large_O:
		bset	#1,d2				*  no function/builtin
opt_small_o:
		bset	#0,d2				*  no alias
		bra	parse_option_loop2

parse_option_done0:
		subq.w	#1,d1
		bcs	which_too_few_args

		lea	1(a0),a1
parse_option_done:
		link	a6,#command_name
loop:
		sf	d7
	*
	*  別名か？
	*
		tst.b	flag_noalias(a5)
		bne	not_alias

		btst	#0,d2
		bne	not_alias

		movea.l	alias_top(a5),a0
		bsr	findvar
		beq	not_alias
		*
		*  別名である
		*
		bsr	answer_alias
		btst	#2,d2
		beq	continue
not_alias:
	*
	*  関数か？
	*
		btst	#1,d2
		bne	not_function

		movea.l	a1,a0
		lea	function_root(a5),a2
		bsr	find_function
		beq	not_function
		*
		*  関数である
		*
		bsr	answer_function
		btst	#2,d2
		beq	continue
not_function:
	*
	*  path 検索
	*
		movea.l	a1,a0
		bsr	strlen
		cmp.w	#MAXPATH,d0
		bhi	not_a_file

		moveq	#0,d0
		move.b	d2,d0
		lsr.b	#1,d0				*  bit 0 : ~~無視フラグ
		btst	#2,d2
		bne	search_all_path

		lea	command_name(a6),a0
		exg	a0,a1
		bsr	search_command_0
		exg	a0,a1
		cmp.l	#-1,d0
		beq	not_a_file

		bsr	answer_path
		bra	continue

search_all_path:
		movea.l	a1,a0
		lea	answer_path(pc),a4
		bsr	search_command
not_a_file:
		tst.b	d7
		bne	continue
		*
		*  見つからない
		*
		tst.b	d3
		bne	continue

		bsr	print_name_is
		lea	msg_not_found,a0
		bsr	nputs
continue:
		movea.l	a1,a0
		bsr	strfor1
		movea.l	a0,a1
		dbra	d1,loop

		moveq	#0,d0
		unlk	a6
return:
		rts
****************
answer_alias:
		st	d7
		tst.b	d3
		bmi	return

		lea	word_alias,a0
		bne	nputs

		bsr	print_name_is
		bsr	put_space
		bsr	print_alias_value
		lea	msg_is_aliased,a0
		bra	nputs
****************
answer_function:
		st	d7
		tst.b	d3
		bmi	return

		lea	word_function,a0
		bne	nputs

		move.l	d0,-(a7)
		bsr	print_name_is
		lea	msg_is_function,a0
		bsr	nputs
		movea.l	(a7)+,a0
		bra	list_1_function
****************
answer_path:
		st	d7
		btst	#31,d0
		beq	print_path

		*  組み込みコマンドである
		tst.b	d3
		bmi	return

		lea	word_builtin,a0
		bne	nputs

		bsr	print_name_is
		lea	msg_is_builtin,a0
		bra	nputs

print_path:
		*  ファイルである
		tst.b	d3
		bmi	nputs

		movea.l	a0,a2
		lea	word_file,a0
		bne	nputs

		bsr	print_name_is
		bsr	put_space
		movea.l	a2,a0
		bsr	cputs
		bsr	put_space
		lea	msg_desu,a0
		bra	nputs
****************
which_too_few_args:
		bsr	too_few_args
		lea	msg_usage,a0
		bra	usage

.data

msg_usage:
	dc.b	'[ -a ] [ -o | -O ] [ -t | -p ] [ - ] <コマンド名> ...',CR,LF
	dc.b	'    -a   見つかってもなお検索を続行して見つかったものすべてを出力する',CR,LF
	dc.b	'    -o   別名を除外する',CR,LF
	dc.b	'    -O   別名，関数，組み込みコマンドを除外し、ファイルのみを検索する',CR,LF
	dc.b	'    -t   シンプルな単語（‘alias’‘function’‘builtin’‘file’あるいは‘’）で答える',CR,LF
	dc.b	'    -p   ファイルならばパス名を答え、それ以外ならば答えない',0

msg_is:			dc.b	' は',0
msg_is_aliased:		dc.b	' の別名'
msg_desu:		dc.b	'です',0
msg_is_function:	dc.b	'関数です',0
msg_is_builtin:		dc.b	' fish組み込みコマンドです',0
msg_not_found:		dc.b	'見当たりません',0
word_builtin:		dc.b	'builtin',0
word_file:		dc.b	'file',0

.end
