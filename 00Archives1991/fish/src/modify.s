* modify.s
* Itagaki Fumihiko 06-Mar-91  Create.

.include ../src/fish.h
.include ../src/modify.h

.xref isspace
.xref iscsym
.xref issjis
.xref isdigit
.xref scanchar2
.xref strlen
.xref strchr
.xref strcpy
.xref strbot
.xref for1str
.xref memmove_dec
.xref memmove_inc
.xref wordlistlen
.xref wordlistmem
.xref copy_wordlist
.xref hide_escape
.xref atou
.xref malloc
.xref eputs
.xref ecputc
.xref enputs
.xref eput_newline
.xref test_pathname
.xref cannot_because_no_memory
.xref msg_no_prev_search
.xref not_execute
.xref prev_search
.xref prev_lhs
.xref prev_rhs

.text

****************************************************************
is_not_subst_separator:
		tst.b	d0
		beq	is_not_subst_separator_return	* EQ

		cmp.w	#$100,d0
		bhi	is_not_subst_separator_return	* NE

		bsr	isspace
		beq	is_not_subst_separator_return	* EQ

		bsr	iscsym
		beq	is_not_subst_separator_return	* EQ

		cmp.b	#'}',d0
is_not_subst_separator_return:
		rts
****************************************************************
* modify - 単語並びを修飾する
*
* CALL
*      A0     単語並びの先頭アドレス
*      A1     修飾子のアドレス
*      D0.L   ステータス
*             bit 0 :  エラー・メッセージを表示しない
*             bit 8 :  !置換の修飾である
*             bit 9 :  ^str1^str2^flag^ である
*      D1.W   単語数
*
* RETURN
*      A0     修飾された単語並びの先頭アドレス
*      A1     修飾子の次のアドレス
*      D0.L   ステータス
*             bit 0 :  エラーがあり、メッセージを表示した
*             bit 1 :  単語リストが長くなり過ぎた（メッセージは表示しない）
*             bit 2 :  failした :s があった（メッセージは表示しない）
*             bit 3 :  :x があった
*             bit 4 :  :q があった
*             bit 5 :  :p があった
*             bit 6 :  A0 は malloc したものである
*             bit 7 :  メモリが足りない（メッセージを表示する）
*
* DESCRIPTION
*
*        :h                    パス名のドライブ＋ディレクトリ部分（最後の/は含まない）
*        :t                    パス名のファイル部分（拡張子を含む）
*        :r                    パス名の拡張子以外の部分
*        :e                    パス名の拡張子部分（.は含まない）
*        :d                    パス名のドライブ名部分（:は含まない）
*        :f                    パス名のドライブ名以外の部分
*        :s/<l>/<r>[/<f>]/     l を r に置換する
*        :&[<f>]               以前の置換を行う
*
*      !置換のみ
*        :p                    行を実行しない（ここでは認識するだけ）
*
*      !置換以外
*        :x                    単語をクオートする（ここでは認識するだけ）
*        :q                    単語並びをクオートする（ここでは認識するだけ）
*
****************************************************************
.xdef modify

modify:
		movem.l	d1-d7/a2-a4,-(a7)
		move.w	d1,d4				* D4.W : 単語数
		movea.l	a0,a4				* A4 : 単語並びのアドレス
		movea.l	a1,a3				* A3 : 修飾子のアドレス
		move.l	d0,d5				* D5.L : ステータス
		btst	#MODIFYSTATBIT_QUICK,d5
		bne	modify_subst
modify_loop:
		btst	#MODIFYSTATBIT_QUICK,d5
		bne	modify_done

		cmpi.b	#':',(a3)
		bne	modify_done

		addq.l	#1,a3
		tst.b	(a3)
		beq	modify_done

		cmpi.b	#'}',(a3)
		beq	modify_done

		exg	a0,a3
		bsr	scanchar2
		exg	a0,a3
		move.b	d0,d6
		lea	str_modifier_rhtedf,a0
		bsr	strchr
		bne	modify_pathname

		cmp.w	#'s',d0
		beq	modify_subst

		cmp.w	#'&',d0
		beq	modify_redo_subst

		btst	#MODIFYSTATBIT_HISTORY,d5
		bne	modify_history_modifyer

		cmp.w	#'x',d0
		beq	modify_xquote

		cmp.w	#'q',d0
		bne	bad_modifier
modify_quote:
		bset	#MODIFYSTATBIT_Q,d5
		bra	modify_loop

modify_xquote:
		bset	#MODIFYSTATBIT_X,d5
		bra	modify_loop

