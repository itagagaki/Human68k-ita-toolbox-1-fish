* modify.s
* Itagaki Fumihiko 06-Mar-91  Create.

.include ../src/fish.h
.include ../src/modify.h

.xref islower
.xref isupper
.xref isdigit
.xref isspace2
.xref issjis
.xref tolower
.xref toupper
.xref scanchar2
.xref strlen
.xref strchr
.xref strcpy
.xref strbot
.xref strfor1
.xref memmovd
.xref memmovi
.xref wordlistlen
.xref wordlistmem
.xref copy_wordlist
.xref hide_escape
.xref suffix
.xref split_pathname
.xref atou
.xref xmalloc
.xref eputs
.xref ecputc
.xref enputs
.xref eput_newline
.xref cannot_because_no_memory
.xref msg_no_prev_search

.xref prev_search
.xref prev_lhs
.xref prev_rhs
.xref not_execute

.text

****************************************************************
is_illegal_subst_separator:
		tst.b	d0
		beq	is_illegal_subst_separator_return	* EQ

		cmp.w	#$100,d0
		bhi	is_illegal_subst_separator_return	* NE

		jsr	isspace2
		beq	is_illegal_subst_separator_return	* EQ

		cmp.b	#'}',d0
is_illegal_subst_separator_return:
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
*        :l                    ASCII大文字を小文字に変換する
*        :u                    ASCII小文字を大文字に変換する
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

OPTBIT_G = 0
OPTBIT_A = 1
OPTBIT_SG = 2

tmp_search_str = -(((MAXSEARCHLEN+1)+1)>>1<<1)
tmp_subst_str = tmp_search_str-(((MAXSUBSTLEN+1)+1)>>1<<1)
number = tmp_subst_str-4
time = number-4
search_pointer = time-4
search_counter = search_pointer-2
special_pattern = search_counter-1
option = special_pattern-1
pad = option-0

modify:
		link	a6,#pad
		movem.l	d1-d7/a2-a4,-(a7)
		move.w	d1,d4				* D4.W : 単語数
		movea.l	a0,a4				* A4 : 単語並びのアドレス
		movea.l	a1,a3				* A3 : 修飾子のアドレス
		move.l	d0,d5				* D5.L : ステータス
		clr.b	option(a6)
		btst	#MODIFYSTATBIT_QUICK,d5
		bne	modify_subst
modify_loop:
		cmpi.b	#':',(a3)
		bne	modify_done

		addq.l	#1,a3
		clr.b	option(a6)
option_loop:
		tst.b	(a3)
		beq	modify_done

		cmpi.b	#'}',(a3)
		beq	modify_done

		exg	a0,a3
		bsr	scanchar2
		exg	a0,a3
		cmp.w	#$100,d0
		bhs	bad_modifier

		cmp.b	#'g',d0
		bne	modify_no_g
		*{
			bset	#OPTBIT_G,option(a6)
			bra	option_loop
		*}
modify_no_g:
		cmp.b	#'a',d0
		bne	modify_no_a
		*{
			bset	#OPTBIT_A,option(a6)
			bra	option_loop
		*}
modify_no_a:
		move.b	d0,d6
		lea	str_modifier_rhtedflu,a0
		jsr	strchr				*  str_modifier_rhtedflu にはシフトJIS文字は無い
		bne	modify_simple

		cmp.b	#'s',d0
		beq	modify_subst

		cmp.b	#'&',d0
		beq	modify_redo_subst

		btst	#MODIFYSTATBIT_HISTORY,d5
		bne	modify_history_modifyer

		cmp.b	#'x',d0
		beq	modify_xquote

		cmp.b	#'q',d0
		bne	bad_modifier
modify_quote:
		bset	#MODIFYSTATBIT_Q,d5
		bra	modify_loop

modify_xquote:
		bset	#MODIFYSTATBIT_X,d5
		bra	modify_loop

modify_history_modifyer:
		cmp.b	#'p',d0
		bne	bad_modifier
modify_print:
		bset	#MODIFYSTATBIT_P,d5
		bra	modify_loop

bad_modifier:
		btst	#MODIFYSTATBIT_ERROR,d5
		bne	modify_loop

		lea	msg_bad_modifier,a0
		jsr	eputs
		cmp.w	#$100,d0
		blo	bad_modifier_1

		move.w	d0,-(a7)
		lsr.w	#8,d0
		jsr	ecputc
		move.w	(a7)+,d0
bad_modifier_1:
		jsr	ecputc
		jsr	eput_newline
modify_error:
		bset	#MODIFYSTATBIT_ERROR,d5
		bra	modify_loop
