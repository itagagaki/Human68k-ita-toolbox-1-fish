* getline.s
* Itagaki Fumihiko 29-Jul-90  Create.

.include doscall.h
.include chrcode.h
.include limits.h
.include ../src/fish.h
.include ../src/source.h

.xref too_long_line
.xref isspace
.xref issjis
.xref irandom
.xref FreeCurrentSource
.xref put_newline
.xref put_space
.xref putc
.xref cputc
.xref puts
.xref cputs
.xref skip_space
.xref crlf_skip
.xref memmove_inc
.xref memmove_dec
.xref memcmp
.xref memxcmp
.xref strcpy
.xref strchr
.xref strlen
.xref strbot
.xref builtin_dir_match
.xref open_passwd
.xref fgetc
.xref fgets
.xref fopen
.xref fclose
.xref expand_tilde
.xref includes_dos_wildcard
.xref test_pathname
.xref find_shellvar
.xref copy_wordlist
.xref sort_wordlist
.xref for1str
.xref fornstrs
.xref common_spell
.xref printu
.xref tolower
.xref utoa
.xref atou
.xref date_cnv_sub
.xref getcwd
.xref zerofill
.xref getitimer
.xref count_time_sec
.xref make_home_filename
.xref mulul
.xref test_drive_path
.xref congetbuf
.xref last_congetbuf
.xref tmpargs
.xref command_table
.xref pathname_buf
.xref word_prompt
.xref dos_allfile
.xref current_source
.xref input_is_tty
.xref flag_stdgets
.xref flag_filec
.xref flag_cifilec
.xref flag_nobeep
.xref his_toplineno
.xref his_nlines_now
.xref last_yow_high
.xref last_yow_low

auto_pathname = (((MAXPATH+1)+1)>>1<<1)

.text

*****************************************************************
* getline
*
* CALL
*      A0     入力バッファの先頭
*      D1.W   入力最大バイト数（最後のNUL分は勘定しない）
*      D2.B   1 ならばコメントを削除する
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
		movem.l	d3-d4/a0-a4,-(a7)
getline_more:
		**
		**  １物理行を入力する
		**
		movea.l	a0,a4
		move.l	d7,d0
		jsr	(a2)
		bne	getline_return

		cmpa.l	a4,a0				* 入力された文字数が0ならば
		beq	getline_done			* 終わり

		suba.l	a1,a1
****************
		**
		**  行継続をチェックする
		**
		moveq	#0,d3
		movea.l	a4,a3
getline_cont_check_loop:
		cmpa.l	a0,a3
		beq	getline_not_cont

		move.b	(a3)+,d0
		bsr	issjis
		beq	getline_cont_check_sjis

		cmp.b	#'"',d0
		beq	getline_cont_check_quote

		cmp.b	#"'",d0
		beq	getline_cont_check_quote

		cmp.b	#'\',d0
		bne	getline_cont_check_loop

		cmpa.l	a0,a3
		beq	getline_cont_check_done		* D0.B is always '\' here.

		move.b	(a3),d0
		bsr	issjis
		beq	getline_cont_check_loop
getline_cont_check_skip:
		addq.l	#1,a3
		bra	getline_cont_check_loop

getline_cont_check_quote:
		tst.b	d3
		bne	getline_cont_check_loop

		eor.b	d0,d3
		bra	getline_cont_check_loop

getline_cont_check_sjis:
		cmpa.l	a0,a3
		bne	getline_cont_check_skip
getline_not_cont:
		moveq	#0,d0
getline_cont_check_done:
		tst.w	d0
		beq	getline_process_comment

		move.b	#' ',-1(a0)
		tst.b	d3
		beq	getline_process_comment

		move.b	#CR,-1(a0)
		subq.w	#1,d1
		bcs	getline_over

		move.b	#LF,(a0)+
****************
getline_process_comment:
		move.w	d0,-(a7)
		tst.b	d2
		beq	getline_comment_cut_done
		**
		**  コメントを探す
		**
		moveq	#0,d3				* D3 : {}レベル
		moveq	#0,d4				* D4 : クオート・フラグ
find_comment_loop:
		move.b	(a4)+,d0
		beq	find_comment_break

		bsr	issjis
		beq	find_comment_skip_one

		tst.l	d3
		beq	find_comment_0

		cmp.b	#'}',d0
		bne	find_comment_0

		subq.l	#1,d3
find_comment_0:
		tst.b	d4
		beq	find_comment_1

		cmp.b	d4,d0
		bne	find_comment_loop
find_comment_flip_quote:
		eor.b	d0,d4
		bra	find_comment_loop

find_comment_1:
		tst.l	d3
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

		cmp.b	#'$',d0
		beq	find_comment_special

		cmp.b	#'!',d0
		bne	find_comment_loop
find_comment_special:
		cmpi.b	#'{',(a4)
		bne	find_comment_ignore_next_char

		addq.l	#1,a4
		addq.l	#1,d3
		bra	find_comment_loop

find_comment_ignore_next_char:
		move.b	(a4)+,d0
		beq	find_comment_break

		bsr	issjis
		bne	find_comment_loop
find_comment_skip_one:
		move.b	(a4)+,d0
		bne	find_comment_loop
