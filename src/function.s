* function.s
* This contains statement function/defun/}, builtin funcitons/undefun.
*
* Itagaki Fumihiko 08-Sep-91  Create.

.include chrcode.h
.include limits.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/function.h
.include ../src/history.h

.xref strlen
.xref strcpy
.xref memcmp
.xref memmovi
.xref strpcmp
.xref strmove
.xref strfor1
.xref make_wordlist
.xref escape_quoted
.xref skip_varname
.xref putc
.xref cputc
.xref puts
.xref nputs
.xref enputs1
.xref put_tab
.xref put_newline
.xref getline
.xref getline_phigical
.xref xmalloc
.xref free
.xref subst_var
.xref strip_quotes
.xref find_history
.xref pre_perror
.xref too_few_args
.xref too_many_args
.xref cannot_because_no_memory
.xref ambiguous
.xref command_error
.xref syntax_error
.xref word_close_brace
.xref paren_pair

.xref save_sourceptr
.xref tmpword1
.xref tmpargs

.xref funcdef_status
.xref funcdef_topptr
.xref funcdef_size
.xref funcname
.xref function_root
.xref function_bot
.xref current_source
.xref in_history_ptr
.xref history_bot
.xref current_eventno
.xref loop_top_eventno
.xref keep_loop
.xref loop_fail
.xref line

.text

****************************************************************
* find_function - 関数を探す
*
* CALL
*      A0     関数名の先頭アドレス（先頭31バイトまでが有効）
*      A2     関数リンクの根ポインタのアドレス
*
* RETURN
*      D0.L   関数のヘッダ先頭アドレス（見つからなければ 0）
*      CCR    TST.L D0
****************************************************************
.xdef find_function

find_function:
		movem.l	d1/a1-a2,-(a7)
		bsr	strlen
		addq.l	#1,d0
		move.l	d0,d1				*  D1.L : 照合する長さ
		movea.l	(a2),a2
find_function_loop:
		cmpa.l	#0,a2
		beq	find_function_done

		lea	FUNC_NAME(a2),a1
		move.l	d1,d0
		bsr	memcmp
		beq	find_function_done

		movea.l	FUNC_NEXT(a2),a2
		bra	find_function_loop

find_function_done:
		move.l	a2,d0
		movem.l	(a7)+,d1/a1-a2
		rts
****************************************************************
* unlink_function - 関数を削除する
*
* CALL
*      A0     関数のヘッダの先頭アドレス
*      A2     関数リンクの根ポインタのアドレス
*
* RETURN
*      D0.L   破壊
****************************************************************
unlink_function:
		movem.l	a0-a1,-(a7)
		move.l	a0,d0
		movea.l	FUNC_NEXT(a0),a1
		movea.l	FUNC_PREV(a0),a0
		bsr	free
		cmpa.l	#0,a0
		bne	unlink_function_1

		move.l	a1,(a2)
		bra	unlink_function_2

unlink_function_1:
		move.l	a1,FUNC_NEXT(a0)
unlink_function_2:
		cmpa.l	#0,a1
		bne	unlink_function_3

		move.l	a0,4(a2)
		bra	unlink_function_return

unlink_function_3:
		move.l	a0,FUNC_PREV(a1)
unlink_function_return:
		movem.l	(a7)+,a0-a1
		rts
****************************************************************
* link_function - 関数プロトタイプを確保してリンクする
*
* CALL
*      A1     関数名の先頭アドレス（31バイト以下であること）
*      A2     関数リンクの根ポインタのアドレス
*      D1.L   関数本体の長さ（バイト）
*
* RETURN
*      D0     関数のヘッダの先頭アドレス．
*             メモリ不足で確保できなかったならば 0．
*      CCR    TST.L D0
*****************************************************************
.xdef link_function

link_function:
		movem.l	a0/a3,-(a7)
		movea.l	a1,a0
		bsr	find_function
		beq	link_function_1

		movea.l	d0,a0
		bsr	unlink_function
