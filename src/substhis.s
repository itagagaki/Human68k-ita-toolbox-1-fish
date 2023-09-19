* substhis.s
* Itagaki Fumihiko 29-Jul-90  Create.

.include ../src/fish.h
.include ../src/modify.h
.include ../src/history.h

.xref isdigit
.xref isspace
.xref issjis
.xref atou
.xref utoa
.xref jstrchr
.xref strlen
.xref strfor1
.xref strforn
.xref strmem
.xref memmovi
.xref skip_space
.xref make_wordlist
.xref scanchar2
.xref eputs
.xref ecputs
.xref enputs
.xref xmallocp
.xref free
.xref xfreep
.xref modify
.xref is_word_separator
.xref pre_perror
.xref syntax_error
.xref cannot_because_no_memory
.xref too_long_line
.xref msg_colon_blank
.xref msg_too_large_number
.xref str_nul

.xref tmpgetlinebufp

.xref history_top
.xref history_bot
.xref current_eventno
.xref prev_search
.xref histchar1
.xref histchar2

****************************************************************
* find_history - 履歴リストからイベントをイベント番号で検索する
*
* CALL
*      D0     イベント番号
*
* RETURN
*      A0     見つかったイベントの先頭アドレス
*             見つからなかったならば 0
*
*      CCR    CMPA.L #0,A0
****************************************************************
.xdef find_history

find_history:
		movea.l	history_bot(a5),a0
find_history_loop:
		cmpa.l	#0,a0
		beq	find_history_done

		cmp.l	HIST_EVENTNO(a0),d0		*  イベント番号を比較する
		beq	find_history_done
		bhi	find_history_fail

		movea.l	HIST_PREV(a0),a0
		bra	find_history_loop

find_history_fail:
		suba.l	a0,a0
find_history_done:
		cmpa.l	#0,a0
		rts
****************************************************************
* wordlistmem - 単語並びからある文字列を探し出す
*
* CALL
*      A0     単語並びの先頭アドレス
*      D0.W   単語数
*      A1     検索文字列の先頭アドレス
*      D1.L   検索文字列の長さ
*      D2.B   0 以外ならば ANK英文字の大文字と小文字を区別しない
*
* RETURN
*      D0.W   残り単語数（見つかった単語も含む）
*             0 なら見つからなかった
*      A0     見つかったアドレス．見つからなければ0
*      D2.L   見つかった単語の番号
*      CCR    TST.W D0
****************************************************************
.xdef wordlistmem

wordlistmem:
		movem.l	d1/d3-d4,-(a7)
		move.l	d1,d4				* D4.W : 検索文字列の長さ
		move.b	d2,d1				* D1.B : case independent flag
		move.w	d0,d3				* D3.W : 単語数
		moveq	#0,d2				* D2.L : 単語番号カウンタ
		bra	wordlistmem_continue

wordlistmem_loop:
		move.l	d4,d0
		bsr	strmem				* 文字列を探す
		bne	wordlistmem_done		* 見つかった

		bsr	strfor1
		addq.l	#1,d2
wordlistmem_continue:
		dbra	d3,wordlistmem_loop

		moveq	#0,d0
wordlistmem_done:
		movea.l	d0,a0
		move.w	d3,d0
		addq.w	#1,d0
		movem.l	(a7)+,d1/d3-d4
		rts
****************************************************************
* histcmp
*
* CALL
*      A0     履歴イベントのボディ
*      A1     比較文字列
*      D0.L   比較文字列の長さ
*
* RETURN
*      D0.L   一致したとき、実際に一致したバイト数
*      CCR    一致すれば EQ
****************************************************************
histcmp:
		movem.l	d1-d2/a0-a2,-(a7)
		movea.l	a0,a2
		move.l	d0,d1
		beq	histcmp_break
histcmp_loop1:
		move.b	(a1),d0
		bsr	isspace
		bne	histcmp_2

		addq.l	#1,a1
		subq.l	#1,d1
		beq	histcmp_break

		bra	histcmp_loop1

histcmp_2:
		move.b	(a0),d0
		bsr	is_word_separator
		sne	d2