find_comment_break:
		**
		**  コメントを削除する
		**
		clr.b	-(a4)
		move.l	a0,d0
		sub.l	a4,d0
		add.w	d0,d1
		movea.l	a4,a0
getline_comment_cut_done:
		move.w	(a7)+,d0
		bne	getline_more
getline_done:
		moveq	#0,d0
getline_return:
		movem.l	(a7)+,d3-d4/a0-a4
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
*      D1.W   入力最大バイト数（最後のNUL分は勘定しない）
*
* RETURN
*      A0     入力文字数分進む
*      D0.L   0:入力有り，-1:EOF，1:入力エラー
*      D1.W   残り入力可能バイト数（最後のNUL分は勘定しない）
*      CCR    TST.L D0
*****************************************************************
.xdef getline_phigical

getline_phigical:
		bsr	irandom

		tst.l	current_source
		beq	getline_phigical_stdin

		DOS	_KEYSNS				* to allow interrupt
		bsr	getline_script
		beq	getline_phigical_return

		move.l	d0,-(a7)
		bsr	FreeCurrentSource
		move.l	(a7)+,d0
		bra	getline_phigical_error

getline_phigical_stdin:
		bsr	getline_stdin
		beq	getline_phigical_return
getline_phigical_error:
		bpl	too_long_line
getline_phigical_return:
		rts
*****************************************************************
getline_script:
		move.l	a1,-(a7)
		movea.l	current_source,a1
		movea.l	SOURCE_POINTER(a1),a1
getline_script_loop:
		move.b	(a1)+,d0
		beq	getline_script_eof

		cmp.b	#EOT,d0
		beq	getline_script_eof

		cmp.b	#CR,d0
		beq	getline_script_cr

		subq.w	#1,d1
		bcs	getline_script_over

		move.b	d0,(a0)+
		bra	getline_script_loop

getline_script_cr:
		exg	a0,a1
		bsr	crlf_skip
		exg	a0,a1
		cmp.b	#LF,d0
		bne	getline_script_loop

		clr.b	(a0)
		moveq	#0,d0
getline_script_return:
		move.l	a1,-(a7)
		movea.l	current_source,a1
		move.l	(a7)+,SOURCE_POINTER(a1)
		movea.l	(a7)+,a1
		tst.l	d0
		rts

getline_script_eof:
		subq.l	#1,a1
		moveq	#-1,d0
		bra	getline_script_return

getline_script_over:
		moveq	#1,d0
		bra	getline_script_return
*****************************************************************
getline_stdin:
		tst.b	input_is_tty
		bne	getline_console

		moveq	#0,d0
		bra	fgets
*****************************************************************
getline_standard_console:
		move.l	a1,-(a7)

		move.l	a0,-(a7)
		lea	congetbuf,a0
		move.l	a0,-(a7)
		move.b	#255,(a0)+

		lea	last_congetbuf,a1
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
		lea	last_congetbuf,a0
		move.b	(a1)+,(a0)+
		bsr	strcpy
getline_console_done:
		movea.l	(a7)+,a0

		lea	congetbuf+1,a1
		clr.w	d0
		move.b	(a1)+,d0
		sub.w	d0,d1
		bcs	getline_console_over

		bsr	memmove_inc
getline_console_ok:
		clr.b	(a0)
		moveq	#0,d0
getline_console_return:
		movea.l	(a7)+,a1
		rts

getline_console_eof:
		moveq	#-1,d0
		bra	getline_console_return

getline_console_over:
		moveq	#1,d0
		bra	getline_console_return
*****************************************************************
.xdef getline_console_2

getline_console_2:
		tst.b	flag_stdgets
		bne	getline_standard_console

		movem.l	a1,-(a7)
		suba.l	a1,a1
		moveq	#0,d0
		bsr	getline_extended_console
		movem.l	(a7)+,a1
		rts

getline_console:
		bsr	put_prompt
		tst.b	flag_stdgets
		bne	getline_standard_console

		moveq	#1,d0
********************************
put_prompt_ptr = -4
line_top = put_prompt_ptr-4
cursor_ptr = line_top-4
nbytes = cursor_ptr-4
more_extended = nbytes-2

getline_extended_console:
		link	a6,#more_extended
		move.l	a0,line_top(a6)
		move.l	a1,put_prompt_ptr(a6)
		move.b	d0,more_extended(a6)
		clr.l	cursor_ptr(a6)
		clr.l	nbytes(a6)
getline_extended_loop:
		DOS	_GETC
		tst.l	d0
		bmi	getline_extended_eof
getline_extended_loop2:
		cmp.b	#'D'-'@',d0
		beq	getline_extended_eof

		cmp.b	#'H'-'@',d0
		beq	getline_extended_erase

		cmp.b	#'J'-'@',d0
		beq	getline_extended_cr

		cmp.b	#'L'-'@',d0
		beq	getline_extended_redraw

		cmp.b	#'M'-'@',d0
		beq	getline_extended_cr

		cmp.b	#'U'-'@',d0
		beq	getline_extended_kill

		cmp.b	#'W'-'@',d0
		beq	getline_extended_werase

		tst.b	more_extended(a6)
		beq	getline_extended_ins_char

		tst.b	flag_filec
		beq	getline_extended_ins_char

		cmp.b	#'['-'@',d0
		beq	getline_extended_filec
