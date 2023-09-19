* b_bind.s
* This contains built-in command 'bind'.
*
* Itagaki Fumihiko 13-Apr-91  Create.

.include chrcode.h

.xref iscntrl
.xref toupper
.xref strcmp
.xref strdup
.xref memcmp
.xref memset
.xref strfor1
.xref xfree
.xref putc
.xref cputc
.xref puts
.xref cputs
.xref eputs
.xref enputs
.xref enputs1
.xref put_newline
.xref put_space
.xref put_tab
.xref expand_wordlist
.xref strip_quotes
.xref pre_perror
.xref insufficient_memory
.xref too_many_args
.xref bad_arg
.xref perror_command_name
.xref msg_usage
.xref msg_too_few_args
.xref msg_too_many_args
.xref word_default

.xref keymap
.xref keymacromap
.xref simple_args
							* = is not in default bindings
X_SELF_INSERT				equ	0
X_ERROR					equ	1
X_NO_OP					equ	2
X_MACRO					equ	3
X_PREFIX_1				equ	4
X_PREFIX_2				equ	5
X_ABORT					equ	6
X_EOF					equ	7
X_ACCEPT_LINE				equ	8
X_KEYBOARD_QUIT				equ	9
X_QUOTED_INSERT				equ	10
X_REDRAW				equ	11
X_CLEAR_AND_REDRAW			equ	12
X_SET_MARK				equ	13
X_EXG_POINT_AND_MARK			equ	14
X_SEARCH_CHARACTER			equ	15	*
X_BOL					equ	16
X_EOL					equ	17
X_BACKWARD_CHAR				equ	18
X_FORWARD_CHAR				equ	19
X_BACKWARD_WORD				equ	20
X_FORWARD_WORD				equ	21
X_NEXT_WORD				equ	22	*
X_DEL_BACK_CHAR				equ	23
X_DEL_FOR_CHAR				equ	24
X_KILL_BACK_WORD			equ	25
X_KILL_FOR_WORD				equ	26
X_KILL_BOL				equ	27	*
X_KILL_EOL				equ	28
X_KILL_WHOLE_LINE			equ	29
X_KILL_REGION				equ	30
X_COPY_REGION				equ	31
X_YANK					equ	32
X_CHANGE_CASE				equ	33	*
X_UPCASE_CHAR				equ	34	*
X_DOWNCASE_CHAR				equ	35	*
X_UPCASE_WORD				equ	36
X_DOWNCASE_WORD				equ	37
X_UPCASE_REGION				equ	38
X_DOWNCASE_REGION			equ	39
X_CAPITALIZE_WORD			equ	40
X_TRANSPOSE_GOSLING			equ	41	*
X_TRANSPOSE_CHARS			equ	42
X_TRANSPOSE_WORDS			equ	43
X_HISTORY_SEARCH_BACKWARD		equ	44
X_HISTORY_SEARCH_FORWARD		equ	45
X_HISTORY_SEARCH_BACKWARD_CIRCULAR	equ	46
X_HISTORY_SEARCH_FORWARD_CIRCULAR	equ	47
X_COMPLETE				equ	48
X_COMPLETE_RAW				equ	49
X_LIST					equ	50
X_LIST_RAW				equ	51
X_LIST_OR_EOF				equ	52
X_DEL_FOR_CHAR_OR_LIST			equ	53
X_DEL_FOR_CHAR_OR_LIST_OR_EOF		equ	54
X_COPY_PREV_WORD			equ	55
X_INSERT_LAST_WORD			equ	56
X_UP_HISTORY				equ	57
X_DOWN_HISTORY				equ	58
X_QUIT_HISTORY				equ	59

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
		lsl.w	#7,d0
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

cmd_bind_default:
		subq.w	#1,d4
		bne	bind_bad_arg

		lea	keymacromap(a5),a0
		move.w	#128*3-1,d1
free_all_macro_strings:
		move.l	(a0)+,d0
		bsr	xfree
		dbra	d1,free_all_macro_strings
