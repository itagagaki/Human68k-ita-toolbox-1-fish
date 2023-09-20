* b_shift.s
* This contains built-in command 'shift'.
*
* Itagaki Fumihiko 30-Oct-90  Create.

.xref strfor1
.xref find_shellvar
.xref get_var_value
.xref set_shellvar
.xref undefined
.xref too_many_args
.xref command_error
.xref word_argv

.text

****************************************************************
*  Name
*       shift - シェル変数をシフトする
*
*  Synopsis
*       shift
*            argv をシフトする
*
*       shift var
*            var をシフトする
****************************************************************
.xdef cmd_shift

cmd_shift:
		cmp.w	#1,d0
		bhi	too_many_args
		beq	shift_var

		lea	word_argv,a0
shift_var:
		movea.l	a0,a2
		bsr	find_shellvar
		movea.l	a2,a0
		beq	undefined

		bsr	get_var_value
		beq	no_more_words

		jsr	strfor1
		movea.l	a0,a1
		subq.w	#1,d0
		movea.l	a2,a0
		st	d1				*  export する
		bra	set_shellvar

no_more_words:
		lea	msg_no_more_words,a0
		bra	command_error
****************************************************************
.data

msg_no_more_words:	dc.b	'単語はもうありません',0

.end