****************
getline_extended_ins_char:
		subq.w	#1,d1
		bcs	getline_extended_console_over

		movea.l	line_top(a6),a0
		move.l	d0,-(a7)
		move.l	nbytes(a6),d0
		add.l	d0,a0				* A0 : 行末
		sub.l	cursor_ptr(a6),d0		* D0.L : カーソル以降のバイト数
		movea.l	a0,a1
		subq.l	#1,a1
		bsr	memmove_dec
		move.l	(a7)+,d0
		move.b	d0,(a0)
		bsr	cputc
		addq.l	#1,cursor_ptr(a6)
		addq.l	#1,nbytes(a6)
		bra	getline_extended_loop
****************
*  ^L : 再表示
getline_extended_redraw:
		bsr	put_newline
		movea.l	put_prompt_ptr(a6),a1
		bsr	put_prompt
		movea.l	line_top(a6),a0
		move.l	nbytes(a6),d0
		clr.b	(a0,d0.l)
		bsr	cputs
		* [cursor]
		bra	getline_extended_loop
****************
*  ^D : EOF
getline_extended_eof:
		bsr	cputc
		moveq	#BS,d0
		bsr	putc
		bsr	putc
		tst.b	more_extended(a6)
		beq	getline_extended_console_ok

		tst.l	nbytes(a6)
		beq	getline_extended_eof_1

		moveq	#0,d0
		tst.b	flag_filec
		bne	getline_extended_filec

		DOS	_GETC
		tst.l	d0
		bmi	getline_extended_eof_1

		cmp.b	#EOF,d0
		bne	getline_extended_loop2
getline_extended_eof_1:
		moveq	#-1,d0
		bra	getline_extended_console_return
****************
getline_extended_console_over:
		moveq	#1,d0
		bra	getline_extended_console_return
****************
*  ^M (CR)
getline_extended_cr:
		bsr	put_newline
getline_extended_console_ok:
		movea.l	line_top(a6),a0
		move.l	nbytes(a6),d0
		adda.l	d0,a0
		clr.b	(a0)
		moveq	#0,d0
getline_extended_console_return:
		movea.l	put_prompt_ptr(a6),a1
		unlk	a6
		rts
****************
*  ^U : 行頭からカーソル直前まで削除
getline_extended_kill:
getline_extended_kill_loop:
		tst.l	cursor_ptr(a6)
		beq	getline_extended_loop

		bsr	erase_char
		bra	getline_extended_kill_loop
****************
*  ^W : カーソル直前の1語を削除
getline_extended_werase:
getline_extended_werase_1:
		move.l	cursor_ptr(a6),d0
		beq	getline_extended_loop

		movea.l	line_top(a6),a0
		move.b	-1(a0,d0.l),d0
		bsr	isspace
		bne	getline_extended_werase_2

		bsr	erase_char
		bra	getline_extended_werase_1

getline_extended_werase_2:
		move.l	cursor_ptr(a6),d0
		beq	getline_extended_loop

		movea.l	line_top(a6),a0
		move.b	-1(a0,d0.l),d0
		bsr	isspace
		beq	getline_extended_loop

		bsr	erase_char
		bra	getline_extended_werase_2
****************
getline_extended_erase:
		bsr	erase_char
		bra	getline_extended_loop
****************
*  ESC-ESC, ESC-^Z : ファイル名完成
getline_extended_filec:

filec_name = -auto_pathname
filec_namebuf = filec_name-auto_pathname

		link	a4,#filec_namebuf
		movem.l	d2-d7/a2-a3,-(a7)
		move.b	d0,d7			* D7.B : 0 ならばリスト表示
		*
		*  カーソルが行末になければダメ
		*
		move.l	cursor_ptr(a6),d6
		cmp.l	nbytes(a6),d6
		bne	filec_fail
		*
		*  対象の単語を取り出す
		*
		movea.l	line_top(a6),a2
filec_find_word_remember:
		movea.l	a2,a1
filec_find_word_loop:
		subq.l	#1,d6
		bcs	filec_find_word_done

		moveq	#0,d0
		move.b	(a2)+,d0
		beq	filec_find_word_remember

		bsr	issjis
		beq	filec_find_word_sjis

		lea	filec_separators,a0
		bsr	strchr
		bne	filec_find_word_remember

		bra	filec_find_word_loop

filec_find_word_sjis:
		subq.l	#1,d6
		bcs	filec_find_word_done

		addq.l	#1,a2
		bra	filec_find_word_loop

filec_find_word_done:
		move.l	line_top(a6),d0
		add.l	cursor_ptr(a6),d0
		sub.l	a1,d0
		cmp.l	#MAXPATH,d0
		bhi	filec_fail

		lea	filec_name(a4),a0
		bsr	memmove_inc
		clr.b	(a0)

		moveq	#0,d5			* D5.W : 検索されたエントリ数
		*
		*  ユーザ名か？ ファイル名か？
		*
		lea	filec_name(a4),a0
		bsr	builtin_dir_match
		beq	filec_not_builtin

		cmpi.b	#'/',(a0,d0.l)
		bne	filec_not_builtin