histcmp_loop2:
		move.b	(a0)+,d0
		beq	histcmp_nul

		cmp.b	(a1)+,d0
		bne	histcmp_break

		subq.l	#1,d1
		beq	histcmp_break

		bra	histcmp_loop2

histcmp_nul:
		tst.b	d2
		beq	histcmp_loop1

		move.b	(a1),d0
		bsr	is_word_separator
		beq	histcmp_loop1
histcmp_break:
		sne	d1
		move.l	a0,d0
		sub.l	a2,d0
		tst.b	d1
		movem.l	(a7)+,d1-d2/a0-a2
		rts
****************************************************************
* search_up_history - ある文字列を含む履歴を遡って検索する
*
* CALL
*      A0     検索文字列
*      D0.L   検索文字列の長さ
*      A1     検索を開始するイベントを指す
*      D2.B   0 = 先頭マッチング   非0 = 部分マッチング
*
* RETURN
*      CCR    見つかったならば NE
*
*      見つかったとき
*
*      A1     見つかったイベントを指す
*      D2.L   部分マッチングのとき、マッチした単語の番号
*      D3.L   先頭マッチングのとき、実際にマッチしたバイト数
*
*      見つからなかったとき
*
*      D2-D3  破壊
****************************************************************
.xdef search_up_history

search_up_history:
		movem.l	d0-d1/d4-d5/a0/a2-a3,-(a7)
		movea.l	a1,a3				* A1 を A3 に退避
		movea.l	a1,a2				* A2 : 履歴ポインタ
		movea.l	a0,a1				* A1 : 検索文字列
		move.l	d0,d3				* D3 : 検索文字列の長さ
		move.b	d2,d4				* D4 : 0=先頭  非0=部分
		moveq	#-1,d2				* D2.L = -1 .. :%は無効
search_up_history_loop:
		cmpa.l	#0,a2
		beq	search_up_history_fail

		move.w	HIST_NWORDS(a2),d5		* D5 : このイベントの語数
		beq	search_up_history_continue

		lea	HIST_BODY(a2),a0
		tst.b	d4
		bne	search_up_history_part_match

		move.l	d3,d0
		bsr	histcmp
		bne	search_up_history_continue

		move.l	d0,d3
		bra	search_up_history_found

search_up_history_part_match:
		move.w	d5,d0
		move.l	d3,d1
		moveq	#0,d2
		bsr	wordlistmem
		bne	search_up_history_found
search_up_history_continue:
		movea.l	HIST_PREV(a2),a2
		bra	search_up_history_loop

search_up_history_found:
		movea.l	a2,a1				*  A1 : 見つかったイベント
		cmpa.l	#0,a1
		bra	search_up_history_return

search_up_history_fail:
		movea.l	a3,a1				*  A1 を元に戻す
search_up_history_return:
		movem.l	(a7)+,d0-d1/d4-d5/a0/a2-a3
		rts
****************************************************************
* search_down_history - ある文字列を含む履歴を降順に検索する
*
* CALL
*      A0     検索文字列
*      D0.L   検索文字列の長さ
*      A1     検索を開始するイベントを指す
*      D2.B   0 = 先頭マッチング   非0 = 部分マッチング
*
* RETURN
*      CCR    見つかったならば NE
*
*      見つかったとき
*
*      A1     見つかったイベントを指す
*      D2.L   部分マッチングのとき、マッチした単語の番号
*      D3.L   先頭マッチングのとき、実際にマッチしたバイト数
*
*      見つからなかったとき
*
*      D2-D3  破壊
****************************************************************
.xdef search_down_history

search_down_history:
		movem.l	d0-d1/d4-d5/a0/a2-a3,-(a7)
		movea.l	a1,a3				* A1 を A3 に退避
		movea.l	a1,a2				* A2 : 履歴ポインタ
		movea.l	a0,a1				* A1 : 検索文字列
		move.l	d0,d3				* D3 : 検索文字列の長さ
		move.b	d2,d4				* D4 : 0=先頭  非0=部分
		moveq	#-1,d2				* D2.L = -1 .. :%は無効
