* ifthen.s
* This contains if/else if/else/endif statement.
*
* Itagaki Fumihiko 13-Aug-90  Create.

.include ../src/fish.h

.xref strcmp
.xref strfor1
.xref skip_paren
.xref copy_wordlist
.xref expression2
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
		exg	a0,a1				*  A1 : ')' の次の単語
		subq.w	#1,d0
		exg	d0,d1				*  D1 : A1 以降の単語数

		sub.w	d1,d0
		subq.w	#2,d0				*  D0 : ()の中の単語数
		beq	test_statement_paren_error

		bsr	strfor1				*  A0 : '(' の次の単語
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
		tst.b	if_status(a5)
		bne	state_if_inc_level

		movea.l	a1,a3
		bsr	test_statement_paren
		bne	syntax_error

		move.w	d1,d2
		beq	empty_if

		movea.l	a1,a2
		movea.l	a0,a1
		lea	tmpargs,a0
		bsr	subst_var_wordlist
		bmi	syntax_error

		move.w	d0,d7
		bsr	expression2
		bne	return				*  D0.L == 1

		tst.w	d7
		bne	expression_syntax_error

		movea.l	a2,a0
		move.w	d2,d7
		lea	word_then,a1
		bsr	strcmp
		beq	state_if_then

		tst.l	d1
		beq	success
		bra	state_if_set_status

state_if_then:
		subq.w	#1,d7
		bne	syntax_error

		bsr	strfor1
state_if_set_status:
		tst.l	d1
		seq	if_status(a5)
		move.w	d7,d0
		clr.w	if_level(a5)
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