filec_builtin:
		*
		*  組み込みコマンドを検索する
		*
		*       A0   : 検索する文字列を格納したバッファのアドレス
		*       D0.L : 仮想ディレクトリ部の長さ-1
		*       D5.W : 検索されたエントリ数（ここでは0）
		*       D7.B : 0 ならばリスト表示
		*
		addq.l	#1,d0
		add.l	d0,a0
		movea.l	a0,a1			* A1 : 比較する文字列
		bsr	strlen
		move.l	d0,d3			* D3.L : 比較する長さ
		moveq	#0,d2			* D2.L : 検索されたエントリの名前の最大長
						*        (リスト表示のため)
		lea	tmpargs,a3		* A3 : 検索された名前のリストを格納するバッファ
		move.w	#MAXWORDLISTSIZE,d4	* D4.W : (A3)の容量
		lea	command_table,a0
filec_builtin_loop:
		tst.b	(a0)
		beq	filec_find_done

		move.l	d3,d0
		bsr	memcmp
		bne	filec_builtin_next

		bsr	filec_append_length
		bcs	filec_fail

		addq.l	#1,d0
		bsr	filec_append_sub
		bcs	filec_fail
filec_builtin_next:
		lea	14(a0),a0
		bra	filec_builtin_loop
********************************
filec_not_builtin:
		cmpi.b	#'~',(a0)
		bne	filec_file

		moveq	#'/',d0
		bsr	strchr
		bne	filec_file
filec_username:
		*
		*  ユーザ名を検索する
		*
		*       D5.W : 検索されたエントリ数
		*       D7.B : 0 ならばリスト表示
		*
		bsr	open_passwd
		bmi	filec_username_done0

		move.w	d0,d6			* D6.W : passwd ファイル・ハンドル

		lea	filec_name+1(a4),a0
		bsr	strlen
		move.l	d0,d3			* D3.L : 比較する長さ
		moveq	#0,d2			* D2.L : 検索されたエントリの名前の最大長
						*        (リスト表示のため)
		lea	tmpargs,a3		* A3 : 検索された名前のリストを格納するバッファ
		move.w	#MAXWORDLISTSIZE,d4	* D4.W : (A3)の容量
filec_username_loop:
		lea	congetbuf+2,a0
		move.w	d6,d0
		move.w	d1,-(a7)
		move.w	#255,d1
		bsr	fgets
		move.w	(a7)+,d1
		tst.l	d0
		bmi	filec_username_done
		bne	filec_username_loop

		lea	congetbuf+2,a0
		moveq	#';',d0
		bsr	strchr
		clr.b	(a0)
		lea	congetbuf+2,a0
		lea	filec_name+1(a4),a1
		move.l	d3,d0
		bsr	memcmp
		bne	filec_username_loop

		bsr	filec_append_length
		bcs	filec_username_fail

		addq.l	#1,d0
		bsr	filec_append_sub
		bcc	filec_username_loop
filec_username_fail:
		move.w	d6,d0
		bsr	fclose
		bra	filec_fail

filec_username_done:
		move.w	d6,d0
		bsr	fclose
filec_username_done0:
		tst.b	d7
		beq	filec_list		* リスト表示へ

		bra	fignore_ok
********************************
filec_file:
		*
		*  ~を展開…
		*
		lea	filec_name(a4),a0
		lea	filec_namebuf(a4),a1
		moveq	#0,d2
		move.l	d1,-(a7)
		move.w	#MAXPATH,d1
		bsr	expand_tilde
		move.l	(a7)+,d1
		tst.l	d0
		bmi	filec_find_done
		*
		*  ファイル名を検索する
		*
		*       D5.W : 検索されたエントリ数（ここでは0）
		*       D7.B : 0 ならばリスト表示
		*
		lea	filec_namebuf(a4),a0
		bsr	includes_dos_wildcard	* Human68k のワイルドカードを含んで
		bne	filec_find_done		* いるならば無効

		moveq	#'\',d0			* \ を
		move.l	a0,-(a7)
		bsr	strchr			* 含んで
		movea.l	(a7)+,a0
		bne	filec_find_done		* いるならば無効

		movem.l	d1,-(a7)
		bsr	test_pathname		* D0-D3/A1-A3
		movem.l	(a7)+,d1
		bhi	filec_find_done
						* A2 : ファイル部のアドレス
		* D2.L : ファイル部の長さ
		* D3.L : 拡張子部の長さ

		bsr	test_directory
		bne	filec_find_done

		movea.l	a0,a1
		bsr	strbot
		tst.l	d3
		bne	filec_file_5

		cmp.l	#MAXFILE,d2
		bhs	filec_file_4

		move.b	#'*',(a0)+
filec_file_4:
		tst.l	d3
		bne	filec_file_5

		move.b	#'.',(a0)+
filec_file_5:
		cmp.l	#MAXEXT,d3
		bhs	filec_file_6

		move.b	#'*',(a0)+
filec_file_6:
		clr.b	(a0)
		add.l	d2,d3			* D3.L : tail部の長さ
		moveq	#0,d2			* D2.L : 検索されたエントリの名前の最大長
						*        (リスト表示のため)
		lea	tmpargs,a3		* A3 : 検索された名前のリストを格納するバッファ
		move.w	#MAXWORDLISTSIZE,d4	* D4.W : (A3)の容量