search_down_history_loop:
		cmpa.l	#0,a2
		beq	search_down_history_fail

		move.w	HIST_NWORDS(a2),d5		* D5 : このイベントの語数
		beq	search_down_history_continue

		lea	HIST_BODY(a2),a0
		tst.b	d4
		bne	search_down_history_part_match

		move.l	d3,d0
		bsr	histcmp
		bne	search_down_history_continue

		move.l	d0,d3
		bra	search_down_history_found

search_down_history_part_match:
		move.w	d5,d0
		move.l	d3,d1
		moveq	#0,d2
		bsr	wordlistmem
		bne	search_down_history_found
search_down_history_continue:
		movea.l	HIST_NEXT(a2),a2
		bra	search_down_history_loop

search_down_history_found:
		movea.l	a2,a1				*  A1 : 見つかったイベント
		cmpa.l	#0,a1
		bra	search_down_history_return

search_down_history_fail:
		movea.l	a3,a1				*  A1 を元に戻す
search_down_history_return:
		movem.l	(a7)+,d0-d1/d4-d5/a0/a2-a3
		rts
****************************************************************
* parse_word_selecter - 単語選択子を解析する
*
* CALL
*      A0     解析する文字列のアドレス
*
* RETURN
*      A0     解析を終えた位置を返す
*      D0.L   範囲が空でもエラーでないケースならば 0、さもなくば 1
*      D1.L   始点単語番号
*      D2.L   終点単語番号
*      CCR    TST.L D0
*
*      D1.L と D2.L は、正ならば単語選択子が示している単語番号であるが、
*      単語番号が数値で記述されており、その値が MAXWORDS-1 を超えている
*      場合には MAXWORDS を返す。
*
*      負ならば次の単語を示す。
*             -1: 最後の単語
*             -2: 最後の1つ前の単語
*             -3: ?str? に一致した単語
*
* DESCRIPTION
*							範囲が空なら…
*	なし		最初(0番目)から最後まで		　空文字列
*	:*		1番目から最後まで		　空文字列
*	:*-*		1番目から最後まで		　空文字列
*	:-*		最初(0番目)から最後まで		　空文字列
*	:<N>*		N番目から最後まで		　空文字列
*	:<N>-*		N番目から最後まで		　空文字列
*	:-		最初(0番目)から最後の1つ前まで	　エラー
*	:-<N>		最初(0番目)からN番目まで	　エラー
*	:*-		1番目から最後の1つ前まで	　エラー
*	:*-<M>		1番目からM番目まで		　エラー
*	:<N>		N番目				　エラー
*	:<N>-		N番目から最後の1つ前まで	　エラー
*	:<N>-<M>	N番目からM番目まで		　エラー
*
*	N,M:
*		<n>	n番目の単語		(n)
*		^	1番目の単語		(1)
*		$	最後の単語		(-1)
*		%	?str? に一致した単語	(-3)
*
*       単語選択子が ^, $, *, -, % で始まっている場合には
*       : は省略することができる
****************************************************************
parse_word_selecter:
		moveq	#0,d1				* 始点単語番号 :=  0 : 最初から
		moveq	#-1,d2				* 終点単語番号 := -1 : 最後まで
		moveq	#0,d0
		move.b	(a0)+,d0
		bsr	is_special_word_selecter
		bne	get_word_selecter

		cmp.b	#':',d0
		beq	parse_word_selecter_1

		subq.l	#1,a0
		bra	parse_word_selecter_done_0

parse_word_selecter_1:
		move.b	(a0)+,d0
		bsr	isdigit
		beq	get_word_selecter

		bsr	is_special_word_selecter
		bne	get_word_selecter

		subq.l	#2,a0
		bra	parse_word_selecter_done_0
****************
get_word_selecter:
		cmp.b	#'*',d0
		beq	parse_word_selecter_asterisk

		cmp.b	#'-',d0
		beq	get_wordno2

		bsr	get_wordno			* 始点単語番号を得る
		move.b	(a0)+,d0
		cmp.b	#'*',d0
		beq	parse_word_selecter_done_0

		cmp.b	#'-',d0
		beq	get_wordno2

		move.l	d1,d2				* 終点単語番号 := 始点単語番号
		subq.l	#1,a0
		bra	parse_word_selecter_done_1