init_key_bind:
		movem.l	d0-d3/a0,-(a7)

		lea	keymap(a5),a0
		moveq	#X_SELF_INSERT,d0
		move.l	#128,d1
		bsr	memset
		lea	(a0,d1.l),a0
		moveq	#X_ERROR,d0
		add.l	d1,d1
		bsr	memset

		lea	keymacromap(a5),a0
		moveq	#0,d0
		move.l	#4*128*3,d1
		bsr	memset

		lea	initial_bindings,a0
init_key_loop:
		move.b	(a0)+,d1
		bmi	init_key_done

		move.b	(a0)+,d2
		move.b	(a0)+,d3
		bsr	do_bind
		bra	init_key_loop

init_key_done:
		movem.l	(a7)+,d0-d3/a0
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
		lea	key_function_word_table,a0
		bsr	put_funcname
		cmp.b	#X_MACRO,d3
		bne	print_bind_done

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
put_funcname:
		lsl.l	#1,d0
		move.w	(a0,d0.l),d0
		lea	key_function_names_top,a0
		lea	(a0,d0.w),a0
		bsr	puts
		bra	put_space
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
cmd_bind_a:
		subq.w	#1,d4
		bne	bind_bad_arg

		st	d0
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
		lea	msg_prefixes,a0
		bsr	put_funcname
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
*  Name
*       bind - キー・バインドの表示と設定
*
*  Synopsis
*       bind -d
*       bind default
*            デフォルトのキー・バインドにする
*
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
		move.w	d0,d4				*  D4.W : 引数の数
		beq	print_all_bind			*  引数が無いなら現在のすべてのバインドを表示

		lea	str_option_a,a1
		bsr	strcmp
		beq	cmd_bind_a

		lea	str_option_d,a1
		bsr	strcmp
		beq	cmd_bind_default

		lea	word_default,a1
		bsr	strcmp
		beq	cmd_bind_default
cmd_bind_1:
		*
		*  マップ番号を決定する
		*
		moveq	#0,d1				*  D1.L : マップ番号

		lea	word_prefix_1,a1
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

		move.b	d0,d2				*  D2.B : キー・コード
		*
		*  引数がもう無いなら、そのキーのバインドを表示
		*
		subq.w	#1,d4
		beq	print_bind
		*
		*  残りの引数を｛コマンド置換，ファイル名展開｝する
		*
		move.w	d4,d0
		lea	simple_args(a5),a0
		bsr	expand_wordlist
		bmi	cmd_bind_return

		move.w	d0,d4				*  置換・展開後の引数の数が
		subq.w	#1,d4				*  1つ
		bcs	bind_bad_arg			*  も無いならば、エラー
		*
		*  ファンクション番号を得る
		*
		moveq	#-1,d3				*  D3.B にファンクション番号を求める
		lea	key_function_word_table,a2
bind_find_func:
		tst.w	(a2)
		bmi	bad_funcname

		addq.b	#1,d3
		move.w	(a2)+,d0
		lea	key_function_names_top,a1
		lea	(a1,d0.w),a1
		bsr	strcmp
		bne	bind_find_func
		*
		*
		bsr	keymap_index
		lsl.l	#2,d0
		lea	keymacromap(a5),a2
		adda.l	d0,a2				*  A2 : keymacromapポインタ
		cmp.b	#X_MACRO,d3
		bne	bind_normal_func
		*
		*
		subq.w	#1,d4
		blo	missing_macro_string
		bhi	too_many_macro_string
		*
		bsr	strfor1				*  A0 : マクロ文字列の先頭アドレス
		bsr	strdup
		beq	insufficient_memory

		movea.l	d0,a0
		move.l	(a2),d0
		bsr	xfree
		move.l	a0,(a2)
		bra	cmd_bind_do_bind

bind_normal_func:
		tst.w	d4
		bne	bind_too_many_args

		move.l	(a2),d0
		bsr	xfree
cmd_bind_do_bind:
		bsr	do_bind
		moveq	#0,d0
cmd_bind_return:
		rts


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

.xdef word_complete
.xdef word_uncomplete
.xdef key_function_word_table
.xdef key_function_names_top

