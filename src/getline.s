* getline.s
* Itagaki Fumihiko 29-Jul-90  Create.

.include doscall.h
.include error.h
.include chrcode.h
.include limits.h
.include stat.h
.include pwd.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/history.h
.include ../src/var.h
.include ../src/function.h

.xref isupper
.xref isalpha
.xref isalnum
.xref iscntrl
.xref issjis
.xref isspace2
.xref tolower
.xref toupper
.xref itoa
.xref atou
.xref scanchar2
.xref strbot
.xref strchr
.xref jstrchr
.xref strcmp
.xref strcpy
.xref stpcpy
.xref strlen
.xref strmove
.xref strfor1
.xref strforn
.xref memcmp
.xref memxcmp
.xref memmovi
.xref memmovd
.xref strpcmp
.xref rotate
.xref skip_space
.xref skip_varname
.xref make_wordlist
.xref sort_wordlist_x
.xref uniq_wordlist
.xref is_all_same_word
.xref strip_quotes
.xref skip_root
.xref skip_slashes
.xref find_slashes
.xref is_slash_or_backslash
.xref putc
.xref cputc
.xref puts
.xref nputs
.xref put_space
.xref put_newline
.xref printfi
.xref printfs
.xref compile_esch
.xref preparse_fmtout
.xref builtin_dir_match
.xref is_builtin_dir
.xref check_executable_suffix
.xref isnotttyin
.xref fgetc
.xref fgets
.xref close_tmpfd
.xref open_passwd
.xref fgetpwent
.xref subst_var
.xref subst_directory
.xref contains_dos_wildcard
.xref fair_pathname
.xref get_fair_pathname
.xref headtail
.xref cat_pathname
.xref isfullpathx
.xref is_dot
.xref stat
.xref findvar
.xref do_line_substhist
.xref which
.if 0
.xref cmd_eval
.xref find_function
.xref source_function
.endif
.xref find_shellvar
.xref get_shellvar
.xref get_var_value
.xref svartol
.xref common_spell
.xref getcwdx
.xref print_dirstack
.xref is_histchar_canceller
.xref xmalloc
.xref xmalloct
.xref free
.xref xfreetp
.xref minmaxul
.xref drvchkp
.xref manage_interrupt_signal
.xref unmatched
.xref too_long_line
.xref statement_table
.xref builtin_table
.xref key_function_word_table
.xref key_function_names_top
.xref word_columns
.xref word_fignore
.xref word_path
.xref word_prompt
.xref word_prompt2
.xref word_status
.xref dos_allfile
.xref msg_nolabel

.xref congetbuf
.xref tmpword1
.xref tmpword2
.xref tmppwline
.xref tmppwbuf

.xref mainjmp
.xref stackp
.xref line
.xref history_top
.xref history_bot
.xref current_eventno
.xref current_source
.xref alias_top
.xref completion_top
.xref shellvar_top
.xref env_top
.xref function_bot
.if 0
.xref function_root
.endif
.xref funcdef_status
.xref switch_status
.xref if_status
.xref loop_status
.xref histchar1
.xref wordchars
.xref flag_addsuffix
.xref flag_autolist
.xref flag_cifilec
.xref flag_listexec
.xref flag_listlinks
.xref flag_matchbeep
.xref flag_noalias
.xref flag_nobeep
.xref flag_noglob
.xref flag_nonullcommandc
.xref flag_recexact
.xref flag_reconlyexec
.xref flag_showdots
.xref flag_usegets
.xref last_congetbuf
.xref keymap
.xref keymacromap
.xref linecutbuf
.xref tmpfd
.xref in_prompt
.xref in_getline_x
.xref tmpargs

.text

*****************************************************************
* getline - line に 1論理行を入力する
*
* CALL
*      D2.B   0 ならばコメントを削除しない
*      D3.B   0 ならば行継続を認識しない
*      A1     プロンプト出力ルーチンのエントリ・アドレス
*
* RETURN
*      D0.L   0:入力有り，-1:EOF，-2: 入力エラー+EOF，1:入力エラー
*      D1.W   残り入力可能バイト数（最後のNUL分は勘定しない）
*      CCR    TST.L D0
*****************************************************************
.xdef getline

getline:
		movem.l	d3-d6/a0-a4,-(a7)
		lea	line(a5),a2
		move.w	#MAXLINELEN,d1
		moveq	#0,d4				*  D4.B : 全体クオート・フラグ
		movea.l	a2,a0
getline_more:
		**
		**  １物理行を入力する
		**
		movea.l	a0,a4
		bsr	getline_phigical
		bmi	getline_eof
		bne	getline_return

		suba.l	a1,a1
****************
		tst.b	d2
		beq	getline_comment_cut_done
		**
		**  コメントを探す
		**
		movea.l	a4,a3
		move.b	d4,d6
		moveq	#0,d5				*  D5.L : {}レベル
find_comment_loop:
		move.b	(a3)+,d0
		beq	find_comment_break

		bsr	issjis
		beq	find_comment_skip_one

		tst.l	d5
		beq	find_comment_0

		cmp.b	#'}',d0
		bne	find_comment_0

		subq.l	#1,d5
find_comment_0:
		tst.b	d6
		beq	find_comment_1

		cmp.b	d6,d0
		bne	find_comment_loop
find_comment_flip_quote:
		eor.b	d0,d6
		bra	find_comment_loop

find_comment_1:
		tst.l	d5
		bne	find_comment_2

		cmp.b	#'#',d0
		beq	find_comment_break
find_comment_2:
		cmp.b	#'\',d0
		beq	find_comment_ignore_next_char

		cmp.b	#'"',d0
		beq	find_comment_flip_quote

		cmp.b	#"'",d0
		beq	find_comment_flip_quote

		cmp.b	#'`',d0
		beq	find_comment_flip_quote

		cmp.b	#'!',d0
		beq	find_comment_special

		cmp.b	#'$',d0
		bne	find_comment_loop

		cmpi.b	#'@',(a3)
		beq	find_comment_special_var

		cmpi.b	#'%',(a3)
		bne	find_comment_special
find_comment_special_var:
		addq.l	#1,a3
find_comment_special:
		cmpi.b	#'{',(a3)
		bne	find_comment_ignore_next_char

		addq.l	#1,a3
		addq.l	#1,d5
		bra	find_comment_loop

find_comment_ignore_next_char:
		move.b	(a3)+,d0
		beq	find_comment_break

		bsr	issjis
		bne	find_comment_loop
find_comment_skip_one:
		move.b	(a3)+,d0
		bne	find_comment_loop
find_comment_break:
		**
		**  コメントを削除する
		**
		clr.b	-(a3)
		move.l	a0,d0
		sub.l	a3,d0
		add.w	d0,d1
		movea.l	a3,a0
getline_comment_cut_done:
		**
		**  行継続をチェックする
		**
		tst.b	d3
		beq	getline_done

		movea.l	a4,a3
getline_cont_check_loop:
		cmpa.l	a0,a3
		beq	getline_newline_not_escaped

		move.b	(a3)+,d0
		bsr	issjis
		beq	getline_cont_check_sjis

		cmp.b	#'"',d0
		beq	getline_cont_check_quote

		cmp.b	#"'",d0
		beq	getline_cont_check_quote

		cmp.b	#'`',d0
		beq	getline_cont_check_quote

		tst.b	d4
		bne	getline_cont_check_loop

		cmp.b	#'\',d0
		bne	getline_cont_check_loop

		cmpa.l	a0,a3
		beq	getline_newline_escaped

		move.b	(a3),d0
		bsr	issjis
		beq	getline_cont_check_loop
getline_cont_check_skip:
		addq.l	#1,a3
		bra	getline_cont_check_loop

getline_cont_check_quote:
		tst.b	d4
		beq	getline_cont_check_quote_open

		cmp.b	d4,d0
		bne	getline_cont_check_loop
getline_cont_check_quote_open:
		eor.b	d0,d4
		bra	getline_cont_check_loop

getline_cont_check_sjis:
		cmpa.l	a0,a3
		bne	getline_cont_check_skip
getline_newline_not_escaped:
		tst.b	d4
		beq	getline_done
		*
		*  クオートが閉じていない。
		*  改行を復帰改行としてクオートする。
		*
		subq.w	#2,d1
		bcs	getline_over

		move.b	#CR,(a0)+
		move.b	#LF,(a0)+
		clr.b	(a0)
		bra	getline_more

getline_newline_escaped:
		*
		*  改行が \ でエスケープされている。
		*  \を取り除き、改行を挿入せずに行継続する。
		*
		addq.w	#1,d1
		clr.b	-(a0)
		bra	getline_more

getline_done:
		moveq	#0,d0
getline_return:
		movem.l	(a7)+,d3-d6/a0-a4
		tst.l	d0
		rts

getline_eof:
		move.b	d4,d0
		beq	getline_eof_1

		bsr	unmatched
		moveq	#-2,d0
		bra	getline_return

getline_eof_1:
		moveq	#-1,d0
		bra	getline_return

getline_over:
		moveq	#1,d0
		bra	getline_return
*****************************************************************
* getline_phigical
*
* CALL
*      A0     行バッファ入力ポインタ
*      A1     プロンプト出力ルーチンのエントリ・アドレス
*      A2     行バッファ先頭アドレス
*      D1.W   入力最大バイト数（32767以下．最後のNUL分は勘定しない）
*
* RETURN
*      A0     入力文字数分進む
*      D0.L   0:入力有り，-1:EOF，1:入力エラー
*      D1.W   残り入力可能バイト数（最後のNUL分は勘定しない）
*      CCR    TST.L D0
*****************************************************************
.xdef getline_phigical

getline_phigical:
		tst.l	current_source(a5)
		beq	getline_phigical_stdin

		bsr	getline_phigical_script
		bra	getline_phigical_1

getline_phigical_stdin:
		bsr	getline_stdin
getline_phigical_1:
		beq	getline_phigical_return
		bpl	too_long_line
getline_phigical_return:
		rts
****************
getline_phigical_script:
		movem.l	a1-a2,-(a7)
		movea.l	current_source(a5),a2
		cmpi.l	#-1,SOURCE_ONINTR_POINTER(a2)
		beq	getline_phigical_script_no_interrupt

		DOS	_KEYSNS				*  To allow interrupt
getline_phigical_script_no_interrupt:
		movea.l	SOURCE_POINTER(a2),a1
		movea.l	SOURCE_BOT(a2),a2
		bsr	getline_script_sub
		bmi	getline_phigical_script_return

		movea.l	current_source(a5),a2
		move.l	a1,SOURCE_POINTER(a2)
		addq.l	#1,SOURCE_LINENO(a2)
getline_phigical_script_return:
		movem.l	(a7)+,a1-a2
		tst.l	d0
		rts
*****************************************************************
getline_script_sub:
		move.l	a3,-(a7)
		movea.l	a1,a3
getline_script_sub_loop:
		cmpa.l	a2,a3
		bhs	getline_script_sub_eof

		cmpi.b	#LF,(a3)+
		bne	getline_script_sub_loop

		move.l	a3,d0
		sub.l	a1,d0
		subq.l	#1,d0
		beq	getline_script_sub_1

		cmpi.b	#CR,-2(a3)
		bne	getline_script_sub_1

		subq.l	#1,d0
getline_script_sub_1:
		cmp.l	#$ffff,d0
		bhi	getline_script_sub_over

		sub.w	d0,d1
		bcs	getline_script_sub_over

		bsr	memmovi
		moveq	#0,d0
getline_script_sub_done:
		clr.b	(a0)
getline_script_sub_return:
		movea.l	a3,a1
		movea.l	(a7)+,a3
		tst.l	d0
		rts

getline_script_sub_over:
		moveq	#1,d0
		bra	getline_script_sub_return

getline_script_sub_eof:
		moveq	#-1,d0
		bra	getline_script_sub_done
*****************************************************************
.xdef getline_stdin

getline_stdin:
		moveq	#0,d0
		bsr	put_prompt
		movem.l	d0,-(a7)
		bsr	isnotttyin
		movem.l	(a7)+,d0
		beq	fgets

		tst.b	flag_usegets(a5)
		beq	getline_x
getline_standard_console:
		move.l	a1,-(a7)

		move.l	a0,-(a7)
		lea	congetbuf,a0
		move.l	a0,-(a7)
		move.b	#255,(a0)+

		lea	last_congetbuf(a5),a1
		move.b	(a1)+,(a0)+
		bsr	strcpy
		DOS	_GETS
		addq.l	#4,a7
		bsr	put_newline
		lea	congetbuf+1,a0
		tst.b	(a0)+
		beq	getline_console_done

		bsr	skip_space
		tst.b	(a0)
		beq	getline_console_done

		lea	congetbuf+1,a1
		lea	last_congetbuf(a5),a0
		move.b	(a1)+,(a0)+
		bsr	strcpy
getline_console_done:
		movea.l	(a7)+,a0

		lea	congetbuf+1,a1
		moveq	#0,d0
		move.b	(a1)+,d0
		sub.w	d0,d1
		bcs	getline_console_over

		clr.b	(a1,d0.l)
		bsr	strmove
		moveq	#0,d0
getline_console_return:
		movea.l	(a7)+,a1
		rts

getline_console_over:
		moveq	#1,d0
		bra	getline_console_return
*****************************************************************

put_prompt_ptr = -4
macro_ptr = put_prompt_ptr-4
line_top = macro_ptr-4
global_line_top = line_top-4
save_line = global_line_top-4
save_length = save_line-4
bottomline = save_length-4
x_histptr = bottomline-4
input_handle = x_histptr-4
mark = input_handle-2
point = mark-2
nbytes = point-2
bottombytes = nbytes-2
keymap_offset = bottombytes-2
quote = keymap_offset-1
killing = quote-1
x_hist_circle = killing-1
pad = x_hist_circle-1			*  偶数バウンダリーに合わせる

getline_x:
		st	in_getline_x(a5)
		link	a6,#pad
		movem.l	d2-d7/a1-a3,-(a7)
		move.w	d0,input_handle(a6)
		move.l	a0,line_top(a6)
		move.l	a1,put_prompt_ptr(a6)
		move.l	a2,global_line_top(a6)
		clr.l	bottomline(a6)
		clr.l	macro_ptr(a6)
		clr.w	nbytes(a6)
		clr.w	point(a6)
		move.w	#-1,mark(a6)
		move.l	#-1,x_histptr(a6)
getline_x_0:
		sf	quote(a6)
getline_x_1:
		sf	killing(a6)
getline_x_2:
		bclr.b	#1,x_hist_circle(a6)
x_no_op:
		clr.w	keymap_offset(a6)
getline_x_3:
		bsr	getline_x_getc
		bmi	getline_x_eof

		tst.b	quote(a6)
		bne	x_self_insert

		tst.b	d0
		bmi	x_self_insert

		moveq	#0,d2
		move.b	d0,d2
		add.w	keymap_offset(a6),d2
		lea	keymap(a5),a0
		moveq	#0,d3
		move.b	(a0,d2.l),d3
		lsl.l	#2,d3
		lea	key_function_jump_table,a0
		movea.l	(a0,d3.l),a0
		jmp	(a0)
********************************
*  list-or-eof
********************************
********************************
*  eof
********************************
x_list_or_eof:
		tst.w	nbytes(a6)
		bne	x_list
x_eof:
		bsr	iscntrl
		sne	d1
		bsr	cputc
		moveq	#2,d0
		tst.b	d1
		beq	x_eof_1

		moveq	#1,d0
x_eof_1:
		bsr	backward_cursor
getline_x_eof:
		moveq	#-1,d0
getline_x_return:
		move.l	d0,-(a7)
		lea	bottomline(a6),a0
		bsr	xfreetp
		bsr	terminate_line
		move.l	(a7)+,d0
		movem.l	(a7)+,d2-d7/a1-a3
		unlk	a6
		sf	in_getline_x(a5)
		rts
********************************
*  self-insert
********************************
x_self_insert:
		move.b	d0,d4				*  D4.B : 第１バイト
		moveq	#1,d2				*  D2.W : 挿入するバイト数
		bsr	issjis
		sne	d3				*  D3.B : 「シフトJIS文字である」
		bne	x_self_insert_1

		bsr	getline_x_getc
		bmi	getline_x_eof

		move.b	d0,d5				*  D5.B : シフトJISの第２バイト
		moveq	#2,d2
x_self_insert_1:
		bsr	open_columns
		bcs	x_self_insert_over

		move.b	d4,(a0)
		tst.b	d3
		bne	x_self_insert_2

		move.b	d5,1(a0)
x_self_insert_2:
		bsr	post_insert_job
x_self_insert_done:
		bra	getline_x_0

x_self_insert_over:
		bsr	beep
		bra	x_self_insert_done
********************************
*  error
********************************
x_error:
		bsr	beep
		bra	getline_x_1
********************************
*  keyboard-quit
********************************
x_keyboard_quit:
		bsr	moveto_bol
		moveq	#0,d4
		move.w	nbytes(a6),d2
		bsr	compile_region
		bsr	delete_region
		bra	getline_x_0
********************************
*  macro
********************************
x_macro:
		tst.l	macro_ptr(a6)
		bne	x_error				*  マクロでマクロは呼び出せないのだ

		lea	keymacromap(a5),a0
		lsl.l	#2,d2
		move.l	(a0,d2.l),macro_ptr(a6)
		bra	getline_x_1
********************************
*  eval-command
********************************
x_eval_command:
		lea	x_eval_command_sub(pc),a2