link_function_1:
		move.l	d1,d0
		add.l	#FUNC_HEADER_SIZE,d0
		bsr	xmalloc
		beq	link_function_return

		movea.l	d0,a3
		move.l	d1,FUNC_SIZE(a3)

		move.l	(a2),FUNC_NEXT(a3)
		tst.l	(a2)
		beq	link_function_2

		movea.l	(a2),a0
		move.l	a3,FUNC_PREV(a0)
		bra	link_function_3

link_function_2:
		move.l	a3,4(a2)
link_function_3:
		clr.l	FUNC_PREV(a3)
		move.l	a3,(a2)

		lea	FUNC_NAME(a3),a0
		bsr	strcpy
		move.l	a3,d0
link_function_return:
		movem.l	(a7)+,a0/a3
		rts
*****************************************************************
* enter_function - 関数を定義する
*
* CALL
*      A0     関数本体の先頭アドレス
*      A1     関数名の先頭アドレス（31バイト以下であること）
*      A2     関数リンクの根ポインタのアドレス
*      D1.L   関数本体の長さ（バイト）
*
* RETURN
*      D0     関数のヘッダの先頭アドレス．
*             メモリ不足で定義できなかったならば 0．
*      CCR    TST.L D0
*****************************************************************
.xdef enter_function

enter_function:
		movem.l	a0-a2,-(a7)
		bsr	link_function
		beq	enter_function_return

		movea.l	a0,a1
		movea.l	d0,a2
		lea	FUNC_HEADER_SIZE(a2),a0
		move.l	d1,d0
		bsr	memmovi
		move.l	a2,d0
enter_function_return:
		movem.l	(a7)+,a0-a2
		rts
****************************************************************
* list_1_function - 関数を表示する
*
* CALL
*      A0     関数のヘッダの先頭アドレス
*
* RETURN
*      none.
****************************************************************
.xdef list_1_function

list_1_function:
		movem.l	d0-d2/a0-a1,-(a7)
		movea.l	a0,a1
		lea	FUNC_NAME(a1),a0
		bsr	puts
		lea	str_beginfunc,a0
		bsr	nputs
		move.l	FUNC_SIZE(a1),d1
		lea	FUNC_HEADER_SIZE(a1),a0
list_1_func_newlined:
		st	d2				*  newline start flag
list_1_func_loop:
		subq.l	#1,d1
		bcs	list_1_func_done

		move.b	(a0)+,d0
		cmp.b	#CR,d0
		beq	list_1_func_cr

		cmp.b	#LF,d0
		beq	list_1_func_newline
list_1_func_cputc:
		tst.b	d2
		beq	list_1_func_cputc_1

		bsr	put_tab
		sf	d2
list_1_func_cputc_1:
		bsr	cputc
		bra	list_1_func_loop

list_1_func_cr:
		tst.l	d1
		beq	list_1_func_cputc

		cmpi.b	#LF,(a0)
		bne	list_1_func_cputc

		subq.l	#1,d1
		addq.l	#1,a0
list_1_func_newline:
		bsr	put_newline
		bra	list_1_func_newlined

list_1_func_done:
		lea	word_close_brace,a0
		bsr	nputs
		movem.l	(a7)+,d0-d2/a0-a1
		rts
****************************************************************
*  Name
*       functions - list functions
*
*  Synopsis
*       functions [ funcname ]
****************************************************************
.xdef cmd_functions

cmd_functions:
		cmp.w	#1,d0
		bhi	too_many_args
		blo	list_all_func

		lea	function_root(a5),a2
		bsr	find_function
		beq	no_func

		movea.l	d0,a0
		bsr	list_1_function
		bra	cmd_functions_return

list_all_func:
		move.l	function_bot(a5),d0
		beq	cmd_functions_return
list_function_loop:
		movea.l	d0,a0
		bsr	list_1_function
		move.l	FUNC_PREV(a0),d0
		bne	list_function_loop
