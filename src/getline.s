* getline.s
* Itagaki Fumihiko 29-Jul-90  Create.

.include doscall.h
.include chrcode.h
.include limits.h
.include stat.h
.include pwd.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/history.h
.include ../src/var.h
.include ../src/function.h

.xref isalnum
.xref iscntrl
.xref isdigit
.xref issjis
.xref isspace2
.xref tolower
.xref toupper
.xref itoa
.xref strbot
.xref strchr
.xref jstrchr
.xref strcpy
.xref stpcpy
.xref strcmp
.xref strlen
.xref strmove
.xref strfor1
.xref strforn
.xref memcmp
.xref memxcmp
.xref memmovi
.xref memmovd
.xref rotate
.xref skip_space
.xref sort_wordlist_x
.xref uniq_wordlist
.xref is_all_same_word
.xref putc
.xref cputc
.xref puts
.xref put_newline
.xref printfi
.xref printfs
.xref compile_esch
.xref preparse_fmtout
.xref builtin_dir_match
.xref check_executable_suffix
.xref test_command_file
.xref isnotttyin
.xref fgetc
.xref fgets
.xref close_tmpfd
.xref open_passwd
.xref fgetpwent
.xref expand_tilde
.xref contains_dos_wildcard
.xref headtail
.xref cat_pathname
.xref isfullpath
.xref stat
.if 0
.xref findvar
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
.xref is_histchar_canceller
.xref xmalloct
.xref xfreetp
.xref minmaxul
.xref divul
.xref drvchk
.xref drvchkp
.xref manage_interrupt_signal
.xref too_long_line
.xref statement_table
.xref builtin_table
.xref word_nomatch
.xref word_exact
.xref word_path
.xref word_prompt
.xref word_prompt2
.xref word_status
.xref dos_allfile

.xref congetbuf
.xref tmpargs
.xref tmpword1
.xref tmpword2
.xref tmppwline

.xref history_top
.xref history_bot
.xref current_eventno
.xref current_source
.xref alias_top
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
.xref flag_autolist
.xref flag_cifilec
.xref flag_execbit
.xref flag_listexec
.xref flag_listlinks
.xref flag_noalias
.xref flag_nobeep
.xref flag_nonullcommandc
.xref flag_recexact
.xref flag_reconlyexec
.xref flag_symlinks
.xref flag_usegets
.xref last_congetbuf
.xref keymap
.xref keymacromap
.xref linecutbuf
.xref tmpfd
.xref in_prompt

.text

*****************************************************************
* getline
*
* CALL
*      A0     入力バッファの先頭
*      D1.W   入力最大バイト数（32767以下．最後のNUL分は勘定しない）
*      D2.B   0 ならばコメントを削除しない
*      D3.B   0 ならば行継続を認識しない
*      A1     プロンプト出力ルーチンのエントリ・アドレス
*      A2     物理行入力ルーチンのエントリ・アドレス
*      D7.L   (A2) への引数 D0.L
*
* RETURN
*      D0.L   0:入力有り，-1:EOF，1:入力エラー
*      D1.W   残り入力可能バイト数（最後のNUL分は勘定しない）
*      CCR    TST.L D0
*****************************************************************
.xdef getline

getline:
		movem.l	d3-d6/a0-a4,-(a7)
		moveq	#0,d4				*  D4.B : 全体クオート・フラグ
getline_more:
		**
		**  １物理行を入力する
		**
		movea.l	a0,a4
		move.l	d7,d0
		jsr	(a2)
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

		cmpa.l	a0,a4
		beq	getline_newline_not_escaped

		cmpi.b	#'\',-1(a4)
		bne	getline_newline_not_escaped

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
		rts

getline_over:
		moveq	#1,d0
		bra	getline_return
*****************************************************************
* getline_phigical
*
* CALL
*      A0     入力バッファの先頭
*      A1     プロンプト出力ルーチンのエントリ・アドレス
*      D0.W   入力ファイル・ハンドル
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
		bsr	getline_file
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
		clr.b	(a0)
		moveq	#0,d0
getline_script_sub_return:
		movea.l	a3,a1
		movea.l	(a7)+,a3
		rts

getline_script_sub_over:
		moveq	#1,d0
		bra	getline_script_sub_return

getline_script_sub_eof:
		moveq	#-1,d0
		bra	getline_script_sub_return
*****************************************************************
.xdef getline_stdin

getline_stdin:
		moveq	#0,d0
getline_file:
		movem.l	d0,-(a7)
		bsr	isnotttyin
		movem.l	(a7)+,d0
		beq	fgets

		bsr	put_prompt
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
bottomline = line_top-4
x_histptr = bottomline-4
input_handle = x_histptr-4
mark = input_handle-2
point = mark-2
nbytes = point-2
bottombytes = nbytes-2
keymap_offset = bottombytes-2
quote = keymap_offset-1
killing = quote-1
pad = killing-0				*  偶数バウンダリーに合わせる

getline_x:
		link	a6,#pad
		movem.l	d2-d7/a1-a3,-(a7)
		move.w	d0,input_handle(a6)
		move.l	a0,line_top(a6)
		move.l	a1,put_prompt_ptr(a6)
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
*  cr
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
		lea	linecutbuf(a5),a0
		bsr	strlen
		move.l	d0,d2
		movea.l	a0,a1
x_copy:
		bsr	open_columns
		bcs	x_over

		move.l	d2,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	post_insert_job
		bra	getline_x_1

x_over:
		bsr	beep
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
		beq	chcase_char_not_changed

		move.b	d0,(a0,d3.w)
		bsr	putc
		bsr	forward_letter
		bra	chcase_loop

chcase_char_not_changed:
		bsr	move_letter_forward
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
*  transpose-chars
********************************
x_transpose_chars:
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		blo	x_transpose_chars_1

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
		move.w	d2,d4				*  D4.W : 右の単語のバイト数
		bsr	move_word_backward
		move.w	d2,d5				*  D5.W : 左の単語＋スペースのバイト数
		move.l	d3,d6				*  D6.L : 左の単語＋スペースの文字幅
		move.w	point(a6),-(a7)
		bsr	forward_word			*  D2.W : 左の単語のバイト数
		move.w	(a7),point(a6)
		exg	d2,d5
		bsr	transpose
		sub.w	d2,point(a6)
		move.l	d6,d0
		bsr	backward_cursor
		move.w	d2,d4
		sub.w	d5,d4
		move.w	d5,d2
		bsr	transpose
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
		bra	x_history_return

x_history_null:
		clr.l	a1
		bra	x_history_return

x_history_bottom:
		movea.l	history_bot(a5),a1
x_history_return:
		cmpa.l	#0,a1
		rts
********************************
x_history_next:
		cmpa.l	#0,a1
		beq	x_history_over
		bmi	x_history_null

		movea.l	HIST_NEXT(a1),a1
		cmpa.l	#0,a1
		bne	x_history_return
x_history_over:
		movea.l	#-1,a1
		bra	x_history_return
********************************
*  up-history
********************************
x_up_history:
		moveq	#-1,d3
		move.l	x_histptr(a6),d0
		movea.l	d0,a1
		bsr	x_history_prev
		beq	x_error

		bra	save_and_insert_history
********************************
*  down-history
********************************
x_down_history:
		moveq	#-1,d3
		movea.l	x_histptr(a6),a1
		bsr	x_history_next
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
********************************
x_history_search_forward:
		movea.l	x_histptr(a6),a1