x_eval_command_1:
		moveq	#0,d0
		move.w	nbytes(a6),d0
		add.l	line_top(a6),d0
		sub.l	global_line_top(a6),d0
		move.l	d0,save_length(a6)
		bsr	xmalloc
		beq	x_error				*  メモリが足りない

		movem.l	a0-a1,-(a7)
		move.l	d0,save_line(a6)
		movea.l	d0,a0
		movea.l	global_line_top(a6),a1
		move.l	save_length(a6),d0
		bsr	memmovi
		movem.l	(a7)+,a0-a1
		movem.l	d1/a4/a6,-(a7)
		move.l	mainjmp(a5),-(a7)
		move.l	stackp(a5),-(a7)
		move.l	a0,-(a7)
		lea	x_eval_command_done(pc),a0
		move.l	a0,mainjmp(a5)
		movea.l	(a7)+,a0
		move.l	a7,stackp(a5)
		bsr	eol_newline
		jsr	(a2)
x_eval_command_done:
		move.l	(a7)+,stackp(a5)
		move.l	(a7)+,mainjmp(a5)
		movem.l	(a7)+,d1/a4/a6
		movea.l	global_line_top(a6),a0
		movea.l	save_line(a6),a1
		move.l	save_length(a6),d0
		move.l	a1,-(a7)
		bsr	memmovi
		move.l	(a7)+,d0
		bsr	free
		bra	x_redraw_1

x_eval_command_sub:
		lea	keymacromap(a5),a0
		lsl.l	#2,d2
		movea.l	(a0,d2.l),a0
		sf	d7
		bra	do_line_substhist
********************************
*  prefix-1
********************************
x_prefix_1:
		move.w	#128,keymap_offset(a6)
		bra	getline_x_3
********************************
*  prefix-2
********************************
x_prefix_2:
		move.w	#256,keymap_offset(a6)
		bra	getline_x_3
********************************
*  abort
********************************
x_abort:
		bsr	cputc
		bsr	put_newline
		bra	manage_interrupt_signal
********************************
*  accept-line
********************************
x_accept_line:
		bsr	eol_newline
		moveq	#0,d0
		bra	getline_x_return

terminate_line:
		movea.l	line_top(a6),a0
		move.w	nbytes(a6),d0
		lea	(a0,d0.w),a0
		clr.b	(a0)
		rts
********************************
*  quoted-insert
********************************
x_quoted_insert:
		st	quote(a6)
		bra	getline_x_1
********************************
*  redraw
********************************
********************************
*  clear-and-redraw
********************************
x_clear_and_redraw:
		lea	t_clear,a0
		bsr	puts
		bra	x_redraw_1

x_redraw:
		bsr	eol_newline
x_redraw_1:
		bsr	redraw_with_prompt
		bra	getline_x_1
********************************
*  set-mark
********************************
x_set_mark:
		move.w	point(a6),mark(a6)
		bra	getline_x_1
********************************
*  exchange-point-and-mark
********************************
x_exg_point_and_mark:
		move.w	mark(a6),d0
		bmi	x_error

		move.w	point(a6),mark(a6)
x_goto:
		move.w	point(a6),d2			*  D2.W : point
		move.w	d0,point(a6)
		movea.l	line_top(a6),a0
		lea	backward_cursor_x(pc),a1
		cmp.w	d0,d2
		bhi	x_exg_point_and_mark_2

		lea	forward_cursor_x(pc),a1
		exg	d0,d2
x_exg_point_and_mark_2:
		lea	(a0,d0.w),a0
		sub.w	d0,d2
		move.w	d2,d0
		jsr	(a1)
		bra	getline_x_1
********************************
*  search-character
********************************
x_search_character:
		bsr	getline_x_getletter
		bmi	getline_x_eof

		movea.l	line_top(a6),a0
		move.w	nbytes(a6),d2
		clr.b	(a0,d2.w)
		move.w	point(a6),d4
		cmp.w	d2,d4
		beq	x_search_char_1

		exg	d0,d4
		bsr	x_size_forward
		exg	d0,d4
		add.w	d2,d4
		lea	(a0,d4.w),a0
		bsr	jstrchr
		bne	x_search_char_ok
x_search_char_1:
		movea.l	line_top(a6),a0
		bsr	jstrchr
		beq	x_error
x_search_char_ok:
		move.l	a0,d0
		movea.l	line_top(a6),a0
		sub.l	a0,d0
		bra	x_goto
********************************
*  beginning-of-line
********************************
x_bol:
		bsr	moveto_bol
		bra	getline_x_1
********************************
*  end-of-line
********************************
x_eol:
		bsr	move_cursor_to_eol
		move.w	nbytes(a6),point(a6)
		bra	getline_x_1
********************************
*  backward-char
********************************
x_backward_char:
		bsr	move_letter_backward
		bra	getline_x_1
********************************
*  forward-char
********************************
x_forward_char:
		bsr	move_letter_forward
		bra	getline_x_1
********************************
*  backward-word
********************************
x_backward_word:
		bsr	move_word_backward
		bra	getline_x_1
********************************
*  forward-word
********************************
x_forward_word:
		bsr	move_word_forward
		bra	getline_x_1
********************************
*  next-word
********************************
x_next_word:
		moveq	#0,d5
		bsr	next_nonwordchar
		bsr	next_wordchar
		move.l	d5,d0
		bsr	forward_cursor
		bra	getline_x_1
********************************
*  delete-backward-char
********************************
x_del_back_char:
		bsr	move_letter_backward
		move.w	point(a6),d4
xp_delete:
		bsr	delete_region
		bra	getline_x_1
********************************
*  delete-forward-char-or-list-or-eof
********************************
********************************
*  delete-forward-char-or-list
********************************
********************************
*  delete-forward-char
********************************
x_del_for_char_or_list_or_eof:
		tst.w	nbytes(a6)
		beq	x_eof
x_del_for_char_or_list:
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	x_list
x_del_for_char:
		move.w	point(a6),d4
		bsr	forward_letter
		move.w	d4,point(a6)
		bra	xp_delete
********************************
*  kill-backward-word
********************************
x_kill_back_word:
		bsr	backward_word
		move.w	point(a6),d4
		moveq	#3,d7
		bra	x_kill_region_backward_1
********************************
*  kill-forward-word
********************************
x_kill_for_word:
		move.w	point(a6),d4
		bsr	forward_word
		moveq	#1,d7
		bra	x_kill_or_copy_region_2
********************************
*  kill-whole-line
********************************
x_kill_whole_line:
		bsr	moveto_bol
********************************
*  kill-to-eol
********************************
x_kill_eol:
		move.w	nbytes(a6),d4
x_kill_eol_1:
		moveq	#1,d7
		bra	x_kill_or_copy_region_1
********************************
*  kill-to-bol
********************************
x_kill_bol:
		moveq	#0,d4
		bra	x_kill_eol_1
********************************
*  kill-region
********************************
********************************
*  copy-region
********************************
x_copy_region:
		moveq	#0,d7
		bra	x_kill_or_copy_region

x_kill_region:
		moveq	#1,d7
x_kill_or_copy_region:
		move.w	mark(a6),d0
		bmi	x_error

		move.w	d0,d4				*  D4.W : mark
x_kill_or_copy_region_1:
		move.w	point(a6),d2			*  D2.W : point
		cmp.w	d4,d2
		bhs	x_kill_region_backward

		exg	d2,d4
		bsr	compile_region
x_kill_or_copy_region_2:
		move.w	d4,point(a6)
x_kill_or_copy_region_3:
		move.b	d7,d0
		bsr	copy_region_to_buffer
		btst	#0,d7
		beq	x_kill_or_copy_region_done

		bsr	delete_region
x_kill_or_copy_region_done:
		bra	getline_x_2

x_kill_region_backward:
		bset	#1,d7
		bsr	compile_region
x_kill_region_backward_1:
		btst	#0,d7
		beq	x_kill_or_copy_region_3

		move.l	d3,d0
		bsr	backward_cursor
		bra	x_kill_or_copy_region_2

compile_region:
		movea.l	line_top(a6),a0
		lea	(a0,d4.w),a0
		sub.w	d4,d2
		move.w	d2,d0
		bsr	region_width
		move.l	d0,d3
		rts
********************************
*  yank
********************************
x_yank:
		movea.l	linecutbuf(a5),a0
x_copy_string:
		movea.l	a0,a1
		bsr	strlen
		move.l	d0,d2
x_copy:
		bsr	open_columns
		bcs	x_error

		move.l	d2,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	post_insert_job
		bra	getline_x_1
********************************
*  copy-prev-word
********************************
x_copy_prev_word:
		move.w	point(a6),-(a7)
		bsr	backward_word
		move.w	point(a6),d0
		move.w	(a7)+,point(a6)
		movea.l	line_top(a6),a1
		lea	(a1,d0.w),a1
		bra	x_copy
********************************
*  insert-last-word
********************************
x_insert_last_word:
		movea.l	history_bot(a5),a0
		cmpa.l	#0,a0
		beq	getline_x_1

		move.w	HIST_NWORDS(a0),d0
		subq.w	#1,d0
		bls	getline_x_1

		lea	HIST_BODY(a0),a0
		bsr	strforn
		bra	x_copy_string
********************************
*  change-case
********************************
x_change_case:
		move.w	point(a6),d3
		cmp.w	nbytes(a6),d3
		beq	getline_x_1

		movea.l	line_top(a6),a0
		move.b	(a0,d3.w),d0
		bsr	isupper
		beq	x_downcase_char
********************************
*  upcase-char
********************************
x_upcase_char:
		lea	toupper(pc),a1
chcase_char:
		moveq	#1,d0
chcase:
		bsr	chcase_sub
		bra	getline_x_1

chcase_sub:
		move.w	point(a6),d4
		add.w	d0,d4
chcase_loop:
		move.w	point(a6),d3
		cmp.w	nbytes(a6),d3
		beq	chcase_done

		cmp.w	d4,d3
		bhs	chcase_done

		movea.l	line_top(a6),a0
		move.b	(a0,d3.w),d0
		jsr	(a1)
		cmp.b	(a0,d3.w),d0
		bne	chcase_char_changed

		bsr	move_letter_forward
		bra	chcase_loop

chcase_char_changed:
		move.b	d0,(a0,d3.w)
		bsr	putc
		bsr	forward_letter
		bra	chcase_loop

chcase_done:
		rts
********************************
*  downcase-char
********************************
x_downcase_char:
		lea	tolower(pc),a1
		bra	chcase_char
********************************
*  upcase-word
********************************
x_upcase_word:
		lea	toupper(pc),a1
chcase_word:
		move.w	point(a6),-(a7)
		bsr	forward_word
		move.w	(a7)+,point(a6)
		move.w	d2,d0
		bra	chcase
********************************
*  downcase-word
********************************
x_downcase_word:
		lea	tolower(pc),a1
		bra	chcase_word
********************************
*  capitalize-word
********************************
x_capitalize_word:
		move.w	point(a6),d4
		bsr	forward_word
		move.w	d4,point(a6)
		add.w	d2,d4
capitalize_loop1:
		move.w	point(a6),d3
		cmp.w	nbytes(a6),d3
		beq	capitalize_done

		cmp.w	d4,d3
		bhs	capitalize_done

		movea.l	line_top(a6),a0
		move.b	(a0,d3.w),d0
		bsr	isalpha
		beq	capitalize_loop1_break

		bsr	move_letter_forward
		bra	capitalize_loop1

capitalize_loop1_break:
		lea	tolower(pc),a1
		bsr	toupper
		bsr	chcase_char_changed
capitalize_done:
		bra	getline_x_1
********************************
*  upcase-region
********************************
x_upcase_region:
		lea	toupper(pc),a1
chcase_region:
		move.w	mark(a6),d0
		bmi	x_error

		move.w	point(a6),d2
		cmp.w	d0,d2
		bls	chcase_region_forward

		move.w	d0,point(a6)
		movea.l	line_top(a6),a0
		lea	(a0,d0.w),a0
		sub.w	d0,d2
		move.w	d2,d0
		bsr	backward_cursor_x
		move.w	d2,d0
		bra	chcase

chcase_region_forward:
		sub.w	d2,d0
		movem.l	d0/d2,-(a7)
		bsr	chcase_sub
		movem.l	(a7)+,d0/d2
		move.w	d2,point(a6)
		movea.l	line_top(a6),a0
		lea	(a0,d2.w),a0
		bsr	backward_cursor_x
		bra	getline_x_1
********************************
*  downcase-region
********************************
x_downcase_region:
		lea	tolower(pc),a1
		bra	chcase_region
********************************
*  transpose-gosling
********************************
x_transpose_gosling:
		cmp.w	#2,point(a6)
		blo	x_error
		bra	x_transpose_chars_0
********************************
*  transpose-chars
********************************
x_transpose_chars:
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		blo	x_transpose_chars_1
x_transpose_chars_0:
		bsr	move_letter_backward
x_transpose_chars_1:
		move.w	point(a6),d0
		beq	x_error

		bsr	x_size_forward
		move.w	d2,d4
		bsr	move_letter_backward
		bsr	transpose
		bra	getline_x_1
********************************
*  transpose-words
********************************
x_transpose_words:
		move.w	point(a6),d4
		bsr	move_word_forward
		bsr	move_word_backward
		move.w	point(a6),d0
		bne	x_transpose_word_ok

		move.w	d4,point(a6)
		move.w	d4,d0
		movea.l	line_top(a6),a0
		bsr	forward_cursor_x
		bra	x_error

x_transpose_word_ok:
*  ROOTS  ROCK REGGAE
*         ~カーソル
*         ^ポインタ
		move.w	d2,d4				*  D4.W : 右の単語のバイト数
		bsr	move_word_backward
*  ROOTS  ROCK REGGAE
*  ~カーソル
*  ^ポインタ
		move.w	d2,d5				*  D5.W : 左の単語＋スペースのバイト数
		move.l	d3,d6				*  D6.L : 左の単語＋スペースの文字幅
		move.w	point(a6),-(a7)
		bsr	forward_word			*  D2.W : 左の単語のバイト数
*  ROOTS  ROCK REGGAE
*  ~カーソル
*       ^ポインタ
		move.w	(a7)+,point(a6)
*  ROOTS  ROCK REGGAE
*  ~カーソル
*  ^ポインタ
		exg	d2,d5
		bsr	transpose
*  ROCKROOTS   REGGAE
*              ~カーソル
*              ^ポインタ
		sub.w	d2,point(a6)
*  ROCKROOTS   REGGAE
*              ~カーソル
*      ^ポインタ
		move.l	d6,d0
		bsr	backward_cursor
*  ROCKROOTS   REGGAE
*      ~カーソル
*      ^ポインタ
		move.w	d2,d4
		sub.w	d5,d4
		move.w	d5,d2
		bsr	transpose
*  ROCK  ROOTS REGGAE
*             ~カーソル
*             ^ポインタ
		bra	getline_x_1
********************************
transpose:
		movea.l	line_top(a6),a0
		adda.w	point(a6),a0			*  正しい
		lea	(a0,d2.w),a1
		lea	(a1,d4.w),a2
		bsr	rotate
		move.w	d2,d0
		add.w	d4,d0
		bsr	write_chars
		move.w	mark(a6),d3
		bmi	transpose_done

		sub.w	point(a6),d3
		blo	transpose_done

		sub.w	d2,d3
		blo	transpose_mark_forward

		sub.w	d4,d3
		bhs	transpose_done

		sub.w	d2,mark(a6)
		bra	transpose_done

transpose_mark_forward:
		add.w	d4,mark(a6)
transpose_done:
		add.w	d0,point(a6)
		rts
********************************
x_history_prev:
		cmpa.l	#0,a1
		beq	x_history_null
		bmi	x_history_bottom

		movea.l	HIST_PREV(a1),a1
		rts
********************************
x_history_next:
		cmpa.l	#0,a1
		beq	x_history_over
		bmi	x_history_null

		movea.l	HIST_NEXT(a1),a1
		cmpa.l	#0,a1
		beq	x_history_over

		rts

x_history_null:
		clr.l	a1
		rts

x_history_over:
		movea.l	#-1,a1
		rts

x_history_bottom:
		movea.l	history_bot(a5),a1
		rts
********************************
*  up-history
********************************
x_up_history:
		moveq	#-1,d3
		move.l	x_histptr(a6),d4
		movea.l	d4,a1
		bsr	x_history_prev
		cmpa.l	#0,a1
		beq	x_error

		bra	save_and_insert_history
********************************
*  down-history
********************************
x_down_history:
		moveq	#-1,d3
		movea.l	x_histptr(a6),a1
		bsr	x_history_next
		cmpa.l	#0,a1
		beq	x_error
		bpl	insert_history
********************************
*  quit-history
********************************
x_quit_history:
		tst.l	x_histptr(a6)
		bmi	x_eol

		moveq	#-1,d3
x_quit_history_1:
		move.l	#-1,x_histptr(a6)
		bsr	delete_line
		move.l	bottomline(a6),d0
		beq	x_quit_history_3

		movea.l	d0,a1
		movea.l	line_top(a6),a0
		moveq	#0,d0
		move.w	bottombytes(a6),d0
		move.w	d0,nbytes(a6)
		bsr	memmovi
x_quit_history_3:
		lea	bottomline(a6),a0
		bsr	xfreetp
		bra	copy_history_done
********************************
*  history-search-forward
*  history-search-forward-circular
********************************
x_history_search_forward_circular:
		bset.b	#0,x_hist_circle(a6)
		bra	x_history_search_forward_start

x_history_search_forward:
		bclr.b	#0,x_hist_circle(a6)