modify_history_modifyer:
		cmp.w	#'p',d0
		bne	bad_modifier
modify_print:
		bset	#MODIFYSTATBIT_P,d5
		bra	modify_loop

bad_modifier:
		btst	#MODIFYSTATBIT_ERROR,d5
		bne	modify_loop

		lea	msg_bad_modifier,a0
		bsr	eputs
		cmp.w	#$100,d0
		blo	bad_modifier_1

		move.w	d0,-(a7)
		lsr.w	#8,d0
		bsr	ecputc
		move.w	(a7)+,d0
bad_modifier_1:
		bsr	ecputc
		bsr	eput_newline
modify_error:
		bset	#MODIFYSTATBIT_ERROR,d5
		bra	modify_loop
****************
modify_pathname:
		bsr	modify_dup
		beq	modify_loop

		movea.l	a4,a0
		move.w	d4,d7
		movem.l	d1-d3/a1-a3,-(a7)
		bra	modify_pathname_continue

modify_pathname_loop:
		bsr	test_pathname
		cmp.b	#'e',d6
		beq	modify_extention

		cmp.b	#'t',d6
		beq	modify_tail

		cmp.b	#'f',d6
		beq	modify_file

		cmp.b	#'r',d6
		beq	modify_root

		cmp.b	#'h',d6
		beq	modify_head
modify_drive:
		sub.l	d1,d0
		beq	modify_pathname_cut_tail

		subq.l	#1,d0
		bra	modify_pathname_cut_tail

modify_root:
		add.l	d2,d0
		bra	modify_pathname_cut_tail

modify_head:
		tst.l	d0
		beq	modify_pathname_next

		subq.l	#1,d0
		cmpi.b	#'/',(a0,d0.l)
		beq	modify_pathname_cut_tail

		cmpi.b	#'\',(a0,d0.l)
		beq	modify_pathname_cut_tail

		addq.l	#1,d0
modify_pathname_cut_tail:
		lea	(a0,d0.l),a1
		bsr	for1str
		exg	a0,a1
		clr.b	(a0)+
		cmpa.l	a1,a0
		beq	modify_pathname_continue

		move.w	d7,d0
		bsr	copy_wordlist
		bra	modify_pathname_continue

modify_extention:
		movea.l	a3,a2
		tst.b	(a2)
		beq	modify_tail

		addq.l	#1,a2
modify_tail:
		movea.l	a2,a1
modify_file:
		cmpa.l	a0,a1
		beq	modify_pathname_next

		move.w	d7,d0
		addq.w	#1,d0
		bsr	copy_wordlist
modify_pathname_next:
		bsr	for1str
modify_pathname_continue:
		dbra	d7,modify_pathname_loop

		movem.l	(a7)+,d1-d3/a1-a3
		bra	modify_loop
****************
tmp_search_str = -(((MAXSEARCHLEN+1)+1)>>1<<1)
tmp_subst_str = tmp_search_str-(((MAXSUBSTLEN+1)+1)>>1<<1)
number = tmp_subst_str-4
time = number-4
search_pointer = time-4
search_counter = search_pointer-2
global = search_counter-1
special_pattern = global-1
pad = special_pattern			* 偶数バウンダリに合わせる

modify_redo_subst:
		link	a6,#pad
		clr.l	number(a6)
		clr.b	global(a6)
		movea.l	a3,a0
		movea.l	a0,a1
		bsr	scanchar2
		cmp.w	#$100,d0
		bhs	modify_redo_subst_no_option

		cmp.b	#'g',d0
		beq	modify_redo_subst_option_g

		bsr	isdigit
		bne	modify_redo_subst_no_option

		movea.l	a1,a0
		bsr	get_subst_number_option
		bra	modify_redo_subst_get_option_ok

modify_redo_subst_option_g:
		move.b	#1,global(a6)
		bra	modify_redo_subst_get_option_ok

modify_redo_subst_no_option:
		movea.l	a1,a0
modify_redo_subst_get_option_ok:
		movea.l	a0,a3

		bsr	modify_dup
		beq	modify_subst_done

		lea	prev_rhs,a2
		lea	prev_lhs,a1
		movea.l	a1,a0
		bsr	strlen
		move.l	d0,d1
		beq	no_prev_sub

		bsr	is_special_pattern
		bra	modify_subst_start

no_prev_sub:
		lea	msg_no_prev_sub,a0
		bra	modify_subst_errorp