x_history_search_forward_more:
		bsr	x_history_next
		beq	x_error

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

		bra	insert_history

x_history_search_forward_1:
		move.l	d0,d3
		beq	x_history_search_forward_2

		move.l	bottomline(a6),d2
		beq	x_error

		movea.l	d2,a1
		move.l	d0,d3
		bsr	memcmp
		bne	x_error
x_history_search_forward_2:
		bra	x_quit_history_1
********************************
*  history-search-backward
********************************
x_history_search_backward:
		move.l	x_histptr(a6),d4
		movea.l	d4,a1
x_history_search_backward_more:
		bsr	x_history_prev
		beq	x_error

		movea.l	line_top(a6),a0
		moveq	#0,d0
		move.w	point(a6),d0
		moveq	#HIST_PREV,d3
		bsr	history_search
		beq	x_error

		bsr	histcmp2
		beq	x_history_search_backward_more

		move.l	d4,d0
save_and_insert_history:
		tst.l	d0
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
		move.b	(a1)+,d0
		beq	copy_history_continue

		bsr	issjis
		bne	copy_history_word_1

		lsl.w	#8,d0
		move.b	(a1)+,d0
		beq	copy_history_continue
copy_history_word_1:
		cmp.w	histchar1(a5),d0
		bne	copy_history_not_histchar

		move.b	(a1),d0
		bsr	is_histchar_canceller
		beq	copy_history_dup_histchar

		subq.w	#1,d1
		bcs	copy_history_over

		move.b	#'\',(a0)+
		addq.w	#1,nbytes(a6)
copy_history_dup_histchar:
		move.w	histchar1(a5),d0
		bra	copy_history_dup_1

copy_history_not_histchar:
		cmp.w	#'\',d0
		beq	copy_history_dup_escape
copy_history_dup_1:
		cmp.w	#$100,d0
		blo	copy_history_dup_1_1
copy_history_dup_1_2:
		subq.w	#1,d1
		bcs	copy_history_over

		move.w	d0,-(a7)
		lsr.w	#8,d0
		move.b	d0,(a0)+
		move.w	(a7)+,d0
		addq.w	#1,nbytes(a6)
copy_history_dup_1_1:
		subq.w	#1,d1
		bcs	copy_history_over

		move.b	d0,(a0)+
		addq.w	#1,nbytes(a6)
		bra	copy_history_dup_word_loop

copy_history_dup_escape:
		subq.w	#1,d1
		bcs	copy_history_over

		move.b	d0,(a0)+
		addq.w	#1,nbytes(a6)

		move.b	(a1)+,d0
		beq	copy_history_continue

		bsr	issjis
		bne	copy_history_dup_1_1

		lsl.w	#8,d0
		move.b	(a1)+,d0
		bne	copy_history_dup_1_2
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

is_word_separator:
		movem.l	d0/a0,-(a7)
		lea	word_separators,a0
		bsr	strchr				*  word_separators にシフトJIS文字は無い
		seq	d0
		tst.b	d0
		movem.l	(a7)+,d0/a0
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
FLAGBIT_LIST     = 0	*  補完文字列の挿入は行わず，補完候補の表示を行う
FLAGBIT_FILE     = 1	*  文字列の位置によらずファイル名として補完する
FLAGBIT_CMD      = 2	*  文字列の位置によらずコマンド名として補完する
FLAGBIT_VAR      = 3	*  $で始まっていなくとも常に変数名として補完する
FLAGBIT_NOSVAR   = 4	*  変数名補完時にシェル変数をデフォルトの候補とする
FLAGBIT_NOENV    = 5	*  変数名補完時に環境変数をデフォルトの候補とする
FLAGBIT_SHOWDOTS = 6	*  . で始まる名前も list 表示する

FLAGX_COMPL      = 0
FLAGX_COMPL_CMD  = (1<<FLAGBIT_CMD)
FLAGX_COMPL_FILE = (1<<FLAGBIT_FILE)
FLAGX_COMPL_VAR  = (1<<FLAGBIT_VAR)
FLAGX_COMPL_SVAR = (1<<FLAGBIT_VAR)|(1<<FLAGBIT_NOENV)
FLAGX_COMPL_ENV  = (1<<FLAGBIT_VAR)|(1<<FLAGBIT_NOSVAR)

FLAGX_LIST       = (1<<FLAGBIT_LIST)
FLAGX_LIST_CMD   = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_CMD)
FLAGX_LIST_FILE  = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_FILE)
FLAGX_LIST_VAR   = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_VAR)
FLAGX_LIST_SVAR  = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_VAR)|(1<<FLAGBIT_NOENV)
FLAGX_LIST_ENV   = (1<<FLAGBIT_LIST)|(1<<FLAGBIT_VAR)|(1<<FLAGBIT_NOSVAR)

********************************
*  list-environment-variable
********************************
x_list_environment_variable:
		moveq	#FLAGX_LIST_ENV,d7
		bra	x_filec_or_list
********************************
*  list-shell-variable
********************************
x_list_shell_variable:
		moveq	#FLAGX_LIST_SVAR,d7
		bra	x_filec_or_list
********************************
*  list-variable
********************************
x_list_variable:
		moveq	#FLAGX_LIST_VAR,d7
		bra	x_filec_or_list
********************************
*  list-command
********************************
x_list_command:
		moveq	#FLAGX_LIST_CMD,d7
		bra	x_filec_or_list
********************************
*  list-file
********************************
x_list_file:
		moveq	#FLAGX_LIST_FILE,d7
		bra	x_filec_or_list
********************************
*  list
********************************
x_list:
		moveq	#FLAGX_LIST,d7
		bra	x_filec_or_list
********************************
*  complete-environment-variable
********************************
x_complete_environment_variable:
		moveq	#FLAGX_COMPL_ENV,d7
		bra	x_filec_or_list
********************************
*  complete-shell-variable
********************************
x_complete_shell_variable:
		moveq	#FLAGX_COMPL_SVAR,d7
		bra	x_filec_or_list
********************************
*  complete-variable
********************************
x_complete_variable:
		moveq	#FLAGX_COMPL_VAR,d7
		bra	x_filec_or_list
********************************
*  complete-command
********************************
x_complete_command:
		moveq	#FLAGX_COMPL_CMD,d7
		bra	x_filec_or_list
********************************
*  complete-file
********************************
x_complete_file:
		moveq	#FLAGX_COMPL_FILE,d7
		bra	x_filec_or_list
********************************
*  complete
********************************
x_complete:
		moveq	#FLAGX_COMPL,d7

filec_statbuf = -STATBUFSIZE
filec_fignore = filec_statbuf-4
filec_command_ptr = filec_fignore-4
filec_files_builtin_ptr = filec_command_ptr-4
filec_buffer_ptr = filec_files_builtin_ptr-4
filec_command_path_count = filec_buffer_ptr-2
filec_buffer_free = filec_command_path_count-2
filec_patlen = filec_buffer_free-4
filec_dirlen = filec_patlen-4
filec_maxlen = filec_dirlen-4
filec_minlen = filec_maxlen-4
filec_minlen_precious = filec_minlen-4
filec_numentry = filec_minlen_precious-2
filec_numprecious = filec_numentry-2
filec_flag = filec_numprecious-1
filec_command = filec_flag-1
filec_suffix = filec_command-1
filec_exact_suffix = filec_suffix-1
filec_showdots = filec_exact_suffix-1
filec_pad = filec_showdots-1