x_history_search_forward_start:
		bclr	#2,x_hist_circle(a6)
		move.l	x_histptr(a6),d4
		movea.l	d4,a1
x_history_search_forward_more:
		bsr	x_history_next
x_history_search_forward_more_1:
		cmpa.l	#0,a1
		beq	x_history_search_forward_fail

		movea.l	line_top(a6),a0
		moveq	#0,d0
		move.w	point(a6),d0
		cmpa.l	#0,a1
		bmi	x_history_search_forward_1

		moveq	#HIST_NEXT,d3
		bsr	history_search
		beq	x_history_search_forward_1

		bsr	histcmp2
		beq	x_history_search_forward_more

		bra	save_and_insert_history

x_history_search_forward_1:
		bsr	histcmp_bottom
		beq	x_quit_history_1
x_history_search_forward_fail:
		btst.b	#0,x_hist_circle(a6)
		beq	x_history_search_circle_warning

		btst	#1,x_hist_circle(a6)
		beq	x_history_search_circle_warning

		btst	#2,x_hist_circle(a6)
		bne	x_history_search_circle_warning

		movea.l	history_top(a5),a1
		bclr.b	#0,x_hist_circle(a6)
		bra	x_history_search_forward_more_1

x_history_search_circle_warning:
		bset	#1,x_hist_circle(a6)
		bsr	beep
		bra	x_no_op
********************************
*  history-search-backward
*  history-search-backward-circular
********************************
x_history_search_backward_circular:
		bset.b	#0,x_hist_circle(a6)
		bra	x_history_search_backward_start

x_history_search_backward:
		bclr.b	#0,x_hist_circle(a6)
x_history_search_backward_start:
		bset	#2,x_hist_circle(a6)
		move.l	x_histptr(a6),d4
		movea.l	d4,a1
x_history_search_backward_more:
		movea.l	line_top(a6),a0
		moveq	#0,d0
		move.w	point(a6),d0
		bsr	x_history_prev
		cmpa.l	#0,a1
		beq	x_history_search_backward_fail

		moveq	#HIST_PREV,d3
		bsr	history_search
		bne	x_history_search_backward_found
x_history_search_backward_fail:
		btst.b	#0,x_hist_circle(a6)
		beq	x_history_search_circle_warning

		btst	#1,x_hist_circle(a6)
		beq	x_history_search_circle_warning

		btst	#2,x_hist_circle(a6)
		beq	x_history_search_circle_warning

		bsr	histcmp_bottom
		beq	x_quit_history_1

		movea.l	#-1,a1
		bclr.b	#0,x_hist_circle(a6)
		bra	x_history_search_backward_more

x_history_search_backward_found:
		bsr	histcmp2
		beq	x_history_search_backward_more

save_and_insert_history:
		tst.l	d4
		bpl	insert_history

		lea	bottomline(a6),a0
		bsr	xfreetp
		moveq	#0,d0
		move.w	nbytes(a6),d0
		move.w	d0,bottombytes(a6)
		beq	insert_history

		bsr	xmalloct
		beq	x_error

		move.l	a1,-(a7)
		move.l	d0,a0
		move.l	a0,bottomline(a6)
		movea.l	line_top(a6),a1
		moveq	#0,d0
		move.w	bottombytes(a6),d0
		bsr	memmovi
		movea.l	(a7)+,a1
****************
insert_history:
		move.l	a1,x_histptr(a6)

		bsr	delete_line

		movea.l	line_top(a6),a0
		move.w	HIST_NWORDS(a1),d2		*  D2.W : このイベントの単語数
		subq.w	#1,d2
		bcs	copy_history_done

		lea	HIST_BODY(a1),a1		*  A1 : 履歴の単語並びの先頭
		bra	copy_history_start

copy_history_loop:
		subq.w	#1,d1
		bcs	copy_history_over

		move.b	#' ',(a0)+
		addq.w	#1,nbytes(a6)
copy_history_start:
copy_history_dup_word_loop:
		moveq	#0,d0
		exg	a0,a1
		bsr	scanchar2
		exg	a0,a1
		beq	copy_history_continue

		cmp.w	histchar1(a5),d0
		bne	copy_history_dup_1

		move.b	(a1),d0
		bsr	is_histchar_canceller
		beq	copy_history_dup_histchar

		subq.w	#1,d1
		bcs	copy_history_over

		move.b	#'\',(a0)+
		addq.w	#1,nbytes(a6)
copy_history_dup_histchar:
		move.w	histchar1(a5),d0
copy_history_dup_1:
		cmp.w	#$100,d0
		blo	copy_history_dup_1byte
copy_history_dup_2byte:
		subq.w	#1,d1
		bcs	copy_history_over

		move.w	d0,-(a7)
		lsr.w	#8,d0
		move.b	d0,(a0)+
		move.w	(a7)+,d0
		addq.w	#1,nbytes(a6)
copy_history_dup_1byte:
		subq.w	#1,d1
		bcs	copy_history_over

		move.b	d0,(a0)+
		addq.w	#1,nbytes(a6)
		bra	copy_history_dup_word_loop

copy_history_continue:
		dbra	d2,copy_history_loop
copy_history_done:
		move.w	nbytes(a6),point(a6)
		cmp.w	point(a6),d3
		bhi	copy_history_draw

		move.w	d3,point(a6)
copy_history_draw:
		bsr	redraw
		bra	getline_x_1

copy_history_over:
		addq.w	#1,d1
		bsr	beep
		bra	copy_history_done
****************************************************************
.xdef is_word_separator

is_special:
		cmp.b	#'\',d0
		beq	is_special_return

		cmp.b	#'*',d0
		beq	is_special_return

		cmp.b	#'?',d0
		beq	is_special_return

		cmp.b	#'[',d0
		beq	is_special_return

		cmp.b	#'{',d0
		beq	is_special_return
is_word_separator:
		movem.l	d0/a0,-(a7)
		lea	word_separators,a0
		bsr	strchr				*  word_separators にシフトJIS文字は無い
		seq	d0
		tst.b	d0
		movem.l	(a7)+,d0/a0
is_special_return:
		rts
****************************************************************
histcmp2:
		movem.l	d1/a1,-(a7)
		move.w	HIST_NWORDS(a1),d0
		lea	HIST_BODY(a1),a0
		movea.l	line_top(a6),a1
		moveq	#0,d1
		move.w	nbytes(a6),d1
		bsr	histcmp
		movem.l	(a7)+,d1/a1
		bne	histcmp2_return

		tst.w	d2
histcmp2_return:
		rts
****************************************************************
histcmp_bottom:
		move.l	d0,d3
		beq	histcmp_bottom_return

		move.l	bottomline(a6),d2
		beq	histcmp_bottom_fail

		movea.l	d2,a1
		bsr	memcmp
histcmp_bottom_return:
		rts

histcmp_bottom_fail:
		moveq	#1,d0
		bra	histcmp_bottom_return
****************************************************************
* histcmp
*
* CALL
*      A0     履歴イベントのボディ
*      D0.W   履歴イベントの単語数
*      A1     比較する文字列
*      D1.L   比較する文字列の長さ
*
* RETURN
*      D0.L   一致したとき、実際に一致したバイト数
*      D2.W   残った単語数
*      CCR    一致すれば EQ
****************************************************************
histcmp:
		movem.l	d1/d3/a0-a2,-(a7)
		movea.l	a0,a2
		move.w	d0,d2
histcmp_loop1:
		subq.l	#1,d1
		bcs	histcmp_matched

		move.b	(a1)+,d0
		bsr	isspace2
		beq	histcmp_loop1

		subq.l	#1,a1
		addq.l	#1,d1

		tst.w	d2
		beq	histcmp_fail

		move.b	(a0),d0
		bsr	is_word_separator
		sne	d3
histcmp_loop2:
		move.b	(a0)+,d0
		beq	histcmp_nul
		
		cmp.b	(a1)+,d0
		bne	histcmp_fail

		subq.l	#1,d1
		bne	histcmp_loop2
histcmp_matched:
		sf	d3
		tst.w	d2
		beq	histcmp_done

		tst.b	(a0)
		bne	histcmp_done

		subq.w	#1,d2
		bra	histcmp_done

histcmp_nul:
		subq.w	#1,d2
		tst.b	d3
		beq	histcmp_loop1

		move.b	(a1),d0
		bsr	is_word_separator
		beq	histcmp_loop1
histcmp_fail:
		st	d3
histcmp_done:
		move.l	a0,d0
		sub.l	a2,d0
		tst.b	d3
		movem.l	(a7)+,d1/d3/a0-a2
		rts
****************************************************************
* history_search - ある文字列を含む履歴を検索する
*
* CALL
*      A0     検索文字列
*      D0.L   検索文字列の長さ
*      A1     検索を開始するイベントを指す
*      D3.W   方向（HIST_PREV or HIST_NEXT）
*
* RETURN
*      CCR    見つかったならば NE
*      A1     見つかったイベントを指す．見つからなければ破壊
*      D3.L   実際にマッチしたバイト数．見つからなければ破壊
****************************************************************
history_search:
		movem.l	d0-d2/d4/a0/a2,-(a7)
		movea.l	a1,a2				* A2 : 履歴ポインタ
		movea.l	a0,a1				* A1 : 検索文字列
		move.l	d0,d1				* D1.L : 検索文字列の長さ
		move.w	d3,d4
		bra	history_search_loop

history_search_continue:
		movea.l	(a2,d4.w),a2
history_search_loop:
		cmpa.l	#0,a2
		beq	history_search_return

		move.w	HIST_NWORDS(a2),d0		* D0.W : このイベントの語数
		beq	history_search_continue

		lea	HIST_BODY(a2),a0
		bsr	histcmp
		bne	history_search_continue

		move.l	d0,d3
history_search_found:
		movea.l	a2,a1				*  A1 : 見つかったイベント
		cmpa.l	#0,a1
history_search_return:
		movem.l	(a7)+,d0-d2/d4/a0/a2
		rts
********************************
*  which-command
********************************
x_which_command:
		bsr	filec_parse_line
		bmi	x_error

		movea.l	a2,a0
		bsr	strlen
		beq	x_error

		lea	which(pc),a2
		bra	x_eval_command_1
****************************************************************
* filec_parse_line
*
* CALL
*      none
*
* RETURN
*      A2     対象となる単一コマンドの先頭
*      D2.L   対象となる単一コマンドの単語数
*      D3.B   補完候補区分
*             0 : files
*             1 : statements ->
*             2 : aliases -> functions -> $path
*      D0/D4/A0-A1   破壊
****************************************************************
filec_parse_line:
	*
	*  物理行を単語に分解する
	*
		movea.l	line_top(a6),a0
		move.w	point(a6),d3
		move.b	(a0,d3.w),d4
		clr.b	(a0,d3.w)
		movea.l	tmpargs(a5),a1
		move.l	d1,-(a7)
		move.w	#MAXWORDLISTSIZE,d1
		st	d2
		bsr	make_wordlist
		move.l	(a7)+,d1
		move.b	d4,(a0,d3.w)
		move.l	d0,d4				*  D4.L : 物理行全体の単語数
		bmi	filec_parse_line_error
	*
	*  コマンドの先頭を見つける
	*  complete_raw での候補（ファイルかコマンドか）を決める
	*
		movea.l	tmpargs(a5),a0
filec_scan_statement:
		moveq	#1,d0
filec_scan_command:
		movea.l	a0,a2				*  A2 : 単一コマンドの先頭
		move.l	d4,d2				*  D2.L : A2 以降の単語数
filec_scan_words:
		move.b	d0,d3				*  D3.B : 候補区分
		subq.l	#1,d4
		beq	filec_scan_done

		move.b	(a0)+,d0
		beq	filec_scan_args

		cmp.b	#';',d0
		beq	filec_scan_semicolon

		cmp.b	#'|',d0
		beq	filec_scan_and_or

		cmp.b	#'&',d0
		beq	filec_scan_and_or

		cmp.b	#'(',d0
		beq	filec_scan_paren
filec_scan_next:
		bsr	strfor1
filec_scan_args:
		moveq	#0,d0			*  0 : all files
		bra	filec_scan_words

filec_scan_and_or:
		cmp.b	(a0)+,d0
		beq	filec_scan_andand_oror

		subq.l	#1,a0
filec_scan_andand_oror:
filec_scan_semicolon:
		tst.b	(a0)+
		bne	filec_scan_next

		moveq	#2,d0
		bra	filec_scan_command

filec_scan_paren:
		tst.b	(a0)+
		bne	filec_scan_next

		tst.b	d3
		beq	filec_scan_args
		bra	filec_scan_statement

filec_scan_done:
		subq.l	#1,d2
		moveq	#0,d0
		rts

filec_parse_line_error:
		rts
********************************

FLAGBIT_LIST       = 0
FLAGBIT_RAW        = 1
FLAGBIT_NOSUBSTDIR = 2

FLAGX_COMPL      = 0
FLAGX_LIST       = 1<<FLAGBIT_LIST
FLAGX_COMPL_RAW  = 1<<FLAGBIT_RAW
FLAGX_LIST_RAW   = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_RAW)

PROP_FILE        = 0
PROP_DIRECTORY   = 1
PROP_COMMAND     = 2
PROP_USER        = 3
PROP_SVAR        = 4
PROP_ENVIRON     = 5
PROP_ALIAS       = 6
PROP_FUNCTION    = 7
PROP_BINDING     = 8
PROP_COMPLETION  = 9

********************************
*  list
********************************
x_list:
		moveq	#FLAGX_LIST,d7
		bra	x_filec_or_list
********************************
*  list-raw
********************************
x_list_raw:
		moveq	#FLAGX_LIST_RAW,d7
		bra	x_filec_or_list
********************************
*  complete
********************************
x_complete:
		moveq	#FLAGX_COMPL,d7
		bra	x_filec_or_list
********************************
*  complete-raw
********************************
x_complete_raw:
		moveq	#FLAGX_COMPL_RAW,d7

filec_statbuf = -STATBUFSIZE
filec_file_search_path = filec_statbuf-(((MAXPATH+1)+1)>>1<<1)
filec_current_program = filec_file_search_path-4
filec_current_statement = filec_current_program-4
filec_action = filec_current_statement-4
filec_pattern = filec_action-4
filec_program_suffix = filec_pattern-4
filec_program_delimiter = filec_program_suffix-2
filec_branch_time = filec_program_delimiter-2
filec_fignore = filec_branch_time-2
filec_fignore_list = filec_fignore-4
filec_files_path_ptr = filec_fignore_list-4
filec_files_path_count = filec_files_path_ptr-2
filec_files_builtin_ptr = filec_files_path_count-4
filec_buffer_ptr = filec_files_builtin_ptr-4
filec_buffer_free = filec_buffer_ptr-2
filec_command_top = filec_buffer_free-4
filec_argno = filec_command_top-4
filec_patlen = filec_argno-4
filec_maxlen = filec_patlen-4
filec_minlen = filec_maxlen-4
filec_minlen_precious = filec_minlen-4
filec_numentry = filec_minlen_precious-2
filec_numprecious = filec_numentry-2
filec_suffix = filec_numprecious-1
filec_suffix_precious = filec_suffix-1
filec_exact_suffix = filec_suffix_precious-1
filec_exact_suffix_precious = filec_exact_suffix-1
filec_flag = filec_exact_suffix_precious-1
filec_quote = filec_flag-1
filec_command_position = filec_quote-1
filec_file_findmode = filec_command_position-1
filec_file_path_fullpath = filec_file_findmode-1
filec_file_path_dot = filec_file_path_fullpath-1
filec_case_independent = filec_file_path_dot-1
filec_pad = filec_case_independent-1

x_filec_or_list:
		link	a4,#filec_pad
		move.b	d7,filec_flag(a4)
		bsr	filec_parse_line
		bmi	filec_error

		move.l	a2,filec_command_top(a4)
		move.l	d2,filec_argno(a4)
		move.b	d3,filec_command_position(a4)	*  0 : files
							*  1 : statements ->
							*  2 : aliases -> functions -> $path
	*
	*  対象の単語を tmpword1 にコピーする
	*  クオートが開いているかどうか調べる
	*
		movea.l	filec_command_top(a4),a0
		move.l	filec_argno(a4),d0
		bsr	strforn
		lea	tmpword1,a1
		clr.b	filec_quote(a4)
filec_copy_word_loop:
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		beq	filec_copy_word_done

		tst.b	filec_quote(a4)
		beq	filec_copy_word_not_in_quote

		cmp.b	filec_quote(a4),d0
		bne	filec_copy_word_1
filec_copy_word_quote:
		eor.b	d0,filec_quote(a4)
		bra	filec_copy_word_loop

filec_copy_word_not_in_quote:
		cmp.b	#'"',d0
		beq	filec_copy_word_quote

		cmp.b	#"'",d0
		beq	filec_copy_word_quote

		cmp.b	#'`',d0
		beq	filec_copy_word_quote

		cmp.b	#'\',d0
		bne	filec_copy_word_1
filec_check_quote_escape:
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		beq	filec_copy_word_done
filec_copy_word_1:
		bsr	issjis
		bne	filec_copy_word_loop

		move.b	(a0)+,d0
		move.b	d0,(a1)+
		bne	filec_copy_word_loop
