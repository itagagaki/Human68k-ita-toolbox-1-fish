* b_which.s
* This contains built-in command 'which'.
*
* Itagaki Fumihiko 16-Feb-91  Create.

.include chrcode.h
.include limits.h

.xref strfor1
.xref strcpy
.xref isopt
.xref start_output
.xref end_output
.xref puts
.xref nputs
.xref cputs
.xref put_space
.xref search_command_0
.xref search_command
.xref findvar
.xref find_function
.xref list_1_function
.xref print_var_value
.xref too_few_args
.xref bad_arg
.xref usage

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
		bsr	cputs_near
		lea	msg_is,a0
		jsr	puts
		movea.l	(a7)+,a0
		rts

cputs_near:
		jmp	cputs
****************************************************************
*  Name
*       which - コマンドの実体を表示する
*
*  Synopsis
*       which [ -o | -O ] [ -t ] [ -a ] command ...
****************************************************************
.xdef cmd_which
.xdef which

command_name = -(((MAXPATH+1)+1)>>1<<1)

cmd_which:
		moveq	#0,d2
		moveq	#0,d3			*  D3 : answer mode
parse_option_loop1:
		jsr	isopt
		bne	parse_option_done
parse_option_loop2:
		move.b	(a0)+,d1
		beq	parse_option_loop1

		cmp.b	#'o',d1
		beq	opt_small_o

		cmp.b	#'O',d1
		beq	opt_large_O

		cmp.b	#'a',d1
		beq	opt_all

		cmp.b	#'t',d1
		beq	opt_type

		cmp.b	#'p',d1
		beq	opt_path

		bsr	bad_arg
		bra	cmd_which_usage

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

parse_option_done:
		subq.w	#1,d0
		bcc	which_start

		bsr	too_few_args
cmd_which_usage:
		lea	msg_usage,a0
		jmp	usage

which:
		moveq	#0,d0
		moveq	#0,d2
		moveq	#0,d3
which_start:
		movea.l	a0,a1
		move.w	d0,d1
		link	a6,#command_name
		jsr	start_output
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
		moveq	#0,d0
		move.b	d2,d0
		lsr.b	#1,d0				*  bit 0 : ~~無視フラグ
		btst	#2,d2
		bne	search_all_path

		lea	command_name(a6),a0
		exg	a0,a1
		jsr	search_command_0
		exg	a0,a1
		cmp.l	#-1,d0
		beq	not_a_file

		bsr	answer_path
		bra	continue

search_all_path:
		movea.l	a1,a0
		lea	answer_path(pc),a4
		jsr	search_command
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
		bsr	nputs_near
continue:
		movea.l	a1,a0
		jsr	strfor1
		movea.l	a0,a1
		dbra	d1,loop

		jsr	end_output
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
		bne	nputs_near

		bsr	print_name_is
		bsr	put_space_near
		bsr	print_var_value
		lea	msg_is_aliased,a0
nputs_near:
		jmp	nputs

put_space_near:
		jmp	put_space
****************
answer_function:
		st	d7
		tst.b	d3
		bmi	return

		lea	word_function,a0
		bne	nputs_near

		move.l	d0,-(a7)
		bsr	print_name_is
		lea	msg_is_function,a0
		bsr	nputs_near
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
		bne	nputs_near

		bsr	print_name_is
		lea	msg_is_builtin,a0
		bra	nputs_near

print_path:
		*  ファイルである
		tst.b	d3
		bmi	nputs_near

		movea.l	a0,a2
		lea	word_file,a0
		bne	nputs_near

		bsr	print_name_is
		bsr	put_space_near
		movea.l	a2,a0
		bsr	cputs_near
		bsr	put_space_near
		lea	msg_desu,a0
		bra	nputs_near
****************************************************************
.data

.xdef msg_is
.xdef msg_not_found

msg_usage:
	dc.b	'[-a] [-o|-O] [-t|-p] [--] <コマンド名> ...',CR,LF
	dc.b	'     -a   見つかってもなお検索を続行して見つかったものすべてを出力する',CR,LF
	dc.b	'     -o   別名を除外する',CR,LF
	dc.b	'     -O   別名，関数，組み込みコマンドを除外し、ファイルのみを検索する',CR,LF
	dc.b	'     -t   シンプルな単語（‘alias’‘function’‘builtin’‘file’あるいは‘’）で答える',CR,LF
	dc.b	'     -p   ファイルならばパス名を答え、それ以外ならば答えない',0

msg_is:			dc.b	' は',0
msg_is_aliased:		dc.b	' の別名'
msg_desu:		dc.b	'です',0
msg_is_function:	dc.b	'関数です',0
msg_is_builtin:		dc.b	' fish組み込みコマンドです',0
msg_not_found:		dc.b	'見当たりません',0
word_builtin:		dc.b	'builtin',0
word_file:		dc.b	'file',0

.end
