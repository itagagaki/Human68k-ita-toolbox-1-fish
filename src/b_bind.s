* b_bind.s
* This contains built-in command 'bind'.
*
* Itagaki Fumihiko 13-Apr-91  Create.

.include chrcode.h

.xref iscntrl
.xref toupper
.xref strcmp
.xref strcpy
.xref strlen
.xref memcmp
.xref memset
.xref memmovi
.xref strfor1
.xref putc
.xref cputc
.xref cputs
.xref put_newline
.xref put_space
.xref put_tab
.xref puts
.xref nputs
.xref eputs
.xref enputs
.xref enputs1
.xref expand_wordlist
.xref strip_quotes
.xref pre_perror
.xref no_space_for
.xref too_many_args
.xref bad_arg
.xref perror_command_name
.xref msg_usage
.xref msg_too_few_args
.xref msg_too_many_args

.xref keymacro
.xref keymap
.xref keymacromap
.xref tmpargs

X_SELF_INSERT		equ	0
X_ERROR			equ	1
X_MACRO			equ	2
X_PREFIX_1		equ	3
X_PREFIX_2		equ	4
X_ABORT			equ	5
X_EOF			equ	6
X_ACCEPT_LINE		equ	7
X_QUOTED_INSERT		equ	8
X_REDRAW		equ	9
X_CLEAR_AND_REDRAW	equ	10
X_SET_MARK		equ	11
X_EXG_POINT_AND_MARK	equ	12
X_SEARCH_CHARACTER	equ	13
X_BOL			equ	14
X_EOL			equ	15
X_BACKWARD_CHAR		equ	16
X_FORWARD_CHAR		equ	17
X_BACKWARD_WORD		equ	18
X_FORWARD_WORD		equ	19
X_DEL_BACK_CHAR		equ	20
X_DEL_FOR_CHAR		equ	21
X_KILL_BACK_WORD	equ	22
X_KILL_FOR_WORD		equ	23
X_KILL_BOL		equ	24
X_KILL_EOL		equ	25
X_KILL_REGION		equ	26
X_COPY_REGION		equ	27
X_YANK			equ	28
X_UPCASE_CHAR		equ	29
X_DOWNCASE_CHAR		equ	30
X_UPCASE_WORD		equ	31
X_DOWNCASE_WORD		equ	32
X_UPCASE_REGION		equ	33
X_DOWNCASE_REGION	equ	34
X_TRANSPOSE_CHARS	equ	35
X_TRANSPOSE_WORDS	equ	36
X_UP_HISTORY		equ	37
X_DOWN_HISTORY		equ	38
X_COMPLETE		equ	39
X_LIST			equ	40

.text

****************************************************************
* keymap_index - キー・マップのインデックスを計算する
*
* CALL
*      D1.B   マップ番号 (0 .. 2)
*      D2.B   キー・コード (0 .. 127)
*
* RETURN
*      D0.L   インデックス
****************************************************************
keymap_index:
		moveq	#0,d0
		move.b	d1,d0
		lsl.l	#7,d0
		or.b	d2,d0
		rts
****************************************************************
* funcno - キーにバインドされている機能番号を得る
*
* CALL
*      D1.B   マップ番号 (0 .. 2)
*      D2.B   キー・コード (0 .. 127)
*
* RETURN
*      D0.L   機能番号
****************************************************************
funcno:
		move.l	a0,-(a7)
		bsr	keymap_index
		lea	keymap(a5),a0
		adda.l	d0,a0
		moveq	#0,d0
		move.b	(a0),d0
		movea.l	(a7)+,a0
		rts
*****************************************************************
* do_bind
*
* CALL
*      D1.B   マップ番号 (0 - 2)
*      D2.B   キー・コード ($00 - $7F)
*      D3.B   ファンクション番号 (0 - 21)
*
* RETURN
*      D0.L   破壊
*****************************************************************
do_bind:
		move.l	a0,-(a7)
		bsr	keymap_index
		lea	keymap(a5),a0
		move.b	d3,(a0,d0.l)
		cmp.b	#X_MACRO,d3
		beq	do_bind_return

		lsl.l	#2,d0
		lea	keymacromap(a5),a0
		clr.l	(a0,d0.l)