filec_copy_word_done:
	*
	*  ワーク初期設定
	*
		movea.l	tmpargs(a5),a0
		move.l	a0,filec_buffer_ptr(a4)
		move.w	#MAXWORDLISTSIZE,filec_buffer_free(a4)
		clr.w	filec_numentry(a4)
		clr.w	filec_numprecious(a4)
		clr.l	filec_maxlen(a4)
		move.l	#-1,filec_minlen(a4)
		move.l	#-1,filec_minlen_precious(a4)
		clr.b	filec_exact_suffix(a4)
		clr.b	filec_exact_suffix_precious(a4)
	*
		clr.l	filec_pattern(a4)		*!!
		clr.l	filec_program_suffix(a4)	*!!
	*
	*  変数名補完か？
	*
		lea	tmpword1,a1
		clr.b	d2				*  quote
filec_check_doller_loop1:
		moveq	#0,d3
filec_check_doller_loop2:
		move.b	(a1)+,d0
		beq	filec_check_doller_done

		tst.b	d2
		beq	filec_check_doller_not_in_quote

		cmp.b	d2,d0
		beq	filec_check_doller_quote

		cmp.b	#"'",d2
		bne	filec_check_doller_not_in_single_quote
		bra	filec_check_doller_check_slash

filec_check_doller_quote:
		eor.b	d0,d2
		bra	filec_check_doller_loop2

filec_check_doller_not_in_quote:
		cmp.b	#'\',d0
		bne	filec_check_doller_not_escape

		move.b	(a1)+,d0
		beq	filec_check_doller_done
		bra	filec_check_doller_check_slash

filec_check_doller_not_escape:
		cmp.b	#'"',d0
		beq	filec_check_doller_quote

		cmp.b	#"'",d0
		beq	filec_check_doller_quote

		cmp.b	#'`',d0
		beq	filec_check_doller_quote
filec_check_doller_not_in_single_quote:
		cmp.b	#'$',d0
		beq	filec_check_doller_doller
filec_check_doller_check_slash:
		bsr	issjis
		beq	filec_check_doller_sjis

		cmp.b	#'/',d0
		beq	filec_check_doller_loop1

		cmp.b	#'\',d0
		beq	filec_check_doller_loop1
		bra	filec_check_doller_loop2

filec_check_doller_sjis:
		tst.b	(a1)+
		beq	filec_check_doller_done
		bra	filec_check_doller_loop2

filec_check_doller_doller:
		move.l	a1,d3
		bra	filec_check_doller_loop2

filec_check_doller_done:
		tst.l	d3
		beq	filec_not_varname

		movea.l	d3,a1
		move.b	(a1)+,d2
		cmp.b	#'@',d2
		beq	filec_doller_varname_1

		cmp.b	#'%',d2
		beq	filec_doller_varname_1

		subq.l	#1,a1
filec_doller_varname_1:
		moveq	#0,d0
		cmpi.b	#'{',(a1)
		bne	filec_doller_varname_3

		addq.l	#1,a1
		moveq	#'}',d0
filec_doller_varname_3:
		move.b	d0,filec_suffix(a4)
		move.b	(a1)+,d0
		cmp.b	#'#',d0
		beq	filec_doller_varname_4

		cmp.b	#'?',d0
		beq	filec_doller_varname_4

		subq.l	#1,a1
filec_doller_varname_4:
		movea.l	a1,a0
		lea	tmpword1,a0
		bsr	strcpy
		bsr	strlen
		move.l	d0,filec_patlen(a4)		*!!

		moveq	#0,d0
		move.b	filec_suffix(a4),d0
		beq	filec_doller_varname_5

		bsr	jstrchr
		bne	filec_beep
filec_doller_varname_5:
		cmp.b	#'%',d2
		beq	filec_doller_varname_6

		bsr	complete_svarname
		bne	filec_error
filec_doller_varname_6:
		cmp.b	#'@',d2
		beq	filec_doller_varname_7

		bsr	complete_envname
		bne	filec_error
filec_doller_varname_7:
		bra	filec_find_done

filec_not_varname:
	*
	*  programmable completion のチェック
	*
		btst.b	#FLAGBIT_RAW,filec_flag(a4)
		bne	complete_raw

		movea.l	filec_command_top(a4),a0
		movea.l	completion_top(a5),a2
complete_search_program_loop:
		cmpa.l	#0,a2
		beq	complete_raw

		lea	var_body(a2),a1
		cmpi.b	#':',(a1)
		beq	complete_search_program_next

		bclr.b	#FLAGBIT_NOSUBSTDIR,filec_flag(a4)
complete_search_program_check_flag:
		move.b	(a1)+,d0
		cmp.b	#'-',d0
		beq	complete_program_x

		cmp.b	#'=',d0
		bne	complete_compare_program
complete_program_nosubst:
		bset.b	#FLAGBIT_NOSUBSTDIR,filec_flag(a4)
complete_program_x:
		bra	complete_search_program_check_flag

complete_compare_program:
		subq.l	#1,a1
		st	d0
		bsr	strpcmp
		beq	complete_program_found
complete_search_program_next:
		movea.l	var_next(a2),a2
		bra	complete_search_program_loop

complete_program_found:
		bsr	filec_try_static_rule
		bmi	filec_error

		subq.l	#1,d0
		beq	filec_find_done

		subq.l	#1,d0
		beq	filec_done

		clr.w	filec_branch_time(a4)
		clr.l	filec_pattern(a4)		*!!
complete_program_found_2:
		move.l	a2,filec_current_program(a4)
		move.l	a2,d0
		bsr	get_var_value
		move.w	d0,d2
		movea.l	a0,a2
		move.l	filec_pattern(a4),d0		*!!
		beq	filec_test_program_start

		tst.w	d2
		beq	completion_label_not_found

		movea.l	d0,a0
		bsr	strlen
		move.l	d0,d3
complete_search_label_loop:
		cmpi.b	#':',(a2)
		bne	complete_search_label_continue

		lea	1(a2),a1
		move.l	d3,d0
		bsr	memcmp
		bne	complete_search_label_continue

		cmpi.b	#':',(a1,d3.l)
		beq	filec_test_program_start
complete_search_label_continue:
		exg	a0,a2
		bsr	strfor1
		exg	a0,a2
		subq.w	#1,d2
		bne	complete_search_label_loop
completion_label_not_found:
		lea	msg_nolabel,a1
		bra	filec_perror

filec_test_program_start:
filec_test_program_loop:
		subq.w	#1,d2
		bcs	complete_raw_2

		move.l	a2,filec_current_statement(a4)
		move.b	(a2)+,d3
		beq	filec_test_program_loop

		cmp.b	#':',d3
		bne	filec_test_program_1

		moveq	#':',d0
		exg	a0,a2
		bsr	strchr
		exg	a0,a2
		beq	filec_program_error

		addq.l	#1,a2
		move.b	(a2)+,d3
		beq	filec_test_program_loop
filec_test_program_1:
		exg	a0,a2
		bsr	scanchar2
		exg	a0,a2
		beq	filec_program_error

		move.w	d0,filec_program_delimiter(a4)

		cmp.b	#'p',d3
		beq	filec_program_p

		bra	filec_program_error

filec_test_program_skip:
		movea.l	a2,a0
		bsr	strfor1
		movea.l	a0,a2
		bra	filec_test_program_loop

filec_program_p:
		bsr	get_filec_program_field		*  get pattern
		beq	filec_error			*  no action field

		cmpi.b	#'*',(a0)
		bne	filec_program_p_1

		tst.b	1(a0)
		bne	filec_program_p_1

		tst.l	filec_argno(a4)
		beq	filec_test_program_skip
		bra	filec_program_pattern_matched

filec_program_p_1:
		lea	tmpword2,a0
		moveq	#0,d4
		cmpi.b	#'-',(a0)+
		beq	filec_program_p_2

		subq.l	#1,a0
		movem.l	d1,-(a7)
		bsr	atou
		exg	d0,d1
		movem.l	(a7)+,d1
		bmi	filec_program_error
		bne	filec_test_program_skip

		move.l	d0,d4
		move.l	d0,d5
		cmpi.b	#'-',(a0)
		bne	filec_program_p_3

		addq.l	#1,a0
filec_program_p_2:
		move.l	filec_argno(a4),d5
		movem.l	d1,-(a7)
		bsr	atou
		exg	d0,d1
		movem.l	(a7)+,d1
		bne	filec_program_p_3

		move.l	d0,d5
filec_program_p_3:
		cmp.l	filec_argno(a4),d4
		bhi	filec_test_program_skip

		cmp.l	filec_argno(a4),d5
		blo	filec_test_program_skip
filec_program_pattern_matched:
		bsr	get_filec_program_field		*  get action
		move.l	a2,filec_program_suffix(a4)	*!!
		move.l	a0,filec_action(a4)
filec_program_action_loop:
		movea.l	filec_action(a4),a0
		move.b	(a0)+,d3
		beq	filec_find_done

		move.l	a0,filec_action(a4)
		move.b	#' ',filec_suffix(a4)		*  default
		cmp.b	#'>',d3
		beq	complete_branch

		clr.l	filec_pattern(a4)		*!!
		cmp.b	#'(',d3
		beq	complact_fromlist

		moveq	#':',d0
		bsr	strchr
		beq	filec_program_action_1

		clr.b	(a0)+
		move.l	a0,filec_pattern(a4)		*!!
filec_program_action_1:
		movea.l	filec_action(a4),a0
		cmp.b	#'$',d3
		beq	complact_fromvar

		move.b	(a0),d0
		bne	filec_error

		cmp.b	#'C',d3
		beq	complact_completion

		cmp.b	#'F',d3
		beq	complact_function

		cmp.b	#'a',d3
		beq	complact_alias

		cmp.b	#'b',d3
		beq	complact_bindings

		cmp.b	#'c',d3
		beq	complact_cmdname

		cmp.b	#'d',d3
		beq	complact_directory

		cmp.b	#'e',d3
		beq	complact_envname

		cmp.b	#'f',d3
		beq	complact_file

		cmp.b	#'s',d3
		beq	complact_svarname

		cmp.b	#'u',d3
		beq	complact_username

		cmp.b	#'v',d3
		beq	complact_anyvarname

		cmp.b	#'x',d3
		beq	complact_explain
filec_program_error:
		movea.l	filec_current_statement(a4),a0
		lea	msg_completion_syntax_error,a1
		bra	filec_perror

complete_branch:
		cmp.w	#1000,filec_branch_time(a4)
		bhs	completion_program_loop

		addq.w	#1,filec_branch_time(a4)

		moveq	#':',d0
		movea.l	a0,a2
		bsr	strchr
		bne	complete_longjmp

		move.l	a2,filec_pattern(a4)		*!!
		movea.l	filec_current_program(a4),a2
		bra	complete_program_found_2

complete_longjmp:
		clr.b	(a0)+
		move.l	a0,filec_pattern(a4)		*!!
		movea.l	a2,a0
		movea.l	completion_top(a5),a2
complete_search_longjmp_loop:
		cmpa.l	#0,a2
		beq	completion_not_found

		lea	var_body(a2),a1
		bsr	strcmp
		beq	complete_program_found_2

		movea.l	var_next(a2),a2
		bra	complete_search_longjmp_loop

completion_not_found:
		lea	msg_completion_not_found,a1
		bra	filec_perror

completion_program_loop:
		suba.l	a0,a0
		lea	msg_completion_program_loop,a1
		bra	filec_perror
****************
complact_fromlist:
		movea.l	a0,a2				*  A2 : リストのポインタ
		moveq	#0,d2				*  D2.L : 単語数
complact_fromlist_sep_loop1:
		movea.l	a0,a1
		bsr	skip_space
		exg	a0,a1
		cmpa.l	a0,a1
		beq	complact_fromlist_separate_space_ok
		bsr	strcpy
complact_fromlist_separate_space_ok:
		move.b	(a0)+,d0
		beq	filec_error

		cmp.b	#')',d0
		beq	complact_fromlist_sep_done

		addq.l	#1,d2
complact_fromlist_sep_loop2:
		cmp.b	#'\',d0
		bne	complact_fromlist_dupchar

		movea.l	a0,a1
		lea	-1(a1),a0
		bsr	strcpy
		move.b	(a0)+,d0
complact_fromlist_dupchar:
		bsr	issjis
		bne	complact_fromlist_check_term

		tst.b	(a0)+
		beq	filec_error
complact_fromlist_check_term:
		move.b	(a0)+,d0
		cmp.b	#')',d0
		beq	complact_fromlist_sep_done_1

		bsr	isspace2
		bne	complact_fromlist_sep_loop2

		clr.b	-1(a0)
		bra	complact_fromlist_sep_loop1

complact_fromlist_sep_done_1:
		clr.b	-1(a0)
complact_fromlist_sep_done:
		move.l	a0,filec_action(a4)
complact_fromlist_2:
		bsr	complete_fromlist
complact_continue_x:
		bne	filec_error

		movea.l	filec_action(a4),a0
		tst.b	(a0)
		bne	filec_error

		bra	filec_find_done
****************
complact_fromvar:
		movea.l	a0,a2
		bsr	skip_varname
		tst.b	d0
		bne	filec_error

		move.l	a0,filec_action(a4)
		movea.l	a2,a0
		bsr	get_shellvar
		movea.l	a0,a2				*  A2 : リストのポインタ
		move.l	d0,d2				*  D2.L : 単語数
		bra	complact_fromlist_2
****************
complact_completion:
		movea.l	completion_top(a5),a2
		bsr	complete_varspace
		bra	complact_continue_x
****************
complact_function:
		bsr	complete_function
		bra	complact_continue_x
****************
complact_alias:
		bsr	complete_alias
		bra	complact_continue_x
****************
complact_bindings:
		bsr	complete_bindings
		bra	complact_continue_x
****************
complact_cmdname:
		bsr	complete_cmdname
		bra	complact_continue_x
****************
complact_directory:
		bsr	complete_directory
		bra	complact_continue_x
****************
complact_file:
		bsr	complete_file
		bra	complact_continue_x
****************
complact_username:
		bsr	complete_username
		bra	complact_continue_x
****************
complact_svarname:
		bsr	complete_svarname
		bra	complact_continue_x
****************
complact_anyvarname:
		bsr	complete_svarname
		bne	complact_anyvarname_done
complact_envname:
		bsr	complete_envname
complact_anyvarname_done:
		bra	complact_continue_x
****************
complact_explain:
		bsr	eol_newline
		move.l	filec_pattern(a4),d0		*!!
		beq	complete_explain_1

		movea.l	d0,a0
		bsr	puts
complete_explain_1:
		bsr	put_newline
		bsr	redraw_with_prompt
		bra	complact_continue_x
********************************
get_filec_program_field:
		move.w	filec_program_delimiter(a4),d0
		movea.l	a2,a0
		bsr	jstrchr
		move.l	a0,d0
		sub.l	a2,d0
		movea.l	a2,a1
		lea	tmpword2,a0
		bsr	memmovi
		clr.b	(a0)
		lea	tmpword2,a0
		movea.l	a1,a2
		tst.b	(a2)
		beq	get_filec_program_field_return	*  ZF=1

		addq.l	#1,a2
		moveq	#1,d0				*  ZF=0
get_filec_program_field_return:
		rts
********************************
complete_raw:
		bclr.b	#FLAGBIT_NOSUBSTDIR,filec_flag(a4)
		bsr	filec_try_static_rule
		bmi	filec_error

		subq.l	#1,d0
		beq	filec_find_done

		subq.l	#1,d0
		beq	filec_done
complete_raw_2:
		clr.l	filec_pattern(a4)		*!!
		tst.b	filec_command_position(a4)
		beq	complete_raw_file

		tst.b	flag_nonullcommandc(a5)
		beq	complete_raw_cmdname

		tst.b	tmpword1
		bne	complete_raw_cmdname
complete_raw_file:
		bsr	complete_file
		bra	filec_find_done_x

complete_raw_cmdname:
		move.b	#' ',filec_suffix(a4)		*  default
		bsr	complete_cmdname
		bra	filec_find_done_x
********************************
filec_try_static_rule:
		clr.l	filec_pattern(a4)		*!!
		tst.b	flag_noglob(a5)
		bne	filec_not_dirstack

		btst.b	#FLAGBIT_NOSUBSTDIR,filec_flag(a4)
		bne	filec_not_dirstack
	*
	*  ユーザ名補完か？
	*
		lea	tmpword1,a1
		lea	tmpword2,a0
		bsr	strcpy
		bsr	strip_quotes
		bsr	builtin_dir_match
		bne	filec_not_username

		lea	tmpword1,a0			*  tmpword1 : 元の単語
		cmpi.b	#'~',(a0)
		bne	filec_not_username

		lea	tmpword2+1,a0			*  tmpword2 : クオートを外した単語
		bsr	find_slashes
		bne	filec_not_username

		move.b	#'/',filec_suffix(a4)
		lea	tmpword1,a0
		lea	1(a0),a1
		bsr	strcpy
		bsr	strlen
		move.l	d0,filec_patlen(a4)		*!!
		bsr	complete_username
		bne	filec_static_rule_error

		moveq	#1,d0
		rts

filec_not_username:
	*
	*  ディレクトリ・スタックか？
	*
		lea	tmpword1,a0			*  tmpword1 : 元の単語
		cmpi.b	#'=',(a0)
		bne	filec_not_dirstack

		lea	tmpword2+1,a0			*  tmpword2 : クオートを外した単語
		bsr	find_slashes
		bne	filec_not_dirstack

		bsr	eol_newline
		movem.l	d1/a4,-(a7)
		moveq	#3,d4				*  -vl
		lea	puts(pc),a3
		lea	put_newline(pc),a4
		bsr	print_dirstack
		bsr	redraw_with_prompt
		movem.l	(a7)+,d1/a4
		moveq	#2,d0
		rts