.even
key_function_word_table:
		dc.w	word_self_insert-key_function_names_top
		dc.w	word_error-key_function_names_top
		dc.w	word_no_op-key_function_names_top
		dc.w	word_macro-key_function_names_top
		dc.w	word_prefix_1-key_function_names_top
		dc.w	word_prefix_2-key_function_names_top
		dc.w	word_abort-key_function_names_top
		dc.w	word_eof-key_function_names_top
		dc.w	word_accept_line-key_function_names_top
		dc.w	word_keyboard_quit-key_function_names_top
		dc.w	word_quoted_insert-key_function_names_top
		dc.w	word_redraw-key_function_names_top
		dc.w	word_clear_and_redraw-key_function_names_top
		dc.w	word_set_mark-key_function_names_top
		dc.w	word_exg_point_and_mark-key_function_names_top
		dc.w	word_search_character-key_function_names_top
		dc.w	word_bol-key_function_names_top
		dc.w	word_eol-key_function_names_top
		dc.w	word_backward_char-key_function_names_top
		dc.w	word_forward_char-key_function_names_top
		dc.w	word_backward_word-key_function_names_top
		dc.w	word_forward_word-key_function_names_top
		dc.w	word_next_word-key_function_names_top
		dc.w	word_del_back_char-key_function_names_top
		dc.w	word_del_for_char-key_function_names_top
		dc.w	word_kill_back_word-key_function_names_top
		dc.w	word_kill_for_word-key_function_names_top
		dc.w	word_kill_bol-key_function_names_top
		dc.w	word_kill_eol-key_function_names_top
		dc.w	word_kill_whole_line-key_function_names_top
		dc.w	word_kill_region-key_function_names_top
		dc.w	word_copy_region-key_function_names_top
		dc.w	word_yank-key_function_names_top
		dc.w	word_change_case-key_function_names_top
		dc.w	word_upcase_char-key_function_names_top
		dc.w	word_downcase_char-key_function_names_top
		dc.w	word_upcase_word-key_function_names_top
		dc.w	word_downcase_word-key_function_names_top
		dc.w	word_upcase_region-key_function_names_top
		dc.w	word_downcase_region-key_function_names_top
		dc.w	word_capitalize_word-key_function_names_top
		dc.w	word_transpose_gosling-key_function_names_top
		dc.w	word_transpose_chars-key_function_names_top
		dc.w	word_transpose_words-key_function_names_top
		dc.w	word_history_search_backward-key_function_names_top
		dc.w	word_history_search_forward-key_function_names_top
		dc.w	word_history_search_backward_circular-key_function_names_top
		dc.w	word_history_search_forward_circular-key_function_names_top
		dc.w	word_complete-key_function_names_top
		dc.w	word_complete_raw-key_function_names_top
		dc.w	word_list-key_function_names_top
		dc.w	word_list_raw-key_function_names_top
		dc.w	word_list_or_eof-key_function_names_top
		dc.w	word_del_for_char_or_list-key_function_names_top
		dc.w	word_del_for_char_or_list_or_eof-key_function_names_top
		dc.w	word_copy_prev_word-key_function_names_top
		dc.w	word_insert_last_word-key_function_names_top
		dc.w	word_up_history-key_function_names_top
		dc.w	word_down_history-key_function_names_top
		dc.w	word_quit_history-key_function_names_top
		dc.w	-1

.even
msg_prefixes:
		dc.w	msg_main-key_function_names_top
		dc.w	word_prefix_1-key_function_names_top
		dc.w	word_prefix_2-key_function_names_top