x_filec_or_list:
		link	a4,#filec_pad
		move.b	d7,filec_flag(a4)
		move.b	#-1,filec_showdots(a4)
		*
		*  対象の単語を取り出す
		*
		move.w	point(a6),d6
		movea.l	line_top(a6),a2
filec_find_word_statement_break:
		move.b	#1,filec_command(a4)	*     0 : all files
						*     1 : statement ->
						*  -> 2 : alias  ->
						*  -> 3 : function  ->
						*  -> 4 : cmdfiles on each $path
						*     5 : cmdfiles on specified directory
filec_find_word_loop1:
		movea.l	a2,a1
		subq.w	#1,d6
		bcs	filec_find_word_loop1_break

		move.b	(a2)+,d0
		beq	filec_find_word_loop1

		bsr	isspace2
		beq	filec_find_word_loop1

		cmp.b	#'=',d0
		beq	filec_find_word_loop2

		subq.l	#1,a2
filec_find_word_loop1_break:
		addq.w	#1,d6
filec_find_word_loop2:
		subq.w	#1,d6
		bcs	filec_find_word_done

		moveq	#0,d0
		move.b	(a2)+,d0
		beq	filec_find_word_normal_break

		bsr	issjis
		beq	filec_find_word_sjis

		lea	filec_separators,a0
		bsr	strchr				*  filec_separators にシフトJIS文字は無い
		beq	filec_find_word_loop2

		cmpa.l	#x_command_separators_1,a0
		blo	filec_find_word_normal_break

		cmpa.l	#x_command_separators_2,a0
		blo	filec_find_word_maybe_subshell

		move.b	#2,filec_command(a4)
		bra	filec_find_word_loop1

filec_find_word_maybe_subshell:
		tst.b	filec_command(a4)
		beq	filec_find_word_normal_break

		move.l	a2,d0
		subq.l	#1,d0
		sub.l	a1,d0
		beq	filec_find_word_statement_break
filec_find_word_normal_break:
		clr.b	filec_command(a4)
		bra	filec_find_word_loop1

filec_find_word_sjis:
		subq.w	#1,d6
		bcs	filec_find_word_done

		addq.l	#1,a2
		bra	filec_find_word_loop2

filec_find_word_done:
		moveq	#0,d0
		move.w	point(a6),d0
		add.l	line_top(a6),d0
		sub.l	a1,d0
		cmp.l	#MAXWORDLEN,d0
		bhi	filec_error

		lea	tmpword1,a0
		bsr	memmovi
		clr.b	(a0)

		clr.w	filec_numentry(a4)
		clr.w	filec_numprecious(a4)
		clr.l	filec_maxlen(a4)
		move.l	#-1,filec_minlen(a4)
		move.l	#-1,filec_minlen_precious(a4)
		lea	tmpargs,a0
		move.l	a0,filec_buffer_ptr(a4)
		move.w	#MAXWORDLISTSIZE,filec_buffer_free(a4)
		clr.b	filec_exact_suffix(a4)
		clr.l	filec_fignore(a4)
		*
		*  変数名か？
		*  ユーザ名か？
		*  コマンド名／ファイル名か？
		*
		lea	tmpword1,a0
		btst.b	#FLAGBIT_VAR,filec_flag(a4)
		bne	complete_varname_start

		moveq	#'$',d0
		bsr	strchr				*  '$' にシフトJISの考慮は不要
		bne	complete_varname

		lea	tmpword1,a0
		bsr	builtin_dir_match
		beq	filec_not_builtin

		cmpi.b	#'/',(a0,d0.l)
		bne	filec_not_builtin

		movea.l	a0,a1
		lea	tmpword2,a0
		bsr	strcpy
		bra	filec_file_0

filec_not_builtin:
		cmpi.b	#'~',(a0)
		bne	filec_file

		moveq	#'/',d0
		bsr	strchr				*  '/' にシフトJISの考慮は不要
		beq	complete_username
****************
filec_file:
	*
	*  ファイルを検索する
	*
		*
		*  ~ を展開…
		*
		lea	tmpword1,a0
		lea	tmpword2,a1
		moveq	#0,d2
		move.l	d1,-(a7)
		move.w	#MAXWORDLEN+1,d1
		bsr	expand_tilde
		move.l	(a7)+,d1
		tst.l	d0
		bmi	filec_find_done
		*
		*  ファイル名を検索する
		*
		lea	tmpword2,a0
		bsr	contains_dos_wildcard		*  Human68k のワイルドカードを含んで
		bne	filec_find_done			*  いるならば無効

		moveq	#'\',d0				*  \ を
		bsr	jstrchr				*  含んで
		bne	filec_find_done			*  いるならば無効

		lea	tmpword2,a0
		bsr	test_directory
		bne	filec_find_done
filec_file_0:
		lea	tmpword2,a0			*  A0 : 補完文字列の先頭アドレス
		bsr	headtail			*  A1 : ファイル部のアドレス
							*  D0.L : ドライブ＋ディレクトリの長さ
		btst.b	#FLAGBIT_FILE,filec_flag(a4)
		bne	filec_file_file

		tst.b	filec_command(a4)
		bne	filec_file_command

		btst.b	#FLAGBIT_CMD,filec_flag(a4)
		beq	filec_file_file

		move.b	#2,filec_command(a4)		*  2 : 2:alias->3:function->4:cmdfile on each $path
filec_file_command:
		*  コマンド名補完
		tst.l	d0				*  D0.L : ドライブ＋ディレクトリの長さ
		bne	filec_file_command_hasdir

		*  ディレクトリ指定無しのコマンド名補完
		bsr	strlen				*  D0.L : 補完単語全体の長さ
		tst.l	d0
		bne	filec_file_start

		tst.b	flag_nonullcommandc(a5)
		bne	filec_error

		bra	filec_file_start

filec_file_command_hasdir:
		*  ディレクトリ指定のコマンド名補完
		move.b	#5,filec_command(a4)		*  5 : cmdfile on specified directory
		bra	filec_just_real_file

filec_file_file:
		*  通常のファイル名補完
		clr.b	filec_command(a4)		*  0 : all files
filec_just_real_file:
		cmp.l	#MAXHEAD,d0
		bhi	filec_find_done

		move.l	d0,filec_dirlen(a4)

		move.l	a1,-(a7)
		movea.l	a0,a1
		lea	tmpword1,a0
		bsr	memmovi
		lea	dos_allfile,a1
		bsr	strcpy
		movea.l	(a7)+,a1
filec_file_start:
		movea.l	a1,a0
		bsr	strlen
		move.l	d0,filec_patlen(a4)

		lea	word_showdots,a0
		bsr	get_shellvar
		beq	filec_file_start_1

		move.l	a1,-(a7)
		lea	str_A,a1
		bsr	strcmp
		movea.l	(a7)+,a1
		bne	filec_file_start_2

		move.b	#1,filec_showdots(a4)
		bra	filec_file_start_2

filec_file_start_1:
		cmpi.b	#'.',(a1)
		beq	filec_file_start_2

		clr.b	filec_showdots(a4)
filec_file_start_2:
		btst.b	#FLAGBIT_LIST,filec_flag(a4)
		bne	filec_file_fignore_ok

		lea	word_fignore,a0
		bsr	find_shellvar
		move.l	d0,filec_fignore(a4)