filec_not_dirstack:
	*
	*  ユーザ名補完でもディレクトリ・スタックでもない
	*
		*  変数置換
		lea	tmpword1,a0
		lea	tmpword2,a1
		clr.b	(a1)
		moveq	#1,d0
		movem.l	d1/a0-a1,-(a7)
		move.w	#MAXWORDLEN+1,d1
		bsr	subst_var
		movem.l	(a7)+,d1/a0-a1
		subq.l	#1,d0
		bhi	filec_static_rule_error

		tst.b	flag_noglob(a5)
		bne	filec_not_substdir

		btst.b	#FLAGBIT_NOSUBSTDIR,filec_flag(a4)
		bne	filec_not_substdir

		cmpi.b	#'.',(a1)
		bne	filec_substdir

		cmpi.b	#'.',1(a1)
		bne	filec_substdir

		tst.b	(a1)
		beq	filec_not_substdir
filec_substdir:
		*  ディレクトリ置換
		exg	a0,a1
		moveq	#3,d2
		movem.l	d1/a0-a1,-(a7)
		move.l	#MAXWORDLEN+1,d1
		bsr	subst_directory
		movem.l	(a7)+,d1/a0-a1
		bne	filec_static_rule_error

		exg	a0,a1
filec_strip_quotes:
		bsr	strip_quotes
		bsr	strlen
		move.l	d0,filec_patlen(a4)		*!!
		moveq	#0,d0
		rts

filec_not_substdir:
		bsr	strcpy
		bra	filec_strip_quotes

filec_static_rule_error:
		moveq	#-1,d0
		rts
********************************
filec_find_done_x:
		bne	filec_error
filec_find_done:
		btst.b	#FLAGBIT_LIST,filec_flag(a4)
		bne	filec_list			*  リスト表示へ

		move.w	filec_numentry(a4),d0
		beq	filec_nomatch

		tst.w	filec_numprecious(a4)
		bne	filec_numprecious_ok

		move.w	d0,filec_numprecious(a4)
		move.b	filec_suffix(a4),filec_suffix_precious(a4)
		move.b	filec_exact_suffix(a4),filec_exact_suffix_precious(a4)
		move.l	filec_minlen(a4),filec_minlen_precious(a4)
filec_numprecious_ok:
		*
		*  最初の曖昧でない部分を確定する
		*
		move.l	d1,-(a7)
		movea.l	tmpargs(a5),a0
		move.w	filec_numprecious(a4),d0
		move.l	filec_patlen(a4),d1
		move.b	filec_case_independent(a4),d2
		bsr	common_spell
		move.l	filec_minlen_precious(a4),d1
		sub.l	filec_patlen(a4),d1
		bsr	minmaxul
		move.l	(a7)+,d1
		move.l	d0,d2				*  D2.L : 共通部分の長さ
		*
		*  cifilec がセットされていれば，
		*  一番短い候補を挿入候補として選ぶ．
		*
		movea.l	tmpargs(a5),a1
		tst.b	filec_case_independent(a4)
		beq	filec_select_word_ok

		movem.l	d1-d2,-(a7)
		movea.l	a1,a0
		moveq	#-1,d2				*  D2.L := HUGEVAL
		move.w	filec_numprecious(a4),d1
		bra	filec_ci_select_word_start

filec_ci_select_word_loop:
		bsr	strlen
		cmp.l	d2,d0
		bhi	filec_ci_select_word_continue

		movea.l	a0,a1
		move.l	d0,d2
filec_ci_select_word_continue:
		bsr	strfor1
filec_ci_select_word_start:
		dbra	d1,filec_ci_select_word_loop

filec_ci_select_word_done:
		*  さらに，既入力部分を上書きする．

		tst.l	filec_patlen(a4)
		beq	filec_ci_redraw_done		*  既入力は無し

		movea.l	line_top(a6),a0
		adda.w	point(a6),a0			*  正しい
		move.l	a0,-(a7)
		move.b	filec_quote(a4),d2
		move.l	filec_patlen(a4),d1
		adda.l	d1,a1
filec_redraw_backup_loop:
		cmp.l	#2,d1
		blo	filec_redraw_backup_not_sjis

		move.b	-2(a0),d0
		bsr	issjis
		bne	filec_redraw_backup_not_sjis

		move.b	-(a1),-(a0)
		subq.l	#1,d1
		subq.l	#1,a0
		bra	filec_redraw_backup_1

filec_redraw_backup_not_sjis:
		move.b	-(a0),d0
		tst.b	d2
		beq	filec_redraw_backup_not_in_quote

		cmp.b	d2,d0
		bne	filec_redraw_backup_1
filec_redraw_backup_quote:
		eor.b	d0,d2
		bra	filec_redraw_backup_loop

filec_redraw_backup_not_in_quote:
		cmp.b	#'\',d0
		beq	filec_redraw_backup_loop

		cmp.b	#'"',d0
		beq	filec_redraw_backup_quote

		cmp.b	#"'",d0
		beq	filec_redraw_backup_quote
filec_redraw_backup_1:
		move.b	-(a1),(a0)
		subq.l	#1,d1
		bne	filec_redraw_backup_loop

		move.l	(a7)+,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		bsr	backward_cursor_x
		move.l	(a7)+,d0
		bsr	write_chars
filec_ci_redraw_done:
		movem.l	(a7)+,d1-d2
filec_select_word_ok:
		*
		*  完成部分を挿入する
		*
		adda.l	filec_patlen(a4),a1
		move.l	d2,d3
		movem.l	d1/a1,-(a7)
		move.l	d2,d1
		moveq	#0,d2
filec_escape_completed:
		subq.l	#1,d1
		bcs	filec_escape_completed_done

		moveq	#0,d0
		move.b	(a1)+,d0
		bsr	issjis
		beq	filec_escape_completed_sjis

		cmp.w	histchar1(a5),d0
		beq	filec_escape_completed_with_escaping

		cmp.b	#'"',d0
		beq	filec_escape_completed_quote

		cmp.b	#"'",d0
		beq	filec_escape_completed_quote

		cmp.b	#'$',d0
		beq	filec_escape_completed_special

		cmp.b	#'`',d0
		beq	filec_escape_completed_special

		tst.b	filec_quote(a4)
		bne	filec_escape_completed_1

		bsr	is_special
		bne	filec_escape_completed_1
filec_escape_completed_with_escaping:
		addq.l	#2,d2
		bra	filec_escape_completed

filec_escape_completed_sjis:
		addq.l	#1,d2
		subq.l	#1,d1
		bcs	filec_escape_completed_done

		addq.l	#1,d2
		lsl.w	#8,d0
		move.b	(a1)+,d0
		cmp.w	histchar1(a5),d0
		bne	filec_escape_completed
filec_escape_completed_1:
		addq.l	#1,d2
		bra	filec_escape_completed

filec_escape_completed_special:
		tst.b	filec_quote(a4)
		beq	filec_escape_completed_with_escaping

		cmpi.b	#'"',filec_quote(a4)
		bne	filec_escape_completed_1

		bra	filec_escape_completed_complex

filec_escape_completed_quote:
		tst.b	filec_quote(a4)
		beq	filec_escape_completed_with_escaping

		cmp.b	filec_quote(a4),d0
		bne	filec_escape_completed_1
filec_escape_completed_complex:
		addq.l	#4,d2
		bra	filec_escape_completed

filec_escape_completed_done:
		movem.l	(a7)+,d1/a1
		bsr	open_columns
		bcs	filec_error

		move.l	a0,-(a7)
filec_insert:
		subq.l	#1,d3
		bcs	filec_insert_done

		moveq	#0,d0
		move.b	(a1)+,d0
		bsr	issjis
		beq	filec_insert_sjis

		cmp.w	histchar1(a5),d0
		beq	filec_insert_with_escaping

		cmp.b	#'"',d0
		beq	filec_insert_quote

		cmp.b	#"'",d0
		beq	filec_insert_quote

		cmp.b	#'$',d0
		beq	filec_insert_special

		cmp.b	#'`',d0
		beq	filec_insert_special

		tst.b	filec_quote(a4)
		bne	filec_insert_1

		bsr	is_special
		bne	filec_insert_1
filec_insert_with_escaping:
		move.b	#'\',(a0)+
		bra	filec_insert_1

filec_insert_special:
		tst.b	filec_quote(a4)
		beq	filec_insert_with_escaping

		cmpi.b	#'"',filec_quote(a4)
		bne	filec_insert_1

		bra	filec_insert_complex

filec_insert_quote:
		tst.b	filec_quote(a4)
		beq	filec_insert_with_escaping

		cmp.b	filec_quote(a4),d0
		bne	filec_insert_1
filec_insert_complex:
		move.b	filec_quote(a4),(a0)+
		move.b	#'\',(a0)+
		move.b	d0,(a0)+
		move.b	filec_quote(a4),(a0)+
		bra	filec_insert

filec_insert_sjis:
		tst.l	d3
		beq	filec_insert_1

		subq.l	#1,d3
		lsl.w	#8,d0
		move.b	(a1)+,d0
		cmp.w	histchar1(a5),d0
		bne	filec_insert_sjis_1

		move.b	#'\',(a0)+
filec_insert_sjis_1:
		move.w	d0,-(a7)
		lsr.w	#8,d0
		move.b	d0,(a0)+
		move.w	(a7)+,d0
filec_insert_1:
		move.b	d0,(a0)+
		bra	filec_insert

filec_insert_done:
		movea.l	(a7)+,a0
		bsr	post_insert_job

		movea.l	tmpargs(a5),a0
		move.w	filec_numprecious(a4),d0
		bsr	is_all_same_word
		beq	filec_match

		tst.b	filec_exact_suffix_precious(a4)
		beq	filec_ambiguous

		*  not unique exact match

		*  unset matchbeep か set matchbeep=notuniq であるならベルを鳴らす
		move.b	flag_matchbeep(a5),d0
		beq	filec_notunique_beep

		subq.b	#3,d0
		bne	filec_notunique_nobeep
filec_notunique_beep:
		bsr	beep
filec_notunique_nobeep:
		move.b	filec_exact_suffix_precious(a4),filec_suffix_precious(a4)
filec_match:
		move.b	flag_addsuffix(a5),d0		*  シェル変数 addsuffix が
		beq	filec_done			*  セットされていなければおしまい

		tst.l	d2				*  1文字も挿入しなかったならば
		beq	filec_addsuffix			*  サフィックスを追加する

		subq.b	#1,d0				*  $@addsuffix[1] == exact なら
		beq	filec_done			*  今回はサフィックスを追加しない
filec_addsuffix:
		cmpi.b	#'/',filec_suffix_precious(a4)
		beq	filec_addsuffix_1

		move.l	filec_program_suffix(a4),d0	*!!
		beq	filec_addsuffix_1

		movea.l	d0,a1
		movea.l	a1,a0
		move.w	filec_program_delimiter(a4),d0
		bsr	jstrchr
		move.l	a0,d2
		sub.l	a1,d2
		bne	filec_addsuffix_2

		tst.b	(a0)
		bne	filec_addsuffix_2
filec_addsuffix_1:
		lea	filec_suffix_precious(a4),a1
		tst.b	(a1)
		beq	filec_done

		moveq	#1,d2
filec_addsuffix_2:
		bsr	open_columns
		bcs	filec_error

		move.l	d2,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	post_insert_job
		bra	filec_done


filec_nomatch:
		cmpi.b	#3,flag_matchbeep(a5)
		bhi	filec_done			*  set matchbeep=other
filec_beep:
		bsr	beep
filec_done:
		unlk	a4
		bra	getline_x_1

filec_perror:
		bsr	eol_newline
		cmpa.l	#0,a0
		beq	filec_perror_1

		bsr	puts
		moveq	#':',d0
		bsr	putc
		bsr	put_space
filec_perror_1:
		movea.l	a1,a0
		bsr	nputs
		bsr	redraw_with_prompt
filec_error:
		bra	filec_beep

filec_ambiguous:
		move.b	flag_matchbeep(a5),d0
		beq	filec_ambiguous_beep		*  unset matchbeep

		subq.b	#2,d0
		beq	filec_ambiguous_beep		*  set matchbeep=ambiguous

		subq.b	#1,d0
		bne	filec_ambiguous_nobeep
		*  set matchbeep=notunique
filec_ambiguous_beep:
		bsr	beep
filec_ambiguous_nobeep:
		tst.b	flag_autolist(a5)
		beq	filec_done
filec_list:
	*
	*  リスト表示
	*
		move.w	filec_numentry(a4),d0
		movea.l	tmpargs(a5),a0
		move.l	a4,-(a7)
		lea	cmpnames(pc),a4
		bsr	sort_wordlist_x
		movea.l	(a7)+,a4
		bsr	uniq_wordlist
		move.w	d0,d6
		beq	filec_list_done

		addq.l	#2,filec_maxlen(a4)
		*
		*  行の桁数を得る
		*
		move.w	d6,d2				*  1行の項目数=エントリ数
		moveq	#1,d3				*  行数=1行
		moveq	#0,d4				*  1項目多い行数=0
		move.l	d1,-(a7)
		lea	word_columns,a0
		bsr	svartol
		exg	d0,d1
		movem.l	(a7)+,d1
		bmi	filec_list_height_ok
		bne	columns_ok

		moveq	#80,d0
columns_ok:
		exg	d2,d3
		tst.l	d0
		bmi	filec_list_height_ok

		subq.l	#1,d0				*  D0.L : 1行の桁数 - 1
		bcs	filec_list_height_ok
		*
		*  1行に入る最大項目数を計算する -> D2.W
		*
		*      1行に入る最大項目数 = (行の桁数 - 1) / 1項目の最大桁数
		*
		move.l	filec_maxlen(a4),d3
		move.l	d0,d2
		divu	d3,d2
		tst.w	d2
		bne	filec_list_width_ok

		moveq	#1,d2
filec_list_width_ok:
		*
		*  何行になるかを計算する -> D3.W
		*
		*      行数 = エントリ数 / 1行に入る最大項目数
		*
		moveq	#0,d3
		move.w	d6,d3
		divu	d2,d3
		swap	d3
		move.w	d3,d4
		swap	d3
		*
		*  余りがなければＯＫ
		*
		tst.w	d4
		beq	filec_list_height_ok
		*
		*  余りがある --- 行数はさらに1行多い
		*
		addq.w	#1,d3
		*
		*  1行多くなったので、行数をもとに 1行の項目数を再計算する
		*
		moveq	#0,d2
		move.w	d6,d2
		divu	d3,d2
		swap	d2
		move.w	d2,d4				*  D4.W : 1項目多い行数
		swap	d2
		tst.w	d4
		beq	filec_list_height_ok
		*
		*  余りがある --- 1行の項目数はさらに1項目多い
		*                 余り(D4.W)はその1項目多い行数
		*
		addq.w	#1,d2
filec_list_height_ok:
		movea.l	tmpargs(a5),a0
		movea.l	a0,a1				*  A1:最初の行の先頭項目
		bsr	move_cursor_to_eol
filec_list_loop1:
		bsr	put_newline
		movea.l	a1,a0
		bsr	strfor1
		exg	a0,a1				*  A0:この行の先頭項目  A1:次行の先頭項目
		move.w	d2,d5
filec_list_loop2:
		movem.l	d1-d4/a1,-(a7)
		moveq	#1,d1				*  左詰め
		moveq	#' ',d2				*  空白でpad
		move.l	filec_maxlen(a4),d3		*  最小フィールド幅
		moveq	#-1,d4				*  最大出力文字数：$FFFFFFFF
		lea	putc(pc),a1
		bsr	printfs
		movem.l	(a7)+,d1-d4/a1

		subq.w	#1,d6
		beq	filec_list_done

		subq.w	#1,d5
		beq	filec_list_loop2_break

		move.w	d3,d0
		bsr	strforn
		bra	filec_list_loop2

filec_list_loop2_break:
		tst.w	d4
		beq	filec_list_loop1

		subq.w	#1,d4
		bne	filec_list_loop1

		subq.w	#1,d2
		bra	filec_list_loop1

filec_list_done:
		unlk	a4
		bsr	put_newline
		bra	x_redraw_1
****************
cmpnames:
		movem.l	d1/a0-a1,-(a7)
cmpnames_loop:
		moveq	#0,d0
		tst.b	1(a0)
		beq	cmpnames_1

		move.b	(a0)+,d0
cmpnames_1:
		moveq	#0,d1
		tst.b	1(a1)
		beq	cmpanames_2

		move.b	(a1)+,d1
cmpanames_2:
		sub.l	d1,d0
		bne	cmpnames_return

		tst.b	d1
		bne	cmpnames_loop

		moveq	#0,d0
cmpnames_return:
		movem.l	(a7)+,d1/a0-a1
		rts
****************************************************************
complete_fromlist:
		lea	pick_fromlist(pc),a3
complete_nonfile:
		clr.w	filec_fignore(a4)
		sf	filec_case_independent(a4)
		lea	tmpword1,a1
complete_nonfile_loop:
		DOS	_KEYSNS				*  To allow interrupt
		jsr	(a3)
		bmi	return_0

		move.l	filec_patlen(a4),d0
		bsr	memcmp
		bne	complete_nonfile_loop

		bsr	filec_compare_pattern
		bne	complete_nonfile_loop

		moveq	#' ',d0
		bsr	filec_enter
		beq	complete_nonfile_loop

		rts
*
pick_fromlist:
		subq.l	#1,d2
		bcs	return_minus

		movea.l	a2,a0
		bsr	strfor1
		exg	a0,a2
		bra	return_0