parse_word_selecter_asterisk:
		moveq	#1,d1				* 始点単語番号 := 1番目
		move.b	(a0)+,d0
		cmp.b	#'-',d0
		beq	get_wordno2

		subq.l	#1,a0
		bra	parse_word_selecter_done_0

get_wordno2:
		move.b	(a0)+,d0
		cmp.b	#'*',d0
		beq	parse_word_selecter_done_0

		exg	d1,d2
		bsr	get_wordno			* 終点単語番号を得る
		exg	d1,d2
parse_word_selecter_done_1:
		moveq	#1,d0
		rts

parse_word_selecter_done_0:
		moveq	#0,d0
		rts
****************************************************************
fix_wordno:
		cmp.l	#-1,d0
		beq	fix_wordno_last_word

		cmp.l	#-2,d0
		beq	fix_wordno_last_of_last

		cmp.l	#-3,d0
		bne	fix_wordno_test

		move.l	d4,d0
fix_wordno_test:
		cmp.l	d3,d0			* hs (D0 >= D3 || D0 < 0) ならばエラー
		rts

fix_wordno_last_word:
		move.l	d3,d0
		subq.l	#1,d0
		bra	fix_wordno_test

fix_wordno_last_of_last:
		move.l	d3,d0
		subq.l	#2,d0
		bra	fix_wordno_test
*****************************************************************
* expand_history - ! 展開を行う
*
* CALL
*      A0     イベントの単語並び
*      D0.W   イベントの単語数
*      A1     展開バッファのアドレス
*      D1.W   展開バッファの容量
*      A2     単語選択子と単語修飾子が始まるアドレス
*      D2.L   単語選択子 % の単語番号（-1:該当なし）
*      D3.L   置換ステータス
*             bit1 : エラー・メッセージを表示しない
*             bit4 : ^str1^str2^flag^ の展開である
*
* RETURN
*      A1     格納した分だけ進む
*      A2     単語修飾子の次に進む
*      D1.W   展開バッファの残り容量
*      D0.L   置換ステータス
*             bit0 : 実行しない
*             bit1 : 表示も実行もしない
*             bit2 : 登録も表示も実行もしない
*****************************************************************
expand_history:
		movem.l	d2-d5/d7/a0,-(a7)
		move.l	d3,d7				*  D7.L : 置換ステータス
		btst	#4,d7
		bne	expand_history_modify

		move.l	d1,-(a7)
		moveq	#0,d3
		move.l	d0,d3				*  D3.L : このイベントの単語数
		move.l	d2,d4				*  D4.L : % の単語番号（-1:該当なし）
		exg	a0,a2
		bsr	parse_word_selecter		*  D1.L : 始点番号  D2.L : 終点番号
		exg	a0,a2
		move.b	d0,d5				*  D5.B : 「範囲が空でもＯＫ」フラグ
		move.l	d1,d0
		bsr	fix_wordno
		bhs	expand_history_word_range_empty

		move.l	d2,d1
		exg	d0,d1
		bsr	fix_wordno
		exg	d0,d1
		bhs	expand_history_word_range_empty

		sub.l	d0,d1
		bcc	expand_history_word_range_ok
expand_history_word_range_empty:
		tst.b	d5
		beq	expand_history_empty_range

		btst	#1,d7
		bne	expand_history_empty_range

		lea	msg_subst,a0
		bsr	eputs
		lea	msg_bad_word_selecter,a0
		bsr	enputs
		or.b	#%11,d7
expand_history_empty_range:
		moveq	#0,d0
		moveq	#-1,d1
expand_history_word_range_ok:
		addq.w	#1,d1				*  D1.W : 取得単語数
		bsr	strforn				*  A0 : 取得単語並び
		move.w	d1,d0				*  D0.W : 取得単語数
		move.l	(a7)+,d1