dir_buf = -(((53)+1)>>1<<1)

		link	a6,#dir_buf
		move.w	#$37,-(a7)		* ボリューム・ラベル以外の全てを検索
		move.l	a1,-(a7)
		pea	dir_buf(a6)
		DOS	_FILES
		lea	10(a7),a7
		movea.l	a2,a1
filec_file_search_loop:
		tst.l	d0
		bmi	filec_file_search_done	* C=0

		lea	dir_buf+30(a6),a0
		cmpi.b	#'.',(a0)
		beq	filec_file_search_next

		move.l	d3,d0
		movem.w	d1,-(a7)
		move.b	flag_cifilec,d1
		bsr	memxcmp
		movem.w	(a7)+,d1
		bne	filec_file_search_next

		bsr	filec_append_length
		bcs	filec_file_search_done

		bsr	filec_append_sub
		bcs	filec_file_search_done

		tst.b	d7
		bne	filec_file_searched_2

		btst.b	#4,dir_buf+21(a6)
		beq	filec_file_searched_2

		subq.w	#1,d4
		bcs	filec_file_search_done

		move.b	#'/',(a3)+
filec_file_searched_2:
		subq.w	#1,d4
		bcs	filec_file_search_done

		clr.b	(a3)+
filec_file_search_next:
		pea	dir_buf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		bra	filec_file_search_loop

filec_file_search_done:
		unlk	a6
		bcs	filec_fail
filec_find_done:
		*
		*       D2.W : 検索されたエントリの名前の最大長
		*       D3.L : 検索条件であるところの長さ
		*       D5.W : 検索されたエントリ数
		*       D7.B : 0 ならばリスト表示
		*
		tst.b	d7
		beq	filec_list		* リスト表示へ
		*
		*  fignore にセットされているサフィックスを持つエントリを外す
		*
		*       D3.L : 検索条件であるところの長さ
		*       D5.W : 検索されたエントリ数
		*
		cmp.w	#1,d5			* 検索されたエントリが
		blo	filec_fail		* 無ければエラー
		beq	fignore_ok		* 唯1個ならば、fignore は無視する

		lea	word_fignore,a0		* シェル変数 fignore を
		bsr	find_shellvar		* 探す
		beq	fignore_ok		* 定義されていなければ無視する

		addq.l	#2,a0
		move.w	(a0)+,d2		* D2.W : fignore 単語数
		bra	fignore_loop1_continue

fignore_loop1:
		bsr	strlen
		move.l	d0,d7			* D7.L : $fignore[i] の長さ
		movea.l	a0,a1			* A1 : $fignore[i]
		lea	tmpargs,a0
		move.w	d5,d4
		bra	fignore_loop2_continue

fignore_loop2:
		movea.l	a0,a3
		bsr	strlen
		sub.l	d7,d0			* $fignore[i] より
		blo	fignore_pass		* 短いならパス

		adda.l	d0,a0
		move.l	d7,d0
		movem.w	d1,-(a7)
		move.b	flag_cifilec,d1
		bsr	memxcmp			* ケツが一致
		movem.w	(a7)+,d1
		bne	fignore_pass		* しないならパス

		subq.w	#1,d5			* --(エントリ数)
		beq	filec_fail		* 1個も無くなったら、エラー

		bsr	for1str
		exg	a0,a1			* A0:$fignore[i], A1:次のエントリ
		exg	a0,a3			* A0:着目中のエントリ, A3:$fignore[i]
		move.w	d4,d0			* D0:次からのエントリ数
		bsr	copy_wordlist		* 要するに着目中のエントリを削除する
		movea.l	a3,a1			* A1:$fignore[i]
		bra	fignore_loop2_continue

fignore_pass:
		bsr	for1str
fignore_loop2_continue:
		dbra	d4,fignore_loop2

		movea.l	a1,a0
fignore_loop1_continue:
		bsr	for1str
		dbra	d2,fignore_loop1
fignore_ok:
		*
		*  最初の曖昧でない部分を確定する
		*
		*       D3.L : 検索条件であるところの長さ
		*       D5.W : 検索されたエントリ数
		*
		lea	tmpargs,a0
		move.w	d5,d0
		move.b	flag_cifilec,d2
		move.w	d1,-(a7)
		move.w	d3,d1
		bsr	common_spell
		move.w	(a7)+,d1
		*
		*  完成部分を挿入する
		*
		sub.w	d0,d1
		bcs	filec_file_over

		adda.l	d3,a0
		movea.l	a0,a1
		movea.l	line_top(a6),a0
		adda.l	cursor_ptr(a6),a0
		bsr	memmove_inc
		clr.b	(a0)
		movea.l	line_top(a6),a0
		adda.l	cursor_ptr(a6),a0
		bsr	cputs
		add.l	d0,cursor_ptr(a6)
		add.l	d0,nbytes(a6)
		cmp.w	#1,d5
		beq	filec_done
filec_fail:
		bsr	beep
filec_done:
		movem.l	(a7)+,d2-d7/a2-a3
		unlk	a4
		bra	getline_extended_loop