****************************************************************
complete_svarname:
		movea.l	shellvar_top(a5),a2
complete_varspace:
		lea	pick_variables(pc),a3
		bra	complete_nonfile
*
pick_variables:
		cmpa.l	#0,a2
		beq	return_minus

		lea	var_body(a2),a0
		movea.l	var_next(a2),a2
		bra	return_0
****************************************************************
complete_envname:
		movea.l	env_top(a5),a2
		bra	complete_varspace
****************************************************************
complete_alias:
		movea.l	alias_top(a5),a2
		bra	complete_varspace
****************************************************************
complete_function:
		movea.l	function_bot(a5),a2
		lea	pick_functions(pc),a3
		bra	complete_nonfile
*
pick_functions:
		cmpa.l	#0,a2
		beq	return_minus

		lea	FUNC_NAME(a2),a0
		movea.l	FUNC_PREV(a2),a2
		bra	return_0
****************************************************************
complete_statements:
		lea	statement_table,a2
		lea	pick_builtins(pc),a3
		bra	complete_nonfile
*
pick_builtins:
		move.l	(a2),d0
		beq	return_minus

		movea.l	d0,a0
		lea	10(a2),a2
		bra	return_0
****************************************************************
complete_bindings:
		lea	key_function_word_table,a2
		lea	pick_bindings(pc),a3
		bra	complete_nonfile
*
pick_bindings:
		move.w	(a2)+,d0
		bmi	return_minus

		lea	key_function_names_top,a0
		lea	(a0,d0.w),a0
		bra	return_0
****************************************************************
complete_username:
		bsr	open_passwd
		bmi	return_0

		move.l	d0,tmpfd(a5)
		move.w	d0,d2				*  D2.W : passwd ファイル・ハンドル
		lea	pick_usernames(pc),a3
		bsr	complete_nonfile
		bra	close_tmpfd
*
pick_usernames:
		movem.l	d1/a1,-(a7)
		move.w	d2,d0
		lea	tmppwbuf,a0
		lea	tmppwline,a1
		move.l	#PW_LINESIZE,d1
		bsr	fgetpwent
		movem.l	(a7)+,d1/a1
		bne	return_minus

		movea.l	PW_NAME(a0),a0
		bra	return_0
****************************************************************
complete_cmdname:
		bsr	complete_file_init
		bne	complete_cmdname_return

		lea	tmpword1,a0
		cmpa.l	a0,a1
		bne	complete_cmdname_in_fixed_path

		cmpi.b	#1,filec_command_position(a4)
		bne	complete_cmdname_statement_ok
		*
		*  statements
		*
		bsr	complete_statements
		bne	complete_cmdname_return
complete_cmdname_statement_ok:
		tst.b	flag_noalias(a5)
		bne	complete_cmdname_alias_ok
		*
		*  aliases
		*
		bsr	complete_alias
		bne	complete_cmdname_return
complete_cmdname_alias_ok:
		*
		*  functions
		*
		bsr	complete_function
		bne	complete_cmdname_return
		*
		*  executable files in each $file
		*
		lea	word_path,a0
		bsr	find_shellvar
		beq	return_0

		bsr	get_var_value
		move.l	a0,filec_files_path_ptr(a4)
		move.w	d0,filec_files_path_count(a4)
		bra	complete_file_3
****************
complete_cmdname_in_fixed_path:
		move.b	#1,filec_file_findmode(a4)	*  1 : cmdfile on specified directory
		bra	complete_file_2
****************
complete_directory:
		move.b	#2,filec_file_findmode(a4)	*  2 : directory
		bra	complete_file_1
****************************************************************
complete_file:
		clr.b	filec_file_findmode(a4)		*  0 : all files
complete_file_1:
		bsr	complete_file_init
		bne	complete_file_return
complete_file_2:
		clr.l	filec_files_path_ptr(a4)	*  0,1,2
complete_file_3:					*  0,1,2,3
		clr.w	filec_fignore(a4)
		btst.b	#FLAGBIT_LIST,filec_flag(a4)
		bne	complete_file_fignore_ok

		lea	word_fignore,a0
		bsr	get_shellvar
		move.w	d0,filec_fignore(a4)
		move.l	a0,filec_fignore_list(a4)
complete_file_fignore_ok:
		move.b	flag_cifilec(a5),filec_case_independent(a4)
		bsr	filec_files
complete_file_loop:
		bmi	return_0

		move.l	d0,d2				*  D2.L : file mode

		move.l	filec_patlen(a4),d0
		beq	complete_file_check_dot

		movem.l	d1,-(a7)
		sf	d1
		btst	#8,d2
		bne	complete_file_compare	* nonfile

		move.b	flag_cifilec(a5),d1
complete_file_compare:
		bsr	memxcmp
		movem.l	(a7)+,d1
		bne	complete_file_next
		bra	complete_file_dot_ok

complete_file_check_dot:
		cmpi.b	#'.',(a0)
		bne	complete_file_dot_ok

		move.b	flag_showdots(a5),d0
		beq	complete_file_next		*  unset showdots

		subq.b	#1,d0
		bne	complete_file_dot_ok		*  set showdots=non-A

		tst.b	1(a0)
		beq	complete_file_next

		cmpi.b	#'.',1(a0)
		bne	complete_file_dot_ok

		tst.b	2(a0)
		beq	complete_file_next
complete_file_dot_ok:
		tst.l	filec_files_path_ptr(a4)
		beq	complete_file_normal
		*
		*  $path に従って検索されるディスク上のコマンド名補完
		*
		btst	#8,d2
		bne	complete_file_matched_regular	*  builtin

		tst.b	flag_reconlyexec(a5)
		bne	filec_command_test_executable

		tst.b	filec_file_path_fullpath(a4)
		bne	complete_file_matched_regular
filec_command_test_executable:
		bsr	filec_check_mode
		bmi	complete_file_next

		btst	#MODEBIT_DIR,d2
		bne	complete_file_command_dir

		bsr	filec_file_test_executable
		bne	complete_file_next
		bra	complete_file_matched_regular

complete_file_command_dir:
		tst.b	filec_file_path_dot(a4)
		beq	complete_file_next
		bra	complete_file_matched_real_dir
		*
		*
		*
complete_file_normal:
		btst	#MODEBIT_DIR,d2
		bne	complete_file_matched_real_dir

		btst	#MODEBIT_LNK,d2
		bne	complete_file_normal_link
** regular
		moveq	#' ',d3
		cmpi.b	#2,filec_file_findmode(a4)
		beq	complete_file_next

		tst.b	flag_listexec(a5)
		bne	complete_file_check_exec
complete_file_regular_1:
		tst.b	filec_file_findmode(a4)
		beq	complete_file_matched_nondir
complete_file_check_exec:
		bsr	filec_file_test_executable
		beq	complete_file_matched_executable

		tst.b	filec_file_findmode(a4)
		beq	complete_file_matched_nondir
		bra	complete_file_next

** link
complete_file_normal_link:
		moveq	#'@',d3
		bsr	filec_check_mode
		bmi	complete_file_bad_link

		btst	#MODEBIT_DIR,d2
		bne	complete_file_link_to_dir

		btst	#MODEBIT_VOL,d2
		bne	complete_file_bad_link
** link to regular
		cmpi.b	#2,filec_file_findmode(a4)
		beq	complete_file_next

		bra	complete_file_regular_1

** illegal link
complete_file_bad_link:
		tst.b	filec_file_findmode(a4)
		bne	complete_file_next

		tst.b	flag_listlinks(a5)
		beq	complete_file_matched_nondir

		moveq	#'&',d3
		bra	complete_file_matched_nondir

** link to directory
complete_file_link_to_dir:
		tst.b	flag_listlinks(a5)
		beq	complete_file_matched_dir

		moveq	#'>',d3
		bra	complete_file_matched_dir

** directory
complete_file_matched_real_dir:
		moveq	#'/',d3
complete_file_matched_dir:
		move.b	#'/',filec_suffix(a4)
		bra	complete_file_matched
*
complete_file_matched_executable:
		moveq	#'*',d3
		bra	complete_file_matched_nondir
*
complete_file_matched_regular:
		moveq	#' ',d3
complete_file_matched_nondir:
		move.b	#' ',filec_suffix(a4)
		bsr	filec_compare_pattern
		bne	complete_file_next
complete_file_matched:
		move.b	d3,d0
		bsr	filec_enter
		bne	complete_file_return
complete_file_next:
		DOS	_KEYSNS				*  To allow interrupt
		bsr	filec_nfiles
		bra	complete_file_loop

complete_file_return:
complete_cmdname_return:
		rts
****************
complete_file_init:
		lea	tmpword1,a1
		movea.l	a1,a0
		bsr	builtin_dir_match
		beq	complete_file_init_not_builtin

		adda.l	d0,a0
		bra	complete_file_init_copy_root

complete_file_init_not_builtin:
		*
		*  パス名のディレクトリが存在するかどうかを調べる
		*
		*      パス名の途中のディレクトリが存在するかどうかを 1つ 1つ順に
		*      検査する．
		*
		*      それぞれの名前のエントリがあれば良しとし，そのエントリの属
		*      性がディレクトリであるかどうかは検査しない．エントリがディ
		*      レクトリでなければ，いずれにしても補完候補は検索されないか
		*      ら，検査する必要は無い．
		*
		*      flag_cifilec(B) が効く．
		*      flag_cifilec(B) が 0 のときには，検索名の大文字と小文字は
		*      区別される．さもなくば区別せずに検索し，最初に見つかったエ
		*      ントリを採用する．その場合 (A0) のパス名は書き換えられる．
		*
		bclr	#31,d0
		bsr	drvchkp
		bmi	filec_check_path_fail

		bsr	skip_root
complete_file_init_copy_root:
		moveq	#MAXHEAD,d4			*  D4.L : filec_file_search_path の容量チェック
		movea.l	a0,a3
		move.l	a3,d0
		sub.l	a1,d0
		sub.l	d0,d4
		bcs	filec_check_path_fail

		lea	filec_file_search_path(a4),a0
		bsr	memmovi
		movea.l	a0,a2
		movea.l	a3,a0
filec_check_path_loop:
		clr.b	(a2)
		bsr	skip_slashes
		*
		*  A0 : 現在着目しているエレメントの先頭
		*  A2 : 検索名バッファのケツ
		*
		movea.l	a0,a3
		bsr	find_slashes
		beq	filec_check_path_done	*  OK

		move.l	a0,d2
		sub.l	a3,d2			*  D2.L : 現在着目しているエレメントの長さ
		cmpi.b	#'.',(a3)
		bne	scan_next_directory

		cmp.l	#2,d2
		bhi	scan_next_directory
		blo	filec_check_path_loop

		cmpi.b	#'.',1(a3)
		bne	scan_next_directory

		subq.l	#2,d4
		bcs	filec_check_path_fail

		move.b	#'.',(a2)+
		move.b	#'.',(a2)+
		bra	filec_check_path_continue

scan_next_directory:
		lea	filec_file_search_path(a4),a0
		bsr	contains_dos_wildcard
		bne	filec_check_path_fail

		move.w	#MODEVAL_ALL,-(a7)
		move.l	a0,-(a7)
		pea	filec_statbuf(a4)
		movea.l	a2,a0
		lea	dos_allfile,a1
		bsr	strcpy
		DOS	_FILES
		lea	10(a7),a7
filec_check_path_find_loop:
		tst.l	d0
		bmi	filec_check_path_fail

		lea	filec_statbuf+ST_NAME(a4),a1
		tst.b	(a1,d2.l)
		bne	filec_check_path_findnext

		movea.l	a3,a0
		move.l	d2,d0
		movem.l	d1,-(a7)
		move.b	flag_cifilec(a5),d1
		bsr	memxcmp
		movem.l	(a7)+,d1
		bne	filec_check_path_findnext

		sub.l	d2,d4
		bcs	filec_check_path_fail

		exg	a0,a2
		bsr	stpcpy				*  検索パス名を伸ばす
		exg	a2,a0

		movea.l	a3,a0
		move.l	d2,d0
		bsr	memmovi				*  見つかったエントリ名に置き替える
filec_check_path_continue:
		subq.l	#1,d4
		bcs	filec_check_path_fail

		move.b	#'/',(a2)+
		bra	filec_check_path_loop

filec_check_path_findnext:
		pea	filec_statbuf(a4)
		DOS	_NFILES
		addq.l	#4,a7
		bra	filec_check_path_find_loop

filec_check_path_fail:
complete_file_init_error:
return_minus:
		moveq	#-1,d0
		rts

filec_check_path_done:
		movea.l	a3,a1				*  A1 : 照合パターン（ファイル部）
		movea.l	a1,a0
		bsr	strlen
		move.l	d0,filec_patlen(a4)		*!!
return_0:
		moveq	#0,d0
		rts
****************
filec_file_test_executable:
		btst	#8,d2
		bne	filec_file_test_executable_ok

		btst	#MODEBIT_EXE,d2
		bne	filec_file_test_executable_ok

		move.l	a0,-(a7)
		bsr	check_executable_suffix
		movea.l	(a7)+,a0
		subq.l	#1,d0
		beq	filec_file_test_executable_ng	*  1:no ext

		subq.l	#4,d0
		blo	filec_file_test_executable_ok	*  2:.R, 3:.X, 4:BAT
filec_file_test_executable_ng:
		moveq	#-1,d0
		rts

filec_file_test_executable_ok:
		moveq	#0,d0
		rts
****************
path_buf = -(((MAXPATH+1)+1)>>1<<1)
path_buf_2 = path_buf-(((MAXPATH+1)+1)>>1<<1)
l_statbuf = path_buf_2-STATBUFSIZE
pad = l_statbuf-0

filec_check_mode:
*  シンボリック・リンクならばリンク先のmodeを得る
		link	a6,#pad
		movem.l	a0-a3,-(a7)
		btst	#MODEBIT_LNK,d2
		beq	filec_check_mode_return

		*  見つかったエントリのパス名を作る
		move.l	a0,-(a7)
		lea	path_buf(a6),a0
		lea	filec_file_search_path(a4),a1
		bsr	stpcpy
		movea.l	(a7)+,a1
		bsr	strcpy
		lea	path_buf(a6),a1
		lea	dos_allfile,a2
		lea	path_buf_2(a6),a0
		bsr	cat_pathname
		bmi	filec_check_mode_nondir

		bsr	get_fair_pathname		*  cat_pathname された結果で get_fair_pathname を呼んでエラーとなることはない
		move.w	#MODEVAL_ALL,-(a7)		*  すべてのエントリを検索する
		move.l	a0,-(a7)
		pea	l_statbuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bpl	filec_check_mode_directory

		cmp.l	#ENOFILE,d0
		beq	filec_check_mode_directory
filec_check_mode_nondir:
		lea	path_buf(a6),a0
		lea	l_statbuf(a6),a1
		bsr	stat
		bmi	filec_check_mode_fail

		moveq	#0,d2
		move.b	ST_MODE(a1),d2			*  D2.L : リンクが示すファイルのmode
		btst	#MODEBIT_LNK,d2
		bne	filec_check_mode_fail
filec_check_mode_return:
		movem.l	(a7)+,a0-a3
		unlk	a6
		tst.l	d2
		rts

filec_check_mode_directory:
		moveq	#MODEVAL_DIR,d2
		bra	filec_check_mode_return

filec_check_mode_fail:
		moveq	#-1,d2
		bra	filec_check_mode_return
****************************************************************
filec_compare_pattern:
		tst.l	filec_pattern(a4)		*!!
		beq	filec_compare_pattern_return

		move.l	a1,-(a7)
		movea.l	filec_pattern(a4),a1		*!!
		st	d0
		bsr	strpcmp
		movea.l	(a7)+,a1
filec_compare_pattern_return:
		rts
****************************************************************
filec_enter:
		movem.l	d1-d5/a0-a2,-(a7)
		addq.w	#1,filec_numentry(a4)
		bcs	filec_enter_error

		move.b	d0,d5				*  D5.B : リスト表示に加えるサフィックス
		bsr	strlen
		cmp.l	#MAXWORDLEN,d0
		bhi	filec_enter_error

		sub.w	d0,filec_buffer_free(a4)
		bcs	filec_enter_error

		subq.w	#2,filec_buffer_free(a4)
		bcs	filec_enter_error

		movea.l	a0,a2				*  A2 : 単語の先頭アドレス
		move.l	d0,d2				*  D2 : 単語の長さ
		cmp.l	filec_maxlen(a4),d2
		bls	filec_entry_1

		move.l	d2,filec_maxlen(a4)
filec_entry_1:
		cmp.l	filec_minlen(a4),d2
		bhs	filec_entry_2

		move.l	d2,filec_minlen(a4)
filec_entry_2:
		*
		*  exact match なら filec_suffix を filec_exact_suffix に記憶しておく
		*
		tst.b	flag_recexact(a5)
		beq	filec_entry_3

		move.l	filec_patlen(a4),d0
		tst.b	(a2,d0.l)
		bne	filec_entry_3

		move.b	filec_suffix(a4),filec_exact_suffix(a4)
filec_entry_3:
		*
		*  fignore に含まれているかどうかを調べる
		*
		move.w	filec_fignore(a4),d4
		beq	not_ignore

		movea.l	filec_fignore_list(a4),a0
		bra	check_fignore_start

check_fignore_loop:
		bsr	strlen
		move.l	d0,d3				*  D3.L : $fignore[i] の長さ
		move.l	d2,d0				*  単語の長さ(D2)は
		sub.l	d3,d0				*  $fignore[i] の長さ(D3)より
		blo	check_fignore_continue		*  短い

		lea	(a2,d0.l),a1
		move.l	d3,d0
		move.b	flag_cifilec(a5),d1
		bsr	memxcmp				*  ケツが一致するか？
		beq	filec_enter_ignored
