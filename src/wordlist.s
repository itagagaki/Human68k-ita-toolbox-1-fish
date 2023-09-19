* wordlist.s
* Itagaki Fumihiko 11-Aug-90  Create.

.include ../src/fish.h

.xref issjis
.xref tolower
.xref skip_space
.xref jstrchr
.xref strlen
.xref strcmp
.xref strmove
.xref strfor1
.xref strforn
.xref rotate
.xref too_many_words
.xref too_long_line
.xref too_long_word
.xref word_separators

****************************************************************
* make_wordlist - 単語並びを作る
*
* CALL
*      A0     source line address
*      A1     destination word list buffer address (MAXWORDLISTSIZE)
*      D1.W   バッファの容量
*
* RETURN
*      D0.L   正数ならば成功．下位ワードは語数．
*             負数ならばエラー．
*
*      D1.W   バッファの残り容量
*
*      A1     バッファの次の格納位置を指す
*
*      CCR    TST.L D0
*
* NOTE
*      空白で区切られていずとも独立な単語として扱われるもの
*           (  )  ;  |  ||  &  &&  <  <<  >  >>  （以上は csh と同じ）
*           <=  >=  <<=  >>=  &=  |=
*      エスケープされていない $ に続く文字は特別な意味を持たない
*      エスケープされていない $ の直後に { があるとき、次に現われる }
*      までの文字は特別な意味を持たない
*****************************************************************
.xdef make_wordlist

make_wordlist:
		movem.l	d2-d6/a0,-(a7)
		moveq	#0,d2			*  D2.W : 単語数
make_wordlist_loop:
		bsr	skip_space		*  空白をスキップする
		move.b	(a0)+,d0		*  最初の文字が
		beq	make_wordlist_done	*  NULならば終わり

		addq.w	#1,d2
		cmp.w	#MAXWORDS,d2
		bhi	make_wordlist_too_many_words

		move.w	#MAXWORDLEN+1,d3	* 単語の終わりのNULの分も勘定する

		bsr	is_word_separator
		bne	make_wordlist_normal_word

		cmp.b	#'>',d0
		beq	special_word_less_great

		cmp.b	#'<',d0
		beq	special_word_less_great

		cmp.b	#'|',d0
		beq	special_word_and_or

		cmp.b	#'&',d0
		beq	special_word_and_or

		bra	special_word_1

special_word_less_great:
		cmp.b	(a0),d0
		bne	special_word_is_assignment

		cmp.b	#'<',d0
		bne	special_word_double_less_great

		cmp.b	1(a0),d0
		beq	special_word_3
special_word_double_less_great:
		cmpi.b	#'=',1(a0)
		beq	special_word_3

		bra	special_word_2

special_word_and_or:
		cmp.b	(a0),d0
		beq	special_word_2
special_word_is_assignment:
		cmpi.b	#'=',(a0)
		beq	special_word_2

		bra	special_word_1

special_word_3:
		bsr	make_wordlist_store1
		bne	make_wordlist_error

		move.b	(a0)+,d0
special_word_2:
		bsr	make_wordlist_store1
		bne	make_wordlist_error

		move.b	(a0)+,d0
special_word_1:
		bsr	make_wordlist_store1
		bne	make_wordlist_error
make_wordlist_terminate_word:
		moveq	#0,d0
		bsr	make_wordlist_store1
		bne	make_wordlist_error

		bra	make_wordlist_loop
****************
make_wordlist_normal_word:
		subq.l	#1,a0
		moveq	#0,d5			*  D5 : ${}レベル
		moveq	#0,d0
make_wordlist_normal_loop_0:
		move.b	d0,d4			*  D4 : クオート・フラグ
make_wordlist_normal_loop_1:
		moveq	#0,d6			*  D6 : 「$ の次」フラグ
make_wordlist_normal_loop_2:
		move.b	(a0)+,d0
		bsr	make_wordlist_store1
		bne	make_wordlist_error

		tst.b	d0
		beq	make_wordlist_done

		bsr	issjis
		beq	make_wordlist_dup_more_1

		cmp.b	d4,d0
		bne	make_wordlist_not_close_quote

			moveq	#0,d4
			bra	make_wordlist_check_term