filec_file_fignore_ok:
		bsr	filec_file_sub
		bne	filec_error
		bra	filec_find_done
****************
complete_username:
		bsr	open_passwd
		bmi	filec_find_done

		move.l	d0,tmpfd(a5)
		move.w	d0,d2				*  D2.W : passwd ファイル・ハンドル

		lea	tmpword1+1,a0
		bsr	strlen
		move.l	d0,filec_patlen(a4)
		move.b	#'/',filec_suffix(a4)

pwd_buf = -(((PW_SIZE+1)+1)>>1<<1)

		link	a6,#pwd_buf
complete_username_loop:
		movem.l	d1,-(a7)
		move.w	d2,d0
		lea	pwd_buf(a6),a0
		lea	tmppwline,a1
		move.l	#PW_LINESIZE,d1
		bsr	fgetpwent
		movem.l	(a7)+,d1
		bne	complete_username_done0

		movea.l	PW_NAME(a0),a0
		lea	tmpword1+1,a1
		move.l	filec_patlen(a4),d0
		bsr	memcmp
		bne	complete_username_continue

		moveq	#' ',d0
		bsr	filec_enter
		bne	complete_username_done		*  D0.L == 1 .. error
complete_username_continue:
		DOS	_KEYSNS				*  To allow interrupt
		bra	complete_username_loop

complete_username_done0:
		moveq	#-1,d0
complete_username_done:
		unlk	a6
		bsr	close_tmpfd
		bpl	filec_error

		bra	filec_find_done
****************
complete_varname:
		addq.l	#1,a0
		cmpi.b	#'@',(a0)
		beq	complete_shellvar

		cmpi.b	#'%',(a0)
		bne	complete_varname_2
complete_environ:
		bclr.b	#FLAGBIT_NOENV,filec_flag(a4)
		bset.b	#FLAGBIT_NOSVAR,filec_flag(a4)
		bra	complete_varname_1

complete_shellvar:
		bclr.b	#FLAGBIT_NOSVAR,filec_flag(a4)
		bset.b	#FLAGBIT_NOENV,filec_flag(a4)
complete_varname_1:
		addq.l	#1,a0
complete_varname_2:
		cmpi.b	#'{',(a0)
		bne	complete_varname_3

		addq.l	#1,a0
complete_varname_3:
		cmpi.b	#'#',(a0)
		beq	complete_varname_4

		cmpi.b	#'?',(a0)
		bne	complete_varname_start
complete_varname_4:
		addq.l	#1,a0
complete_varname_start:
		bsr	strlen
		move.l	d0,filec_patlen(a4)
		move.b	#$ff,filec_suffix(a4)		*  決して addsuffix しないことを示す
		movea.l	a0,a1				*  A1 : 検索名の先頭アドレス
		btst.b	#FLAGBIT_NOSVAR,filec_flag(a4)
		bne	do_complete_varname_skip_shellvar

		movea.l	shellvar_top(a5),a2
		bsr	do_complete_varname_sub
		bne	filec_error
do_complete_varname_skip_shellvar:
		btst.b	#FLAGBIT_NOENV,filec_flag(a4)
		bne	do_complete_varname_skip_environ

		movea.l	env_top(a5),a2
		bsr	do_complete_varname_sub
		bne	filec_error
do_complete_varname_skip_environ:
		bra	filec_find_done
****************
filec_find_done:
		btst.b	#FLAGBIT_LIST,filec_flag(a4)
		bne	filec_list			*  リスト表示へ

		move.w	filec_numentry(a4),d0
		beq	filec_nomatch

		tst.w	filec_numprecious(a4)
		bne	filec_numprecious_ok

		move.w	d0,filec_numprecious(a4)
		move.l	filec_minlen(a4),d0
		move.l	d0,filec_minlen_precious(a4)
filec_numprecious_ok:
		*
		*  最初の曖昧でない部分を確定する
		*
		move.l	d1,-(a7)
		lea	tmpargs,a0
		move.w	filec_numprecious(a4),d0
		move.l	filec_patlen(a4),d1
		move.b	flag_cifilec(a5),d2
		bsr	common_spell
		move.l	filec_minlen_precious(a4),d1
		sub.l	filec_patlen(a4),d1
		bsr	minmaxul
		move.l	(a7)+,d1
		move.l	d0,d2				*  D2.L : 共通部分の長さ
		*
		*  cifilec がセットされているならば，caseを現実のものに合わせるために
		*  既存入力部分を上書きする
		*
		lea	tmpargs,a1
		adda.l	filec_patlen(a4),a1
		tst.b	flag_cifilec(a5)
		beq	filec_redraw_ok

		moveq	#0,d0
		move.w	nbytes(a6),d0
		sub.l	filec_patlen(a4),d0
		movea.l	line_top(a6),a1
		adda.l	d0,a1
		movem.l	d1-d2,-(a7)
		move.l	filec_patlen(a4),d2
filec_redraw_select_loop1:
		lea	tmpargs,a0
		move.w	filec_numprecious(a4),d1
		subq.w	#1,d1
filec_redraw_select_loop2:
		move.l	d2,d0
		bsr	memcmp
		beq	filec_redraw_select_ok

		bsr	strfor1
		dbra	d1,filec_redraw_select_loop2

		subq.l	#1,d2
		bne	filec_redraw_select_loop1

		lea	tmpargs,a0
filec_redraw_select_ok:
		movem.l	(a7)+,d1-d2
		exg	a0,a1
		move.l	filec_patlen(a4),d0
		bsr	backward_cursor_x
		move.l	filec_patlen(a4),d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	write_chars
filec_redraw_ok:
		*
		*  完成部分を挿入する
		*
		bsr	open_columns
		bcs	filec_error

		move.l	d2,d0
		move.l	a0,-(a7)
		bsr	memmovi
		movea.l	(a7)+,a0
		bsr	post_insert_job

		lea	tmpargs,a0
		move.w	filec_numprecious(a4),d0
		bsr	is_all_same_word
		beq	filec_match

		tst.b	filec_exact_suffix(a4)
		beq	filec_ambiguous

		*  not unique exact match
		*  set matchbeep=notuniq であるときにのみベルを鳴らす

		bsr	find_matchbeep
		beq	filec_notunique_nobeep
		bpl	filec_match

		lea	word_notunique,a1
		bsr	strcmp
		bne	filec_notunique_nobeep

		bsr	beep
filec_notunique_nobeep:
		move.b	filec_exact_suffix(a4),d0
		move.b	d0,filec_suffix(a4)
filec_match:
		btst.b	#7,filec_suffix(a4)
		bne	filec_done

		lea	word_addsuffix,a0		*  シェル変数 addsuffix が
		bsr	find_shellvar			*  セットされて
		beq	filec_done			*  いなければおしまい

		tst.l	d2				*  1文字も挿入しなかったならば
		beq	filec_addsuffix			*  サフィックスを追加する

		bsr	get_var_value			*  $@addsuffix[1] == exact でなければ
		beq	filec_addsuffix			*  サフィックスを追加する

		lea	word_exact,a1
		bsr	strcmp
		beq	filec_done
filec_addsuffix:
		moveq	#1,d2
		bsr	open_columns
		bcs	filec_error

		move.b	filec_suffix(a4),d0
		move.b	d0,(a0)
		bsr	post_insert_job
		bra	filec_done