check_fignore_continue:
		bsr	strfor1
check_fignore_start:
		dbra	d4,check_fignore_loop
not_ignore:
		addq.w	#1,filec_numprecious(a4)
		move.b	filec_suffix(a4),filec_suffix_precious(a4)
		move.b	filec_exact_suffix(a4),filec_exact_suffix_precious(a4)
		cmp.l	filec_minlen_precious(a4),d2
		bhs	filec_entry_4

		move.l	d2,filec_minlen_precious(a4)
filec_entry_4:
		move.l	filec_buffer_ptr(a4),a1
		movea.l	tmpargs(a5),a0
		move.l	a1,d0
		sub.l	a0,d0
		movea.l	a1,a0
		adda.l	d2,a0
		addq.l	#2,a0
		bsr	memmovd
		movea.l	tmpargs(a5),a0
		bra	filec_add_entry

filec_enter_ignored:
		movea.l	filec_buffer_ptr(a4),a0
filec_add_entry:
		*
		*  登録する
		*
		move.l	d2,d0
		movea.l	a2,a1
		bsr	memmovi
		move.b	d5,(a0)+
		clr.b	(a0)
		add.l	d2,filec_buffer_ptr(a4)
		addq.l	#2,filec_buffer_ptr(a4)
		moveq	#0,d0
filec_enter_return:
		movem.l	(a7)+,d1-d5/a0-a2
		rts

filec_enter_error:
		moveq	#1,d0
		bra	filec_enter_return
****************************************************************
filec_files:
		tst.l	filec_files_path_ptr(a4)
		bne	filec_files_path_next
filec_files_1:
		lea	filec_file_search_path(a4),a0
		bsr	builtin_dir_match
		bne	filec_files_builtin

		clr.l	filec_files_builtin_ptr(a4)
		move.w	#MODEVAL_ALL,-(a7)
		move.l	a0,-(a7)
		bsr	strbot
		move.l	a1,-(a7)
		lea	dos_allfile,a1
		bsr	strcpy
		movea.l	(a7)+,a1
		pea	filec_statbuf(a4)
		DOS	_FILES
		lea	10(a7),a7
		clr.b	(a0)
filec_files_done:
		tst.l	d0
		bmi	filec_files_return

		lea	filec_statbuf+ST_NAME(a4),a0
		moveq	#0,d0
		move.b	filec_statbuf+ST_MODE(a4),d0
		btst	#MODEBIT_DIR,d0
		bne	filec_files_return

		btst	#MODEBIT_VOL,d0
		beq	filec_files_return
filec_nfiles_normal:
		pea	filec_statbuf(a4)
		DOS	_NFILES
		addq.l	#4,a7
		bra	filec_files_done

filec_files_return:
		tst.l	d0
		rts
****************
filec_nfiles_sub:
		tst.l	filec_files_builtin_ptr(a4)
		bne	filec_nfiles_builtin
		bra	filec_nfiles_normal
****************
filec_nfiles:
		bsr	filec_nfiles_sub
		bpl	filec_files_return

		tst.l	filec_files_path_ptr(a4)
		beq	filec_files_return
filec_files_path_next:
		DOS	_KEYSNS				*  To allow interrupt
		subq.w	#1,filec_files_path_count(a4)
		bcs	filec_files_nomore

		movea.l	filec_files_path_ptr(a4),a0
		move.l	a0,-(a7)
		bsr	strfor1
		move.l	a0,filec_files_path_ptr(a4)
		movea.l	(a7)+,a0
		bclr	#31,d0
		bsr	drvchkp
		bmi	filec_files_path_next

		bsr	isfullpathx
		seq	filec_file_path_fullpath(a4)
		bsr	is_dot
		seq	filec_file_path_dot(a4)
		move.l	a1,-(a7)
		movea.l	a0,a1
		bsr	is_builtin_dir
		lea	filec_file_search_path(a4),a0
		bne	filec_files_path_next_builtin

		moveq	#MAXPATH,d0
		bsr	fair_pathname
		scs	d0
		bra	filec_files_path_next_1

filec_files_path_next_builtin:
		bsr	memmovi
		clr.b	(a0)
		sf	d0
filec_files_path_next_1:
		movea.l	(a7)+,a1
		tst.b	d0
		bne	filec_files_path_next

		lea	filec_file_search_path(a4),a0
		tst.b	(a0)
		beq	filec_files_path_next_2

		bsr	strlen
		cmp.l	#MAXHEAD-1,d0
		bhi	filec_files_fail

		move.b	#'/',(a0,d0.l)
		clr.b	1(a0,d0.l)
filec_files_path_next_2:
		bsr	filec_files_1
		tst.l	d0
		bmi	filec_files_path_next

		rts
****************
filec_files_builtin:
		lea	builtin_table,a0
		move.l	a0,filec_files_builtin_ptr(a4)
filec_nfiles_builtin:
		movea.l	filec_files_builtin_ptr(a4),a2
		bsr	pick_builtins
		move.l	a2,filec_files_builtin_ptr(a4)
		tst.l	d0
		bmi	filec_files_nomore

		move.l	#$100|MODEVAL_EXE,d0
		rts
****************
filec_files_nomore:
filec_files_fail:
		moveq	#-1,d0
		rts
*****************************************************************
getline_x_getletter:
		bsr	getline_x_getc
		bmi	getline_x_getletter_return

		bsr	issjis
		bne	getline_x_getletter_1

		move.b	d0,d2
		lsl.w	#8,d2
		bsr	getline_x_getc
		bmi	getline_x_getletter_return

		or.w	d2,d0
getline_x_getletter_1:
		cmp.l	d0,d0
getline_x_getletter_return:
getline_x_getc_return:
		rts
*****************************************************************
getline_x_getc:
		tst.l	macro_ptr(a6)
		beq	getline_x_getc_tty

		move.l	a0,-(a7)
		movea.l	macro_ptr(a6),a0
		moveq	#0,d0
		move.b	(a0)+,d0
		move.l	a0,macro_ptr(a6)
		movea.l	(a7)+,a0
		tst.l	d0
		bne	getline_x_getc_return

		clr.l	macro_ptr(a6)
getline_x_getc_tty:
	.if	0		*  なぜか多くのトラブルを引き起こす
		move.w	input_handle(a6),d0
		bra	fgetc
	.else			*  91/12/28
		move.w	input_handle(a6),d0
		bne	fgetc

		DOS	_INKEY
		tst.l	d0
		rts
	.endif
*****************************************************************
x_size_forward:
		movem.l	d0/a0,-(a7)
		movea.l	line_top(a6),a0
		move.b	(a0,d0.w),d0
		moveq	#1,d2
		moveq	#4,d3
		cmp.b	#HT,d0
		beq	x_size_forward_return

		moveq	#2,d3
		bsr	iscntrl
		beq	x_size_forward_return

		moveq	#1,d3
		bsr	issjis
		bne	x_size_forward_return

		moveq	#2,d2
		cmp.b	#$80,d0
		beq	x_size_forward_return

		cmp.b	#$f0,d0
		bhs	x_size_forward_return

		moveq	#2,d3
x_size_forward_return:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
x_size_backward:
		movem.l	d0-d1/a0,-(a7)
		move.w	d0,d1
		movea.l	line_top(a6),a0
		lea	(a0,d1.w),a0
		move.b	-1(a0),d0
		moveq	#1,d2
		moveq	#4,d3
		cmp.b	#HT,d0
		beq	x_size_backward_return

		moveq	#2,d3
		bsr	iscntrl
		beq	x_size_backward_return

		moveq	#1,d3
		cmp.w	#2,d1
		blo	x_size_backward_return

		move.b	-2(a0),d0
		bsr	issjis
		bne	x_size_backward_return

		move.w	d1,d0
		subq.w	#1,d0
		bsr	getline_isnsjisp
		beq	x_size_backward_return

		moveq	#2,d2
		cmp.b	#$80,d0
		beq	x_size_backward_return

		cmp.b	#$f0,d0
		bhs	x_size_backward_return

		moveq	#2,d3
x_size_backward_return:
		movem.l	(a7)+,d0-d1/a0
		rts
****************
getline_isnsjisp:
		movem.l	d1/a0,-(a7)
		movea.l	line_top(a6),a0
		move.w	d0,d1
getline_isnsjisp_loop:
		move.b	(a0)+,d0
		bsr	issjis
		bne	getline_isnsjisp_continue

		subq.w	#1,d1
		beq	getline_isnsjisp_break

		addq.l	#1,a0
getline_isnsjisp_continue:
		subq.w	#1,d1
		bne	getline_isnsjisp_loop

		moveq	#0,d0
getline_isnsjisp_break:
		movem.l	(a7)+,d1/a0
		tst.b	d0
		rts
*****************************************************************
region_width:
		movem.l	d1-d3/a0,-(a7)
		moveq	#0,d2
		move.w	d0,d1
		beq	region_width_return
region_width_loop:
		move.b	(a0)+,d0
		subq.w	#1,d1
		moveq	#4,d3
		cmp.b	#HT,d0
		beq	region_width_1

		moveq	#2,d3
		bsr	iscntrl
		beq	region_width_1

		moveq	#1,d3
		bsr	issjis
		bne	region_width_1

		cmp.b	#$80,d0
		beq	region_width_2

		cmp.b	#$f0,d0
		bhs	region_width_2

		moveq	#2,d3
region_width_2:
		tst.w	d1
		beq	region_width_1

		addq.l	#1,a0
		subq.w	#1,d1
region_width_1:
		add.l	d3,d2
		tst.w	d1
		bne	region_width_loop
region_width_return:
		move.l	d2,d0
		movem.l	(a7)+,d1-d3/a0
		rts
*****************************************************************
* backward_cursor_x - 指定のフィールドの幅だけカーソルを左に移動する
*
* CALL
*      A0     フィールドの先頭アドレス
*      D0.W   フィールドの長さ（バイト）
*
* RETURN
*      D0.L   フィールドの幅
*****************************************************************
*****************************************************************
* backward_cursor - カーソルを左に移動する
*
* CALL
*      D0.L   移動幅
*
* RETURN
*      none
*****************************************************************
.xdef backward_cursor

backward_cursor_x:
		bsr	region_width
backward_cursor:
		move.l	a0,-(a7)
		lea	t_bs,a0
		bsr	puts_ntimes
		movea.l	(a7)+,a0
		rts
*****************************************************************
* forward_cursor_x - 指定のフィールドの幅だけカーソルを右に移動する
*
* CALL
*      A0     フィールドの先頭アドレス
*      D0.W   フィールドの長さ（バイト）
*
* RETURN
*      D0.L   フィールドの幅
*****************************************************************
*****************************************************************
* forward_cursor - カーソルを右に移動する
*
* CALL
*      D0.L   移動幅
*
* RETURN
*      none
*****************************************************************
forward_cursor_x:
		bsr	region_width
forward_cursor:
		move.l	a0,-(a7)
		lea	t_fs,a0
		bsr	puts_ntimes
		movea.l	(a7)+,a0
		rts
*****************************************************************
* backward_letter - ポインタを1文字戻す．カーソルは移動しない
*
* CALL
*      none
*
* RETURN
*      D0.L   破壊
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*****************************************************************
backward_letter:
		moveq	#0,d2
		moveq	#0,d3
		move.w	point(a6),d0
		beq	backward_letter_done

		bsr	x_size_backward
		sub.w	d2,point(a6)
backward_letter_done:
		rts
*****************************************************************
* forward_letter - ポインタを1文字進める．カーソルは移動しない
*
* CALL
*      none
*
* RETURN
*      D0.L   破壊
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*      CCR    TST.W D2
*****************************************************************
forward_letter:
		moveq	#0,d2
		moveq	#0,d3
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	forward_letter_done

		bsr	x_size_forward
		add.w	d2,point(a6)
forward_letter_done:
		tst.w	d2
		rts
*****************************************************************
next_wordchar:
		bsr	is_point_wordchars
		beq	next_wordchar_done

		bsr	forward_letter
		beq	next_wordchar_done

		add.w	d2,d4
		add.l	d3,d5
		bra	next_wordchar

next_wordchar_done:
next_nonwordchar_done:
		rts
*****************************************************************
next_nonwordchar:
		bsr	is_point_wordchars
		bne	next_nonwordchar_done

		bsr	forward_letter
		beq	next_nonwordchar_done

		add.w	d2,d4
		add.l	d3,d5
		bra	next_nonwordchar
*****************************************************************
* backward_word - ポインタを1語戻す．カーソルは移動しない
*
* CALL
*      none
*
* RETURN
*      D0.L   破壊
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*****************************************************************
backward_word:
		movem.l	d0/d4-d5/a0,-(a7)
		moveq	#0,d4
		moveq	#0,d5
backward_word_1:
		tst.w	point(a6)
		beq	backward_word_done

		bsr	backward_letter
		add.w	d2,d4
		add.l	d3,d5

		bsr	is_point_wordchars
		bne	backward_word_1
backward_word_2:
		tst.w	point(a6)
		beq	backward_word_done

		bsr	backward_letter
		add.w	d2,d4
		add.l	d3,d5

		bsr	is_point_wordchars
		beq	backward_word_2

		bsr	forward_letter
		sub.w	d2,d4
		sub.l	d3,d5
backward_word_done:
		move.w	d4,d2
		move.l	d5,d3
		movem.l	(a7)+,d0/d4-d5/a0
		rts
*****************************************************************
* forward_word, next_word - ポインタを1語進める．カーソルは移動しない
*
* CALL
*      none
*
* RETURN
*      D0.L   破壊
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*****************************************************************
forward_word:
		movem.l	d0/d4-d5/a0,-(a7)
		moveq	#0,d4
		moveq	#0,d5
		bsr	next_wordchar
		bsr	next_nonwordchar
		move.w	d4,d2
		move.l	d5,d3
		movem.l	(a7)+,d0/d4-d5/a0
		rts
*****************************************************************
is_point_wordchars:
		move.w	point(a6),d0
		movea.l	line_top(a6),a0
		move.b	(a0,d0.w),d0
		bsr	issjis
		beq	is_point_wordchars_return

		bsr	isalnum
		beq	is_point_wordchars_return

		movea.l	wordchars(a5),a0
		bsr	strchr
		seq	d0
		tst.b	d0
is_point_wordchars_return:
		rts
*****************************************************************
* move_letter_backward - ポインタを1文字戻し、カーソルも左に移動する
* move_word_backward - ポインタを1語戻し、カーソルも左に移動する
*
* CALL
*      none
*
* RETURN
*      D0.L   カーソル移動幅
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*****************************************************************
move_letter_backward:
		bsr	backward_letter
		bra	backward_cursor_d3

move_word_backward:
		bsr	backward_word
backward_cursor_d3:
		move.l	d3,d0
		bra	backward_cursor
*****************************************************************
* move_letter_forward - ポインタを1文字進め、カーソルも右に移動する
* move_word_forward - ポインタを1語進め、カーソルも右に移動する
*
* CALL
*      none
*
* RETURN
*      D0.L   カーソル移動幅
*      D2.W   移動バイト数
*      D3.L   カーソル移動幅
*****************************************************************
move_letter_forward:
		bsr	forward_letter
		bra	forward_cursor_d3

move_word_forward:
		bsr	forward_word
forward_cursor_d3:
		move.l	d3,d0
		bra	forward_cursor
*****************************************************************
moveto_bol:
		movea.l	line_top(a6),a0
		move.w	point(a6),d0
		bsr	backward_cursor_x
		clr.w	point(a6)
		rts
*****************************************************************
move_cursor_to_eol:
		movem.l	d0/a0,-(a7)
		movea.l	line_top(a6),a0
		adda.w	point(a6),a0			*  正しい
		move.w	nbytes(a6),d0
		sub.w	point(a6),d0
		bsr	forward_cursor_x
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
erase_line:
		movem.l	d0/a0-a1,-(a7)
		movea.l	line_top(a6),a0
		move.w	point(a6),d0
		lea	(a0,d0.w),a1			*  A1 : カーソル位置
		bsr	backward_cursor_x
		move.l	d0,-(a7)			*  行の先頭からカーソル位置までの幅
		movea.l	a1,a0
		move.w	nbytes(a6),d0
		sub.w	point(a6),d0
		bsr	region_width			*  カーソル位置から行末までの幅
		add.l	(a7)+,d0			*  D0.L : 行全体の幅
		bsr	put_spaces
		bsr	backward_cursor
		movem.l	(a7)+,d0/a0-a1
		rts
*****************************************************************
delete_line:
		bsr	erase_line
		add.w	nbytes(a6),d1
		clr.w	nbytes(a6)
		clr.w	point(a6)
		move.w	#-1,mark(a6)
		rts
*****************************************************************
* open_columns
*
* CALL
*      D2.W   挿入バイト数
*****************************************************************
open_columns:
		cmp.w	d2,d1
		blo	open_columns_return

		sub.w	d2,d1
		movem.l	d0/a1,-(a7)
		movea.l	line_top(a6),a0
		moveq	#0,d0
		move.w	nbytes(a6),d0
		adda.l	d0,a0				*  A0 : 行末
		sub.w	point(a6),d0			*  D0.W : カーソル以降のバイト数
		movea.l	a0,a1
		lea	(a0,d2.w),a0
		bsr	memmovd
		movem.l	(a7)+,d0/a1
		suba.w	d2,a0				*  正しい
		cmp.w	d0,d0
