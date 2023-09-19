* setsvar.s
* Itagaki Fumihiko 24-Oct-90  Create.

.xref issjis
.xref itoa
.xref strcmp
.xref strcpy
.xref strfor1
.xref sltobsl
.xref rehash
.xref set_var
.xref fish_setenv
.xref flagvarptr
.xref is_builtin_dir
.xref no_space_for
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

.xref shellvar
.xref histchar1
.xref histchar2

.text

****************************************************************
* set_svar - シェル変数を定義する
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
.xdef set_svar
.xdef set_svar_nul

set_svar_nul:
		lea	str_nul,a1
		moveq	#1,d0
set_svar:
		movem.l	d1-d3/a0-a4,-(a7)
		movea.l	a1,a2				*  A2 : value
		movea.l	a0,a1				*  A1 : name
		move.w	d0,d2				*  D2.W : number of words
		movea.l	shellvar(a5),a0
		bsr	set_var
		bne	no_space_in_shellvar
****************
		exg	a0,a1
		bsr	flagvarptr
		exg	a0,a1
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

		lea	export_table-6,a3
compare_export_loop:
		addq.l	#6,a3
		move.l	(a3)+,d0
		beq	set_svar_return

		movea.l	d0,a0
		bsr	strcmp
		bne	compare_export_loop

		movea.l	(a3)+,a4			*  A4 : 環境変数名
		move.w	(a3),d3				*  D3.B : フラグ
		lea	tmpargs,a3			*  A3 : temporaly
		btst	#1,d3
		beq	export_normal
		*
		*  シェル変数 path が再設定された．
		*  ハッシュ表を更新し，環境変数 path に形を変えてexportする．
		*
		bsr	rehash
		movea.l	a2,a1				*  A1 : value
		bra	export_continue_build
****************
export_normal:
		movea.l	a2,a1				*  A1 : value
		tst.w	d2
		beq	do_export

		moveq	#0,d2
		bra	dup_a_word

build_loop:
		lea	str_current_dir,a0
		bsr	strcmp
		beq	build_ignore_this

		exg	a0,a1
		bsr	is_builtin_dir
		exg	a0,a1
		beq	build_ignore_this

		tst.b	d1
		bne	dup_a_word

		move.b	#';',(a3)+
dup_a_word:
		exg	a0,a3
		bsr	strcpy
		btst	#0,d3
		beq	dup_a_word_done

		bsr	sltobsl
dup_a_word_done:
		adda.l	d0,a0
		exg	a0,a3
		moveq	#0,d1
build_ignore_this:
		exg	a0,a1
		bsr	strfor1
		exg	a0,a1
export_continue_build:
		dbra	d2,build_loop
do_export:
		clr.b	(a3)
		lea	tmpargs,a1
		movea.l	a4,a0
		bsr	fish_setenv
set_svar_return:
		movem.l	(a7)+,d1-d3/a0-a4
		rts
****************
set_svar_return0:
		moveq	#0,d0
		bra	set_svar_return
****************
no_space_in_shellvar:
		lea	msg_shellvar_space,a0
		bsr	no_space_for
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
* set_svar_num - シェル変数に数値を定義する
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
.xdef set_svar_num

set_svar_num:
		link	a6,#-12
		movem.l	d0/a1,-(a7)

		movem.l	d1/a0,-(a7)
		lea	-12(a6),a0
		moveq	#0,d1				*  整数に符号やスペースはつけない
		bsr	itoa
		movea.l	a0,a1
		movem.l	(a7)+,d1/a0

		moveq	#1,d0
		bsr	set_svar

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
msg_shellvar_space:	dc.b	'シェル変数ブロック',0

.end