****************
modify_subst:
		link	a6,#pad
		exg	a0,a3
		*  区切り文字を拾う
		movea.l	a0,a1
		bsr	scanchar2			* D0.W : 区切り文字
		bsr	is_not_subst_separator
		bne	modify_subst_ok

		movea.l	a1,a3
		lea	msg_bad_substitute,a0
		bra	modify_subst_errorp

modify_subst_ok:
		*  検索文字列を拾う
		lea	tmp_search_str(a6),a1
		moveq	#MAXSEARCHLEN+1,d1
		bsr	scan_subst_str
		move.l	d1,d2				* D2.L : MAXSEARCHLEN+1-strlen(l)
		*  置換文字列を拾う
		lea	tmp_subst_str(a6),a1
		moveq	#MAXSUBSTLEN+1,d1
		bsr	scan_subst_str
		move.l	d1,d3				* D3.L : MAXSUBSTLEN+1-strlen(r)
		*  オプションフラグを拾う
		clr.l	number(a6)
		clr.b	global(a6)
		move.w	d0,d1				* D1.W : 区切り文字
		movea.l	a0,a1
		bsr	scanchar2
		cmp.w	d1,d0
		beq	modify_subst_get_option_done

		cmp.w	#$100,d0
		bhs	modify_subst_get_option_eos

		cmp.b	#'g',d0
		beq	modify_subst_got_option_g

		bsr	isdigit
		bne	modify_subst_get_option_eos

		movea.l	a1,a0
		bsr	get_subst_number_option
		bra	modify_subst_get_option_ok

modify_subst_got_option_g:
		move.b	#1,global(a6)
modify_subst_get_option_ok:
		movea.l	a0,a1
		bsr	scanchar2
		cmp.w	d1,d0
		beq	modify_subst_get_option_done
modify_subst_get_option_eos:
		movea.l	a1,a0
modify_subst_get_option_done:
		exg	a0,a3
		*
		*
		tst.l	d2
		beq	modify_lhs_too_long		* Lhs too long

		clr.b	special_pattern(a6)
		lea	tmp_search_str(a6),a1
		tst.b	(a1)
		beq	modify_search_prev

		bsr	is_special_pattern
		beq	modify_lhs_ok

		exg	a0,a1
		bsr	hide_escape
		bsr	strlen
		exg	a0,a1
		move.l	d0,d1				* D1.L : 検索文字列の長さ
		lea	prev_search,a0
		bsr	strcpy
		bra	modify_lhs_ok

modify_search_prev:
		lea	prev_search,a1
		exg	a0,a1
		bsr	strlen
		exg	a0,a1
		move.l	d0,d1
		beq	modify_no_prev_search		* No prev search
modify_lhs_ok:
		tst.l	d3
		beq	modify_rhs_too_long		* Rhs too long

		lea	tmp_subst_str(a6),a2
		cmpi.b	#'%',(a2)
		bne	modify_rhs_ok

		tst.b	1(a2)
		bne	modify_rhs_ok

		lea	prev_rhs,a2
modify_rhs_ok:
		lea	prev_lhs,a0
		bsr	strcpy
		exg	a1,a2
		lea	prev_rhs,a0
		bsr	strcpy
		exg	a1,a2
modify_subst_start:
		cmp.l	#-1,number(a6)
		beq	modify_modifier_failed		* Modifier failed

		bsr	modify_dup
		beq	modify_subst_done

		move.w	d4,d0
		movea.l	a4,a0
		bsr	modify_subst_search
		tst.w	d0
		beq	modify_modifier_failed		* Modifier failed

		move.w	d0,-(a7)
		*  何バイト増えるかをD2.Lに求める
		moveq	#0,d2
		move.l	a2,-(a7)
modify_subst_count_replace:
		move.b	(a2)+,d0
		beq	modify_subst_count_replace_done

		cmp.b	#'&',d0
		beq	modify_subst_count_replace_ampersand

		cmp.b	#'\',d0
		bne	modify_subst_count_replace_char

		move.b	(a2)+,d0
		beq	modify_subst_count_replace_done
modify_subst_count_replace_char:
		addq.l	#1,d2
		bsr	issjis
		bne	modify_subst_count_replace

		move.b	(a2)+,d0
		beq	modify_subst_count_replace_done

		addq.l	#1,d2
		bra	modify_subst_count_replace

modify_subst_count_replace_ampersand:
		add.l	d1,d2
		bra	modify_subst_count_replace

modify_subst_count_replace_done:
		movea.l	(a7)+,a2
		sub.l	d1,d2				* D2.L : 増加する文字数
		move.w	d4,d0
		exg	a0,a4
		bsr	wordlistlen
		exg	a0,a4
		move.l	d0,d3				* D3.L : 現在の単語リストのバイト数
		move.w	(a7)+,d0
		clr.l	time(a6)