****************
modify_simple:
		tst.w	d4
		beq	modify_loop

		bsr	modify_dup
		beq	modify_loop

		movea.l	a4,a0
		move.w	d4,d7
		subq.w	#1,d7
		movem.l	d1-d3/a1-a4,-(a7)
modify_simple_loop:
		movea.l	a0,a4
		jsr	strfor1
		exg	a0,a4				*  A4 : 次の単語の先頭アドレス

		lea	isupper(pc),a1
		lea	tolower(pc),a2
		cmp.b	#'l',d6
		beq	modify_chcase

		lea	islower(pc),a1
		lea	toupper(pc),a2
		cmp.b	#'u',d6
		beq	modify_chcase

		cmp.b	#'r',d6
		beq	modify_root

		bsr	split_pathname
		cmp.b	#'h',d6
		beq	modify_head

		cmp.b	#'t',d6
		beq	modify_tail

		cmp.b	#'e',d6
		beq	modify_extention

		cmp.b	#'f',d6
		beq	modify_file
****************
modify_drive:
		cmpa.l	a0,a1
		beq	modify_simple_cut_tail

		subq.l	#1,a1
modify_simple_cut_tail:
		movea.l	a1,a0
		clr.b	(a0)+
		cmpa.l	a4,a0
		beq	modify_simple_continue

		movea.l	a4,a1
		move.w	d7,d0
		jsr	copy_wordlist
		bra	modify_simple_continue
****************
modify_root:
		movea.l	a0,a1
		bsr	suffix
		exg	a0,a1
		beq	modify_simple_cut_tail

		btst.b	#OPTBIT_A,option(a6)
		beq	modify_simple_cut_tail

		clr.b	(a1)
		bra	modify_root
****************
modify_head:
		tst.l	d1
		beq	modify_head_skip
modify_head_0:
		lea	-1(a2),a1
		btst.b	#OPTBIT_A,option(a6)
		beq	modify_simple_cut_tail

		clr.b	(a1)
		move.l	a1,-(a7)
		bsr	split_pathname
		movea.l	(a7)+,a1
		tst.l	d1
		beq	modify_simple_cut_tail
		bra	modify_head_0

modify_head_skip:
		movea.l	a4,a0
		dbra	d7,modify_simple_loop
		bra	modify_simple_done
****************
modify_extention:
		movea.l	a3,a2
		tst.b	(a2)
		beq	modify_tail

		addq.l	#1,a2
****************
modify_tail:
		movea.l	a2,a1
****************
modify_file:
		cmpa.l	a0,a1
		beq	modify_simple_skip

		move.w	d7,d0
		addq.w	#1,d0
		jsr	copy_wordlist
		jsr	strfor1
		bra	modify_simple_continue
****************
modify_chcase:
		move.b	(a0)+,d0
		beq	modify_simple_continue

		jsr	issjis
		beq	modify_chcase_sjis

		jsr	(a1)
		bne	modify_chcase

		jsr	(a2)
		move.b	d0,-1(a0)
		btst.b	#OPTBIT_A,option(a6)
		bne	modify_chcase
modify_simple_skip:
		movea.l	a4,a0
		bra	modify_simple_continue

modify_chcase_sjis:
		tst.b	(a0)+
		bne	modify_chcase
modify_simple_continue:
		btst.b	#OPTBIT_G,option(a6)
		dbeq	d7,modify_simple_loop
modify_simple_done:
		movem.l	(a7)+,d1-d3/a1-a4
		bra	modify_loop
****************
modify_redo_subst:
		movea.l	a3,a0
		clr.l	number(a6)
		movea.l	a0,a1
		bsr	scanchar2
		bsr	get_subst_option
		movea.l	a0,a3
		bsr	modify_dup
		beq	modify_subst_done

		lea	prev_rhs(a5),a2
		lea	prev_lhs(a5),a1
		movea.l	a1,a0
		jsr	strlen
		move.l	d0,d1
		beq	no_prev_sub

		bsr	is_special_pattern
		bra	modify_subst_start

no_prev_sub:
		lea	msg_no_prev_sub,a0
		bra	modify_subst_errorp
****************
modify_subst:
		exg	a0,a3
		*  区切り文字を拾う
		movea.l	a0,a1
		bsr	scanchar2			* D0.W : 区切り文字
		bsr	is_illegal_subst_separator
		bne	modify_subst_ok

		movea.l	a1,a3
		lea	msg_bad_substitute,a0
		bra	modify_subst_errorp