****************
*
*  A0     単語並び
*  D0.W   単語数
*  A1     展開バッファのアドレス
*  D1.W   バッファ容量
*  A2     単語修飾子が始まるアドレス
*  D7     置換ステータス
*
expand_history_modify:
		moveq	#0,d4
		move.w	d1,d4				*  D4.L : バッファ容量
		move.w	d0,d1				*  D1.W : 取得単語数
		exg	a1,a2
		move.w	#%100000000,d0
		btst	#1,d7
		beq	expand_history_modify_1

		bset	#MODIFYSTATBIT_ERROR,d0
expand_history_modify_1:
		btst	#4,d7
		beq	expand_history_modify_2

		bset	#MODIFYSTATBIT_QUICK,d0
expand_history_modify_2:
		bsr	modify
		move.l	a0,d3				*  D3.L : 修飾された単語並びの先頭アドレス
		move.l	d0,d2				*  D2.L : 修飾ステータス
		btst	#MODIFYSTATBIT_ERROR,d2
		beq	expand_history_modify_noerror

		or.b	#%11,d7
expand_history_modify_noerror:
		btst	#MODIFYSTATBIT_NOMEM,d2
		bne	expand_history_fatal_error

		btst	#MODIFYSTATBIT_OVFLO,d2
		bne	expand_history_over

		exg	a1,a2
		subq.w	#1,d1
		bcs	expand_history_ok
		bra	expand_history_start

expand_history_nullword:
		addq.l	#1,a0
		subq.w	#1,d1
		bcs	expand_history_ok

		bra	expand_history_start

expand_history_loop:
		addq.l	#1,a0
		subq.w	#1,d4
		bcs	expand_history_over

		move.b	#' ',(a1)+			* 空白で区切る
expand_history_start:
		bsr	strlen
		tst.l	d0
		beq	expand_history_nullword

		sub.l	d0,d4
		bcs	expand_history_over

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		dbra	d1,expand_history_loop
expand_history_ok:
		moveq	#0,d0
		bra	expand_history_done

expand_history_over:
		bsr	too_long_line
expand_history_fatal_error:
		or.b	#%111,d7
expand_history_done:
		btst	#MODIFYSTATBIT_MALLOC,d2
		beq	expand_history_not_free

		exg	d0,d3
		bsr	free
		exg	d0,d3
expand_history_not_free:
		btst	#MODIFYSTATBIT_FAILED,d2
		beq	expand_history_not_failed

		btst	#1,d7
		bne	expand_history_not_failed

		lea	msg_modifier_failed,a0
		bsr	enputs
		or.b	#%11,d7
expand_history_not_failed:
		btst	#MODIFYSTATBIT_P,d2
		beq	expand_history_not_p

		bset	#0,d7
expand_history_not_p:
		move.w	d4,d1
****************
		move.l	d7,d0
		movem.l	(a7)+,d2-d5/d7/a0
		rts
****************************************************************
compare_histchar:
		movea.l	a2,a3
		exg	a0,a3
		bsr	scanchar2
		exg	a0,a3
		cmp.w	d1,d0
		rts
*****************************************************************
.xdef is_histchar_canceller

is_histchar_canceller:
		tst.b	d0
		beq	is_histchar_canceller_return

		bsr	isspace
		beq	is_histchar_canceller_return

		cmp.b	#'=',d0
		beq	is_histchar_canceller_return

		cmp.b	#'~',d0
		beq	is_histchar_canceller_return

		cmp.b	#'(',d0
		beq	is_histchar_canceller_return

		cmp.b	#'\',d0
is_histchar_canceller_return:
		rts
*****************************************************************
* subst_history - ! 置換を行う
*
* CALL
*      A0     ソース文字列アドレス
*      A1     展開バッファの先頭アドレス
*      A2     参照する単語並びのアドレス．0 ならば履歴イベントを参照する
*      D1.W   展開バッファの容量
*      D2.W   参照する単語並びの単語数（A2 が 0 でないとき）
*
* RETURN
*      A0     ソース文字列の最後の NUL の次を指す
*      A1     バッファの次の格納位置を指す
*      D1.W   展開バッファの残り容量
*      D0.B   置換ステータス
*             bit0 : 実行しない
*             bit1 : 表示も実行もしない
*             bit2 : 登録も表示も実行もしない
*             bit3 : 置換が行われた
*****************************************************************
.xdef subst_history