filec_nomatch:
		bsr	find_matchbeep
		beq	filec_beep
		bpl	filec_done

		lea	word_nomatch,a1
		bsr	strcmp
		beq	filec_beep

		lea	word_ambiguous,a1
		bsr	strcmp
		beq	filec_beep

		lea	word_notunique,a1
		bsr	strcmp
		bne	filec_done
filec_beep:
filec_error:
		bsr	beep
filec_done:
		unlk	a4
		bra	getline_x_1


filec_ambiguous:
		bsr	find_matchbeep
		beq	filec_ambiguous_beep
		bpl	filec_ambiguous_nobeep

		lea	word_ambiguous,a1
		bsr	strcmp
		beq	filec_ambiguous_beep

		lea	word_notunique,a1
		bsr	strcmp
		bne	filec_ambiguous_nobeep
filec_ambiguous_beep:
		bsr	beep
filec_ambiguous_nobeep:
		tst.l	d2
		bne	filec_done

		tst.b	flag_autolist(a5)
		beq	filec_done
filec_list:
	*
	*  リスト表示
	*
		move.w	filec_numentry(a4),d0
		lea	tmpargs,a0
		move.l	a4,-(a7)
		lea	cmpnames(pc),a4
		bsr	sort_wordlist_x
		movea.l	(a7)+,a4
		bsr	uniq_wordlist
		move.w	d0,d6
		beq	filec_list_done

		addq.l	#2,filec_maxlen(a4)
		*
		*  79(行の桁数-1)を1項目の桁数で割って、1行あたりの項目数を暫定する
		*
		moveq	#1,d2
		move.l	filec_maxlen(a4),d0
		moveq	#79,d3
		cmp.l	d0,d3
		blo	filec_list_width_ok

		move.l	d3,d2
		divu	d0,d2				*  D2.W : 79 / 桁数 = 1行の項目数(暫定)
filec_list_width_ok:
		*
		*  何行になるかを求める
		*
		moveq	#0,d3
		move.w	d6,d3
		divu	d2,d3				*  D3.W : エントリ数 / 1行の項目数 = 行数
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
		*  1行多くなったので、1行の項目数を計算し直す
		*
		moveq	#0,d2
		move.w	d6,d2
		divu	d3,d2
		swap	d2
		move.w	d2,d4
		swap	d2
		tst.w	d4
		beq	filec_list_height_ok
		*
		*  余りがある --- 1行の項目数はさらに1項目多い
		*                 余り(D4.W)は1項目多い行数である
		*
		addq.w	#1,d2
filec_list_height_ok:
		lea	tmpargs,a0
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
.xdef filec_enter

filec_enter:
		movem.l	d1-d5/a0-a2,-(a7)
		cmpi.b	#'.',(a0)
		bne	filec_enter_1

		tst.b	filec_showdots(a4)
		bmi	filec_enter_1
		beq	filec_enter_success		*  登録しない

		tst.b	1(a0)
		beq	filec_enter_success

		cmpi.b	#'.',1(a0)
		bne	filec_enter_1

		tst.b	2(a0)
		beq	filec_enter_success
filec_enter_1:
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
		*  fignore に含まれているかどうかを調べる
		*
		move.l	filec_fignore(a4),d0
		beq	filec_enter_ignored

		bsr	get_var_value
		move.w	d0,d4				*  D4.W : fignore の要素数
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
		cmp.l	filec_minlen_precious(a4),d2
		bhs	filec_entry_3

		move.l	d2,filec_minlen_precious(a4)
filec_entry_3:
		move.l	filec_buffer_ptr(a4),a1
		lea	tmpargs,a0
		move.l	a1,d0
		sub.l	a0,d0
		movea.l	a1,a0
		adda.l	d2,a0
		addq.l	#2,a0
		bsr	memmovd
		lea	tmpargs,a0
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

		tst.b	flag_recexact(a5)
		beq	filec_enter_success

		move.l	filec_patlen(a4),d0
		tst.b	(a2,d0.l)
		bne	filec_enter_success

		move.b	filec_suffix(a4),d0
		move.b	d0,filec_exact_suffix(a4)
filec_enter_success:
		moveq	#0,d0
filec_enter_return:
		movem.l	(a7)+,d1-d5/a0-a2
		rts

filec_enter_error:
		moveq	#1,d0
		bra	filec_enter_return
****************
find_matchbeep:
		lea	word_matchbeep,a0
		bsr	find_shellvar
		beq	find_matchbeep_return		*  D0.L == 0

		bsr	get_var_value
		beq	find_matchbeep_1

		moveq	#-1,d0				*  D0.L == -1
find_matchbeep_return:
		rts

find_matchbeep_1:
		moveq	#1,d0				*  D0.L == 1
		rts
****************
do_complete_varname_sub:
		cmpa.l	#0,a2
		beq	do_complete_varname_sub_done

		lea	var_body(a2),a0
		move.l	var_next(a2),a2
		move.l	filec_patlen(a4),d0
		bsr	memcmp
		bne	do_complete_varname_sub_continue

		moveq	#' ',d0
		bsr	filec_enter
		bne	do_complete_varname_sub_return

do_complete_varname_sub_continue:
		DOS	_KEYSNS				*  To allow interrupt
		bra	do_complete_varname_sub

do_complete_varname_sub_done:
		moveq	#0,d0
do_complete_varname_sub_return:
		rts
****************
path_buf = -(((MAXPATH+1)+1)>>1<<1)
l_statbuf = path_buf-STATBUFSIZE

filec_file_sub:
		link	a6,#l_statbuf
		bsr	filec_files
filec_file_sub_loop:
		bmi	filec_file_sub_done

		move.w	d0,d2				*  D2 : file mode
		movem.l	d1,-(a7)
		sf	d1
		btst	#8,d2
		bne	filec_file_compare

		move.b	flag_cifilec(a5),d1
filec_file_compare:
		move.l	filec_patlen(a4),d0
		bsr	memxcmp
		movem.l	(a7)+,d1
		bne	filec_file_sub_next
filec_file_compare_ok:
		clr.b	path_buf(a6)

		*  unset symlinks なら MODEBIT_LNK を落としておく
		tst.b	flag_symlinks(a5)
		bne	filec_file_linkbit_ok

		bclr	#MODEBIT_LNK,d2
filec_file_linkbit_ok:
		move.b	filec_command(a4),d0
		beq	filec_file_sub_normal		*  0 : 一般的なファイル名補完

		cmp.b	#5,d0
		beq	filec_file_sub_normal		*  5 : ディレクトリ指定のコマンド名補完

		*
		*  ディレクトリ指定の無いコマンド置換
		*
		cmp.b	#4,d0
		blo	filec_file_sub_regular		*  statement, alias, function

		btst	#8,d2
		bne	filec_file_sub_regular		*  builtin

		tst.b	flag_reconlyexec(a5)
		bne	filec_command_test_executable

		move.l	a0,-(a7)
		lea	tmpword1,a0
		bsr	isfullpath
		movea.l	(a7)+,a0
		beq	filec_file_sub_regular		*  完全パス
filec_command_test_executable:
		bsr	filec_check_mode
		bmi	filec_file_sub_next

		btst	#MODEBIT_DIR,d0
		bne	filec_file_sub_command_dir

		move.l	d0,d2
		bsr	filec_file_test_executable
		beq	filec_file_sub_regular
		bra	filec_file_sub_next

