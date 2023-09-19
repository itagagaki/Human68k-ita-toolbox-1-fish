* setsvar.s
* Itagaki Fumihiko 24-Oct-90  Create.

.xref itoa
.xref scanchar2
.xref strcmp
.xref strcpy
.xref stpcpy
.xref strfor1
.xref sltobsl
.xref rehash
.xref setvar
.xref get_var_value
.xref fish_setenv
.xref set_flagvar
.xref is_builtin_dir
.xref insufficient_memory
.xref word_path
.xref word_temp
.xref word_user
.xref word_upper_user
.xref word_term
.xref word_upper_term
.xref word_home
.xref word_upper_home
.xref word_columns
.xref word_upper_columns
.xref word_shlvl
.xref word_upper_shlvl

.xref shellvar_top
.xref histchar1
.xref histchar2
.xref wordchars
.xref tmpargs

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

set_shellvar:
		movem.l	d1-d3/a0-a3,-(a7)
		move.b	d1,d2				*  D2.B : export flag
		movea.l	a1,a2				*  A2 : セットする値（単語リスト）
		movea.l	a0,a1				*  A1 : シェル変数名
		move.w	d0,d1				*  D1.W : 単語数
		lea	shellvar_top(a5),a0
		bsr	setvar
		beq	no_space_in_shellvar

		bsr	get_var_value
		movea.l	a0,a2				*  A2 : セットした変数の最初の値のアドレス
		movea.l	a1,a0				*  A0 : 変数名
		movea.l	a2,a1
		st	d0
		bsr	set_flagvar
		bne	set_svar_return0

		lea	word_histchars,a1
		bsr	strcmp
		bne	not_histchars

		clr.w	histchar1(a5)
		clr.w	histchar2(a5)
		tst.w	d1
		beq	set_histchars_done

		movea.l	a2,a0
		bsr	scanchar2
		beq	set_histchars_done

			move.w	d0,histchar1(a5)

		bsr	scanchar2
		beq	set_histchars_done

			move.w	d0,histchar2(a5)
set_histchars_done:
		bra	set_svar_return0
****************
not_histchars:
		lea	word_wordchars,a1
		bsr	strcmp
		bne	not_wordchars

		tst.w	d1
		bne	set_wordchars

		lea	str_nul,a2
set_wordchars:
		move.l	a2,wordchars(a5)
		bra	set_svar_return0
****************
not_wordchars:
		tst.b	d2				*  エクスポートが禁止されているならば
		beq	set_svar_return0		*  完了

		lea	word_path,a1
		bsr	strcmp
		bne	not_path

		bsr	rehash

		movea.l	a2,a0				*  A0 : シェル変数 path の値
		movea.l	tmpargs(a5),a2			*  A2 : バッファ
		clr.b	(a2)
		st	d2				*  D2.B : first flag
		bra	export_build_path_continue

export_build_path_loop:
		bsr	is_builtin_dir
		bne	ignore

		tst.b	d2
		bne	dup_a_word

		move.b	#';',(a2)+
dup_a_word:
		movea.l	a0,a1
		exg	a0,a2
		bsr	stpcpy
		exg	a0,a2
		sf	d2
ignore:
		bsr	strfor1
export_build_path_continue:
		dbra	d1,export_build_path_loop

		movea.l	tmpargs(a5),a0
		bsr	sltobsl
		lea	word_path,a1
		bra	set_svar_setenv
****************
not_path:
		lea	export_table-6,a3
compare_export_loop:
		addq.l	#6,a3
		move.l	(a3)+,d0
		beq	set_svar_return0

		movea.l	d0,a1
		bsr	strcmp
		bne	compare_export_loop

		movea.l	tmpargs(a5),a0			*  A0 : バッファ
		clr.b	(a0)
		tst.w	d1
		beq	do_export

		movea.l	a2,a1				*  A1 : シェル変数の値
		bsr	strcpy
		tst.w	4(a3)
		beq	do_export

		bsr	sltobsl
do_export:
		movea.l	(a3),a1				*  A1 : 環境変数名
set_svar_setenv:
		exg	a0,a1
		bsr	fish_setenv
		beq	set_svar_return1
set_svar_return0:
		moveq	#0,d0
set_svar_return:
		movem.l	(a7)+,d1-d3/a0-a3
		rts
****************
no_space_in_shellvar:
		bsr	insufficient_memory
set_svar_return1:
		moveq	#1,d0
		bra	set_svar_return
****************************************************************
* set_shellvar_nul - シェル変数に空文字列をセットする．exportはしない
*
* CALL
*      A0     変数名の先頭アドレス
*
* RETURN
*      D0.L   0:成功  1:失敗
*      CCR    TST.L D0
****************************************************************
.xdef set_shellvar_nul

set_shellvar_nul:
		movem.l	d1/a1,-(a7)
		lea	str_nul,a1
		moveq	#1,d0
		sf	d1
		bsr	set_shellvar
		movem.l	(a7)+,d1/a1
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
*      none
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
.xdef word_wordchars
.xdef str_nul

.even
export_table:
		dc.l	word_temp
		dc.l	word_temp
		dc.w	1

		dc.l	word_home
		dc.l	word_upper_home
		dc.w	0

		dc.l	word_user
		dc.l	word_upper_user
		dc.w	0

		dc.l	word_term
		dc.l	word_upper_term
		dc.w	0

		dc.l	word_columns
		dc.l	word_upper_columns
		dc.w	0

		dc.l	word_shlvl
		dc.l	word_upper_shlvl
		dc.w	0

		dc.l	0

word_histchars:		dc.b	'histchars',0
word_wordchars:		dc.b	'wordchars'
str_nul:		dc.b	0

.end
