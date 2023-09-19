* b_set.s
* This contains built-in command 'set'.
*
* Itagaki Fumihiko 15-Jul-90  Create.

.include ../src/fish.h
.include ../src/var.h

.xref isdigit
.xref isupper
.xref islower
.xref isalpha
.xref isalnum
.xref strfor1
.xref strforn
.xref divsl
.xref mulsl
.xref atou
.xref find_close_paren
.xref expand_wordlist
.xref expression
.xref expr_atoi
.xref expr_itoa
.xref find_shellvar
.xref set_shellvar
.xref printvar
.xref skip_varname
.xref undefined
.xref ambiguous
.xref syntax_error
.xref expression_syntax_error
.xref bad_subscript
.xref subscript_out_of_range
.xref divide_by_0
.xref mod_by_0
.xref strmove
.xref str_nul

.xref shellvar_top
.xref tmpline
.xref tmpword1
.xref tmpargs

OP_ASSIGN	equ	1
OP_MULASSIGN	equ	2
OP_DIVASSIGN	equ	3
OP_MODASSIGN	equ	4
OP_ADDASSIGN	equ	5
OP_SUBASSIGN	equ	6
OP_SHLASSIGN	equ	7
OP_SHRASSIGN	equ	8
OP_BITANDASSIGN	equ	9
OP_BITXORASSIGN	equ	10
OP_BITORASSIGN	equ	11
OP_INCREMENT	equ	12
OP_DECREMENT	equ	13

.text

****************************************************************
*  Name
*       set - シェル変数の表示と設定
*
*  Synopsis
*       set
*            定義されているすべてのシェル変数とそれらの値を表示する
*
*       name
*       name=
*       name=word
*       name= ( wordlist )
*       name = word
*       name = ( wordlist )
*
*       name[index]
*       name[index]=
*       name[index]=word
*       name[index] = word
****************************************************************
.xdef cmd_set

cmd_set:
		lea	shellvar_top(a5),a3
		move.w	d0,d7				*  引数が無いなら
		beq	printvar			*  シェル変数のリストを表示
set_loop:
		tst.w	d7
		beq	return_0

		bsr	scan_name_and_index
		bne	return

		sf	d3				*   D3 : ()フラグ
		cmpi.b	#'=',(a0)
		bne	cmd_set_not_includes_equal

		clr.b	(a0)+
		tst.b	(a0)
		bne	set_single_word

		addq.l	#1,a0
		subq.w	#1,d7
		beq	set_nul_word

		cmpi.b	#'(',(a0)
		bne	set_nul_word
		bra	set_wordlist

cmd_set_not_includes_equal:
		tst.b	(a0)+
		bne	syntax_error

		subq.w	#1,d7
		beq	set_nul_word

		cmpi.b	#'=',(a0)
		bne	set_nul_word

		tst.b	1(a0)
		bne	set_nul_word

		bsr	strfor1
		subq.w	#1,d7
		beq	set_nul_word

		cmpi.b	#'(',(a0)
		bne	set_single_word
set_wordlist:
		tst.l	d2
		bpl	syntax_error

		bsr	strfor1
		subq.w	#1,d7
		movea.l	a0,a1
		move.w	d7,d0
		bsr	find_close_paren
		bmi	syntax_error

		sub.w	d0,d7
		st	d3
		bra	set_arg_word

set_nul_word:
		lea	str_nul,a1
		moveq	#1,d0
		bra	set_value

set_single_word:
		movea.l	a0,a1
		moveq	#1,d0
set_arg_word:
		bsr	strfor1
		subq.w	#1,d7
set_value:
		movea.l	a0,a4				*  A4 : 次の引数を指すポインタ
		move.l	a1,d6				*  D6.L : 展開前の値を指すポインタ
		movea.l	tmpargs(a5),a0
		bsr	expand_wordlist
		bmi	return

		movea.l	a0,a1				*  A1 : value wordlist
		tst.l	d2				*  [index]形式か？
		bpl	do_set_a_element

		tst.b	d3
		bne	do_set_one

		tst.w	d0
		bne	do_set_one

		clr.b	(a1)
		moveq	#1,d0
do_set_one:
		bsr	do_set
		bra	cmd_set_next

do_set_a_element:
		cmp.w	#1,d0				*  [index]形式なのに単語数が
		bhi	set_ambiguous			*  １個を超えるならエラー
		beq	do_set_a_element_1		*  １個ならばＯＫ

		clr.b	(a1)				*  0個ならば "\0" とする