make_wordlist_not_close_quote:
		cmp.b	#'{',d0
		bne	make_wordlist_not_open_brace

			tst.b	d6
			beq	make_wordlist_check_term

			addq.l	#1,d5
			bra	make_wordlist_check_term

make_wordlist_not_open_brace:
		cmp.b	#'}',d0
		bne	make_wordlist_not_close_brace

			tst.l	d5
			beq	make_wordlist_check_term

			subq.l	#1,d5
			bra	make_wordlist_check_term

make_wordlist_not_close_brace:
		cmp.b	#"'",d4
		beq	make_wordlist_normal_loop_1

		cmp.b	#"`",d4
		beq	make_wordlist_normal_loop_1

		cmp.b	#'$',d0
		bne	make_wordlist_not_doller

			tst.b	d6
			bne	make_wordlist_check_term

			moveq	#1,d6
			tst.b	d4
			bne	make_wordlist_normal_loop_2

			tst.l	d5
			bne	make_wordlist_normal_loop_2

			cmpi.b	#'{',(a0)
			bne	make_wordlist_normal_loop_2

			addq.l	#1,d5
			move.b	(a0)+,d0
			bsr	make_wordlist_store1
			bne	make_wordlist_error

			bra	make_wordlist_normal_loop_2

make_wordlist_not_doller:
		tst.b	d4
		bne	make_wordlist_normal_loop_1

		cmp.b	#'"',d0
		beq	make_wordlist_normal_loop_0

		cmp.b	#"'",d0
		beq	make_wordlist_normal_loop_0

		cmp.b	#'`',d0
		beq	make_wordlist_normal_loop_0

		cmp.b	#'\',d0
		bne	make_wordlist_check_term

		move.b	(a0),d0
		bsr	issjis
		beq	make_wordlist_normal_loop_1
make_wordlist_dup_more_1:
		move.b	(a0)+,d0
		bsr	make_wordlist_store1
		bne	make_wordlist_error

		tst.b	d0
		beq	make_wordlist_done
make_wordlist_check_term:
		tst.b	d4
		bne	make_wordlist_normal_loop_1

		tst.l	d5
		bne	make_wordlist_normal_loop_1

		move.b	(a0),d0
		bsr	is_word_separator
		bne	make_wordlist_normal_loop_1

		bra	make_wordlist_terminate_word
****************
make_wordlist_done:
		move.l	d2,d0
make_wordlist_return:
		movem.l	(a7)+,d2-d6/a0
		rts
********************************
make_wordlist_too_many_words:
		bsr	too_many_words
make_wordlist_error:
		moveq	#-1,d0
		bra	make_wordlist_return
*******************************
make_wordlist_store1:
		subq.w	#1,d1
		bcs	too_long_line

		subq.w	#1,d3
		bcs	too_long_word

		move.b	d0,(a1)+
		cmp.b	d0,d0				* ゼロ・フラグをセットする
		rts
****************************************************************
.xdef is_word_separator

is_word_separator:
		movem.l	d0/a0,-(a7)
		lea	word_separators,a0
		and.w	#$ff,d0
		bsr	jstrchr
		seq	d0
		tst.b	d0
		movem.l	(a7)+,d0/a0
		rts
****************************************************************
* words_to_line - 単語並びを行にする
*
* CALL
*      A0     単語並びの先頭アドレス
*      D0.W   単語数
*
* RETURN
*      none.
*****************************************************************
.xdef words_to_line

words_to_line:
		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
		blo	words_to_line_null
		bra	words_to_line_continue

words_to_line_loop:
		bsr	strfor1
		move.b	#' ',-1(a0)
words_to_line_continue:
		dbra	d0,words_to_line_loop
words_to_line_return:
		movem.l	(a7)+,d0/a0
		rts

words_to_line_null:
		clr.b	(a0)
		bra	words_to_line_return
****************************************************************
* copy_wordlist - 単語並びをコピーする
*
* CALL
*      A0     destination buffer
*      A1     source word list
*      D0.W   number of words
*
* RETURN
*      none
*****************************************************************
.xdef copy_wordlist

