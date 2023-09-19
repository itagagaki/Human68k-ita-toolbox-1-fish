* setsvar.s
* Itagaki Fumihiko 24-Oct-90  Create.

.xref issjis
.xref itoa
.xref strcmp
.xref strpcmp
.xref strcpy
.xref strfor1
.xref sltobsl
.xref rehash
.xref setvar
.xref find_shellvar
.xref get_var_value
.xref fish_setenv
.xref flagvarptr
.xref is_builtin_dir
.xref insufficient_memory
.xref str_nul
.xref str_current_dir
.xref word_path
.xref word_temp
.xref word_user
.xref word_upper_user
.xref word_term
.xref word_upper_term
.xref word_home
.xref word_upper_home
.xref word_shlvl
.xref word_upper_shlvl

.xref tmpargs

.xref shellvar_top
.xref histchar1
.xref histchar2

.text

****************************************************************
* set_shellvar - シェル変数を定義する
*
* CALL
*      A0     変数名の先頭アドレス
*      A1     値の語並びの先頭アドレス
*      D0.W   値の語数
*      D1.B   0 : exportしない
*
* RETURN
*      D0.L   0:成功  1:失敗
*      CCR    TST.L D0
****************************************************************
.xdef set_shellvar
.xdef set_shellvar_nul

set_shellvar_nul:
		lea	str_nul,a1
		moveq	#1,d0
set_shellvar:
		movem.l	d1-d4/a0-a4,-(a7)
		movea.l	a1,a2				*  A2 : value
		movea.l	a0,a1				*  A1 : name
		move.w	d0,d2				*  D2.W : number of words
		lea	shellvar_top(a5),a0
		bsr	setvar
		beq	no_space_in_shellvar

		movea.l	d0,a3				*  A3 : セットした変数の先頭アドレス
****************
		movea.l	a1,a0
		bsr	flagvarptr
		beq	not_flagvar

		movea.l	d0,a0
		st	(a0)
		bra	set_svar_return0
****************
not_flagvar:
		lea	word_histchars,a0
		bsr	strcmp
		bne	not_histchars

		clr.w	histchar1(a5)
		clr.w	histchar2(a5)
		tst.w	d2
		beq	set_svar_return0

		bsr	get_histchar
		beq	set_svar_return0

		move.w	d0,histchar1(a5)

		bsr	get_histchar
		beq	set_svar_return0

		move.w	d0,histchar2(a5)
		bra	set_svar_return0
****************
not_histchars:
		tst.b	d1				*  エクスポートが禁止されているならば
		beq	set_svar_return0		*  完了

		lea	export_table-6,a2
compare_export_loop:
		addq.l	#6,a2
		move.l	(a2)+,d0
		beq	set_svar_return0

		movea.l	d0,a0
		bsr	strcmp
		bne	compare_export_loop

		move.l	a3,d0
		bsr	get_var_value			*  A0   : シェル変数の値
		movea.l	(a2)+,a3			*  A3   : 環境変数名
		move.w	(a2),d3				*  D3.B : フラグ
		lea	tmpargs,a2			*  A2   : バッファ
		btst	#1,d3
		bne	export_path

		tst.w	d2
		beq	do_export

		moveq	#0,d2
		bra	dup_a_word
****************
export_path:
		bsr	rehash

		move.l	a0,-(a7)
		lea	word_notexportpath,a0
		bsr	find_shellvar
		movea.l	(a7)+,a0
		movea.l	d0,a4
		bra	export_build_path_continue
****************
export_build_path_loop:
		lea	str_current_dir,a1
		bsr	strcmp
		beq	export_build_path_ignore_this

		bsr	is_builtin_dir
		beq	export_build_path_ignore_this

		move.l	a4,d0
		beq	not_notexportpath

		exg	a0,a1
		bsr	get_var_value
		exg	a0,a1				*  A1 : $notexportpath
		move.w	d0,d4				*  D4 : $#notexportpath
		bra	check_notexportpath_continue

check_notexportpath_loop:
		moveq	#0,d0
		bsr	strpcmp
		beq	export_build_path_ignore_this

		exg	a0,a1
		bsr	strfor1
		exg	a0,a1
check_notexportpath_continue:
		dbra	d4,check_notexportpath_loop
not_notexportpath:
		tst.b	d1
		bne	dup_a_word

		move.b	#';',(a2)+
dup_a_word:
		movea.l	a0,a1
		exg	a0,a2
		bsr	strcpy
		btst	#0,d3
		beq	dup_a_word_done

		bsr	sltobsl
dup_a_word_done:
		adda.l	d0,a0
		exg	a0,a2
		moveq	#0,d1
export_build_path_ignore_this:
		bsr	strfor1
export_build_path_continue:
		dbra	d2,export_build_path_loop
do_export:
		clr.b	(a2)
		lea	tmpargs,a1
		movea.l	a3,a0
		bsr	fish_setenv
		beq	set_svar_return1
set_svar_return0:
		moveq	#0,d0
set_svar_return:
		movem.l	(a7)+,d1-d4/a0-a4
		rts
****************
no_space_in_shellvar:
		bsr	insufficient_memory
set_svar_return1:
		moveq	#1,d0
		bra	set_svar_return
****************************************************************
get_histchar:
		move.b	(a2)+,d0
		beq	get_histchar_return

		bsr	issjis
		bne	get_histchar_return

		lsl.w	#8,d0
		move.b	(a2)+,d0
		bne	get_histchar_return

		clr.w	d0
get_histchar_return:
		rts
****************************************************************
* set_shellvar_num - シェル変数に数値を定義する
*
* CALL
*      A0     変数名の先頭アドレス
*      D0.L   数値
*      D1.B   0 : exportしない
*
* RETURN
*      D0.L   0:成功  1:失敗
*      CCR    TST.L D0
****************************************************************
.xdef set_shellvar_num

set_shellvar_num:
		link	a6,#-12
		movem.l	d0/a1,-(a7)

		movem.l	d1/a0,-(a7)
		lea	-12(a6),a0
		moveq	#0,d1				*  整数に符号やスペースはつけない
		bsr	itoa
		movea.l	a0,a1
		movem.l	(a7)+,d1/a0

		moveq	#1,d0
		bsr	set_shellvar

		movem.l	(a7)+,d0/a1
		unlk	a6
		rts
****************************************************************
.data

.xdef word_histchars

.even
export_table:
		dc.l	word_path
		dc.l	word_path
		dc.w	1+2

		dc.l	word_temp
		dc.l	word_temp
		dc.w	1

		dc.l	word_home
		dc.l	word_upper_home
		dc.w	1

		dc.l	word_user
		dc.l	word_upper_user
		dc.w	0

		dc.l	word_term
		dc.l	word_upper_term
		dc.w	0

		dc.l	word_shlvl
		dc.l	word_upper_shlvl
		dc.w	0

		dc.l	0

word_histchars:		dc.b	'histchars',0
word_notexportpath:	dc.b	'notexportpath',0

.end