do_set_a_element_1:
		bsr	set_a_element
cmd_set_next:
		bne	return

		movea.l	a4,a0
		bra	set_loop

set_ambiguous:
		movea.l	d6,a0
		bra	ambiguous
****************************************************************
*  Name
*       @ - シェル変数の表示と設定
*
*  Synopsis
*       @
*            定義されているすべてのシェル変数とそれらの値を表示する
*
*       @ lvalue op expression
*
*            lvalue:
*                 name
*                 name[index]
*
*            op:
*                 =
*                 +=
*                 -=
*                 *=
*                 /=
*                 %=
*                 <<=
*                 >>=
*                 &=
*                 ^=
*                 |=
*
*            op の左右には空白があってもなくても良い
****************************************************************
.xdef cmd_set_expression

cmd_set_expression:
		lea	shellvar_top(a5),a3
		move.w	d0,d7				*  引数が無いなら
		beq	printvar			*  シェル変数のリストを表示
set_expression_loop:
		moveq	#0,d0
		tst.w	d7
		beq	cmd_set_expression_return

		bsr	scan_name_and_index
		bne	cmd_set_expression_return
		*
		*  A0   : 引数ポインタ
		*  D7.W : 引数カウンタ
		*  A2   : 左辺変数名
		*  D2.L : 左辺変数の添字の値（[index]形式で無ければ-1）
		*
		bsr	scan_assign_operator
		move.b	d0,d4
		bne	set_expression_op_ok

		tst.b	(a0)+
		bne	syntax_error

		subq.w	#1,d7
		beq	syntax_error

		bsr	scan_assign_operator
		move.b	d0,d4
		beq	syntax_error
set_expression_op_ok:
		clr.b	(a0)
		movea.l	a3,a0
		*
		*  A0   : 引数ポインタ
		*  D7.W : 引数カウンタ
		*  A2   : 左辺変数名
		*  D2.L : 左辺変数の添字の値（[index]形式で無ければ-1）
		*  D4.B : 演算子コード
		*
		cmp.b	#OP_INCREMENT,d4
		blo	set_expression_expression

		tst.b	(a0)+
		bne	syntax_error

		subq.w	#1,d7
		moveq	#1,d1
		bra	set_expression_postcalc

**  var op= expr
set_expression_expression:
		tst.b	(a0)
		bne	set_expression_do_expression

		addq.l	#1,a0
		subq.w	#1,d7
set_expression_do_expression:
		bsr	expression
		bne	cmd_set_expression_return
********************************
set_expression_postcalc:
		movea.l	a0,a4				*  A4 : 次の引数
		move.l	d1,d5				*  D5.L : 右辺値
		*
		*  A4   : 引数ポインタ
		*  D7.W : 引数カウンタ
		*  A2   : 左辺変数名
		*  D2.L : 左辺変数の添字の値（[index]形式で無ければ-1）
		*  D4.B : 演算子コード
		*  D5.L : 右辺値
		*
		subq.b	#OP_ASSIGN,d4
		beq	set_expression_lvalue_ok

		moveq	#0,d1
		movea.l	a2,a0				*  A0 = A2 (name)
		bsr	find_shellvar			*  A0 = var ptr
		beq	set_expression_lvalue_ok

		movea.l	d0,a0
		move.l	d2,d0
		beq	set_expression_lvalue_ok
		bpl	set_expression_check_nwords

		moveq	#1,d0
set_expression_check_nwords:
		moveq	#0,d3
		move.w	var_nwords(a0),d3		*  D3.L : この変数の要素数
		cmp.l	d3,d0
		bgt	set_expression_lvalue_ok

		lea	var_body(a0),a0
		bsr	strforn
		tst.b	(a0)
		beq	set_expression_lvalue_ok

		movea.l	a0,a1
		bsr	expr_atoi
		beq	set_expression_lvalue_ok

		cmp.b	#OP_INCREMENT-OP_ASSIGN,d4
		bne	expression_syntax_error

		move.b	(a1),d0
		bsr	isalpha
		bne	expression_syntax_error

		lea	tmpword1+1,a0
test_magical_increment:
		move.b	(a1)+,d0
		beq	do_magical_increment

		bsr	isalnum
		bne	expression_syntax_error

		move.b	d0,(a0)+
		bra	test_magical_increment

do_magical_increment:
		clr.b	(a0)
		lea	tmpword1+1,a1
		move.l	a0,d1
		sub.l	a1,d1