copy_wordlist:
		movem.l	d0/a0-a1,-(a7)
		bra	copy_wordlist_continue

copy_wordlist_loop:
		bsr	strmove
copy_wordlist_continue:
		dbra	d0,copy_wordlist_loop

		movem.l	(a7)+,d0/a0-a1
		rts
****************************************************************
* find_close_paren - find ) in wordlist
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*
* RETURN
*      A0     ) を指す（もしあれば）
*
*      D0.L   進んだ単語数
*             負数ならば見つからなかったことを示している
*
*      CCR    TST.L D0
*****************************************************************
.xdef find_close_paren

find_close_paren:
		movem.l	d1,-(a7)
		moveq	#0,d1
		bra	find_close_paren_start

find_close_paren_loop:
		cmpi.b	#')',(a0)
		beq	close_paren_found

		bsr	strfor1
		addq.w	#1,d1
find_close_paren_start:
		dbra	d0,find_close_paren_loop

		moveq	#-1,d0
find_close_paren_return:
		movem.l	(a7)+,d1
		rts

close_paren_found:
		move.l	d1,d0
		bra	find_close_paren_return
****************************************************************
* sort_wordlist - 単語の並びをソートする
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*
* RETURN
*      なし
*
* NOTE
*      アルゴリズムは単純選択法．遅い．実行時間はpow(N,2)のオーダー．
*      交換は配列を巡回しているので特に遅い．
*      安定ではある．
*****************************************************************
.xdef sort_wordlist

sort_wordlist:
		movem.l	d0-d2/a0-a3,-(a7)
		move.w	d0,d1				*  D1.W : 要素数
		movea.l	a0,a2
		bsr	strforn
		exg	a0,a2				*  A0:最初の要素  A2:最後の要素の次
sort_wordlist_loop2:
		cmp.w	#2,d1
		blo	sort_wordlist_done

		*  A0 以降の最小の単語のアドレスを A1 に得る
		movea.l	a0,a3
		subq.w	#1,d1
		move.w	d1,d2
		bra	sort_wordlist_loop1_start

sort_wordlist_loop1:
		bsr	strfor1
		bsr	strcmp
		bhs	sort_wordlist_loop1_continue
sort_wordlist_loop1_start:
		movea.l	a0,a1
sort_wordlist_loop1_continue:
		dbra	d2,sort_wordlist_loop1

		movea.l	a3,a0
		cmpa.l	a0,a1				*  先頭の単語が最小なら
		beq	sort_wordlist_loop2_continue	*  交換しない

		bsr	rotate
sort_wordlist_loop2_continue:
		bsr	strfor1
		bra	sort_wordlist_loop2

sort_wordlist_done:
		movem.l	(a7)+,d0-d2/a0-a3
		rts
****************************************************************
* uniq_wordlist - 単語の並びの中で隣接している重複単語を削除する
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*
* RETURN
*      D0.L   下位ワードは単語数．上位は破壊
*****************************************************************
.xdef uniq_wordlist

uniq_wordlist:
		movem.l	d1-d2/a0-a2,-(a7)
		moveq	#0,d2
		movea.l	a0,a1				*  A1 : 比較する単語のアドレス
		move.w	d0,d1				*  D1.W : A1以降の単語数
uniq_wordlist_loop1:
		cmp.w	#2,d1
		blo	uniq_wordlist_done

		bsr	strfor1
		subq.w	#1,d1
		addq.w	#1,d2
		bsr	strcmp
		bne	uniq_wordlist_continue

		subq.w	#2,d1
		bcs	uniq_wordlist_return

		movea.l	a0,a2
uniq_wordlist_loop2:
		bsr	strfor1
		bsr	strcmp
		dbne	d1,uniq_wordlist_loop2
		beq	uniq_wordlist_return

		addq.w	#1,d1
		move.w	d1,d0
		movea.l	a0,a1
		movea.l	a2,a0
		bsr	copy_wordlist
uniq_wordlist_continue:
		movea.l	a0,a1
		bra	uniq_wordlist_loop1

uniq_wordlist_done:
		add.w	d1,d2
