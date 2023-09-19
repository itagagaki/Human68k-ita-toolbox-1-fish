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
.xref put_newline
.xref search_command
.xref findvar
.xref find_function
.xref list_1_function
.xref print_alias_value
.xref usage
.xref too_few_args

.xref alias_top
.xref function_root
.xref flag_noalias

.text

****************************************************************
print_name_is:
		bsr	cputs
		move.l	a0,-(a7)
		lea	msg_is,a0
		bsr	puts
		movea.l	(a7)+,a0
		rts
****************************************************************
*  Name
*       which - コマンドの実体を表示する
*
*  Synopsis
*       which [ -o | -O | -a ] command ...
****************************************************************
.xdef cmd_which

command_name = -(((MAXPATH+1)+1)>>1<<1)

cmd_which:
		move.w	d0,d1
		moveq	#0,d2
parse_option_loop1:
		subq.w	#1,d1
		bcs	which_too_few_args

		movea.l	a0,a1
		cmpi.b	#'-',(a0)+
		bne	parse_option_done
parse_option_loop2:
		move.b	(a0)+,d0
		beq	parse_option_loop1

		cmp.b	#'o',d0
		beq	opt_small_o

		cmp.b	#'O',d0
		beq	opt_large_O

		cmp.b	#'a',d0
		bne	parse_option_done
opt_a:
		bclr	#0,d2				*  search alias
		bclr	#1,d2				*  search function/builtin
		bset	#2,d2				*  show all
		bra	parse_option_loop2

opt_large_O:
		bset	#1,d2				*  no function/builtin
opt_small_o:
		bset	#0,d2				*  no alias
		bra	parse_option_loop2


parse_option_done:
		link	a6,#command_name
loop:
	*
	*  別名
	*
		tst.b	flag_noalias(a5)
		bne	not_alias

		btst	#0,d2
		bne	not_alias

		movea.l	alias_top(a5),a0
		bsr	findvar
		beq	not_alias

		movea.l	a1,a0
		bsr	print_name_is
		bsr	put_space
		bsr	print_alias_value
		lea	msg_is_aliased,a0
		bsr	nputs
		btst	#2,d2
		beq	continue
not_alias:
	*
	*  関数
	*
		btst	#1,d2
		bne	not_function

		movea.l	a1,a0
		lea	function_root(a5),a2
		bsr	find_function
		beq	not_function

		move.l	d0,-(a7)
		bsr	print_name_is
		lea	msg_is_function,a0
		bsr	nputs
		movea.l	(a7)+,a0
		bsr	list_1_function
		btst	#2,d2
		beq	continue
not_function:
	*
	*  path 検索
	*
		movea.l	a1,a0
		lea	msg_not_found,a2
		bsr	strlen
		cmp.w	#MAXPATH,d0
		bhi	print_name_and_a2

		lea	command_name(a6),a0
		bsr	strcpy
		btst	#1,d2
		sne	d0
		bsr	search_command
		cmp.l	#-1,d0
		beq	print_name_and_a2

		btst	#31,d0
		beq	print_path

		lea	msg_is_builtin,a2
print_name_and_a2:
		bsr	print_name_is
		movea.l	a2,a0
		bsr	nputs
		bra	continue

print_path:
		bsr	cputs
		bsr	put_newline
continue:
		movea.l	a1,a0
		bsr	strfor1
		movea.l	a0,a1
		dbra	d1,loop

		moveq	#0,d0
		unlk	a6
		rts

which_too_few_args:
		bsr	too_few_args
		lea	msg_usage,a0
		bra	usage

.data

msg_usage:		dc.b	'[ -o | -O ] <コマンド名> ...',CR,LF
			dc.b	'    -o   別名を除外する',CR,LF
			dc.b	'    -O   別名，関数，組み込みコマンドを除外する',CR,LF
			dc.b	'         （ディスク・ファイルのみを検索する）',0

*    -t   シンプルな単語で答える
*           'alias'    - 別名
*           'function' - 関数
*           'builtin'  - FISH組み込みコマンド
*           'file'     - ディスク・ファイル
*           ''         - 見当たらない

*    -p   -t と同様だがディスク・ファイルの場合にはパス名を出力する


msg_is:			dc.b	' は',0
msg_is_aliased:		dc.b	' の別名です',0
msg_is_function:	dc.b	'関数です',0
msg_is_builtin:		dc.b	'FISH組み込みコマンドです',0
msg_not_found:		dc.b	'見当たりません',0

.end
