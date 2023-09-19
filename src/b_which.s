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
.xref cputs
.xref put_space
.xref put_newline
.xref search_command
.xref headtail
.xref find_var
.xref find_shellvar
.xref print_alias_value
.xref print_var_value
.xref usage
.xref too_few_args
.xref word_path
.xref msg_too_long

.xref alias

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
*       which [ -o | -O ] command ...
****************************************************************
.xdef cmd_which

command_name = -(((MAXPATH+1)+1)>>1<<1)

cmd_which:
		move.w	d0,d1
		beq	which_too_few_args

		cmpi.b	#'-',(a0)
		bne	no_option

		move.b	1(a0),d0
		beq	no_option

		tst.b	2(a0)
		bne	no_option

		moveq	#3,d2
		cmp.b	#'O',d0
		beq	start0

		moveq	#1,d2
		cmp.b	#'o',d0
		beq	start0
no_option:
		moveq	#0,d2
		bra	start

start0:
		bsr	strfor1
		subq.w	#1,d1
start:
		subq.w	#1,d1
		bcs	which_too_few_args

		link	a6,#command_name
loop:
		btst	#0,d2
		bne	not_alias

		movea.l	a0,a1
		movea.l	alias(a5),a0
		bsr	find_var
		exg	a0,a1
		beq	not_alias

		bsr	print_name_is
		bsr	put_space
		exg	a0,a1
		bsr	print_alias_value
		lea	msg_aliased,a0
		bra	continue

not_alias:
		movea.l	a0,a1
		bsr	strlen
		cmp.w	#MAXPATH,d0
		bhi	too_long_command_name

		lea	command_name(a6),a0
		bsr	strcpy
		move.b	d2,d0
		and.b	#2,d0
		bsr	search_command
		bmi	not_found

		cmp.l	#6,d0
		bls	continue

		bsr	print_name_is
		lea	msg_builtin,a0
		bra	continue

not_found:
		bsr	print_name_is
		move.l	a1,-(a7)
		bsr	headtail
		cmpa.l	a0,a1
		movea.l	(a7)+,a1
		lea	msg_not_found,a0
		bne	continue

		bsr	put_space
		lea	word_path,a0
		bsr	find_shellvar
		beq	put_pathlist

		addq.l	#2,a0
		move.w	(a0)+,d0			* D0.W : $path の要素数
		bsr	strfor1				* A0 : $path[1] のアドレス
put_pathlist:
		bsr	print_var_value
		lea	msg_not_found_in,a0
		bra	continue

too_long_command_name:
		bsr	print_name_is
		lea	msg_too_long,a0
continue:
		bsr	cputs
		bsr	put_newline
		movea.l	a1,a0
		bsr	strfor1
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
			dc.b	'    -O   別名と組み込みコマンドを除外する',0
msg_is:			dc.b	' は',0
msg_aliased:		dc.b	' の別名です',0
msg_builtin:		dc.b	' FISH の組み込みコマンドです',0
msg_not_found_in:	dc.b	' の中に'
msg_not_found:		dc.b	'ありません',0

.end