buftop = -4
braceflag = buftop-1
istr_flag = braceflag-1
quick_modify = istr_flag-1
subst_status = quick_modify-1
pad = subst_status - 0

subst_history:
		link	a6,#pad
		movem.l	d2-d7/a2-a4,-(a7)
		move.l	a1,buftop(a6)
		movea.l	a2,a4				*  A4 : 参照単語並び
		move.w	d2,d4				*  D4.W : 参照単語数
		movea.l	a0,a2				*  A2 : ソース
		move.w	d1,d7				*  D7.W : 展開バッファの容量
		clr.b	subst_status(a6)
subst_history_dup_first_blank_loop:
		move.b	(a2)+,d0
		bsr	isspace
		bne	subst_history_dup_first_blank_done

		subq.w	#1,d7
		bcs	subst_hist_over

		move.b	d0,(a1)+
		bra	subst_history_dup_first_blank_loop

subst_history_dup_first_blank_done:
		subq.l	#1,a2
		move.w	histchar2(a5),d1
		bsr	compare_histchar
		bne	subst_history_loop

		st	quick_modify(a6)
		clr.b	braceflag(a6)
		bra	default_event_1
********************************
subst_history_loop:
		move.b	(a2)+,d0
		beq	subst_history_dup1

		subq.l	#1,a2
		move.w	histchar1(a5),d1
		bsr	compare_histchar
		bne	subst_history_not_histchar

		move.b	(a3),d0
		bsr	is_histchar_canceller
		beq	subst_history_dup_char

		sf	quick_modify(a6)
		movea.l	a3,a2
		move.b	d0,braceflag(a6)
		cmp.b	#'{',d0
		bne	subst_hist_nobrace

		addq.l	#1,a2
subst_hist_nobrace:
		move.b	(a2),d0
		move.w	histchar1(a5),d1
		bsr	compare_histchar		*  !!
		beq	default_event

		bsr	isdigit				*  !N
		beq	search_absolute

		cmp.b	#'-',d0				*  !-N
		beq	search_relative

		cmp.b	#'?',d0				*  !?str?
		beq	search_istr

		cmp.b	#'#',d0				*  !#
		beq	current_event
**
**  !str
**
search_str:
		sf	istr_flag(a6)
		movea.l	a2,a0				*  A0 : str の先頭
find_str_loop:
		moveq	#0,d0
		move.b	(a2)+,d0
		beq	find_str_done

		bsr	isspace
		beq	find_str_done

		cmp.b	#':',d0
		beq	find_str_done

		move.l	a0,-(a7)
		lea	special_word_selecters_2,a0	*   -  *  $  ^
		bsr	jstrchr
		movea.l	(a7)+,a0
		bne	find_str_done

		cmp.b	#'}',d0
		beq	find_str_done

		bsr	issjis
		bne	find_str_loop

		move.b	(a2)+,d0
		bne	find_str_loop
find_str_done:
		subq.l	#1,a2				*  A2 : 次のポイント
		move.l	a2,d0
		sub.l	a0,d0				*  D0.L : strの長さ
		beq	default_event_1
		bra	set_search_str
**
**  !?str?
**
search_istr:
		st	istr_flag(a6)
		addq.l	#1,a2				*  1つめの ? をスキップ
		movea.l	a2,a0				*  A0 : str の先頭
		moveq	#'?',d0
		bsr	jstrchr
		exg	a0,a2				*  A2 : 次のポイント
		move.l	a2,d0
		sub.l	a0,d0				*  D0.L : strの長さ
		cmpi.b	#'?',(a2)
		bne	set_search_str

		addq.l	#1,a2
set_search_str:
		tst.l	d0
		beq	get_hist_search_str

		cmp.l	#MAXSEARCHLEN,d0
		bls	put_hist_search_str_len_ok

		move.l	#MAXSEARCHLEN,d0
put_hist_search_str_len_ok:
		move.l	a1,-(a7)
		movea.l	a0,a1
		lea	prev_search(a5),a0
		bsr	memmovi
		movea.l	(a7)+,a1
		clr.b	(a0)