do_bind_return:
		movea.l	(a7)+,a0
		rts
*****************************************************************
* init_key_bind
*****************************************************************
.xdef init_key_bind

init_key_bind:
		movem.l	d0-d3/a0-a1,-(a7)
		*
		lea	keymap(a5),a0
		moveq	#X_SELF_INSERT,d0
		move.l	#128,d1
		bsr	memset
		lea	(a0,d1.l),a0
		moveq	#X_ERROR,d0
		add.l	d1,d1
		bsr	memset
		*
		lea	keymacromap(a5),a0
		moveq	#0,d0
		move.l	#4*128*3,d1
		bsr	memset
		*
		lea	initial_bindings,a1
init_key_loop:
		move.b	(a1)+,d1
		bmi	init_key_done

		move.b	(a1)+,d2
		move.b	(a1)+,d3
		bsr	do_bind
		bra	init_key_loop

init_key_done:
		movem.l	(a7)+,d0-d3/a0-a1
		rts
****************************************************************
* print_bind - キーにバインドされている機能を表示する
*
* CALL
*      D1.B   マップ番号 (0 .. 2)
*      D2.B   キー・コード (0 .. 127)
*
* RETURN
*      D0.L   0
****************************************************************
print_bind:
		movem.l	d3/a0,-(a7)
		bsr	funcno
		move.b	d0,d3
		lsl.l	#2,d0
		lea	key_function_name_table,a0
		movea.l	(a0,d0.l),a0
		bsr	puts
		cmp.b	#X_MACRO,d3
		bne	print_bind_done

		bsr	put_space
		moveq	#"'",d0
		bsr	putc
		bsr	keymap_index
		lsl.l	#2,d0
		lea	keymacromap(a5),a0
		move.l	(a0,d0.l),d0
		beq	print_bind_macro_1

		movea.l	d0,a0
		bsr	cputs
print_bind_macro_1:
		moveq	#"'",d0
		bsr	putc
print_bind_done:
		bsr	put_newline
		movem.l	(a7)+,d3/a0
		moveq	#0,d0
		rts
****************************************************************
* print_all_bind - 現在のすべてのバインドを表示する
*
* CALL
*      D0.B   0 ならば、self-insert と error を除外する
*
* RETURN
*      D0.L   0
*      その他は破壊
****************************************************************
print_all_bind:
		move.b	d0,d3

		moveq	#0,d1
print_all_bind_loop1:
		moveq	#0,d2
print_all_bind_loop2:
		tst.b	d3
		bne	print_all_bind_1

		bsr	funcno
		cmp.b	#X_ERROR,d0
		bls	print_all_bind_continue
print_all_bind_1:
		move.l	d1,d0
		lsl.l	#2,d0
		lea	msg_prefixes,a0
		move.l	(a0,d0.l),a0
		bsr	puts
		bsr	put_space
		move.b	d2,d0
		bsr	cputc
		bsr	put_tab
		bsr	print_bind
print_all_bind_continue:
		addq.b	#1,d2
		bpl	print_all_bind_loop2

		addq.b	#1,d1
		cmp.b	#2,d1
		bls	print_all_bind_loop1

		moveq	#0,d0
		rts
****************************************************************
* delete_macro - マクロ文字列を削除する
*
* CALL
*      A2     マクロ文字列格納領域のヘッダのアドレス
*      A3     keymacromap ポインタ
*
* RETURN
*      none
****************************************************************
delete_macro:
		tst.l	(a3)
		beq	delete_macro_done

		movem.l	d0-d2/a0-a1,-(a7)
		movea.l	(a3),a0
		bsr	strlen
		addq.l	#1,d0
		move.l	d0,d1			*  D1.L : 削除するバイト数
		lea	(a0,d1.l),a1
		move.l	a2,d0
		add.l	4(a2),d0
		sub.l	a1,d0
		bsr	memmovi			*  文字列を削除
		sub.l	d1,4(a2)		*  マクロ文字列格納領域の使用量を修正する

		move.l	(a3),d2
		lea	keymacromap(a5),a0
		move.w	#128*3,d0