modify_subst_loop:
		move.l	a0,d6				* D6 : 置換されるべき場所
		move.w	d0,search_counter(a6)
		adda.l	d1,a0
		move.l	a0,search_pointer(a6)

		tst.l	number(a6)
		beq	modify_subst_number_ok

		addq.l	#1,time(a6)
		move.l	time(a6),d0
		cmp.l	number(a6),d0
		bne	modify_subst_next
modify_subst_number_ok:
		tst.l	d2
		bmi	modify_subst_store		* 減る
		beq	modify_subst_store		* 同じ

		*  増える .. キャパシティーをチェックする
		move.l	d3,d0
		add.l	d2,d0
		cmp.l	#MAXWORDLISTSIZE,d0
		bhi	modify_overflow			*  ERROR - Subst buf ovflo

		*  増える分だけ中身をずらしておいてから
		*        D6+D1    .. A4+D3-1
		*    ->  D6+D1+D2 .. A4+D3-1+D2
		move.l	a1,-(a7)
		lea	(a4,d3.l),a1
		lea	(a1,d2.l),a0
		move.l	a1,d0
		sub.l	d6,d0
		sub.l	d1,d0
		bsr	memmove_dec
		movea.l	(a7)+,a1
****************
modify_subst_store:
		*  置換文字列を置く
		movea.l	d6,a0
		move.l	a2,-(a7)
modify_subst_store_loop:
		move.b	(a2)+,d0
		beq	modify_subst_store_done

		cmp.b	#'&',d0
		beq	modify_subst_store_ampersand

		cmp.b	#'\',d0
		bne	modify_subst_store_char

		move.b	(a2)+,d0
		beq	modify_subst_store_done
modify_subst_store_char:
		move.b	d0,(a0)+
		bsr	issjis
		bne	modify_subst_store_continue

		move.b	(a2)+,d0
		beq	modify_subst_store_done

		move.b	d0,(a0)+
		bra	modify_subst_store_continue

modify_subst_store_ampersand:
		move.l	d1,d0
		move.l	a1,-(a7)
		bsr	memmove_inc
		movea.l	(a7)+,a1
modify_subst_store_continue:
		bra	modify_subst_store_loop

modify_subst_store_done:
		movea.l	(a7)+,a2
****************
		*  D2.L が負ならば -D2.L 文字空いているので、切り詰める
		move.l	d2,d0
		bpl	modify_subst_doneone

		move.l	a1,-(a7)
		neg.l	d0
		lea	(a0,d0.l),a1
		move.l	a1,d0
		sub.l	a4,d0
		sub.l	d3,d0
		neg.l	d0
		bsr	memmove_inc
		movea.l	(a7)+,a1
modify_subst_doneone:
		tst.b	global(a6)
		beq	modify_subst_done

		add.l	d2,d3
		movea.l	search_pointer(a6),a0
		adda.l	d2,a0
		move.l	a0,search_pointer(a6)
modify_subst_next:
		move.w	search_counter(a6),d0
		bsr	modify_subst_search_next
		tst.w	d0
		bne	modify_subst_loop

		tst.l	number(a6)
		beq	modify_subst_done
modify_modifier_failed:
		bset	#MODIFYSTATBIT_FAILED,d5
modify_subst_done:
		unlk	a6
		bra	modify_loop

modify_lhs_too_long:
		lea	msg_lhs_too_long,a0
		bra	modify_subst_errorp

modify_rhs_too_long:
		lea	msg_rhs_too_long,a0
		bra	modify_subst_errorp

modify_no_prev_search:
		lea	msg_no_prev_search,a0
modify_subst_errorp:
		btst	#MODIFYSTATBIT_ERROR,d5
		bne	modify_subst_done

		bsr	enputs
		bset	#MODIFYSTATBIT_ERROR,d5
		bra	modify_subst_done

modify_overflow:
		bset	#MODIFYSTATBIT_OVFLO,d5
		bra	modify_subst_done
****************
modify_done:
		movea.l	a3,a1
		movea.l	a4,a0
		move.l	d5,d0
		movem.l	(a7)+,d1-d7/a2-a4
		rts
****************************************************************
is_special_pattern:
		tst.b	1(a1)
		bne	is_special_pattern_return

		move.b	(a1),d0
		cmp.b	#'^',d0
		beq	is_special_pattern_true

		cmp.b	#'$',d0
		bne	is_special_pattern_return