***
filec_list:
		*
		*  リスト表示
		*
		*       D2.W : 検索されたエントリの名前の最大長
		*       D5.W : 検索されたエントリ数
		*
		move.w	d5,d0
		beq	filec_list_done

		lea	tmpargs,a0
		bsr	sort_wordlist
		addq.w	#2,d2			* D2.W : 1項目の桁数
		*
		*  79(行の桁数-1)を1項目の桁数で割って、1行あたりの項目数を暫定する
		*
		moveq	#79,d3
		divu	d2,d3			* D3.W : 79 / 桁数 = 1行の項目数(暫定)
		*
		*  1項目の桁数が79を超えている場合には1行あたりの項目数は0となって
		*  しまうが、その場合には1行に1項目とする
		*
		tst.w	d3
		bne	filec_list_width_ok

		moveq	#1,d3
filec_list_width_ok:
		*
		*  何行になるかを求める
		*
		moveq	#0,d4
		move.w	d5,d4
		divu	d3,d4			* D4.W : エントリ数 / 1行の項目数 = 行数
		swap	d4
		move.w	d4,d6
		swap	d4
		*
		*  余りがなければＯＫ
		*
		tst.w	d6
		beq	filec_list_height_ok
		*
		*  余りがある --- 行数はさらに1行多い
		*
		addq.w	#1,d4
		*
		*  1行多くなったので、1行の項目数を計算し直す
		*
		moveq	#0,d3
		move.w	d5,d3
		divu	d4,d3
		swap	d3
		move.w	d3,d6
		swap	d3
		tst.w	d6
		beq	filec_list_height_ok
		*
		*  余りがある --- 1行の項目数はさらに1項目多い
		*                 余り(D6.W)は1項目多い行数である
		*
		addq.w	#1,d3
filec_list_height_ok:
		lea	tmpargs,a0
		movea.l	a0,a1			* A1:最初の行の先頭項目
filec_list_loop1:
		bsr	put_newline
		movea.l	a1,a0
		bsr	for1str
		exg	a0,a1			* A0:この行の先頭項目  A1:次行の先頭項目
		move.w	d3,d7
filec_list_loop2:
		bsr	puts
		bsr	strlen
		sub.w	d2,d0
		neg.w	d0
		subq.w	#1,d0
filec_list_loop3:
		bsr	put_space
		dbra	d0,filec_list_loop3

		subq.w	#1,d5
		beq	filec_list_done

		subq.w	#1,d7
		beq	filec_list_loop2_break

		move.w	d4,d0
		bsr	fornstrs
		bra	filec_list_loop2

filec_list_loop2_break:
		tst.w	d6
		beq	filec_list_loop1

		subq.w	#1,d6
		bne	filec_list_loop1

		subq.w	#1,d3
		bra	filec_list_loop1

filec_list_done:
		movem.l	(a7)+,d2-d7/a2-a3
		bra	getline_extended_redraw
***
filec_file_over:
		movem.l	(a7)+,d2-d7/a2-a3
		bra	getline_extended_console_over
***
filec_append_length:
		bsr	strlen
		cmp.l	d2,d0
		bls	filec_append_length_return

		move.l	d0,d2
filec_append_length_return:
		addq.w	#1,d5
		rts
***
filec_append_sub:
		sub.w	d0,d4
		bcs	filec_append_sub_return

		movem.l	a0-a1,-(a7)
		movea.l	a0,a1
		movea.l	a3,a0
		bsr	memmove_inc
		movea.l	a0,a3
		movem.l	(a7)+,a0-a1
		cmp.w	d0,d0
filec_append_sub_return:
erase_char_done:
		rts
*****************************************************************
erase_char:
		tst.l	cursor_ptr(a6)
		beq	erase_char_done

		subq.l	#1,cursor_ptr(a6)
		subq.l	#1,nbytes(a6)
		addq.w	#1,d1
		movea.l	line_top(a6),a0
		adda.l	cursor_ptr(a6),a0
		move.b	(a0),d0
		cmp.b	#HT,d0
		beq	erase_ht

		cmp.b	#$20,d0
		blo	erase_2letter

		cmp.b	#$7f,d0
		beq	erase_2letter

		tst.l	cursor_ptr(a6)
		beq	erase_1letter

		move.b	-1(a0),d0
		bsr	issjis
		bne	erase_1letter

		movea.l	line_top(a6),a0
		move.l	d1,-(a7)
		move.l	cursor_ptr(a6),d1
erase_test_loop:
		move.b	(a0)+,d0
		bsr	issjis
		bne	erase_test_continue

		subq.l	#1,d1
		beq	erase_test_break

		addq.l	#1,a0
erase_test_continue:
		subq.l	#1,d1
		bne	erase_test_loop

		moveq	#0,d0
erase_test_break:
		move.l	(a7)+,d1
		tst.b	d0
		beq	erase_1letter

		subq.l	#1,cursor_ptr(a6)
		subq.l	#1,nbytes(a6)
		addq.w	#1,d1
		cmp.b	#$80,d0
		bls	erase_1letter

		cmp.b	#$f0,d0
		bhs	erase_1letter
erase_2letter:
		bsr	put_back_space
erase_ht:
erase_1letter:
put_back_space:
		moveq	#BS,d0
		bsr	putc
		bsr	put_space
		bra	putc
*****************************************************************
beep:
		tst.b	flag_nobeep
		bne	beep_done

		moveq	#BL,d0
		bsr	putc
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
.xdef put_prompt_1