magical_increment_loop:
		move.b	-(a0),d0
		moveq	#'a',d3
		moveq	#'z',d4
		bsr	islower
		beq	magical_increment_1

		moveq	#'A',d3
		moveq	#'Z',d4
		bsr	isupper
		beq	magical_increment_1

		moveq	#'0',d3
		moveq	#'9',d4
		bsr	isdigit
		bne	expression_syntax_error
magical_increment_1:
		addq.b	#1,d0
		move.b	d0,(a0)
		cmp.b	d4,d0
		bls	magical_increment_ok

		move.b	d3,(a0)
		cmpa.l	a1,a0
		bne	magical_increment_loop

		cmp.w	#MAXWORDLEN,d1
		bhs	expression_syntax_error

		move.b	d3,-(a1)
magical_increment_ok:
		bra	set_expression_do_set

set_expression_lvalue_ok:
		move.l	d5,d0
		*
		*  A4   : 引数ポインタ
		*  D7.W : 引数カウンタ
		*  A2   : 左辺変数名
		*  D2.L : 左辺変数の添字の値（[index]形式で無ければ-1）
		*  D0.L : 右辺値
		*  D4.B : 演算子コード
		*  D1.L : 左辺値
		*
		lea	postcalc_jump_table,a0
		moveq	#0,d3
		move.b	d4,d3
		lsl.l	#2,d3
		move.l	(a0,d3.l),a0
		jmp	(a0)

postcalc_or:
		or.l	d0,d1
		bra	postcalc_itoa

postcalc_xor:
		eor.l	d0,d1
		bra	postcalc_itoa

postcalc_and:
		and.l	d0,d1
		bra	postcalc_itoa

postcalc_shr:
		asr.l	d0,d1
		bra	postcalc_itoa

postcalc_shl:
		asl.l	d0,d1
		bra	postcalc_itoa

postcalc_sub:
		sub.l	d0,d1
		bra	postcalc_itoa

postcalc_add:
		add.l	d0,d1
		bra	postcalc_itoa

postcalc_mod:
		exg	d0,d1
		tst.l	d1
		beq	mod_by_0

		bsr	divsl
		bra	postcalc_itoa

postcalc_div:
		exg	d0,d1
		tst.l	d1
		beq	divide_by_0

		bsr	divsl
		bra	postcalc_itoa_0

postcalc_mul:
		bsr	mulsl
postcalc_itoa_0:
		move.l	d0,d1
postcalc_itoa:
		lea	tmpword1,a1
		bsr	expr_itoa
		*
		*  A4   : 引数ポインタ
		*  D7.W : 引数カウンタ
		*  A2   : 左辺変数名
		*  D2.L : 左辺変数の添字の値（[index]形式で無ければ-1）
		*  A1   : 値を表す文字列が格納されているバッファのアドレス
		*
set_expression_do_set:
		bsr	do_set_expression
		movea.l	a4,a0
		beq	set_expression_loop
cmd_set_expression_return:
		rts
****************************************************************
* CALL
*      A0     単語
*
* RETURN
*      A0     単語の続き
*      A2     名前
*      D0.L   エラーが無ければ0
*      D1.L   破壊
*      D2.L   添字の値（[index]形式で無ければ-1）
*      CCR    TST.L D0
****************************************************************
scan_name_and_index:
		movea.l	a0,a2				*  A2 : name
		moveq	#-1,d2				*  D2.L : index
		bsr	skip_varname
		cmpa.l	a2,a0
		beq	syntax_error

		cmpi.b	#'[',(a0)
		bne	name_and_index_are_ok

		clr.b	(a0)+
		bsr	atou
		bmi	bad_subscript

		cmpi.b	#']',(a0)+
		bne	bad_subscript

		move.l	d1,d2
		bmi	subscript_out_of_range
name_and_index_are_ok:
return_0:
		moveq	#0,d0
return:
		rts
****************************************************************
* CALL
*      A0     文字列
*
* RETURN
*      D0.B   演算子コード
*      A3     演算子の次を指す
****************************************************************
scan_assign_operator:
		tst.b	(a0)
		beq	no_operator

		lea	1(a0),a3
		moveq	#OP_ASSIGN,d0
		cmpi.b	#'=',(a0)
		beq	scan_assign_operator_return

		tst.b	1(a0)
		beq	no_operator

		cmpi.b	#'=',1(a0)
		bne	scan_assign_operator_2

		lea	2(a0),a3
		moveq	#OP_MULASSIGN,d0
		cmpi.b	#'*',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_DIVASSIGN,d0
		cmpi.b	#'/',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_MODASSIGN,d0
		cmpi.b	#'%',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_ADDASSIGN,d0
		cmpi.b	#'+',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_SUBASSIGN,d0
		cmpi.b	#'-',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_BITANDASSIGN,d0
		cmpi.b	#'&',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_BITXORASSIGN,d0
		cmpi.b	#'^',(a0)
		beq	scan_assign_operator_return

		moveq	#OP_BITORASSIGN,d0
		cmpi.b	#'|',(a0)
		beq	scan_assign_operator_return

		bra	no_operator