cmd_functions_return:
		moveq	#0,d0
		rts

no_func:
		bsr	pre_perror
		lea	msg_no_func,a0
		bra	enputs1
****************************************************************
*  Name
*       undefun - undefine function
*
*  Synopsis
*       undefun [ pattern ] ...
****************************************************************
.xdef cmd_undefun

cmd_undefun:
		move.w	d0,d1
		subq.w	#1,d1
		bcs	too_few_args
undefun_loop:
		move.l	a0,-(a7)
		lea	tmpword1,a1
		bsr	escape_quoted		* A1 : クオートをエスケープに代えた検索文字列

		movea.l	function_root(a5),a2
undefun_find_loop:
		cmpa.l	#0,a2
		beq	undefun_done1

		movea.l	FUNC_NEXT(a2),a3
		lea	FUNC_NAME(a2),a0
		moveq	#0,d0
		bsr	strpcmp
		bne	undefun_find_next

		movea.l	a2,a0
		lea	function_root(a5),a2
		bsr	unlink_function
undefun_find_next:
		movea.l	a3,a2
		bra	undefun_find_loop

undefun_done1:
		movea.l	(a7)+,a0
		bsr	strfor1
		dbra	d1,undefun_loop

		moveq	#0,d0
		rts
*****************************************************************
* function
*****************************************************************
.xdef state_function

state_function:
		move.w	d0,d1
		beq	syntax_error

		movea.l	a0,a2
		bsr	strfor1
		cmp.w	#3,d1
		blo	no_paren

		lea	paren_pair,a1
		moveq	#4,d0
		bsr	memcmp
		bne	no_paren

		addq.l	#4,a0
		subq.w	#2,d1
no_paren:
		subq.w	#2,d1
		bne	syntax_error

		cmpi.b	#'{',(a0)+
		bne	syntax_error

		tst.b	(a0)
		bne	syntax_error

		movea.l	a2,a0
		lea	tmpword1,a1
		moveq	#1,d0
		move.l	#MAXWORDLEN+1,d1
		bsr	subst_var
		bpl	funcname_expand_done

		cmp.l	#-4,d0
		beq	function_return

		movea.l	a2,a0
		cmp.l	#-1,d0
		beq	ambiguous

funcname_too_long:
		bsr	pre_perror
		lea	msg_too_long_funcname,a0
		bra	enputs1

funcname_expand_done:
		lea	tmpword1,a0
		bsr	strip_quotes
		bsr	strlen
		cmp.l	#MAXFUNCNAMELEN,d0
		bhi	funcname_too_long

		movea.l	a0,a1
		lea	funcname(a5),a0
		bsr	strcpy
		movea.l	a0,a1
		bsr	skip_varname
		tst.b	(a0)
		bne	bad_funcname

		cmpa.l	a1,a0
		beq	bad_funcname

		st	funcdef_status(a5)
		clr.l	funcdef_size(a5)

		move.l	current_source(a5),d0
		beq	function_terminal

		movea.l	d0,a0
		move.l	SOURCE_POINTER(a0),d0
		bra	function_static

function_terminal:
		move.l	in_history_ptr(a5),d0
		bne	function_static

		move.l	current_eventno(a5),d0
		move.l	d0,funcdef_topptr(a5)
		move.l	d0,loop_top_eventno(a5)
		st	keep_loop(a5)
		sf	loop_fail(a5)
		bra	function_success_return

function_static:
		move.l	d0,funcdef_topptr(a5)
function_success_return:
		moveq	#0,d0
function_return:
		rts

bad_funcname:
		movea.l	a1,a0
		bsr	pre_perror
		lea	msg_bad_funcname,a0
		bra	enputs1
*****************************************************************
* }
*****************************************************************
.xdef state_endfunc

state_endfunc:
		lea	msg_not_in_funcdef,a0
		bra	command_error
****************************************************************
.xdef do_defun