put_prompt_1:
		bsr	yow
		movem.l	d0-d1/a0-a1,-(a7)
		lea	word_prompt,a0
		bsr	find_shellvar
		beq	prompt_done

		addq.l	#2,a0
		tst.w	(a0)+
		beq	prompt_done

		bsr	for1str
		movea.l	a0,a1
prompt_loop:
		move.b	(a1)+,d0
		beq	prompt_done

		bsr	issjis
		beq	prompt_sjis

		cmp.b	#'!',d0
		beq	prompt_eventno

		cmp.b	#'$',d0
		beq	prompt_misc

		bra	prompt_normal

prompt_sjis:
		bsr	putc
		move.b	(a1)+,d0
		beq	prompt_done
prompt_normal:
		bsr	putc
		bra	prompt_loop

prompt_eventno:
		move.l	his_toplineno,d0
		add.l	his_nlines_now,d0
		movem.l	d2/a1,-(a7)
		moveq	#1,d2
		lea	puts(pc),a1
		bsr	printu
		movem.l	(a7)+,d2/a1
		bra	prompt_loop

prompt_misc:
		move.b	(a1)+,d0
		beq	prompt_done

		bsr	issjis
		beq	prompt_misc_sjis

		cmp.b	#'$',d0
		beq	prompt_normal

		cmp.b	#'_',d0
		beq	prompt_flag_under

		cmp.b	#'n',d0
		beq	prompt_flag_ln

		cmp.b	#'N',d0
		beq	prompt_flag_un

		bsr	tolower
		cmp.b	#'d',d0
		beq	prompt_flag_d

		cmp.b	#'e',d0
		beq	prompt_flag_e

		cmp.b	#'h',d0
		beq	prompt_flag_h

		cmp.b	#'p',d0
		beq	prompt_flag_p

		cmp.b	#'t',d0
		beq	prompt_flag_t

		bra	prompt_loop

prompt_misc_sjis:
		move.b	(a1)+,d0
		bne	prompt_loop
prompt_done:
		movem.l	(a7)+,d0-d1/a0-a1
		rts

prompt_flag_d:
		move.l	a1,-(a7)
		DOS	_GETDATE
		move.l	d0,d1
		link	a6,#-42
		lea	-42(a6),a0
		lsr.l	#8,d0
		lsr.l	#1,d0
		and.l	#$7f,d0
		add.l	#1980,d0
		bsr	utoa
		addq.l	#7,a0
		bsr	puts
		lea	-30(a6),a0
		bsr	date_cnv_sub
		lea	-30(a6),a0
		bsr	puts
		unlk	a6
		bsr	put_space
		moveq	#'(',d0
		bsr	putc
		move.l	d1,d0
		lsr.l	#8,d0
		lsr.l	#7,d0
		and.l	#$e,d0
		lea	date_tbl,a1
		adda.l	d0,a1
		move.b	(a1)+,d0
		bsr	putc
		move.b	(a1)+,d0
		bsr	putc
		moveq	#')',d0
		bsr	putc
		movea.l	(a7)+,a1
		bra	prompt_loop

prompt_flag_e:
		moveq	#ESC,d0
		bra	prompt_normal

prompt_flag_h:
		moveq	#BS,d0
		bra	prompt_normal

prompt_flag_ln:
		DOS	_CURDRV
		add.b	#'a',d0
		bra	prompt_normal

prompt_flag_un:
		DOS	_CURDRV
		add.b	#'A',d0
		bra	prompt_normal

prompt_flag_p:
		link	a6,#-(MAXPATH+2)
		lea	-(MAXPATH+2)(a6),a0
		bsr	getcwd
		bsr	puts
		unlk	a6
		bra	prompt_loop

prompt_flag_t:
		move.l	a1,-(a7)
		DOS	_GETTIM2
		move.l	d0,d1
		link	a6,#-12
		lea	-12(a6),a0
		lsr.l	#8,d0
		lsr.l	#8,d0
		and.l	#$1f,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	puts
		moveq	#':',d0
		bsr	putc
		move.l	d1,d0
		lea	-12(a6),a0
		lsr.l	#8,d0
		and.l	#$003f,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		bsr	puts
		moveq	#':',d0
		bsr	putc
		move.l	d1,d0
		lea	-12(a6),a0
		and.l	#$3f,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		bsr	puts
		unlk	a6
		movea.l	(a7)+,a1
		bra	prompt_loop

prompt_flag_under:
		bsr	put_newline
		bra	prompt_loop
*****************************************************************
yow:
		movem.l	d0-d5/a0-a1,-(a7)
		lea	word_yow,a0
		bsr	find_shellvar
		beq	yow_return		* yow は unset

		move.l	#1800,d4		* D4.L : 間隔(秒)  デフォルト=30分
		addq.l	#2,a0
		move.w	(a0)+,d5		* D5.W : $#yow
		beq	yow_interval_ok

		bsr	for1str
		bsr	atou
		bmi	yow_interval_ok		* 数字で始まっていない ; 間隔はデフォルト
		bne	yow_return		* オーバーフロー ; 間隔を無限大とみなす

		move.l	d1,d4
		bsr	for1str
		subq.w	#1,d5