key_function_names_top:
word_self_insert:			dc.b	'self-insert',0
word_error:				dc.b	'error',0
word_no_op:				dc.b	'no-op',0
word_macro:				dc.b	'macro',0
word_prefix_1:				dc.b	'prefix-1',0
word_prefix_2:				dc.b	'prefix-2',0
word_abort:				dc.b	'abort',0
word_del_for_char_or_list_or_eof:	dc.b	'delete-forward-char-or-list-or-'
word_eof:				dc.b	'eof',0
word_accept_line:			dc.b	'accept-line',0
word_keyboard_quit:			dc.b	'keyboard-quit',0
word_quoted_insert:			dc.b	'quoted-insert',0
word_clear_and_redraw:			dc.b	'clear-and-'
word_redraw:				dc.b	'redraw',0
word_set_mark:				dc.b	'set-mark',0
word_exg_point_and_mark:		dc.b	'exchange-point-and-mark',0
word_search_character:			dc.b	'search-character',0
word_bol:				dc.b	'beginning-of-line',0
word_eol:				dc.b	'end-of-line',0
word_del_back_char:			dc.b	'delete-'
word_backward_char:			dc.b	'backward-char',0
word_del_for_char:			dc.b	'delete-'
word_forward_char:			dc.b	'forward-char',0
word_kill_back_word:			dc.b	'kill-'
word_backward_word:			dc.b	'backward-word',0
word_kill_for_word:			dc.b	'kill-'
word_forward_word:			dc.b	'forward-word',0
word_next_word:				dc.b	'next-word',0
word_kill_bol:				dc.b	'kill-to-bol',0
word_kill_eol:				dc.b	'kill-to-eol',0
word_kill_whole_line:			dc.b	'kill-whole-line',0
word_kill_region:			dc.b	'kill-region',0
word_copy_region:			dc.b	'copy-region',0
word_yank:				dc.b	'yank',0
word_change_case:			dc.b	'change-case',0
word_upcase_char:			dc.b	'upcase-char',0
word_downcase_char:			dc.b	'downcase-char',0
word_upcase_word:			dc.b	'upcase-word',0
word_downcase_word:			dc.b	'downcase-word',0
word_upcase_region:			dc.b	'upcase-region',0
word_downcase_region:			dc.b	'downcase-region',0
word_capitalize_word:			dc.b	'capitalize-word',0
word_transpose_gosling:			dc.b	'transpose-gosling',0
word_transpose_chars:			dc.b	'transpose-chars',0
word_transpose_words:			dc.b	'transpose-words',0
word_history_search_backward:		dc.b	'history-search-backward',0
word_history_search_forward:		dc.b	'history-search-forward',0
word_history_search_backward_circular:	dc.b	'history-search-backward-circular',0
word_history_search_forward_circular:	dc.b	'history-search-forward-circular',0
word_uncomplete:			dc.b	'un'
word_complete:				dc.b	'complete',0
word_complete_raw:			dc.b	'complete-raw',0
word_del_for_char_or_list:		dc.b	'delete-forward-char-or-'
word_list:				dc.b	'list',0
word_list_raw:				dc.b	'list-raw',0
word_list_or_eof:			dc.b	'list-or-eof',0
word_copy_prev_word:			dc.b	'copy-prev-word',0
word_insert_last_word:			dc.b	'insert-last-word',0
word_up_history:			dc.b	'up-history',0
word_down_history:			dc.b	'down-history',0
word_quit_history:			dc.b	'quit-history',0

msg_main:		dc.b	'        ',0