filec_file_sub_command_dir:
		move.l	a0,-(a7)
		lea	tmpword1,a0
		cmpi.b	#'.',(a0)
		bne	filec_file_sub_command_dir_1

		cmpi.b	#'/',1(a0)
		beq	filec_file_sub_command_dir_1

		cmpi.b	#'\',1(a0)
filec_file_sub_command_dir_1
		movea.l	(a7)+,a0
		bne	filec_file_sub_next

		moveq	#' ',d3
		bra	filec_file_matched_dir

		*

filec_file_sub_normal:
		btst	#MODEBIT_DIR,d2
		bne	filec_file_sub_normal_dir

		moveq	#0,d3
		btst	#MODEBIT_LNK,d2
		beq	filec_file_sub_normal_nonlink

		tst.b	flag_listlinks(a5)
		bne	filec_file_sub_listlinks

		tst.b	filec_command(a4)
		beq	filec_file_sub_link_points_nondir
filec_file_sub_listlinks:
		moveq	#'&',d3				*  '&' : bad link
		bsr	filec_check_mode
		bmi	filec_file_matched_regular

		moveq	#'>',d3				*  '>' : linked to directory
		btst	#MODEBIT_DIR,d0
		bne	filec_file_matched_dir

		moveq	#'&',d3				*  '&' : bad link
		btst	#MODEBIT_VOL,d0
		bne	filec_file_matched_regular

		moveq	#'@',d3				*  '@' : linked to non-directory
		tst.b	filec_command(a4)
		beq	filec_file_sub_regular

		move.l	d0,d2
filec_file_sub_check_exec:
		bsr	filec_file_test_executable
		bne	filec_file_sub_next
filec_file_sub_normal_executable:
		tst.b	d3
		bne	filec_file_matched_regular

		moveq	#'*',d3
		bra	filec_file_matched_regular

filec_file_sub_normal_nonlink:
		tst.b	filec_command(a4)
		bne	filec_file_sub_check_exec

		move.b	flag_listexec(a5),d0
		beq	filec_file_sub_regular

		bsr	filec_file_test_executable_1
		beq	filec_file_sub_normal_executable
filec_file_sub_regular:
		moveq	#' ',d3
filec_file_matched_regular:
		move.b	#' ',filec_suffix(a4)
filec_file_matched:
		move.b	d3,d0
		bsr	filec_enter
		bne	filec_file_sub_return
filec_file_sub_next:
		DOS	_KEYSNS				*  To allow interrupt
		bsr	filec_nfiles
		bra	filec_file_sub_loop
*
filec_file_sub_link_points_nondir:
		moveq	#'@',d3
		bra	filec_file_matched_regular
*
filec_file_sub_normal_dir:
		moveq	#'/',d3
filec_file_matched_dir:
		move.b	#'/',filec_suffix(a4)
		bra	filec_file_matched
*
filec_file_sub_done:
		moveq	#0,d0
filec_file_sub_return:
		unlk	a6
		rts
****************
*  見つかったエントリのパス名を作る
make_pathname:
		move.l	a1,-(a7)
		lea	path_buf(a6),a1
		tst.b	(a1)
		bne	make_pathname_return

		move.l	a0,-(a7)
		movea.l	a1,a0
		lea	tmpword1,a1
		move.l	filec_dirlen(a4),d0
		bsr	memmovi
		movea.l	(a7)+,a1
		bsr	strcpy
make_pathname_return:
		movea.l	(a7)+,a1
		lea	path_buf(a6),a0
		rts
****************
filec_check_mode:
		movem.l	a0-a1,-(a7)
		*  シンボリック・リンクならばリンク先のmodeを得る
		move.l	d2,d0
		btst	#MODEBIT_LNK,d2
		beq	filec_check_mode_return

		bsr	make_pathname
		lea	l_statbuf(a6),a1
		bsr	stat
		bmi	filec_check_mode_return

		moveq	#0,d0
		move.b	ST_MODE(a1),d0			*  D0.L : リンクが示すファイルのmode
filec_check_mode_return:
		movem.l	(a7)+,a0-a1
		tst.l	d0
		rts
****************
filec_file_test_executable:
		moveq	#-1,d0
filec_file_test_executable_1:
		move.l	d3,-(a7)
		move.b	d0,d3
		beq	filec_file_test_executable_ng

		btst	#8,d2
		bne	filec_file_test_executable_ok

		tst.b	flag_execbit(a5)
		beq	filec_file_test_executable_2

		btst	#MODEBIT_EXE,d2
		bne	filec_file_test_executable_ok
filec_file_test_executable_2:
		move.l	a0,-(a7)
		bsr	check_executable_suffix
		movea.l	(a7)+,a0
		subq.l	#1,d0
		beq	filec_file_test_magic		*  1:no ext

		subq.l	#4,d0
		blo	filec_file_test_executable_ok	*  2:.R, 3:.X, 4:BAT
filec_file_test_magic:
		tst.b	d3
		bpl	filec_file_test_executable_ng

		move.l	a0,-(a7)
		bsr	make_pathname
		bsr	test_command_file
		movea.l	(a7)+,a0
		bmi	filec_file_test_executable_return
filec_file_test_executable_ok:
		moveq	#0,d0
filec_file_test_executable_return:
		move.l	(a7)+,d3
		tst.l	d0
		rts

filec_file_test_executable_ng:
		moveq	#-1,d0
		bra	filec_file_test_executable_return
****************
filec_files:
		cmpi.b	#1,filec_command(a4)
		beq	filec_nfiles_statement_first

		cmpi.b	#2,filec_command(a4)
		beq	filec_nfiles_alias_first
filec_files_normal:
		lea	tmpword1,a0
		bsr	builtin_dir_match
		beq	filec_files_not_builtin

		cmpi.b	#'/',(a0,d0.l)
		beq	filec_files_builtin

		cmpi.b	#'\',(a0,d0.l)
		bne	filec_files_not_builtin
filec_files_builtin:
		lea	builtin_table,a0
		move.l	a0,filec_files_builtin_ptr(a4)
		bra	filec_nfiles_normal

filec_files_not_builtin:
		clr.l	filec_files_builtin_ptr(a4)
		move.w	#MODEVAL_ALL,-(a7)
		move.l	a0,-(a7)
		pea	filec_statbuf(a4)
		DOS	_FILES
		lea	10(a7),a7
filec_files_normal_not_builtin_done:
		tst.l	d0
		bmi	filec_files_return

		lea	filec_statbuf+ST_NAME(a4),a0
		moveq	#0,d0
		move.b	filec_statbuf+ST_MODE(a4),d0
		btst	#MODEBIT_DIR,d0
		bne	filec_files_return

		btst	#MODEBIT_VOL,d0
		bne	filec_nfiles_normal_not_builtin
filec_files_return:
		tst.l	d0
		rts

filec_nfiles_normal_not_builtin:
		pea	filec_statbuf(a4)
		DOS	_NFILES
		addq.l	#4,a7
		bra	filec_files_normal_not_builtin_done
****************
filec_nfiles:
		cmpi.b	#1,filec_command(a4)
		beq	filec_nfiles_statement

		cmpi.b	#2,filec_command(a4)
		beq	filec_nfiles_alias

		cmpi.b	#3,filec_command(a4)
		beq	filec_nfiles_function

		bsr	filec_nfiles_normal
		bpl	filec_files_return

		cmpi.b	#4,filec_command(a4)
		bne	filec_files_return

		bra	filec_files_command_file_next