get_hist_search_str:
		lea	prev_search(a5),a0		*  A0 : 検索文字列
		bsr	strlen
		tst.l	d0
		beq	no_prev_search

		move.l	a1,-(a7)
		movea.l	history_bot(a5),a1
		move.b	istr_flag(a6),d2
		bsr	search_up_history
		movea.l	a1,a0
		movea.l	(a7)+,a1
		beq	fail_str

		bra	subst_hist_do_expand_1
**
**  !#
**
current_event:
		addq.l	#1,a2				*  # をスキップ

		lea	tmpgetlinebufp,a0
		move.l	#MAXWORDLISTSIZE,d0
		bsr	xmallocp
		beq	cannot_expand_current_event

		clr.b	(a1)

		move.l	a1,-(a7)
		movea.l	d0,a1
		move.l	#MAXWORDLISTSIZE,d0
		movea.l	buftop(a6),a0
		move.l	a1,-(a7)
		bsr	make_wordlist
		movea.l	(a7)+,a0
		movea.l	(a7)+,a1
		bmi	error

		moveq	#-1,d2
		bra	subst_hist_do_expand_2

cannot_expand_current_event:
		btst.b	#1,subst_status(a6)
		bne	error

		lea	msg_cannot_sharp,a0
		bsr	cannot_because_no_memory
		bra	error
**
**  !!  !*  !$  !^
**
default_event:
		movea.l	a3,a2
default_event_1:
		cmpa.l	#0,a4
		beq	last_history_event

		movea.l	a4,a0
		move.w	d4,d0
		moveq	#-1,d2
		bra	subst_hist_do_expand_2

last_history_event:
		moveq	#1,d0
		bra	search_minus_d0
**
**  !-N
**
search_relative:
		movea.l	a2,a0
		addq.l	#1,a0
		bsr	atou
		exg	a0,a2
		exg	d0,d1
		bmi	search_minus_d0
		bne	overflow
search_minus_d0:
		sub.l	current_eventno(a5),d0
		neg.l	d0
		cmpa.l	#0,a4
		beq	search_absolute_1

		subq.l	#1,d0
		bra	search_absolute_1
**
**  !N
**
search_absolute:
		movea.l	a2,a0
		bsr	atou
		exg	a0,a2
		bne	overflow

		move.l	d1,d0
search_absolute_1:
		bsr	find_history
		beq	fail_n

		moveq	#-1,d2					*  D2.L = -1 .. :%は無効
subst_hist_do_expand_1:
		move.l	current_eventno(a5),HIST_REFNO(a0)	*  参照ポインタをセットする
		move.w	HIST_NWORDS(a0),d0			*  D0.W : このイベントの単語数
		lea	HIST_BODY(a0),a0			*  A0 : 単語並びの先頭
subst_hist_do_expand_2:
		*
		* ここで、
		*      A0     イベントの単語並び
		*      A1     展開バッファのアドレス
		*      A2     単語選択子と単語修飾子が始まるアドレス
		*      D0.W   イベントの単語数
		*      D2.L   単語選択子 % の単語番号（-1:該当なし）
		*      D7.W   展開バッファの容量
		*
		move.b	subst_status(a6),d3
		bset	#3,d3
		bclr	#4,d3
		tst.b	quick_modify(a6)
		beq	subst_hist_do_expand_3

		bset	#4,d3
subst_hist_do_expand_3:
		exg	d1,d7
		bsr	expand_history
		exg	d1,d7
		move.b	d0,subst_status(a6)
		btst	#2,d0
		bne	subst_history_fatal_error

		cmpi.b	#'{',braceflag(a6)
		bne	subst_history_loop

		cmpi.b	#'}',(a2)+
		beq	subst_history_loop

		subq.l	#1,a2
		btst.b	#1,subst_status(a6)
		bne	subst_history_loop

		lea	msg_subst,a0
		bsr	eputs
		bsr	syntax_error
		move.b	subst_status(a6),d0
		or.b	#%11,d0
		move.b	d0,subst_status(a6)
		bra	subst_history_loop