initial_bindings:
			dc.b	0,'@'-'@',X_SET_MARK
			dc.b	0,'A'-'@',X_BOL
			dc.b	0,'B'-'@',X_BACKWARD_CHAR
			dc.b	0,'C'-'@',X_ABORT
			dc.b	0,'D'-'@',X_DEL_FOR_CHAR_OR_LIST_OR_EOF
			dc.b	0,'E'-'@',X_EOL
			dc.b	0,'F'-'@',X_FORWARD_CHAR
			dc.b	0,'G'-'@',X_ERROR
			dc.b	0,'H'-'@',X_DEL_BACK_CHAR
			dc.b	0,'I'-'@',X_COMPLETE
			dc.b	0,'J'-'@',X_ACCEPT_LINE
			dc.b	0,'K'-'@',X_KILL_EOL
			dc.b	0,'L'-'@',X_CLEAR_AND_REDRAW
			dc.b	0,'M'-'@',X_ACCEPT_LINE
			dc.b	0,'N'-'@',X_DOWN_HISTORY
			dc.b	0,'P'-'@',X_UP_HISTORY
			dc.b	0,'Q'-'@',X_QUOTED_INSERT
			dc.b	0,'R'-'@',X_REDRAW
			dc.b	0,'T'-'@',X_TRANSPOSE_CHARS
			dc.b	0,'U'-'@',X_KILL_WHOLE_LINE
			dc.b	0,'V'-'@',X_QUOTED_INSERT
			dc.b	0,'W'-'@',X_KILL_REGION
			dc.b	0,'X'-'@',X_PREFIX_2
			dc.b	0,'Y'-'@',X_YANK
			dc.b	0,'['-'@',X_PREFIX_1
			dc.b	0,$7f,X_DEL_BACK_CHAR
			dc.b	1,'D'-'@',X_LIST
			dc.b	1,'H'-'@',X_KILL_BACK_WORD
			dc.b	1,'I'-'@',X_COMPLETE
			dc.b	1,'L'-'@',X_CLEAR_AND_REDRAW
			dc.b	1,'['-'@',X_COMPLETE
			dc.b	1,'_'-'@',X_COPY_PREV_WORD
			dc.b	1,' ',X_SET_MARK
			dc.b	1,'>',X_QUIT_HISTORY
			dc.b	1,'B',X_BACKWARD_WORD
			dc.b	1,'C',X_CAPITALIZE_WORD
			dc.b	1,'D',X_KILL_FOR_WORD
			dc.b	1,'F',X_FORWARD_WORD
			dc.b	1,'L',X_DOWNCASE_WORD
			dc.b	1,'N',X_HISTORY_SEARCH_FORWARD_CIRCULAR
			dc.b	1,'P',X_HISTORY_SEARCH_BACKWARD_CIRCULAR
			dc.b	1,'T',X_TRANSPOSE_WORDS
			dc.b	1,'U',X_UPCASE_WORD
			dc.b	1,'W',X_COPY_REGION
			dc.b	1,'_',X_INSERT_LAST_WORD
			dc.b	1,'b',X_BACKWARD_WORD
			dc.b	1,'c',X_CAPITALIZE_WORD
			dc.b	1,'d',X_KILL_FOR_WORD
			dc.b	1,'f',X_FORWARD_WORD
			dc.b	1,'l',X_DOWNCASE_WORD
			dc.b	1,'n',X_HISTORY_SEARCH_FORWARD
			dc.b	1,'p',X_HISTORY_SEARCH_BACKWARD
			dc.b	1,'t',X_TRANSPOSE_WORDS
			dc.b	1,'u',X_UPCASE_WORD
			dc.b	1,'w',X_COPY_REGION
			dc.b	1,$7f,X_KILL_BACK_WORD
			dc.b	2,'D'-'@',X_LIST_RAW
			dc.b	2,'I'-'@',X_COMPLETE_RAW
			dc.b	2,'L'-'@',X_DOWNCASE_REGION
			dc.b	2,'U'-'@',X_UPCASE_REGION
			dc.b	2,'X'-'@',X_EXG_POINT_AND_MARK
			dc.b	-1

msg_follows_macro:	dc.b	'macro に続く',0
msg_bad_funcname:	dc.b	'このような名前の機能はありません',0

msg_usage_of_bind:
		dc.b	'     bind [-a]',CR,LF
		dc.b	'          現在のキー・バインドを表示する',CR,LF,LF
		dc.b	'     bind -d',CR,LF
		dc.b	'     bind default',CR,LF
		dc.b	'          デフォルトのキー・バインドに戻す',CR,LF,LF
		dc.b	'     bind [[prefix]-{1|2}] <キー>',CR,LF
		dc.b	'          <キー>にバインドされている機能を表示する',CR,LF,LF
		dc.b	'     bind [[prefix]-{1|2}] <キー> <機能>',CR,LF
		dc.b	'          <キー>に<機能>をバインドする',CR,LF,LF
		dc.b	'     bind [[prefix]-{1|2}] <キー> macro <文字列>',CR,LF
		dc.b	'          <キー>に<文字列>をバインドする',0

str_option_a:		dc.b	'-a',0
str_option_d:		dc.b	'-d',0

.end