yow_interval_ok:
		bsr	getitimer
		move.l	last_yow_low,d2
		move.l	last_yow_high,d3
		bsr	count_time_sec
		cmp.l	d4,d0
		blo	yow_return

		cmp.w	#1,d5
		blo	yow_file_default
		bhi	yow_file_ok

		tst.b	(a0)
		bne	yow_file_ok
yow_file_default:
		lea	pathname_buf,a0
		lea	default_yow,a1
		bsr	make_home_filename
		bmi	yow_return

		moveq	#1,d5
yow_file_ok:
		bsr	irandom
		mulu	d5,d0
		lsl.l	#1,d0
		swap	d0
		bsr	fornstrs
		moveq	#0,d0			* 読み込みモード
		bsr	fopen
		move.l	d0,d2
		bmi	yow_leave

		move.w	#2,-(a7)
		clr.l	-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		move.l	d0,d1
		bmi	yow_close_leave

		bsr	irandom
		lsl.w	#1,d0
		bsr	mulul
		move.w	d1,d0
		swap	d0
		clr.w	-(a7)
		move.l	d0,-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	yow_close_leave
yow_backtrack:
		move.w	#1,-(a7)
		move.l	#-1,-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	yow_start

		move.w	d2,d0
		bsr	fgetc
		bmi	yow_close_leave

		cmp.b	#CR,d0
		beq	yow_start

		move.w	#1,-(a7)
		move.l	#-1,-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bpl	yow_backtrack
yow_start:
		move.w	d2,d0
		bsr	fgetc
		bmi	yow_close_leave

		cmp.b	#LF,d0
		beq	yow_start
yow_dup_loop:
		bsr	putc
		move.w	d2,d0
		bsr	fgetc
		bmi	yow_newline_leave

		cmp.b	#CR,d0
		bne	yow_dup_loop
yow_newline_leave:
		bsr	put_newline
yow_close_leave:
		move.w	d2,d0
		bsr	fclose
yow_leave:
		bsr	getitimer
		move.l	d0,last_yow_low
		move.l	d1,last_yow_high
yow_return:
		movem.l	(a7)+,d0-d5/a0-a1
		rts
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
*      / のみが許され、\ は許さない
*      flag_cifilec(B) が効く
****************************************************************
filebuf = -54
searchnamebuf = filebuf-(MAXPATH+1)
pad = searchnamebuf-(searchnamebuf.MOD.2)

test_directory:
		link	a6,#pad
		movem.l	d1-d2/a0-a3,-(a7)
		lea	searchnamebuf(a6),a2
		moveq	#0,d2
get_firstdir_restart:
		movea.l	a0,a3
		move.b	(a0)+,d0
		beq	get_firstdir_done

		cmp.b	#'/',d0
		beq	get_firstdir_root

		tst.w	d2
		bne	get_firstdir_done

		bsr	issjis
		beq	get_firstdir_done

		move.b	d0,d1
		move.b	(a0)+,d0
		beq	get_firstdir_done

		cmp.b	#':',d0
		bne	get_firstdir_done

		move.b	d1,(a2)+
		move.b	d0,(a2)+
		moveq	#1,d2
		bra	get_firstdir_restart

get_firstdir_root:
		move.b	d0,(a2)+
		movea.l	a0,a3
get_firstdir_done:
		clr.b	(a2)
		lea	searchnamebuf(a6),a0
		bsr	test_drive_path			* ドライブ名は有効か
		bne	test_directory_return		* 無効 .. false
test_directory_loop:
		*
		*  A2 : 検索名バッファのケツ
		*  A3 : 現在着目しているエレメントの先頭
		*
		movea.l	a3,a0				* 現在着目しているエレメントの後ろに
		moveq	#'/',d0				* / が
		bsr	strchr				* あるか？
		beq	test_directory_true		* 無い .. true

		move.l	a0,d2
		sub.l	a3,d2				* D2.L : エレメントの長さ
		move.w	#%010000,-(a7)			* ディレクトリのみを検索
		pea	searchnamebuf(a6)
		pea	filebuf(a6)
		movea.l	a2,a0
		lea	dos_allfile,a1
		bsr	strcpy
		DOS	_FILES
		lea	10(a7),a7
test_directory_find_loop:
		tst.l	d0
		bmi	test_directory_return		* エントリが無い .. false

		lea	filebuf+30(a6),a0
		movea.l	a3,a1
		move.l	d2,d0
		move.b	flag_cifilec,d1
		bsr	memxcmp
		beq	test_directory_found

		pea	filebuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		bra	test_directory_find_loop

test_directory_found:
		move.l	d2,d0
		addq.l	#1,d0
		exg	a1,a3
		exg	a0,a2
		bsr	memmove_inc
		exg	a0,a2
		exg	a1,a3
		clr.b	(a2)
		bra	test_directory_loop

test_directory_true:
		moveq	#0,d0
test_directory_return:
		movem.l	(a7)+,d1-d2/a0-a3
		unlk	a6
		tst.l	d0
		rts
*****************************************************************
.data

.xdef word_separators

word_fignore:		dc.b	'fignore',0
default_yow:		dc.b	'%'
word_yow:		dc.b	'yow',0
filec_separators:	dc.b	'"',"'",'^'
word_separators:	dc.b	' ',HT,VT,CR,LF,FS,';&|<>()',0
date_tbl:		dc.b	'日月火水木金土？'

.end
