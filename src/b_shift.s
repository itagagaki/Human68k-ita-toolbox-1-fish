* b_shift.s
* This contains built-in command 'shift'.
*
* Itagaki Fumihiko 30-Oct-90  Create.

.xref strfor1
.xref find_shellvar
.xref set_svar
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
		movea.l	a0,a2				* A2 : 変数名
		bsr	find_shellvar
		exg	a0,a2				* A0 : 変数名   A2 : var ptr
		beq	undefined

		move.w	2(a2),d0			* D0.W : この変数の要素数
		beq	no_more_words

		exg	a0,a2
		addq.l	#4,a0
		bsr	strfor1
		bsr	strfor1
		subq.w	#1,d0
		movea.l	a0,a1
		movea.l	a2,a0
		moveq	#1,d1				* export する
		bra	set_svar

no_more_words:
		lea	msg_no_more_words,a0
		bra	command_error
****************************************************************
.data

msg_no_more_words:	dc.b	'単語はもうありません',0

.end