is_special_pattern_true:
		move.b	d0,special_pattern(a6)
		moveq	#0,d1
is_special_pattern_return:
		rts
****************************************************************
modify_subst_search_next:
		tst.b	special_pattern(a6)
		beq	modify_subst_search

		bsr	for1str
		subq.w	#1,d0
modify_subst_search:
		move.l	d2,-(a7)
		tst.w	d0
		beq	modify_subst_search_return

		cmpi.b	#'^',special_pattern(a6)
		beq	modify_subst_search_return

		cmpi.b	#'$',special_pattern(a6)
		beq	modify_subst_search_tail

		tst.b	(a1)
		beq	modify_subst_search_fail

		moveq	#0,d2
		bsr	wordlistmem
		bra	modify_subst_search_return

modify_subst_search_fail:
		moveq	#0,d0
		bra	modify_subst_search_return

modify_subst_search_tail:
		bsr	strbot
modify_subst_search_return:
		move.l	(a7)+,d2
		rts
****************************************************************
modify_dup:
		tst.b	not_execute
		bne	modify_dup_fail_2

		btst	#MODIFYSTATBIT_MALLOC,d5
		bne	modify_dup_ok

		btst	#MODIFYSTATBIT_NOMEM,d5
		bne	modify_dup_fail_1

		move.l	#MAXWORDLISTSIZE,d0
		bsr	malloc
		beq	modify_dup_fail

		bclr	#MODIFYSTATBIT_NOMEM,d5
		bset	#MODIFYSTATBIT_MALLOC,d5
		movem.l	a0-a1,-(a7)
		movea.l	d0,a0
		movea.l	a4,a1
		move.w	d4,d0
		bsr	copy_wordlist
		movea.l	a0,a4
		movem.l	(a7)+,a0-a1
modify_dup_ok:
		move.l	a4,d0
		rts

modify_dup_fail:
		lea	msg_cannot_modify,a0
		bsr	cannot_because_no_memory
		bset	#MODIFYSTATBIT_ERROR,d5
modify_dup_fail_1:
		bset	#MODIFYSTATBIT_NOMEM,d5
modify_dup_fail_2:
		moveq	#0,d0
		rts
****************************************************************
scan_subst_str:
		movem.l	d2/a2,-(a7)
		move.w	d0,d2
scan_subst_str_loop:
		movea.l	a0,a2
		bsr	scanchar2
		cmp.w	d2,d0
		beq	scan_subst_str_done

		cmp.w	#'}',d0
		beq	scan_subst_str_eos

		cmp.w	#'\',d0
		bne	scan_subst_str_dup

		bsr	scanchar2
		tst.l	d1
		beq	scan_subst_str_loop

		move.b	#'\',(a1)+
		subq.l	#1,d1
scan_subst_str_dup:
		cmp.w	#$100,d0
		blo	scan_subst_str_dup1

		tst.l	d1
		beq	scan_subst_str_loop

		ror.w	#8,d0
		move.b	d0,(a1)+
		subq.l	#1,d1
		rol.w	#8,d0
scan_subst_str_dup1:
		tst.b	d0
		beq	scan_subst_str_eos

		tst.l	d1
		beq	scan_subst_str_loop

		move.b	d0,(a1)+
		subq.l	#1,d1
		bra	scan_subst_str_loop

scan_subst_str_eos:
		subq.l	#1,a0
scan_subst_str_done:
		move.w	d2,d0
		tst.l	d1
		beq	scan_subst_str_return

		clr.b	(a1)
scan_subst_str_return:
		movem.l	(a7)+,d2/a2
		rts
****************************************************************
get_subst_number_option:
		move.w	d1,-(a7)
		bsr	atou
		bne	bad_number_opt

		tst.l	d1
		bne	number_opt_ok
bad_number_opt:
		moveq	#-1,d1
number_opt_ok:
		move.l	d1,number(a6)
		move.w	(a7)+,d1
		rts
****************************************************************
.data

str_modifier_rhtedf:	dc.b	'rhtedf',0
msg_bad_modifier:	dc.b	'無効な修飾子 :',0
msg_bad_substitute:	dc.b	':sの区切り文字が無効です',0
msg_lhs_too_long:	dc.b	'文字列修正の検索文字列が長過ぎます',0
msg_rhs_too_long:	dc.b	'文字列修正の置換文字列が長過ぎます',0
msg_no_prev_sub:	dc.b	'文字列修正の記憶はありません',0
msg_cannot_modify:	dc.b	':修飾ができません',0
****************************************************************

.end