modify_subst_ok:
		*
		*  検索文字列を拾う
		*
		lea	tmp_search_str(a6),a1
		moveq	#MAXSEARCHLEN+1,d1
		bsr	scan_subst_str
		move.l	d1,d2				* D2.L : MAXSEARCHLEN+1-strlen(l)
		*
		*  置換文字列を拾う
		*
		lea	tmp_subst_str(a6),a1
		moveq	#MAXSUBSTLEN+1,d1
		bsr	scan_subst_str
		move.l	d1,d3				* D3.L : MAXSUBSTLEN+1-strlen(r)
		*
		*  オプションフラグを拾う
		*
		move.w	d0,d1				* D1.W : 区切り文字

		clr.l	number(a6)
		movea.l	a0,a1
		bsr	scanchar2
		cmp.w	d1,d0
		beq	modify_subst_get_option_done

		bsr	get_subst_option
		bne	modify_subst_get_option_done

		movea.l	a0,a1
		bsr	scanchar2
		cmp.w	d1,d0
		beq	modify_subst_get_option_done

		movea.l	a1,a0
modify_subst_get_option_done:
		exg	a0,a3
		*
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
		jsr	hide_escape
		jsr	strlen
		exg	a0,a1
		move.l	d0,d1				* D1.L : 検索文字列の長さ
		lea	prev_search(a5),a0
		jsr	strcpy
		bra	modify_lhs_ok

modify_search_prev:
		lea	prev_search(a5),a1
		exg	a0,a1
		jsr	strlen
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

		lea	prev_rhs(a5),a2
modify_rhs_ok:
		lea	prev_lhs(a5),a0
		jsr	strcpy
		exg	a1,a2
		lea	prev_rhs(a5),a0
		jsr	strcpy
		exg	a1,a2
modify_subst_start:
		*
		*  1回目の検索
		*
		tst.l	number(a6)
		bmi	modify_modifier_failed

		bsr	modify_dup
		beq	modify_subst_done

		move.w	d4,d0
		movea.l	a4,a0
		bsr	modify_subst_search
		beq	modify_modifier_failed

		move.w	d0,-(a7)
		*
		*  1回の置換で何バイト増えるかを D2.L に求めておく
		*
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
		jsr	issjis
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
		jsr	wordlistlen
		exg	a0,a4
		move.l	d0,d3				* D3.L : 現在の単語リストのバイト数
		*
		move.w	(a7)+,d0
		*
		*  置換開始
		*
		clr.l	time(a6)
modify_subst_loop:
		move.l	a0,d6				* D6 : 置換されるべき場所
		move.w	d0,search_counter(a6)
		adda.l	d1,a0
		move.l	a0,search_pointer(a6)

		tst.l	number(a6)
		beq	modify_subst_do_replace		*  番号指定なし

		addq.l	#1,time(a6)
		move.l	time(a6),d0
		cmp.l	number(a6),d0
		bne	modify_subst_next		*  指定番号に一致せず
modify_subst_do_replace:
		*
		*  D2.L が 1以上ならば D2.L バイト増える
		*
		*  キャパシティをチェックする
		*
		*  増える分だけ中身をずらしておく
		*        D6+D1    .. A4+D3-1
		*    ->  D6+D1+D2 .. A4+D3-1+D2
		*
		tst.l	d2
		bmi	modify_subst_store		* 減る
		beq	modify_subst_store		* 同じ

		move.l	d3,d0
		add.l	d2,d0
		cmp.l	#MAXWORDLISTSIZE,d0
		bhi	modify_overflow			*  ERROR - Subst buf ovflo

		move.l	a1,-(a7)
		lea	(a4,d3.l),a1
		lea	(a1,d2.l),a0
		move.l	a1,d0
		sub.l	d6,d0
		sub.l	d1,d0
		bsr	memmovd
		movea.l	(a7)+,a1
modify_subst_store:
		*
		*  置換文字列を置く
		*
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
		jsr	issjis
		bne	modify_subst_store_continue

		move.b	(a2)+,d0
		beq	modify_subst_store_done

		move.b	d0,(a0)+
		bra	modify_subst_store_continue

modify_subst_store_ampersand:
		move.l	d1,d0
		move.l	a1,-(a7)
		jsr	memmovi
		movea.l	(a7)+,a1
modify_subst_store_continue:
		bra	modify_subst_store_loop

modify_subst_store_done:
		movea.l	(a7)+,a2
		*
		*  D2.L が負ならば -D2.L 文字空いている ... 切り詰める
		*
		move.l	d2,d0
		bpl	modify_subst_done_replace

		move.l	a1,-(a7)
		neg.l	d0
		lea	(a0,d0.l),a1
		move.l	a1,d0
		sub.l	a4,d0
		sub.l	d3,d0
		neg.l	d0
		jsr	memmovi
		movea.l	(a7)+,a1
