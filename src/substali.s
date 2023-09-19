* substali.s
* Itagaki Fumihiko 11-Feb-91  Create.

.xref strlen
.xref memcmp
.xref strmove
.xref strfor1
.xref strforn
.xref skip_paren
.xref is_word_separator
.xref findvar
.xref get_var_value
.xref subst_history
.xref too_long_line

.xref alias_top

.text

****************************************************************
* count_command_word - 単一のコマンドの単語数を数える
*
* CALL
*      A0     単語並び
*      D5.W   単語数
*
* RETURN
*      D2.W   単一のコマンドの単語数
****************************************************************
count_command_word:
		movem.l	d0-d1/a0,-(a7)
		moveq	#0,d2				* D2.W に数える
		move.w	d5,d1				* D1.W : カウンタ
count_command_word_loop:
		tst.w	d1
		beq	count_command_word_no_separator

		move.b	(a0),d0
		cmp.b	#'(',d0
		bne	count_command_word_1

		move.w	d1,d0
		bsr	skip_paren
		exg	d0,d1
		sub.w	d1,d0
		add.w	d0,d2
		bra	count_command_word_continue

count_command_word_1:
		cmp.b	#';',d0
		beq	semicolon_found

		cmp.b	#'|',d0
		beq	vertical_line_found

		cmp.b	#'&',d0
		beq	ampersand_found
count_command_word_continue:
		bsr	strfor1
		addq.w	#1,d2
		subq.w	#1,d1
		bra	count_command_word_loop

count_command_word_no_separator:
		move.w	d5,d2
		bra	count_command_word_done

semicolon_found:
		tst.b	1(a0)
		bra	test_separator_tail

vertical_line_found:
		tst.b	1(a0)
		beq	count_command_word_done
ampersand_found:
		cmp.b	1(a0),d0
		bne	count_command_word_continue

		tst.b	2(a0)
test_separator_tail:
		bne	count_command_word_continue
count_command_word_done:
		movem.l	(a7)+,d0-d1/a0
		rts
****************************************************************
dup_a_word:
		bsr	strlen
		sub.w	d0,d1
		bcs	dup_a_word_return		*  cs : 文字数オーバー

		exg	a0,a1
		bsr	strmove
		exg	a0,a1
		subq.l	#1,a1
		subq.w	#1,d5
		beq	dup_a_word_return		*  eq : もうソース単語は無い

		move.b	#' ',(a1)+
		clr.b	(a1)
		tst.w	d5				*  必ず ne
dup_a_word_return:
		rts
****************************************************************
* subst_alias - 別名置換をする
*
* CALL
*      A0     ソース（単語並び）の先頭
*      A1     展開バッファの先頭
*      D0.W   ソース単語数
*      D1.W   展開バッファの容量（最後の NUL の分は含まない）
*
* RETURN
*      D0.L   成功ならば 0．さもなくば 1（エラー・メッセージはここで表示される）
*      D1.W   展開バッファの残り容量
*      D2.B   0 ならば、 1度も置換は行われなかった
*             1 ならば、少なくとも 1度は置換が行われたが、これ以上置換は起こらない
*             3 ならば、更に置換される可能性がある
*      CCR    TST.L D0
****************************************************************
.xdef subst_alias

subst_alias:
		movem.l	d3-d7/a0-a2,-(a7)
		moveq	#0,d7				*  D7.B : 「置換した」フラグ
		move.w	d0,d5				*  D5.W : ソース単語数
		beq	subst_alias_done
subst_alias_loop:
	*
	*  単一のコマンドの単語数を数える
	*
		bsr	count_command_word
		tst.w	d2
		beq	expand_command_done		*  コマンドの単語数が 0 ならば置換しない

		cmpi.b	#'(',(a0)
		bne	subst_alias_1

		tst.b	1(a0)
		beq	dup_args			*  サブシェルならば置換しない
subst_alias_1:
		cmpi.b	#'\',(a0)			*  コマンド名の最初の文字が '\' でエスケープされているなら
		beq	dup_args			*  別名置換しない

		move.l	a1,-(a7)			*  バッファ・ポインタを退避
		movea.l	a0,a1				*  A1 : コマンドの先頭
		movea.l	alias_top(a5),a0
		bsr	findvar				*  別名かどうかを調べる
		movea.l	a1,a0				*  A0 : コマンドの先頭
		movea.l	(a7)+,a1			*  A1 : バッファ・ポインタ
		beq	dup_args			*  別名ではない .. 置換しない
	*
	*  別名を展開する
	*
		movea.l	a0,a2				*  A2 : コマンドの先頭
		bsr	get_var_value			*  A0 : 実コマンド単語並び
		move.w	d0,d4				*  D4.W : このエントリの単語数
		*
		*  ここで
		*      A0     実コマンド単語並び
		*      A1     展開バッファ・ポインタ
		*      A2     別名参照単語並び
		*      D1.W   展開バッファの容量
		*      D2.W   別名参照の単語数
		*      D4.W   実コマンドの単語数
		*
		bset	#0,d7				* 「置換した」フラグを立てる
		moveq	#0,d6				*  D6 : 「!置換した」フラグ
	*
	*  別名と実名が同名でなければ、更に置換されることを許すために
	*  先に加えた '\' を削除する
	*
		tst.w	d4
		beq	allow_more_alias

		exg	a0,a2
		bsr	strlen
		move.l	d0,d3
		exg	a1,a2
		bsr	memcmp
		exg	a1,a2
		exg	a0,a2
		bne	allow_more_alias

		move.b	(a0,d3.l),d0
		beq	not_allow_more_alias

		bsr	is_word_separator
		beq	not_allow_more_alias
allow_more_alias:
		bset	#1,d7				* 「再帰の可能性あり」フラグを立てる
		bra	expand_alias_start

not_allow_more_alias:
	*
	*  これ以上は置換しない .. '\' を加える
	*
		subq.w	#1,d1
		bcs	subst_alias_over

		move.b	#'\',(a1)+
		bra	expand_alias_start

expand_alias_loop:
		sf	d0
		bsr	subst_history
		or.b	d0,d6
		moveq	#1,d0
		btst	#2,d6
		bne	subst_alias_return

		btst	#1,d6
		bne	subst_alias_return

		subq.w	#1,d1
		bcs	subst_alias_over

		move.b	#' ',(a1)+
expand_alias_start:
		dbra	d4,expand_alias_loop

		movea.l	a2,a0
		btst	#3,d6
		beq	expand_alias_dup_args

		move.w	d2,d0
		bsr	strforn
		sub.w	d0,d5
		bra	expand_command_done

expand_alias_dup_args:
		bsr	strfor1
		subq.w	#1,d5
		subq.w	#1,d2
		bra	dup_args

dup_args_loop:
		bsr	dup_a_word
		bcs	subst_alias_over
dup_args:
		dbra	d2,dup_args_loop
expand_command_done:
		tst.w	d5
		beq	subst_alias_done
	*
	*  コマンド区切り単語をコピーする
	*
		bsr	dup_a_word
		bcs	subst_alias_over
		bne	subst_alias_loop
subst_alias_done:
		move.l	d7,d2
		moveq	#0,d0
subst_alias_return:
		clr.b	(a1)
		movem.l	(a7)+,d3-d7/a0-a2
		tst.l	d0
		rts

subst_alias_over:
		bsr	too_long_line
		bra	subst_alias_return
****************************************************************
.end