scan_assign_operator_2:
		cmpi.b	#'=',2(a0)
		bne	try_scan_incdec

		lea	3(a0),a3
		cmpi.b	#'<',(a0)
		bne	try_scan_shla

		cmpi.b	#'<',1(a0)
		bne	no_operator

		moveq	#OP_SHLASSIGN,d0
		bra	scan_assign_operator_return

try_scan_shla:
		cmpi.b	#'>',(a0)
		bne	try_scan_incdec

		cmpi.b	#'>',1(a0)
		bne	no_operator

		moveq	#OP_SHRASSIGN,d0
		bra	scan_assign_operator_return

try_scan_incdec:
		lea	2(a0),a3
		cmpi.b	#'+',(a0)
		bne	try_scan_dec

		cmpi.b	#'+',1(a0)
		bne	no_operator

		moveq	#OP_INCREMENT,d0
		rts

try_scan_dec:
		cmpi.b	#'-',(a0)
		bne	no_operator

		cmpi.b	#'-',1(a0)
		bne	no_operator

		moveq	#OP_DECREMENT,d0
		rts

no_operator:
		lea	(a0),a3
		moveq	#0,d0
scan_assign_operator_return:
		rts
****************************************************************
do_set_expression:
		moveq	#1,d0
		tst.l	d2				*  [index]形式でなければ
		bmi	do_set				*  name に A1 を設定する
****************************************************************
* CALL
*      A1     セットする値（文字列）
*      A2     名前
*      D2.L   添字の値（正数）
*
* RETURN
*      D1-D3/A0-A1/A3     破壊
*      D0.L   エラーが無ければ0
*      CCR    TST.L D0
****************************************************************
set_a_element:
		movea.l	a2,a0				*  A0 : name
		bsr	find_shellvar
		movea.l	a2,a0
		beq	undefined

		tst.l	d2
		beq	subscript_out_of_range

		movea.l	d0,a0				*  A0 : 変数のヘッダのアドレス
		moveq	#0,d3
		move.w	var_nwords(a0),d3		*  D3.L : この変数の要素数
		cmp.l	d3,d2
		bhi	subscript_out_of_range

		lea	var_body(a0),a0
		bsr	strfor1
		movea.l	a0,a3				*  A3 : 変数の値の単語並びの先頭アドレス
		lea	tmpline(a5),a0
		moveq	#0,d1				*  D1.W : 要素番号カウンタ
		bra	set_a_element_dup_continue

set_a_element_dup_loop:
		cmp.w	d2,d1
		bne	set_a_element_dup_other

		bsr	strmove
		exg	a0,a3
		bsr	strfor1
		exg	a0,a3
		bra	set_a_element_dup_continue

set_a_element_dup_other:
		exg	a1,a3
		bsr	strmove
		exg	a1,a3
set_a_element_dup_continue:
		addq.w	#1,d1
		dbra	d3,set_a_element_dup_loop

		subq.w	#1,d1
		move.w	d1,d0
		lea	tmpline(a5),a1
****************************************************************
* CALL
*      A1     セットする値（単語並び）
*      A2     名前
*      D0.L   単語数
*
* RETURN
*      D1/A0     破壊
*      D0.L   0:成功  1:失敗
*      CCR    TST.L D0
****************************************************************
do_set:
		movea.l	a2,a0
		st	d1				*  export する
		bra	set_shellvar
****************************************************************
.data

.even
postcalc_jump_table:
		dc.l	postcalc_itoa_0
		dc.l	postcalc_mul
		dc.l	postcalc_div
		dc.l	postcalc_mod
		dc.l	postcalc_add
		dc.l	postcalc_sub
		dc.l	postcalc_shl
		dc.l	postcalc_shr
		dc.l	postcalc_and
		dc.l	postcalc_xor
		dc.l	postcalc_or
		dc.l	postcalc_add
		dc.l	postcalc_sub

.end