modify_subst_done_replace:
		tst.l	number(a6)
		bne	modify_subst_done		*  指定番の置換は果たした

		add.l	d2,d3
		movea.l	search_pointer(a6),a0
		adda.l	d2,a0
		move.l	a0,search_pointer(a6)
modify_subst_next:
		move.w	search_counter(a6),d0

		tst.b	special_pattern(a6)
		bne	modify_subst_skip_current_word

		tst.l	number(a6)
		bne	modify_subst_ready_next

		btst.b	#OPTBIT_SG,option(a6)
		bne	modify_subst_ready_next

		btst.b	#OPTBIT_A,option(a6)
		bne	modify_subst_ready_next
modify_subst_skip_current_word:
		*  現在の単語をスキップして次の単語に進む
		jsr	strfor1
		subq.w	#1,d0
modify_subst_ready_next:
		tst.l	number(a6)
		bne	modify_subst_continue

		btst.b	#OPTBIT_SG,option(a6)
		bne	modify_subst_continue

		btst.b	#OPTBIT_G,option(a6)
		bne	modify_subst_continue

		btst.b	#OPTBIT_A,option(a6)
		beq	modify_subst_done

		cmp.w	search_counter(a6),d0
		bne	modify_subst_done

		moveq	#1,d0
modify_subst_continue:
		bsr	modify_subst_search
		bne	modify_subst_loop

		tst.l	number(a6)
		beq	modify_subst_done
modify_modifier_failed:
		bset	#MODIFYSTATBIT_FAILED,d5
modify_subst_done:
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

		jsr	enputs
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
		unlk	a6
		rts
****************************************************************
is_special_pattern:
		clr.b	special_pattern(a6)
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
		move.w	d0,-(a7)
		jsr	strbot
		move.w	(a7)+,d0
modify_subst_search_return:
		move.l	(a7)+,d2
		tst.w	d0
		rts
****************************************************************
modify_dup:
		tst.b	not_execute(a5)
		bne	modify_dup_fail_2

		btst	#MODIFYSTATBIT_MALLOC,d5
		bne	modify_dup_ok

		btst	#MODIFYSTATBIT_NOMEM,d5
		bne	modify_dup_fail_1

		move.l	#MAXWORDLISTSIZE,d0
		jsr	xmalloc
		beq	modify_dup_fail

		bclr	#MODIFYSTATBIT_NOMEM,d5
		bset	#MODIFYSTATBIT_MALLOC,d5
		movem.l	a0-a1,-(a7)
		movea.l	d0,a0
		movea.l	a4,a1
		move.w	d4,d0
		jsr	copy_wordlist
		movea.l	a0,a4
		movem.l	(a7)+,a0-a1
modify_dup_ok:
		move.l	a4,d0
		rts

modify_dup_fail:
		lea	msg_cannot_modify,a0
		jsr	cannot_because_no_memory
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
get_subst_option:
		cmp.w	#$ff,d0
		bhi	get_subst_option_fail		*  NE

		cmp.b	#'g',d0
		beq	get_subst_option_g

		bsr	isdigit
		bne	get_subst_option_fail		*  NE

		movea.l	a1,a0
		move.w	d1,-(a7)
		jsr	atou
		bne	bad_number_opt			*  overflow または no digit

		tst.l	d1
		bne	number_opt_ok
bad_number_opt:
		moveq	#-1,d1
number_opt_ok:
		move.l	d1,number(a6)
		move.w	(a7)+,d1
get_subst_option_return_eq:
		cmp.w	d0,d0				*  EQ
		rts

get_subst_option_g:
		bset.b	#OPTBIT_SG,option(a6)
		bra	get_subst_option_return_eq

get_subst_option_fail:
		movea.l	a1,a0
		rts
****************************************************************
.data

str_modifier_rhtedflu:	dc.b	'rhtedflu',0
msg_bad_modifier:	dc.b	'無効な修飾子 :',0
msg_bad_substitute:	dc.b	':sの区切り文字が無効です',0
msg_lhs_too_long:	dc.b	'文字列修正の検索文字列が長過ぎます',0
msg_rhs_too_long:	dc.b	'文字列修正の置換文字列が長過ぎます',0
msg_no_prev_sub:	dc.b	'文字列修正の記憶はありません',0
msg_cannot_modify:	dc.b	':修飾ができません',0
****************************************************************

.end
