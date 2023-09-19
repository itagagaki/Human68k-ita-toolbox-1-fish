* getcwdx.s
* Itagaki Fumihiko 25-Apr-91  Create.

.xref issjis
.xref tolower
.xref toupper
.xref strcpy
.xref strfor1
.xref isfullpath
.xref getcwd
.xref find_shellvar
.xref get_var_value
.xref word_home

.text

****************************************************************
* getcwdx - カレント・ワーキング・ディレクトリを得る
*
* CALL
*      A0     格納するバッファのアドレス（MAXPATH+1バイト必要）
*      D0.B   非0ならば ~省略を行う
*
* RETURN
*      D0.L   最下位バイトは、~省略をしたならば非0
*             上位バイトは不定
*
*      CCR    TST.B D0
****************************************************************
.xdef getcwdx

getcwdx:
		bsr	getcwd
		tst.b	d0
		beq	return
****************************************************************
* abbrev_directory - ディレクトリを省略形に書き換える
*
* CALL
*      A0     ディレクトリ名
*
* RETURN
*      D0.L   ~で書き換えたならば 1，さもなくば 0．
*      CCR    TST.B D0
*
* DESCRIPTION
*      A0 の指す領域を直接書き換える
*      元よりも長くはならないから大丈夫
*      ディレクトリ名のディレクトリの区切りは / でなければならない
****************************************************************
.xdef abbrev_directory

abbrev_directory:
		bsr	is_under_home
		beq	return

		movem.l	a0-a1,-(a7)
		lea	(a0,d0.l),a1
		move.b	#'~',(a0)+
		bsr	strcpy
		movem.l	(a7)+,a0-a1
		moveq	#1,d0
return:
		rts
****************************************************************
* is_under_home - ディレクトリ名がホーム・ディレクトリ下かどうか
*
* CALL
*      A0     ディレクトリ名
*
* RETURN
*      D0.L   $home下ならば、~に続くべき部分までのオフセット
*             そうでなければ 0
*
*      CCR    TST.L D0
*
* NOTE
*      ディレクトリ名のディレクトリの区切りは / でなければならない
****************************************************************
.xdef is_under_home

is_under_home:
		movem.l	d1-d2/a0-a2,-(a7)
		moveq	#0,d2			*  D2.L : 結果
		movea.l	a0,a2			*  A2 : ディレクトリ名の先頭アドレス
		bsr	isfullpath		*  ディレクトリ名は絶対パス
		bne	is_under_home_return	*  ではない

		lea	word_home,a0		*  シェル変数 home
		bsr	find_shellvar		*  は
		beq	is_under_home_return	*  は無い

		bsr	get_var_value
		beq	is_under_home_return	*  $#home は 0 である

		bsr	isfullpath		*  $home[1] は絶対パス名
		bne	is_under_home_return	*  ではない

		move.b	(a0),d0			*  $home[1] のドライブ名
		bsr	toupper			*  を大文字にして
		move.b	d0,d1			*  D1.B に格納
		move.b	(a2),d0			*  ディレクトリ名のドライブ名
		bsr	toupper			*  を大文字にして
		cmp.b	d1,d0			*  比較
		bne	is_under_home_return	*  一致しない

		lea	2(a2),a1		*  A1 : ディレクトリ名の @: の次のアドレス
		addq.l	#2,a0			*  A0 : $home[1] の @: の次のアドレス
is_under_home_compare_loop:
		move.b	(a0)+,d0
		beq	is_under_home_check_bottom

		bsr	issjis
		beq	is_under_home_compare_sjis

		bsr	tolower
		cmp.b	#'\',d0
		bne	is_under_home_compare_1

		moveq	#'/',d0
is_under_home_compare_1:
		cmp.b	#'/',d0
		bne	is_under_home_compare_ank

		tst.b	(a0)
		beq	is_under_home_check_bottom
is_under_home_compare_ank:
		move.b	d0,d1
		move.b	(a1)+,d0
		bsr	tolower
		cmp.b	d1,d0
		bra	is_under_home_check_one

is_under_home_compare_sjis:
		move.b	d0,d1
		move.b	(a1)+,d0
		bsr	issjis
		bne	is_under_home_return

		cmp.b	d1,d0
		bne	is_under_home_return

		move.b	(a0)+,d0
		beq	is_under_home_return

		cmp.b	(a1)+,d0
is_under_home_check_one:
		bne	is_under_home_return
		bra	is_under_home_compare_loop

is_under_home_check_bottom:
		move.b	(a1),d0
		beq	is_under_home_true

		cmp.b	#'/',d0
		beq	is_under_home_true

		cmp.b	#'\',d0
		bne	is_under_home_return
is_under_home_true:
		move.l	a1,d2
		sub.l	a2,d2
is_under_home_return:
		move.l	d2,d0
		movem.l	(a7)+,d1-d2/a0-a2
		rts
****************************************************************

.end