****************
filec_nfiles_normal:
		move.l	filec_files_builtin_ptr(a4),d0
		beq	filec_nfiles_normal_not_builtin

		movea.l	d0,a0
		move.l	(a0),d0
		beq	filec_files_nomore

		lea	10(a0),a0
		move.l	a0,filec_files_builtin_ptr(a4)
filec_files_builtin_set_return:
		movea.l	d0,a0
filec_files_builtin_return:
		move.l	#$100|MODEVAL_EXE,d0
		rts
****************
filec_nfiles_statement_first:
		lea	statement_table,a0
		move.l	a0,filec_command_ptr(a4)
filec_nfiles_statement:
		move.l	filec_command_ptr(a4),a0
		move.l	(a0),d0
		beq	filec_nfiles_statement_nomore

		lea	10(a0),a0
		move.l	a0,filec_command_ptr(a4)
		bra	filec_files_builtin_set_return

filec_nfiles_statement_nomore:
		addq.b	#1,filec_command(a4)
filec_nfiles_alias_first:
		tst.b	flag_noalias(a5)
		bne	filec_nfiles_alias_nomore

		move.l	alias_top(a5),filec_command_ptr(a4)
filec_nfiles_alias:
		move.l	filec_command_ptr(a4),d0
		beq	filec_nfiles_alias_nomore

		movea.l	d0,a0
		move.l	var_next(a0),filec_command_ptr(a4)
		lea	var_body(a0),a0
		bra	filec_files_builtin_return

filec_nfiles_alias_nomore:
		addq.b	#1,filec_command(a4)
		move.l	function_bot(a5),filec_command_ptr(a4)
filec_nfiles_function:
		move.l	filec_command_ptr(a4),d0
		beq	filec_files_function_nomore

		movea.l	d0,a0
		move.l	FUNC_PREV(a0),filec_command_ptr(a4)
		lea	FUNC_NAME(a0),a0
		bra	filec_files_builtin_return

filec_files_function_nomore:
		addq.b	#1,filec_command(a4)
		lea	word_path,a0
		bsr	find_shellvar
		beq	filec_files_nomore

		bsr	get_var_value
		move.l	a0,filec_command_ptr(a4)
		move.w	d0,filec_command_path_count(a4)
filec_files_command_file_next:
		subq.w	#1,filec_command_path_count(a4)
		bcs	filec_files_nomore

		lea	tmpword1,a0
		movem.l	a1-a3,-(a7)
		lea	dos_allfile,a2
		movea.l	filec_command_ptr(a4),a1
		bsr	cat_pathname
		move.l	a1,filec_command_ptr(a4)
		movem.l	(a7)+,a1-a3
		tst.l	d0
		bmi	filec_files_command_file_next

		bsr	drvchkp
		bmi	filec_files_command_file_next

		move.l	a1,-(a7)
		bsr	headtail
		movea.l	(a7)+,a1
		cmp.l	#MAXHEAD,d0
		bhi	filec_files_command_file_next

		move.l	d0,filec_dirlen(a4)
		bsr	filec_files_normal
		tst.l	d0
		bmi	filec_files_command_file_next

		rts
****************
filec_files_nomore:
		moveq	#-1,d0
		rts
*****************************************************************
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
		rts
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

.if 0

		movem.l	d0/d4-d6/a0,-(a7)
		moveq	#0,d4
		moveq	#0,d5
backward_word_1:
		tst.w	point(a6)
		beq	backward_word_done

		bsr	backward_letter
		add.w	d2,d4
		add.l	d3,d5

		bsr	is_point_space
		beq	backward_word_1

		bsr	is_special_character
		move.b	(a0),d6
backward_word_3:
		tst.w	point(a6)
		beq	backward_word_done

		bsr	backward_letter
		add.w	d2,d4
		add.l	d3,d5

		bsr	is_point_space
		beq	backward_word_5

		tst.b	d6
		beq	backward_word_4

		cmp.b	d6,d0
		beq	backward_word_3
		bra	backward_word_5

backward_word_4:
		bsr	is_special_character
		beq	backward_word_3
backward_word_5:
		bsr	forward_letter
		sub.w	d2,d4
		sub.l	d3,d5
backward_word_done:
		move.w	d4,d2
		move.l	d5,d3
		movem.l	(a7)+,d0/d4-d6/a0
		rts

.else

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

.endif
*****************************************************************
* forward_word - ポインタを1語進める．カーソルは移動しない
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

.if 0

		movem.l	d0/d4-d6/a0,-(a7)
		moveq	#0,d4
		moveq	#0,d5
forward_word_1:
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	forward_word_done

		bsr	is_point_space
		bne	forward_word_2

		bsr	forward_letter
		add.w	d2,d4
		add.l	d3,d5
		bra	forward_word_1

forward_word_2:
		bsr	is_special_character
		move.b	(a0),d6
forward_word_3:
		bsr	forward_letter
		add.w	d2,d4
		add.l	d3,d5
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	forward_word_done

		bsr	is_point_space
		beq	forward_word_done

		tst.b	d6
		beq	forward_word_4

		cmp.b	d6,d0
		beq	forward_word_3
		bra	forward_word_done

forward_word_4:
		bsr	is_special_character
		beq	forward_word_3
forward_word_done:
		move.w	d4,d2
		move.l	d5,d3
		movem.l	(a7)+,d0/d4-d6/a0
		rts

.else

		movem.l	d0/d4-d5/a0,-(a7)
		moveq	#0,d4
		moveq	#0,d5
forward_word_1:
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	forward_word_done

		bsr	is_point_wordchars
		beq	forward_word_2

		bsr	forward_letter
		add.w	d2,d4
		add.l	d3,d5
		bra	forward_word_1

forward_word_2:
		bsr	forward_letter
		add.w	d2,d4
		add.l	d3,d5
		move.w	point(a6),d0
		cmp.w	nbytes(a6),d0
		beq	forward_word_done

		bsr	is_point_wordchars
		beq	forward_word_2
forward_word_done:
		move.w	d4,d2
		move.l	d5,d3
		movem.l	(a7)+,d0/d4-d5/a0
		rts

.endif
*****************************************************************
.if 0

is_point_space:
		move.w	point(a6),d0
		movea.l	line_top(a6),a0
		move.b	(a0,d0.w),d0
		bra	isspace2

is_special_character:
		and.w	#$ff,d0
		lea	x_special_characters,a0
		bra	strchr				*  x_special_characters にシフトJIS文字は無い

.else

is_point_wordchars:
		move.w	point(a6),d0
is_dot_wordchars:
		movea.l	line_top(a6),a0
		move.b	(a0,d0.w),d0
		bsr	issjis
		beq	is_dot_wordchars_return

		bsr	isalnum
		beq	is_dot_wordchars_return

		movea.l	wordchars(a5),a0
		bsr	strchr
		seq	d0
		tst.b	d0
is_dot_wordchars_return:
		rts

.endif
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
		lea	linecutbuf(a5),a0
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
		lea	linecutbuf(a5),a0
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
		movem.l	d1,-(a7)
		bsr	svartol
		exg	d0,d1
		cmp.l	#5,d1
		movem.l	(a7)+,d1
		beq	prompt_digit

		lea	msg_no_status,a0
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
		DOS	_GETDATE
		lsr.l	#5,d0
		and.l	#%1111,d0
		subq.l	#1,d0
		lea	month_word_table,a0