********************************
subst_history_not_histchar:
		cmp.w	#'\',d0
		bne	subst_history_dup_char

		addq.l	#1,a2
		move.w	histchar1(a5),d1
		bsr	compare_histchar
		beq	subst_history_dup_char

		subq.w	#1,d7
		bcs	subst_hist_over

		move.b	#'\',(a1)+
subst_history_dup_char:
		move.b	(a2)+,d0
		bsr	issjis
		bne	subst_history_dup1
subst_history_dup2:
		move.b	d0,(a1)+
		beq	subst_hist_done

		subq.w	#1,d7
		bcs	subst_hist_over

		move.b	(a2)+,d0
subst_history_dup1:
		move.b	d0,(a1)+
		beq	subst_hist_done

		subq.w	#1,d7
		bcc	subst_history_loop
subst_hist_over:
		btst.b	#1,subst_status(a6)
		bne	subst_history_fatal_error

		bsr	too_long_line
subst_history_fatal_error:
		move.b	subst_status(a6),d0
		or.b	#%111,d0
		move.b	d0,subst_status(a6)
		addq.l	#1,a1
subst_hist_done:
		subq.l	#1,a1
subst_history_return:
		lea	tmpgetlinebufp,a0
		bsr	xfreep
		movea.l	a2,a0
		move.w	d7,d1
		move.b	subst_status(a6),d0
		movem.l	(a7)+,d2-d7/a2-a4
		unlk	a6
		rts


overflow:
		btst.b	#1,subst_status(a6)
		bne	error

		move.b	(a2),d0
		clr.b	(a2)
		bsr	pre_perror
		move.b	d0,(a2)
		lea	msg_too_large_number,a0
		bsr	enputs
		bra	error

fail_n:
		btst.b	#1,subst_status(a6)
		bne	error

		link	a6,#-12
		lea	-12(a6),a0
		bsr	utoa
		bsr	eputs
		unlk	a6
		lea	msg_colon_blank,a0
		bsr	eputs
		bra	fail

no_prev_search:
		btst.b	#1,subst_status(a6)
		bne	error

		lea	msg_no_prev_search,a0
		bsr	enputs
		bra	error

fail_str:
		btst.b	#1,subst_status(a6)
		bne	error

		lea	prev_search(a5),a0
		bsr	pre_perror
fail:
		lea	msg_event_not_found,a0
		bsr	enputs
error:
		move.b	subst_status(a6),d0
		or.b	#%11,d0
		move.b	d0,subst_status(a6)
		lea	str_nul,a0
		moveq	#0,d0
		moveq	#-1,d2
		bra	subst_hist_do_expand_2
*****************************************************************
is_special_word_selecter:
		move.l	a0,-(a7)
		lea	special_word_selecters,a0
		bsr	jstrchr
		movea.l	(a7)+,a0
		rts
****************************************************************
get_wordno:
		moveq	#1,d1
		cmp.b	#'^',d0
		beq	get_wordno_return

		moveq	#-1,d1
		cmp.b	#'$',d0
		beq	get_wordno_return

		moveq	#-3,d1
		cmp.b	#'%',d0
		beq	get_wordno_return

		subq.l	#1,a0
		bsr	atou
		bmi	get_wordno_no_wordno
		bne	get_wordno_overflow

		cmp.l	#MAXWORDS,d1
		bls	get_wordno_return
get_wordno_overflow:
		move.l	#MAXWORDS,d1
get_wordno_return:
		rts

get_wordno_no_wordno:
		moveq	#-2,d1
		rts
****************************************************************
.data

.xdef msg_no_prev_search

special_word_selecters:		dc.b	'%'
special_word_selecters_2:	dc.b	'-*^$',0
msg_event_not_found:		dc.b	'イベントが見当たりません',0
msg_subst:			dc.b	'!置換の',0
msg_bad_word_selecter:		dc.b	'単語選択子が無効です',0
msg_no_prev_search:		dc.b	'検索文字列の記憶はありません',0
msg_modifier_failed:		dc.b	'文字列修正は起こりませんでした',0
msg_cannot_sharp:		dc.b	'!#を処理できません',0
****************************************************************

.end