uniq_wordlist_return:
		move.w	d2,d0
		movem.l	(a7)+,d1-d2/a0-a2
		rts
****************************************************************
* is_all_same_word - 単語の並びの中の単語がすべて同じであるかどうかを調べる
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*
* RETURN
*      D0.L   すべて同じならば 0
*      CCR    TST.L D0
*****************************************************************
.xdef is_all_same_word

is_all_same_word:
		movem.l	d1/a0-a1,-(a7)
		move.w	d0,d1
		moveq	#0,d0
		subq.w	#2,d1
		bcs	is_all_same_word_return

		movea.l	a0,a1
is_all_same_word_loop:
		bsr	strfor1
		bsr	strcmp
		dbne	d1,is_all_same_word_loop
is_all_same_word_return:
		movem.l	(a7)+,d1/a0-a1
		tst.l	d0
		rts
****************************************************************
* wordlistlen - 語並びの長さ
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*
* RETURN
*      D0.L   単語並びのバイト数
*****************************************************************
.xdef wordlistlen

wordlistlen:
		movem.l	d1-d2/a0,-(a7)
		moveq	#0,d2
		move.w	d0,d1
		bra	wordlistlen_start

wordlistlen_loop:
		bsr	strlen
		addq.l	#1,d0
		add.l	d0,d2
		add.l	d0,a0
wordlistlen_start:
		dbra	d1,wordlistlen_loop

		move.l	d2,d0
		movem.l	(a7)+,d1-d2/a0
		rts
****************************************************************
* common_spell - 単語並びの最初の共通部分の長さを得る
*
* CALL
*      A0     単語並び
*      D0.W   単語数
*      D1.L   単語の最初の無視するべき部分の長さ
*      D2.B   0 ならば大文字と小文字を区別する
*
* RETURN
*      D0.L   最初の共通部分の長さ
*****************************************************************
.xdef common_spell

common_spell:
		movem.l	d1-d6/a0-a1,-(a7)
		moveq	#0,d4				*  共通部分の長さカウンタ
		move.w	d0,d5				*  D5.W : 単語数
		beq	common_spell_done

		subq.w	#1,d5
		lea	(a0,d1.l),a1
common_spell_loop1:
		move.w	d5,d3				*  D3.W : 単語数カウンタ
		movea.l	a1,a0
		move.b	(a1)+,d0
		beq	common_spell_done		*  もう文字は無い…これまで

		bsr	issjis
		beq	common_spell_sjis
****************
		tst.b	d2				*  大文字と小文字を区別
		beq	common_spell_ank_1		*  しないなら

		bsr	tolower				*  tolower しておく
common_spell_ank_1:
		move.b	d0,d6
		bra	common_spell_ank_continue

common_spell_ank_loop:
		bsr	strfor1
		add.l	d1,a0
		move.b	(a0),d0
		tst.b	d2				*  （大文字と小文字を区別
		beq	common_spell_ank_2		*    しないなら

		bsr	tolower				*    tolower してから）
common_spell_ank_2:
		cmp.b	d6,d0				*  比較する．
		bne	common_spell_done		*  一致しない単語がある…ここまで
common_spell_ank_continue:
		dbra	d3,common_spell_ank_loop

		*  1バイト伸ばしてさらに比較する

		addq.l	#1,d1
		addq.l	#1,d4
		bra	common_spell_loop1
****************
common_spell_sjis:
		lsl.w	#8,d0
		move.b	(a1)+,d0
		beq	common_spell_done		*  この単語にはもう文字は無い…これまで

		bra	common_spell_sjis_continue

common_spell_sjis_loop:
		bsr	strfor1
		add.l	d1,a0
		move.b	(a0),d6
		lsl.l	#8,d6
		move.b	1(a0),d6
		cmp.w	d0,d6
		bne	common_spell_done		*  一致しない単語がある…これまで
common_spell_sjis_continue:
		dbra	d3,common_spell_sjis_loop

		*  2バイト伸ばしてさらに比較する

		addq.l	#2,d1
		addq.l	#2,d4
		bra	common_spell_loop1
****************
common_spell_done:
		move.l	d4,d0
		movem.l	(a7)+,d1-d6/a0-a1
		rts

.end