do_defun:
		move.l	current_source(a5),d0
		beq	defun_terminal

		move.l	funcdef_size(a5),d1
		lea	funcname(a5),a1
		lea	function_root(a5),a2
		bsr	link_function
		beq	defun_no_memory

		movea.l	d0,a0
		lea	FUNC_HEADER_SIZE(a0),a0
		movea.l	funcdef_topptr(a5),a2
		movea.l	save_sourceptr,a3
		movea.l	current_source(a5),a1
		move.l	SOURCE_POINTER(a1),-(a7)
		move.l	a2,SOURCE_POINTER(a1)
make_function_body_script_loop:
		movea.l	current_source(a5),a1
		movea.l	SOURCE_POINTER(a1),a2
		cmpa.l	a3,a2
		beq	make_function_body_script_done

		move.l	a0,-(a7)
		lea	line(a5),a0
		move.w	#MAXLINELEN,d1
		suba.l	a1,a1
		st	d2
		lea	getline_phigical(pc),a2
		bsr	getline
		movea.l	(a7)+,a0
		bne	make_function_body_script_done

		move.l	a0,-(a7)
		lea	line(a5),a0
		lea	tmpargs,a1
		move.w	#MAXWORDLISTSIZE,d1
		bsr	make_wordlist
		movea.l	(a7)+,a0
		bmi	make_function_body_script_done

		move.w	d0,d1
		beq	make_function_body_script_loop

		subq.w	#1,d1
		lea	tmpargs,a1
make_function_body_script_1:
		bsr	strmove
		move.b	#' ',-1(a0)
		dbra	d1,make_function_body_script_1

		move.b	#LF,-1(a0)
		bra	make_function_body_script_loop

make_function_body_script_done:
		movea.l	current_source(a5),a1
		move.l	(a7)+,SOURCE_POINTER(a1)
		bra	make_function_body_done

defun_terminal:
		movea.l	funcdef_topptr(a5),a0
		move.l	in_history_ptr(a5),d0
		bne	defun_static

		tst.b	loop_fail(a5)
		bne	defun_no_memory

		move.l	funcdef_topptr(a5),d0
		bsr	find_history
		beq	defun_no_memory

		movea.l	history_bot(a5),a4
		bra	defun_history

defun_static:
		movea.l	d0,a4
		movea.l	HIST_PREV(a4),a4
defun_history:
		movea.l	a0,a3
		move.l	funcdef_size(a5),d1
		lea	funcname(a5),a1
		lea	function_root(a5),a2
		bsr	link_function
		beq	defun_no_memory

		movea.l	d0,a0
		lea	FUNC_HEADER_SIZE(a0),a0
make_function_body:
		cmpa.l	#0,a3
		beq	make_function_body_done

		cmpa.l	a4,a3
		beq	make_function_body_done

		move.w	HIST_NWORDS(a3),d1
		beq	make_function_body_next

		subq.w	#1,d1
		lea	HIST_BODY(a3),a1
make_function_body_1:
		bsr	strmove
		move.b	#' ',-1(a0)
		dbra	d1,make_function_body_1

		move.b	#LF,-1(a0)
make_function_body_next:
		movea.l	HIST_NEXT(a3),a3
		bra	make_function_body

make_function_body_done:
		sf	keep_loop(a5)
defun_success:
		moveq	#0,d0
defun_return:
		sf	funcdef_status(a5)
		tst.l	d0
		rts

defun_no_memory:
		lea	msg_cannot_defun,a0
		bsr	cannot_because_no_memory
		bra	defun_return
****************************************************************
.data

str_beginfunc:	dc.b	' () {',0

msg_too_long_funcname:	dc.b	'関数名が長過ぎます',0
msg_bad_funcname:	dc.b	'関数名が無効です',0
msg_cannot_defun:	dc.b	'関数を定義できません',0
msg_no_func:		dc.b	'この関数は定義されていません',0
msg_not_in_funcdef:	dc.b	'関数定義は開始していません',0

.end