open_columns_return:
		rts
*****************************************************************
* post_insert_job
*
* CALL
*      D2.W   挿入バイト数
*****************************************************************
post_insert_job:
		movem.l	d0/a0,-(a7)
		move.w	d2,d0
		bsr	write_chars
		lea	(a0,d2.w),a0
		move.w	nbytes(a6),d0
		sub.w	point(a6),d0
		bsr	write_chars
		bsr	backward_cursor_x
		move.w	mark(a6),d0
		bmi	post_insert_1

		cmp.w	point(a6),d0
		blo	post_insert_1

		add.w	d2,mark(a6)
post_insert_1:
		add.w	d2,nbytes(a6)
		add.w	d2,point(a6)
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
* copy_region_to_buffer
*
* CALL
*      D0.B     bit0 : 非0ならば失敗したときに尋ねる
*               bit1 : 0:後ろに追加, 1:先頭に追加
*      D2.W     コピーする領域の長さ（バイト数）
*      D4.W     コピーする領域の先頭オフセット
*
* RETURN
*      D0.L     成功したなら 0，失敗したなら 1
*      CCR      TST.L D0
*****************************************************************
copy_region_to_buffer:
		movem.l	d1/d3/a0-a1,-(a7)
		move.b	d0,d1
		movea.l	linecutbuf(a5),a0
		tst.b	killing(a6)
		bne	copy_region_to_buffer_1

		clr.b	(a0)
copy_region_to_buffer_1:
		bsr	strlen
		move.l	d0,d3
		add.w	d2,d0
		cmp.w	#MAXLINELEN,d0
		bhi	cannot_copy_region_to_buffer

		clr.b	(a0,d0.w)
		btst	#1,d1
		bne	copy_region_to_buffer_2

		bsr	strbot
		bra	copy_region_to_buffer_3

copy_region_to_buffer_2:
		lea	(a0,d0.w),a0
		movea.l	a0,a1
		suba.w	d2,a1				*  正しい
		move.l	d3,d0
		bsr	memmovd
		movea.l	linecutbuf(a5),a0
copy_region_to_buffer_3:
		movea.l	line_top(a6),a1
		lea	(a1,d4.w),a1
		moveq	#0,d0
		move.w	d2,d0
		bsr	memmovi
		st	killing(a6)
copy_region_to_buffer_success:
		moveq	#0,d0
copy_region_to_buffer_return:
		movem.l	(a7)+,d1/d3/a0-a1
		rts

cannot_copy_region_to_buffer:
		bsr	beep
		moveq	#1,d0
		bra	copy_region_to_buffer_return
*****************************************************************
* delete_region
*
* CALL
*      D2.W     削除する領域の長さ（バイト数）
*      D3.L     削除する領域の幅
*      D4.W     削除する領域の先頭オフセット
*
* RETURN
*      none.
*****************************************************************
delete_region:
		movem.l	d0/a0-a1,-(a7)
		tst.w	d2
		beq	delete_region_done

		movea.l	line_top(a6),a0
		lea	(a0,d4.w),a0
		lea	(a0,d2.w),a1
		moveq	#0,d0
		move.w	nbytes(a6),d0
		sub.w	d4,d0
		sub.w	d2,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	write_chars
		bsr	region_width
		exg	d0,d3
		bsr	put_spaces
		exg	d0,d3
		add.l	d3,d0
		bsr	backward_cursor

		sub.w	d2,nbytes(a6)
		add.w	d2,d1
		move.w	mark(a6),d0
		bmi	delete_region_done

		sub.w	d4,d0
		blo	delete_region_done

		cmp.w	d2,d0
		blo	delete_region_mark_missed

		sub.w	d2,mark(a6)
		bra	delete_region_done

delete_region_mark_missed:
		move.w	d4,mark(a6)
delete_region_done:
		movem.l	(a7)+,d0/a0-a1
		rts
*****************************************************************
redraw_with_prompt:
		move.l	a1,-(a7)
		movea.l	put_prompt_ptr(a6),a1
		bsr	put_prompt
		movea.l	(a7)+,a1
redraw:
		movem.l	d0/d2/a0,-(a7)
		movea.l	line_top(a6),a0
		move.w	nbytes(a6),d0
		bsr	write_chars
		move.w	point(a6),d2
		lea	(a0,d2.w),a0
		move.w	nbytes(a6),d0
		sub.w	d2,d0
		bsr	backward_cursor_x
		movem.l	(a7)+,d0/d2/a0
		rts
*****************************************************************
puts_ntimes:
		move.l	d0,-(a7)
		beq	puts_nitems_done
puts_ntimes_loop:
		bsr	puts
		subq.l	#1,d0
		bne	puts_ntimes_loop
puts_nitems_done:
		move.l	(a7)+,d0
		rts
*****************************************************************
put_spaces:
		movem.l	d0-d1,-(a7)
		move.l	d0,d1
		beq	put_spaces_done

		moveq	#' ',d0
put_spaces_loop:
		bsr	putc
		subq.l	#1,d1
		bne	put_spaces_loop
put_spaces_done:
		movem.l	(a7)+,d0-d1
		rts
*****************************************************************
write_chars:
		movem.l	d0-d1/a0,-(a7)
		move.w	d0,d1
		bra	write_chars_continue

write_chars_loop:
		move.b	(a0)+,d0
		cmp.b	#HT,d0
		beq	write_chars_tab

		bsr	cputc
		bra	write_chars_continue

write_chars_tab:
		moveq	#4,d0
		bsr	put_spaces
write_chars_continue:
		dbra	d1,write_chars_loop

		movem.l	(a7)+,d0-d1/a0
		rts
*****************************************************************
eol_newline:
		bsr	move_cursor_to_eol
		bra	put_newline
*****************************************************************
beep:
		tst.b	flag_nobeep(a5)
		bne	beep_done

		move.l	a0,-(a7)
		lea	t_bell,a0
		bsr	puts
		movea.l	(a7)+,a0
beep_done:
		rts
*****************************************************************
put_prompt:
		cmpa.l	#0,a1
		beq	put_prompt_done

		jsr	(a1)
put_prompt_done:
		rts
*****************************************************************
*  $prompt の書式付き出力変換操作記号
*
*	記号	種別	意味
*	%	s	文字 '%'
*	!	d	履歴イベント番号
*	/	s	カレント・ディレクトリの完全パス
*	~	s	カレント・ディレクトリのパス（可能なら ~ で略記）
*	?	d	シェル変数 status の値
*	R	s	パーサの状態			# 未完成
*	y	d	年(1980-2107)（精度を指定すると世紀抜き(0-99)）
*	m	d	月(1-12)
*	d	d	日(1-31)
*	H	d	時(0-23)
*	M	d	分(0-59)
*	S	d	秒(0-59)
*	w	s	曜日の英語名（#フラグを付けると日本語名）
*	h	s	月の英語名
*****************************************************************
.xdef put_prompt_1

put_prompt_1:
		movem.l	d0-d7/a0-a3,-(a7)
		lea	word_prompt2,a0
		tst.b	funcdef_status(a5)
		bne	put_prompt_2

		tst.b	switch_status(a5)
		bne	put_prompt_2

		tst.b	if_status(a5)
		bne	put_prompt_2

		tst.b	loop_status(a5)
		bmi	put_prompt_2

		lea	word_prompt,a0
put_prompt_2:
.if 0
		movem.l	d0-d7/a0-a4,-(a7)
		tst.b	in_prompt(a5)
		bne	no_prompt_function

		lea	word_prompt,a0
		lea	function_root(a5),a2
		bsr	find_function
		beq	no_prompt_function

		movea.l	d0,a1				*  A1 : 関数のヘッダの先頭アドレス
		moveq	#0,d0
		st	in_prompt(a5)
		bsr	source_function			*  関数を実行する
no_prompt_function:
		sf	in_prompt(a5)
		movem.l	(a7)+,d0-d7/a0-a4
.endif
.if 0
		movem.l	d0-d7/a0-a4,-(a7)
		tst.b	in_prompt(a5)
		bne	no_prompt_alias

		lea	word_prompt,a1
		movea.l	alias_top(a5),a0
		bsr	findvar				*  別名を探す
		beq	no_prompt_alias

		bsr	get_var_value
		st	in_prompt(a5)
		bsr	cmd_eval
no_prompt_alias:
		sf	in_prompt(a5)
		movem.l	(a7)+,d0-d7/a0-a4
.endif
		bsr	get_shellvar
		beq	prompt_done

		movea.l	a0,a1
		lea	tmpword1,a0
		bsr	strcpy
		bsr	compile_esch
		move.w	d0,d7
		movea.l	a0,a3
prompt_loop:
		subq.w	#1,d7
		bcs	prompt_done

		move.b	(a3)+,d0
		cmp.b	#'%',d0
		bne	prompt_normal_letter

		tst.w	d7
		beq	prompt_normal_char

		sf	d0				*  最小フィールド幅，精度に‘*’形式なし
		bsr	preparse_fmtout
		bne	prompt_done

		cmp.b	#'%',d0
		beq	prompt_percent

		cmp.b	#'!',d0
		beq	prompt_eventno

		cmp.b	#'/',d0
		beq	prompt_cwd

		cmp.b	#'~',d0
		beq	prompt_cwd_abbrev

		cmp.b	#'?',d0
		beq	prompt_status

		cmp.b	#'R',d0
		beq	prompt_request

		cmp.b	#'y',d0
		beq	prompt_year

		cmp.b	#'m',d0
		beq	prompt_month_of_year

		cmp.b	#'d',d0
		beq	prompt_day_of_month

		cmp.b	#'H',d0
		beq	prompt_hour

		cmp.b	#'M',d0
		beq	prompt_minute

		cmp.b	#'S',d0
		beq	prompt_second

		cmp.b	#'w',d0
		beq	prompt_week_word

		cmp.b	#'h',d0
		beq	prompt_month_word

		bra	prompt_loop

prompt_normal_letter:
		bsr	issjis
		bne	prompt_normal_char

		bsr	putc
		subq.w	#1,d7
		bcs	prompt_done

		move.b	(a3)+,d0
prompt_normal_char:
		bsr	putc
		bra	prompt_loop

prompt_done:
		movem.l	(a7)+,d0-d7/a0-a3
		rts
****************
*  %% : %
****************
prompt_percent:
		lea	word_percent,a0
prompt_string:
		bsr	prompt_string_sub
		bra	prompt_loop

prompt_string_sub:
		lea	putc(pc),a1
		tst.b	d5
		bne	prompt_string_precision_ok

		moveq	#-1,d4
prompt_string_precision_ok:
		bra	printfs
****************
*  %R : request
****************
prompt_request:
.if 0
		move.l	prompt_request_word(a5),a0
.else
		lea	word_sorry,a0
.endif
		bra	prompt_string
****************
*  %? : current status
****************
prompt_status:
		lea	word_status,a0
		bsr	get_shellvar
		beq	prompt_loop
		bra	prompt_string
****************
*  %! : current event number of history
****************
prompt_eventno:
		move.l	current_eventno(a5),d0
prompt_digit:
		lea	itoa(pc),a0
		lea	putc(pc),a1
		suba.l	a2,a2
		tst.b	d5
		bne	prompt_digit_precision_ok

		moveq	#1,d4
prompt_digit_precision_ok:
		bsr	printfi
		bra	prompt_loop
****************
*  %/ : cwd
****************
cwdbuf = -(((MAXPATH+1)+1)>>1<<1)

prompt_cwd:
		sf	d0
prompt_cwd_1:
		link	a6,#cwdbuf
		lea	cwdbuf(a6),a0
		bsr	getcwdx
		bsr	prompt_string_sub
		unlk	a6
		bra	prompt_loop
****************
*  %~ : cwd (abbrev. if possible)
****************
prompt_cwd_abbrev:
		st	d0
		bra	prompt_cwd_1
****************
*  %w : week word
****************
prompt_week_word:
		DOS	_GETDATE
		clr.w	d0
		swap	d0
		and.w	#%111,d0
		lea	english_week,a0
		tst.b	d6
		beq	prompt_name_in_table

		lea	japanese_week,a0
		bra	prompt_name_in_table
****************
*  %h : month word
****************
prompt_month_word:
		bsr	get_month
		lea	month_words,a0
prompt_name_in_table:
		bsr	strforn
		bra	prompt_string

get_month:
		DOS	_GETDATE
		lsr.l	#5,d0
		and.l	#%1111,d0
		rts
****************
*  %y : year
****************
prompt_year:
		DOS	_GETDATE
		lsr.l	#8,d0
		lsr.l	#1,d0
		and.l	#%1111111,d0
		add.l	#1980,d0
		tst.b	d5
		beq	prompt_digit

		cmp.l	#2,d4
		bhi	prompt_digit

		divu	#100,d0
		clr.w	d0
		swap	d0
		bra	prompt_digit
****************
*  %m : month of year
****************
prompt_month_of_year:
		bsr	get_month
		bra	prompt_digit
****************
*  %d : day of month
****************
prompt_day_of_month:
		DOS	_GETDATE
		and.l	#%11111,d0
		bra	prompt_digit
****************
*  %H : hour
****************
prompt_hour:
		DOS	_GETTIM2
		clr.w	d0
		swap	d0
		and.l	#%11111,d0
		bra	prompt_digit
****************
*  %M : minute
****************
prompt_minute:
		DOS	_GETTIM2
		lsr.l	#8,d0
		and.l	#%111111,d0
		bra	prompt_digit
****************
*  %S : second
****************
prompt_second:
		DOS	_GETTIM2
		and.l	#%111111,d0
		bra	prompt_digit
*****************************************************************
.data

.even
key_function_jump_table:
		dc.l	x_self_insert
		dc.l	x_error
		dc.l	x_no_op
		dc.l	x_macro
		dc.l	x_eval_command
		dc.l	x_prefix_1
		dc.l	x_prefix_2
		dc.l	x_abort
		dc.l	x_eof
		dc.l	x_accept_line
		dc.l	x_keyboard_quit
		dc.l	x_quoted_insert
		dc.l	x_redraw
		dc.l	x_clear_and_redraw
		dc.l	x_set_mark
		dc.l	x_exg_point_and_mark
		dc.l	x_search_character
		dc.l	x_bol
		dc.l	x_eol
		dc.l	x_backward_char
		dc.l	x_forward_char
		dc.l	x_backward_word
		dc.l	x_forward_word
		dc.l	x_next_word
		dc.l	x_del_back_char
		dc.l	x_del_for_char
		dc.l	x_kill_back_word
		dc.l	x_kill_for_word
		dc.l	x_kill_bol
		dc.l	x_kill_eol
		dc.l	x_kill_whole_line
		dc.l	x_kill_region
		dc.l	x_copy_region
		dc.l	x_yank
		dc.l	x_change_case
		dc.l	x_upcase_char
		dc.l	x_downcase_char
		dc.l	x_upcase_word
		dc.l	x_downcase_word
		dc.l	x_upcase_region
		dc.l	x_downcase_region
		dc.l	x_capitalize_word
		dc.l	x_transpose_gosling
		dc.l	x_transpose_chars
		dc.l	x_transpose_words
		dc.l	x_history_search_backward
		dc.l	x_history_search_forward
		dc.l	x_history_search_backward_circular
		dc.l	x_history_search_forward_circular
		dc.l	x_complete
		dc.l	x_complete_raw
		dc.l	x_list
		dc.l	x_list_raw
		dc.l	x_list_or_eof
		dc.l	x_del_for_char_or_list
		dc.l	x_del_for_char_or_list_or_eof
		dc.l	x_copy_prev_word
		dc.l	x_insert_last_word
		dc.l	x_up_history
		dc.l	x_down_history
		dc.l	x_quit_history
		dc.l	x_which_command

word_separators:	dc.b	' ',HT,'><)(;&|',0

english_week:
		dc.b	'Sunday',0
		dc.b	'Monday',0
		dc.b	'Tuesday',0
		dc.b	'Wednesday',0
		dc.b	'Thursday',0
		dc.b	'Friday',0
		dc.b	'Saturday',0
month_words:
		dc.b	0
		dc.b	'January',0
		dc.b	'February',0
		dc.b	'March',0
		dc.b	'April',0
		dc.b	'May',0
		dc.b	'June',0
		dc.b	'July',0
		dc.b	'August',0
		dc.b	'September',0
		dc.b	'October',0
		dc.b	'November',0
		dc.b	'December',0
		dc.b	0
		dc.b	0
		dc.b	0

japanese_week:
		dc.b	'日',0
		dc.b	'月',0
		dc.b	'火',0
		dc.b	'水',0
		dc.b	'木',0
		dc.b	'金',0
		dc.b	'土',0
		dc.b	0

t_bs:		dc.b	BS,0				*  ［termcap］
t_fs:		dc.b	FS,0				*  ［termcap］
t_clear:	dc.b	ESC,'[2J',0			*  ［termcap］
t_bell:		dc.b	BL,0				*  ［termcap］

.if 0
msg_reverse_i_search:	dc.b	'reverse-'
msg_i_search:		dc.b	'i-search: ',0
msg_i_search_colon:	dc.b	' : ',0
.endif

msg_completion_syntax_error:	dc.b	'補完プログラムの構文が誤りです',0
msg_completion_not_found:	dc.b	'この補完プログラムは定義されていません',0
msg_completion_program_loop:	dc.b	'補完プログラムの分岐が多すぎます',0

word_sorry:	dc.b	'(%R is not available yet)',0
word_percent:	dc.b	'%',0

.end