delete_macro_loop:
		movea.l	(a0)+,a1
		cmpa.l	d2,a1
		blo	delete_macro_continue
		beq	delete_macro_0

		sub.l	d1,-4(a0)		*  続く文字列たちを指していたポインタを修正する
		bra	delete_macro_continue

delete_macro_0:
		clr.l	-4(a0)			*  削除した文字列を指しているものは NULL に
delete_macro_continue:
		dbra	d0,delete_macro_loop

		movem.l	(a7)+,d0-d2/a0-a1
delete_macro_done:
		rts
****************************************************************
*  Name
*       bind - キー・バインドの表示と設定
*
*  Synopsis
*       bind [ -a ]
*            現在のすべてのキー・バインドを表示する
*
*       bind [ [prefix]-{1|2} ] key
*            key にバインドされている機能を表示する
*
*       bind [ [prefix]-{1|2} ] key function
*            key に function をバインドする
*
*       bind [ [prefix]-{1|2} ] key macro string
*            key に マクロ string をバインドする
****************************************************************
.xdef cmd_bind

cmd_bind:
		move.w	d0,d4			*  D4.W : 引数の数
		beq	print_all_bind		*  引数が無いなら現在のすべてのバインドを表示

		lea	str_option_a,a1
		bsr	strcmp
		bne	cmd_bind_1

		subq.w	#1,d4
		bne	bind_bad_arg

		moveq	#1,d0
		bra	print_all_bind

cmd_bind_1:
		*
		*  マップ番号を決定する
		*
		moveq	#0,d1			*  D1.L : マップ番号

		lea	name_prefix_1,a1
		moveq	#6,d0
		bsr	memcmp
		bne	cmd_bind_not_prefix_

		addq.l	#6,a0
cmd_bind_not_prefix_:
		cmpi.b	#'-',(a0)
		bne	mapno_ok

		tst.b	1(a0)
		beq	mapno_ok

		addq.l	#1,a0
		move.b	(a0)+,d1
		sub.b	#'0',d1
		bls	bind_bad_arg

		cmp.b	#2,d1
		bhi	bind_bad_arg

		tst.b	(a0)+
		bne	bind_bad_arg

		subq.w	#1,d4
		beq	bind_bad_arg
mapno_ok:
		*
		*  キー・コードを得る
		*
		movea.l	a0,a1
		bsr	strfor1
		exg	a0,a1
		bsr	strip_quotes
		move.b	(a0)+,d0
		bmi	bind_bad_arg

		bsr	iscntrl
		beq	keycode_ok

		cmp.b	#'^',d0
		bne	keycode_ok

		tst.b	(a0)
		beq	keycode_ok

		move.b	(a0)+,d0
		bmi	bind_bad_arg

		bsr	toupper
		sub.b	#'@',d0
		bclr	#7,d0
keycode_ok:
		tst.b	(a0)+
		bne	bind_bad_arg

		move.b	d0,d2			*  D2.B : キー・コード
		*
		*  引数がもう無いなら、そのキーのバインドを表示
		*
		subq.w	#1,d4
		beq	print_bind
		*
		*  残りの引数を｛コマンド置換，ファイル名展開｝する
		*
		move.w	d4,d0
		lea	tmpargs,a0
		bsr	expand_wordlist
		bmi	cmd_bind_return

		move.w	d0,d4			*  置換・展開後の引数の数が
		subq.w	#1,d4			*  1つ
		bcs	bind_bad_arg		*  も無いならば、エラー
		*
		*  ファンクション番号を得る
		*
		moveq	#-1,d3			*  D3.B にファンクション番号を求める
		lea	key_function_name_table,a2
