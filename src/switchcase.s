* switchcase.s
* This contains switch/case/default/breaksw/endsw statement.
*
* Itagaki Fumihiko 7-Apr-91  Create.

.include ../src/fish.h

.xref strlen
.xref strcpy
.xref strpcmp
.xref test_statement_paren
.xref expand_wordlist
.xref subst_var_wordlist
.xref escape_quoted
.xref command_error
.xref syntax_error
.xref too_deep_statement_nest
.xref too_many_args
.xref word_switch
.xref tmpword1

.xref switch_status	* -1:caseè∆çáíÜ, 0:í èÌèÛë‘, 1:endswåüçıíÜ
.xref switch_level
.xref switch_string
.xref exitflag

.text

****************************************************************
*   switch (string)
*         case pattern1:
*            statement(s)
*            breaksw
*         case pattern2:
*            statement(s)
*            breaksw
*               .
*               .
*               .
*         default:
*            statement(s)
*            breaksw
*       endsw
****************************************************************
.xdef state_switch

state_switch:
		tst.b	switch_status(a5)
		bne	state_switch_inc_level

		exg	a0,a1
		bsr	subst_var_wordlist
		bmi	return

		movea.l	a0,a2
		bsr	test_statement_paren
		bne	syntax_error

		tst.w	d1
		bne	syntax_error

		movea.l	a0,a1
		movea.l	a2,a0
		bsr	expand_wordlist
		bmi	return				*  D0.L != 0

		cmp.w	#1,d0
		blo	state_switch_missing
		bhi	syntax_error

		movea.l	a0,a1
		lea	switch_string(a5),a0
		bsr	strcpy
state_switch_ok:
		clr.w	switch_level(a5)
		move.b	#-1,switch_status(a5)
success:
		moveq	#0,d0
return:
		rts


state_switch_inc_level:
		lea	word_switch,a0
		cmpi.w	#MAXSWITCHLEVEL,switch_level(a5)
		beq	too_deep_statement_nest

		addq.w	#1,switch_level(a5)
		bra	success


state_switch_missing:
		lea	msg_missing_string,a0
		bra	command_error
****************************************************************
.xdef state_case

state_case:
		tst.w	switch_level(a5)
		bne	success

		exg	a0,a1
		bsr	subst_var_wordlist
		bmi	return				*  D0.L != 0

		move.w	d0,d1
		tst.b	switch_status(a5)
		bpl	success

		bra	state_switch_start

state_switch_loop:
		bsr	strlen
		lea	1(a0,d0.l),a2
		tst.l	d0
		beq	state_switch_continue

		cmpi.b	#':',-2(a2)
		bne	state_case_no_colon

		clr.b	-2(a2)
state_case_no_colon:
		lea	tmpword1,a1
		bsr	escape_quoted
		lea	switch_string(a5),a0
		moveq	#0,d0
		bsr	strpcmp
		beq	clear_switch_status
state_switch_continue:
		movea.l	a2,a0
state_switch_start:
		dbra	d1,state_switch_loop
		bra	success

clear_switch_status:
		clr.b	switch_status(a5)
		bra	success
****************************************************************
.xdef state_default

state_default:
		tst.w	switch_level(a5)
		bne	success

		tst.b	switch_status(a5)
		bpl	success

		bra	clear_switch_status
****************************************************************
.xdef state_endsw

state_endsw:
		tst.w	switch_level(a5)
		beq	clear_switch_status

		subq.w	#1,switch_level(a5)
		bra	success
****************************************************************
.xdef cmd_breaksw

cmd_breaksw:
		tst.w	d0
		bne	too_many_args

		sf	exitflag(a5)

		tst.w	switch_level(a5)
		bne	success

		move.b	#1,switch_status(a5)
		bra	success
****************************************************************
.data

msg_missing_string:	dc.b	'ï∂éöóÒÇ™Ç†ÇËÇ‹ÇπÇÒ',0

.end
