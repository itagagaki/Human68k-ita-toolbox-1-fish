* ifthen.s
* This contains if/else if/else/endif statement.
*
* Itagaki Fumihiko 13-Aug-90  Create.

.include ../src/fish.h

.xref strcmp
.xref strfor1
.xref skip_paren
.xref copy_wordlist
.xref expression
.xref subst_var_wordlist
.xref do_line
.xref too_deep_statement_nest
.xref expression_syntax_error
.xref syntax_error
.xref command_error
.xref word_if

.xref if_status
.xref if_level
.xref tmpargs

.text

****************************************************************
* test_statement_paren - ステートメントの ( ) をチェックする
*
* CALL
*      A0       単語並び
*      D0.W     単語数
*
* RETURN
*      A0       ( の次の単語を指す
*      A1       ) の次の単語を指す
*      D0.W     ( ) の中の単語数
*      D1.W     A1以降の単語数
*      CCR      エラーならば NZ
****************************************************************
.xdef test_statement_paren

test_statement_paren:
		cmp.w	#3,d0
		blo	test_statement_paren_error

		cmpi.b	#'(',(a0)
		bne	test_statement_paren_error

		tst.b	1(a0)
		bne	test_statement_paren_error

		move.w	d0,d1
		movea.l	a0,a1
		bsr	skip_paren
		beq	test_statement_paren_error

		bsr	strfor1
		exg	a0,a1				*  A1 : ) の次の単語
		subq.w	#1,d0
		exg	d0,d1				*  D1 : A1 以降の単語数

		sub.w	d1,d0
		subq.w	#2,d0				*  D0 : ()の中の単語数
		beq	test_statement_paren_error

		bsr	strfor1				*  A0 : ( の次の単語
		cmp.w	d0,d0
		rts

test_statement_paren_error:
		moveq	#1,d0
		rts
****************************************************************
*   1.  if (expression) statement
*
*   2.  if (expression) then
*           statement(s)
*       [ else if (expression) then
*           statement(s) ]
*               .
*               .
*               .
*       [ else
*           statement(s) ]
*       endif
****************************************************************
.xdef state_if

state_if:
		movea.l	a1,a3
		bsr	test_statement_paren		*  戻り値：A0/D0/A1/D1
		bne	syntax_error

		move.w	d1,d2				*  D2.W : ( ) に続く単語数
		beq	empty_if

		movea.l	a1,a2				*  A2 : ( ) に続く単語を指す
		movea.l	a0,a1				*  A1 : ( の次の単語を指す

		tst.b	if_status(a5)			*  現在
		bne	state_if_1			*  FALSE状態である

		lea	tmpargs,a0
		bsr	subst_var_wordlist
		bmi	syntax_error

		move.w	d0,d7
		bsr	expression
		bne	return				*  D0.L == 1

		tst.w	d7
		bne	expression_syntax_error
state_if_1:
		move.w	d2,d7				*  D7.W : ( ) に続く単語数
		movea.l	a2,a0				*  A0 : ( ) に続く単語を指す
		lea	word_then,a1
		bsr	strcmp
		beq	state_if_then
		*
		*  then は無い
		*
		tst.b	if_status(a5)			*  現在
		bne	state_if_recurse		*  FALSE状態である

		tst.l	d1				*  式の値が
		bne	state_if_recurse		*    真
		bra	success				*    偽

state_if_then:
		*
		*  then がある
		*
		subq.w	#1,d7				*  then の後に
		bne	syntax_error			*  まだ単語があるならエラー

		tst.b	if_status(a5)			*  現在
		bne	state_if_inc_level		*  FALSE状態である

		clr.w	if_level(a5)
		tst.l	d1
		seq	if_status(a5)			*  if_status := 式は0 ? -1 : 0
state_if_recurse:
		move.w	d7,d0
		movea.l	a3,a1
recurse:
		tst.w	d0
		beq	success

		exg	a0,a1
		bsr	copy_wordlist
		addq.l	#4,a7			**  戻りアドレスを捨てる **
		bra	do_line			**!! 再帰 !!**


state_if_inc_level:
		lea	word_if,a0
		cmpi.w	#MAXIFLEVEL,if_level(a5)
		beq	too_deep_statement_nest

		addq.w	#1,if_level(a5)
success:
		moveq	#0,d0
return:
		rts


empty_if:
		lea	msg_empty_if,a0
		bra	command_error
****************************************************************
.xdef state_else

state_else:
		tst.w	if_level(a5)
		bne	success

		tst.b	if_status(a5)
		bpl	set_if_status_1

		clr.b	if_status(a5)
		bra	recurse

set_if_status_1:
		move.b	#1,if_status(a5)
		bra	success
****************************************************************
.xdef state_endif

state_endif:
		tst.w	if_level(a5)
		beq	clear_if_status

		subq.w	#1,if_level(a5)
		bra	success

clear_if_status:
		clr.b	if_status(a5)
		bra	success
****************************************************************
.data

word_then:		dc.b	'then',0
msg_empty_if:		dc.b	'then またはコマンドがありません',0

.end