bind_find_func:
		tst.l	(a2)
		beq	bad_funcname

		addq.b	#1,d3
		movea.l	(a2)+,a1
		bsr	strcmp
		bne	bind_find_func
		*
		*
		movea.l	keymacro(a5),a2		*  A2 : マクロ文字列格納領域のヘッダのアドレス
		bsr	keymap_index
		lsl.l	#2,d0
		lea	keymacromap(a5),a3
		adda.l	d0,a3			*  A3 : keymacromapポインタ
		cmp.b	#X_MACRO,d3
		bne	bind_normal_func
		*
		*
		subq.w	#1,d4
		blo	missing_macro_string
		bhi	too_many_macro_string
		*
		bsr	strfor1			*  A0 : マクロ文字列の先頭アドレス
		bsr	strlen
		addq.l	#1,d0
		move.l	d0,d4			*  D4.L : マクロ文字列の長さ+1
		*
		move.l	(a3),d0
		beq	bind_macro_1

		exg	a0,a3
		bsr	strlen
		exg	a0,a3
bind_macro_1:
		add.l	(a2),d0
		sub.l	4(a2),d0		*  D0.L : キー・マクロ領域の空き容量
		cmp.l	d4,d0
		blo	bind_macro_no_space

		bsr	delete_macro
		move.l	4(a2),d0
		lea	(a2,d0.l),a1
		exg	a0,a1
		bsr	strcpy
		add.l	d4,4(a2)
		move.l	a0,(a3)
		bra	cmd_bind_do_bind

bind_normal_func:
		tst.w	d4
		bne	bind_too_many_args

		bsr	delete_macro
cmd_bind_do_bind:
		bsr	do_bind
		moveq	#0,d0
cmd_bind_return:
		rts


bind_macro_no_space:
		lea	msg_key_macro_space,a0
		bra	no_space_for

missing_macro_string:
		lea	msg_too_few_args,a1
		bra	bad_arg_after_macro

too_many_macro_string:
		lea	msg_too_many_args,a1
bad_arg_after_macro:
		bsr	perror_command_name
		lea	msg_follows_macro,a0
		bsr	eputs
		movea.l	a1,a0
		bsr	enputs
		bra	bind_usage

bad_funcname:
		bsr	pre_perror
		lea	msg_bad_funcname,a0
		bra	enputs1

bind_too_many_args:
		bsr	too_many_args
		bra	bind_usage

bind_bad_arg:
		bsr	bad_arg
bind_usage:
		lea	msg_usage,a0
		bsr	enputs
		lea	msg_usage_of_bind,a0
		bra	enputs1
****************************************************************
.data

.even
key_function_name_table:
		dc.l	name_self_insert
		dc.l	name_error
		dc.l	name_macro
		dc.l	name_prefix_1
		dc.l	name_prefix_2
		dc.l	name_abort
		dc.l	name_eof
		dc.l	name_accept_line
		dc.l	name_quoted_insert
		dc.l	name_redraw
		dc.l	name_clear_and_redraw
		dc.l	name_set_mark
		dc.l	name_exg_point_and_mark
		dc.l	name_search_character
		dc.l	name_bol
		dc.l	name_eol
		dc.l	name_backward_char
		dc.l	name_forward_char
		dc.l	name_backward_word
		dc.l	name_forward_word
		dc.l	name_del_back_char
		dc.l	name_del_for_char
		dc.l	name_kill_back_word
		dc.l	name_kill_for_word
		dc.l	name_kill_bol
		dc.l	name_kill_eol
		dc.l	name_kill_region
		dc.l	name_copy_region
		dc.l	name_yank
		dc.l	name_upcase_char
		dc.l	name_downcase_char
		dc.l	name_upcase_word
		dc.l	name_downcase_word
		dc.l	name_upcase_region
		dc.l	name_downcase_region
		dc.l	name_transpose_chars
		dc.l	name_transpose_words
		dc.l	name_up_history
		dc.l	name_down_history
		dc.l	name_complete
		dc.l	name_list
		dc.l	0