prompt_name_in_table:
		bsr	strforn
		bra	prompt_string
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

		move.l	d1,-(a7)
		moveq	#100,d1
		bsr	divul
		move.l	d1,d0
		move.l	(a7)+,d1
		bra	prompt_digit
****************
*  %m : month of year
****************
prompt_month_of_year:
		DOS	_GETDATE
		lsr.l	#5,d0
		and.l	#%1111,d0
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
		lsr.l	#8,d0
		lsr.l	#8,d0
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
* test_directory - パス名のディレクトリが存在するかどうかを調べる
*
* CALL
*      A0     パス名
*
* RETURN
*      D0.L   存在するならば0
*      CCR    TST.L D0
*
* NOTE
*      / のみが許され、\ は許さない。
*      flag_cifilec(B) が効く。
*      flag_cifilec(B) が０のときには、検索名の大文字と小文字は
*      区別される。さもなくば区別せずに検索し、１番最初に見つかった
*      エントリを採用する。その際、(A0) のパス名は書き換えられる。
****************************************************************
statbuf = -STATBUFSIZE
l_statbuf = statbuf-STATBUFSIZE
searchnamebuf = statbuf-(((MAXPATH+1)+1)>>1<<1)

test_directory:
		link	a6,#searchnamebuf
		movem.l	d1-d3/a0-a3,-(a7)
		lea	searchnamebuf(a6),a2
get_firstdir_restart:
		movea.l	a0,a3
		move.b	(a0)+,d0
		beq	get_firstdir_done

		cmpi.b	#':',(a0)
		bne	get_firstdir_no_drive

		move.b	d0,(a2)+
		move.b	(a0)+,(a2)+
		movea.l	a0,a3
		bsr	drvchk
		bmi	test_directory_return

		move.b	(a0)+,d0
		beq	get_firstdir_done
get_firstdir_no_drive:
		cmp.b	#'/',d0
		bne	get_firstdir_done

		move.b	d0,(a2)+
		movea.l	a0,a3
get_firstdir_done:
		clr.b	(a2)
		lea	searchnamebuf(a6),a0
test_directory_loop:
		*
		*  A2 : 検索名バッファのケツ
		*  A3 : 現在着目しているエレメントの先頭
		*
		movea.l	a3,a0				*  現在着目しているエレメントの後ろに
		moveq	#'/',d0				*  / が
		bsr	strchr				*  あるか？  （'/' にシフトJISの考慮は不要）
		beq	test_directory_true		*  無い .. true

		move.l	a0,d2
		sub.l	a3,d2
		*
		*  A4   : 現在着目しているエレメントの末尾
		*  D2.L : 現在着目しているエレメントの長さ
		*
		move.w	#MODEVAL_ALL,-(a7)
		pea	searchnamebuf(a6)
		pea	statbuf(a6)
		movea.l	a2,a0
		lea	dos_allfile,a1
		bsr	strcpy
		DOS	_FILES
		lea	10(a7),a7
test_directory_find_loop:
		tst.l	d0
		bmi	test_directory_return		*  エントリが無い .. false

		move.b	statbuf+ST_MODE(a6),d3
		btst	#MODEBIT_DIR,d3
		bne	test_directory_2

		btst	#MODEBIT_VOL,d3
		bne	test_directory_findnext

		tst.b	flag_symlinks(a5)
		beq	test_directory_findnext

		btst	#MODEBIT_LNK,d3
		beq	test_directory_findnext
test_directory_2:
		lea	statbuf+ST_NAME(a6),a1
		tst.b	(a1,d2.l)
		bne	test_directory_findnext

		movea.l	a3,a0
		move.l	d2,d0
		move.b	flag_cifilec(a5),d1
		bsr	memxcmp
		bne	test_directory_findnext

		exg	a0,a2
		bsr	stpcpy
		exg	a2,a0

		btst	#MODEBIT_DIR,d3
		bne	test_directory_found

		tst.b	flag_symlinks(a5)
		beq	test_directory_fail

		btst	#MODEBIT_LNK,d3
		beq	test_directory_fail

		lea	searchnamebuf(a6),a0
		lea	l_statbuf(a6),a1
		bsr	stat
		bmi	test_directory_fail

		btst.b	#MODEBIT_DIR,l_statbuf+ST_MODE(a6)
		beq	test_directory_fail
test_directory_found:
		lea	statbuf+ST_NAME(a6),a1
		movea.l	a3,a0
		move.l	d2,d0
		bsr	memmovi
		movea.l	a0,a3
		move.b	(a3)+,(a2)+
		bra	test_directory_loop

test_directory_findnext:
		pea	statbuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		bra	test_directory_find_loop

test_directory_fail:
		moveq	#-1,d0
		bra	test_directory_return

test_directory_true:
		moveq	#0,d0
test_directory_return:
		movem.l	(a7)+,d1-d3/a0-a3
		unlk	a6
		tst.l	d0
		rts
*****************************************************************
.data

.even
key_function_jump_table:
		dc.l	x_self_insert
		dc.l	x_error
		dc.l	x_no_op
		dc.l	x_macro
		dc.l	x_prefix_1
		dc.l	x_prefix_2
		dc.l	x_abort
		dc.l	x_eof
		dc.l	x_accept_line
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
		dc.l	x_upcase_char
		dc.l	x_downcase_char
		dc.l	x_upcase_word
		dc.l	x_downcase_word
		dc.l	x_upcase_region
		dc.l	x_downcase_region
		dc.l	x_transpose_chars
		dc.l	x_transpose_words
		dc.l	x_history_search_backward
		dc.l	x_history_search_forward
		dc.l	x_complete
		dc.l	x_complete_command
		dc.l	x_complete_file
		dc.l	x_complete_variable
		dc.l	x_complete_environment_variable
		dc.l	x_complete_shell_variable
		dc.l	x_list
		dc.l	x_list_command
		dc.l	x_list_file
		dc.l	x_list_variable
		dc.l	x_list_environment_variable
		dc.l	x_list_shell_variable
		dc.l	x_list_or_eof
		dc.l	x_del_for_char_or_list
		dc.l	x_del_for_char_or_list_or_eof
		dc.l	x_copy_prev_word
		dc.l	x_up_history
		dc.l	x_down_history
		dc.l	x_quit_history

word_fignore:		dc.b	'fignore',0
word_matchbeep:		dc.b	'matchbeep',0
word_ambiguous:		dc.b	'ambiguous',0
word_notunique:		dc.b	'notunique',0
word_addsuffix:		dc.b	'addsuffix',0
word_showdots:		dc.b	'showdots',0

str_A:			dc.b	'-A',0

filec_separators:	dc.b	'"',"'",'`^='
word_separators:	dc.b	' ',HT
x_special_characters:	dc.b	'<>)'
x_command_separators_1:	dc.b	'('
x_command_separators_2:	dc.b	';&|',0

month_word_table:
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

english_week:
		dc.b	'Sunday',0
		dc.b	'Monday',0
		dc.b	'Tuesday',0
		dc.b	'Wednesday',0
		dc.b	'Thursday',0
		dc.b	'Friday',0
		dc.b	'Saturday',0
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

msg_no_status:	dc.b	'(status is unset)',0
word_sorry:	dc.b	'(%R is not available yet)',0
word_percent:	dc.b	'%',0

.end