.even
msg_prefixes:
		dc.l	msg_main
		dc.l	name_prefix_1
		dc.l	name_prefix_2

name_self_insert:		dc.b	'self-insert',0
name_error:			dc.b	'error',0
name_macro:			dc.b	'macro',0
name_prefix_1:			dc.b	'prefix-1',0
name_prefix_2:			dc.b	'prefix-2',0
name_abort:			dc.b	'abort',0
name_eof:			dc.b	'eof',0
name_accept_line:		dc.b	'accept-line',0
name_quoted_insert:		dc.b	'quoted-insert',0
name_redraw:			dc.b	'redraw',0
name_clear_and_redraw:		dc.b	'clear-and-redraw',0
name_set_mark:			dc.b	'set-mark',0
name_exg_point_and_mark:	dc.b	'exchange-point-and-mark',0
name_search_character:		dc.b	'search-character',0
name_bol:			dc.b	'beginning-of-line',0
name_eol:			dc.b	'end-of-line',0
name_backward_char:		dc.b	'backward-char',0
name_forward_char:		dc.b	'forward-char',0
name_backward_word:		dc.b	'backward-word',0
name_forward_word:		dc.b	'forward-word',0
name_del_back_char:		dc.b	'delete-backward-char',0
name_del_for_char:		dc.b	'delete-forward-char',0
name_kill_back_word:		dc.b	'kill-backward-word',0
name_kill_for_word:		dc.b	'kill-forward-word',0
name_kill_bol:			dc.b	'kill-to-bol',0
name_kill_eol:			dc.b	'kill-to-eol',0
name_kill_region:		dc.b	'kill-region',0
name_copy_region:		dc.b	'copy-region',0
name_yank:			dc.b	'yank',0
name_upcase_char:		dc.b	'upcase-char',0
name_downcase_char:		dc.b	'downcase-char',0
name_upcase_word:		dc.b	'upcase-word',0
name_downcase_word:		dc.b	'downcase-word',0
name_upcase_region:		dc.b	'upcase-region',0
name_downcase_region:		dc.b	'downcase-region',0
name_transpose_chars:		dc.b	'transpose-chars',0
name_transpose_words:		dc.b	'transpose-words',0
name_up_history:		dc.b	'up-history',0
name_down_history:		dc.b	'down-history',0
name_complete:			dc.b	'complete',0
name_list:			dc.b	'list',0

msg_main:		dc.b	'        ',0

initial_bindings:
			dc.b	0,'C'-'@',X_ABORT
			dc.b	0,'D'-'@',X_EOF
			dc.b	0,'H'-'@',X_DEL_BACK_CHAR
			dc.b	0,'M'-'@',X_ACCEPT_LINE
			dc.b	-1

msg_follows_macro:	dc.b	'macro に続く',0
msg_bad_funcname:	dc.b	'このような名前の機能はありません',0

msg_key_macro_space:	dc.b	'キー・マクロ・ブロック',0

msg_usage_of_bind:
		dc.b	'     bind [ -a ]',CR,LF
		dc.b	'          現在のキー・バインドを表示する',CR,LF,LF
		dc.b	'     bind [ [prefix]-{1|2} ] <キー>',CR,LF
		dc.b	'          <キー>にバインドされている機能を表示する',CR,LF,LF
		dc.b	'     bind [ [prefix]-{1|2} ] <キー> <機能>',CR,LF
		dc.b	'          <キー>に<機能>をバインドする',CR,LF,LF
		dc.b	'     bind [ [prefix]-{1|2} ] <キー> macro <文字列>',CR,LF
		dc.b	'          <キー>に<文字列>をバインドする',0

str_option_a:		dc.b	'-a',0

.end
