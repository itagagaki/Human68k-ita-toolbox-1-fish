* substdir.s
* Itagaki Fumihiko 23-Sep-90  Create.

.include limits.h
.include pwd.h
.include ../src/fish.h
.include ../src/dirstack.h

.xref isdigit
.xref iscsym
.xref issjis
.xref toupper
.xref atou
.xref strchr
.xref strlen
.xref strfor1
.xref strforn
.xref strmove
.xref memmovi
.xref xmalloct
.xref freet
.xref get_1char
.xref no_close_brace
.xref drvchk
.xref getcdd
.xref open_passwd
.xref fgetpwnam
.xref close_tmpfd
.xref get_dstack_d0
.xref search_command_0
.xref get_shellvar
.xref is_nul_or_slash_or_backslash
.xref is_slash_or_backslash
.xref pre_perror
.xref perror
.xref eputs
.xref ecputs
.xref enputs
.xref perror_command_name
.xref command_error
.xref too_long_word
.xref too_long_line
.xref too_many_words
.xref cannot_because_no_memory
.xref dstack_not_deep

.xref word_home
.xref characters_to_be_escaped_3
.xref msg_is
.xref msg_not_found

.xref subst_tmpword1
.xref subst_tmpword2
.xref tmppwline
.xref tmppwbuf
.xref pathname_buf

.xref tmpline
.xref dirstack
.xref tmpfd
.xref cwd

.xref flag_noglob
.xref flag_nonomatch
.xref flag_refersysroot
.xref flag_symlinks

.text

****************************************************************
* bqstrchr - 文字列からある文字を探し出す．
*           但し ' " ` の対の中の文字と \ の直後の文字は無視する．
*           また，{} の中は無視する．
*           ' " ` \ { } を探すことはできる．
*           シフトＪＩＳ文字を探すことはできない．
*
* CALL
*      A0     文字列の先頭アドレス
*      D0.B   検索文字
*
* RETURN
*      A0     見つかったアドレス
*             見つからなかった場合には NUL を指す
*      D1.B   検索文字までの間に {} が 1つでもあれば $FF, 無ければ 0
*      CCR    TST.B (A0)
*****************************************************************
bqstrchr:
		movem.l	d0/d2-d4,-(a7)
		sf	d1				*  D1.L : {} フラグ
		move.b	d0,d2				*  D2.B : 検索文字
		moveq	#0,d3				*  D3.L : {} ネスト・レベル
		clr.b	d4				*  D4.B : クオート・フラグ
bqstrchr_loop:
		move.b	(a0)+,d0
		beq	bqstrchr_done

		jsr	issjis
		beq	bqstrchr_skip_one

		tst.b	d4
		beq	bqstrchr_1

		cmp.b	d4,d0
		bne	bqstrchr_loop
bqstrchr_flip_quote:
		eor.b	d0,d4
		bra	bqstrchr_loop

bqstrchr_1:
		tst.l	d3
		beq	bqstrchr_2

		cmp.b	#'}',d0
		bne	bqstrchr_3

		subq.l	#1,d3
		bra	bqstrchr_loop

bqstrchr_open_brace:
		addq.l	#1,d3
		st	d1
		bra	bqstrchr_loop

bqstrchr_2:
		cmp.b	d2,d0
		beq	bqstrchr_done
bqstrchr_3:
		cmp.b	#'{',d0
		beq	bqstrchr_open_brace

		cmp.b	#'"',d0
		beq	bqstrchr_flip_quote

		cmp.b	#"'",d0
		beq	bqstrchr_flip_quote

		cmp.b	#'`',d0
		beq	bqstrchr_flip_quote

		cmp.b	#'\',d0
		bne	bqstrchr_loop

		move.b	(a0)+,d0
		beq	bqstrchr_done

		jsr	issjis
		bne	bqstrchr_loop
bqstrchr_skip_one:
		tst.b	(a0)+
		bne	bqstrchr_loop
bqstrchr_done:
		subq.l	#1,a0
		movem.l	(a7)+,d0/d2-d4
		tst.b	(a0)
		rts
****************************************************************
* unpack - unpack_word の再帰部分
*
* CALL
*      A0     展開文字列の先頭
*             ', " and/or \ によるクオートが可
*             長さは MAXWORDLEN 以内であること
*
*      A1     展開バッファの位置
*      A2     現在までの展開途中結果の先頭
*      D5.W   これまでに展開した語数
*      D6.L   展開するバッファの残り容量
*      D7.W   展開する個数の限度
*
* RETURN
*      D0.L    0  成功
*            $FF  成功だが，更に展開する必要がある
*             -1  展開個数が限度を超えた
*             -2  バッファの容量を超えた
*             -4  } が無い（メッセージが表示される）
*
*      D5.W   展開した数だけ増加する
*             D1>D7 となるようならば D0.L に -1 をセットして処理を中止する
*
*      D6.L   展開するバッファの残り容量
*      A1     バッファの次の格納位置
*      CCR    TST.L D0
*
* NOTE
*      無制限に再帰する．スタックに注意！
****************************************************************
unpack:
		movem.l	d1-d3/a0/a2-a4,-(a7)
		move.l	a0,-(a7)
unpack_1:
		moveq	#'{',d0
		bsr	bqstrchr
		beq	unpack_2

		cmpi.b	#'}',1(a0)
		bne	unpack_2

		addq.l	#2,a0
		bra	unpack_1

unpack_2:
		move.l	a0,d0
		movea.l	(a7)+,a0
		sub.l	a0,d0
		sub.l	d0,d6
		bcs	unpack_buffer_over

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		tst.b	(a0)+
		bne	after_brace

		subq.l	#1,d6
		bcs	unpack_buffer_over

		clr.b	(a1)+
		addq.w	#1,d5
		sf	d1
		bra	unpack_success

after_brace:
		moveq	#'}',d0
		movea.l	a0,a3
		bsr	bqstrchr
		beq	unpack_no_close_brace

		exg	a0,a3		*  A3 : 展開文字列の，閉じ } の位置
		lea	1(a3),a4	*  A4 : 展開文字列の，閉じ } の次の位置
		move.l	a1,d2
		sub.l	a2,d2		*  D2.L : これまでに展開が済んだ部分のしたバイト数
exp_brace:
		move.l	d2,-(a7)
		clr.b	(a3)
		moveq	#',',d0
		movem.l	d1/a0,-(a7)
		bsr	bqstrchr
		move.l	a0,d3
		movem.l	(a7)+,d1/a0
		sub.l	a0,d3		*  D3.L : 着目要素のバイト数
		move.b	#'}',(a3)
		move.l	(a7)+,d2
		sub.l	d3,d6
		bcs	unpack_buffer_over

		move.l	d3,d0
		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		exg	a0,a4
		bsr	unpack				***!! 再帰 !!***
		exg	a0,a4
		bmi	unpack_return

		or.b	d0,d1
		cmpa.l	a3,a0
		beq	unpack_success

		addq.l	#1,a0

		cmp.w	d7,d5
		bhs	unpack_too_many

		sub.l	d2,d6
		bcs	unpack_buffer_over

		move.l	a0,-(a7)
		movea.l	a1,a0
		movea.l	a2,a1
		move.l	d2,d0
		movea.l	a0,a2
		bsr	memmovi
		movea.l	a0,a1
		movea.l	(a7)+,a0
		bra	exp_brace

unpack_success:
		moveq	#0,d0
		or.b	d1,d0
unpack_return:
		movem.l	(a7)+,d1-d3/a0/a2-a4
		tst.l	d0
		rts

unpack_too_many:
		moveq	#-1,d0
		bra	unpack_return

unpack_buffer_over:
		moveq	#-2,d0
		bra	unpack_return

unpack_no_close_brace:
		bsr	no_close_brace
		moveq	#-4,d0
		bra	unpack_return
****************************************************************
* unpack_words - {} の省略記法を展開する
*
* CALL
*      A0     単語リスト
*      D0.W   語数
*      A1     展開バッファのアドレス
*      D1.L   展開バッファの容量
*      D2.W   展開する個数の限度
*
* RETURN
*      D0.L   正数ならば成功．このとき下位ワードは展開した数．
*             負数ならばエラー．
*                  -1  展開個数が限度を超えた
*                  -2  バッファの容量を超えた
*                  -4  その他のエラー（メッセージが表示される）
*　　　　　　　　　　　} が無い
*　　　　　　　　　　　メモリが足りない
*
*      CCR    TST.L D0
*****************************************************************
.xdef unpack_words

unpack_buf1 = -4
unpack_buf2 = unpack_buf1-4

unpack_words:
		link	a6,#unpack_buf2
		movem.l	d1-d7/a0-a3,-(a7)
		clr.l	unpack_buf1(a6)
		clr.l	unpack_buf2(a6)
		move.w	d0,d4				*  D4.W : 単語カウンタ
		moveq	#0,d0
		subq.w	#1,d4
		bcs	unpack_words_return

		moveq	#0,d3				*  D3.W : 展開後の単語数
		move.w	d2,d7				*  D7.W : 展開単語数の限度
		move.l	d1,d6				*  D6.L : 最終展開バッファの容量
unpack_words_loop:
		moveq	#-1,d0
		tst.w	d7
		beq	unpack_words_return

		movea.l	a1,a3				*  A3 : 最終展開バッファのアドレス
		movea.l	a0,a1
		moveq	#'{',d0
		bsr	bqstrchr
		exg	a0,a1
		beq	unpack_word_just_move

		cmpa.l	a1,a0
		bne	unpack_words_go

		tst.b	1(a0)
		beq	unpack_word_just_move
unpack_words_go:
		lea	unpack_buf1(a6),a2
		bsr	get_unpack_buffer
		beq	cannot_unpack

		movea.l	d0,a1
		movea.l	a1,a2
		moveq	#0,d5
		movem.l	d6-d7,-(a7)
		move.l	#MAXWORDLISTSIZE,d6
		move.w	#MAXWORDS,d7
		bsr	unpack
		movem.l	(a7)+,d6-d7
		bmi	unpack_words_return
		beq	unpack_word_whole_done

		lea	unpack_buf2(a6),a2
		bsr	get_unpack_buffer
		beq	cannot_unpack

		movea.l	d0,a1
		move.l	#MAXWORDLISTSIZE,d1
		move.w	#MAXWORDS,d2
		move.w	d5,d0
		move.l	a0,-(a7)
		movea.l	unpack_buf1(a6),a0
		bsr	unpack_words
		movea.l	(a7)+,a0
		bmi	unpack_words_return

		move.w	d0,d5
		movea.l	a1,a2
		exg	a0,a1
		bsr	strforn
		exg	a0,a1
unpack_word_whole_done:
		bsr	strfor1
		bra	unpack_word_store

unpack_word_just_move:
		moveq	#1,d5
		movea.l	a0,a2
		bsr	strfor1
		movea.l	a0,a1
unpack_word_store:
		moveq	#-1,d0
		sub.w	d5,d7
		bcs	unpack_words_return

		add.w	d5,d3
		moveq	#-2,d0
		move.l	a1,d5
		sub.l	a2,d5
		sub.l	d5,d6
		bcs	unpack_words_return

		move.l	a0,-(a7)
		movea.l	a2,a1
		movea.l	a3,a0
		move.l	d5,d0
		bsr	memmovi
		movea.l	a0,a1
		movea.l	(a7)+,a0
unpack_words_next:
		dbra	d4,unpack_words_loop

		moveq	#0,d0
		move.w	d3,d0
unpack_words_return:
		move.l	d0,-(a7)
		lea	unpack_buf1(a6),a2
		bsr	free_unpack_buffer
		lea	unpack_buf2(a6),a2
		bsr	free_unpack_buffer
		move.l	(a7)+,d0
		movem.l	(a7)+,d1-d7/a0-a3
		unlk	a6
		rts
**
get_unpack_buffer:
		move.l	(a2),d0
		bne	get_unpack_buffer_ok

		move.l	#MAXWORDLISTSIZE,d0
		bsr	xmalloct
		move.l	d0,(a2)
get_unpack_buffer_ok:
free_unpack_buffer_return:
		rts
**
free_unpack_buffer:
		move.l	(a2),d0
		beq	free_unpack_buffer_return

		bra	freet
**
cannot_unpack:
		lea	msg_cannot_unpack,a0
		bsr	cannot_because_no_memory
		bra	unpack_words_return
****************************************************************
check_slash:
		move.b	(a0),d0
		cmp.b	#'\',d0
		bne	check_slash_1

		move.b	1(a0),d0
check_slash_1:
		btst	#1,d2
		bne	is_slash_or_backslash
		bra	is_nul_or_slash_or_backslash
****************************************************************
* subst_directory - ~ = .. を置換する
*
* CALL
*      A0     単語の先頭アドレス
*      A1     展開するバッファのアドレス
*      D1.L   バッファの容量
*      D2.B   bit0 : 非0 ならば、エラーコード -4 のエラー・メッセージ出力を抑止する
*             bit1 : 非0 ならば、/ か \ の続かないtail部はディレクトリ置換しない
*
* RETURN
*      A0     次の単語の先頭アドレス
*      A1     バッファの次の格納位置
*
*      D0.L    0  OK
*              1  単語が捨てられた
*             -2  バッファの容量を超えた
*             -3  単語の長さが規定を超えた
*             -4  その他のエラー（メッセージが表示される）
*
*      D1.L   下位ワードは残りバッファ容量
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef subst_directory

source_ptr = -4
dest_top = source_ptr-4
dest_bot = dest_top-4
dest_size = dest_bot-4
dest_remain = dest_size-4
subst_dotdot_top = dest_remain-4
subst_dotdot_bot = subst_dotdot_top-4
command_name = subst_dotdot_bot-(((MAXPATH+1)+1)>>1<<1)
slash = command_name-1
dotdot_substed = slash-1
dotdot_slash_stat = dotdot_substed-1
					*   1 : 空
					*   2 : ?:
					*   3 : [?:]/
					*  -1 : */
					*   0 : それ以外
pad = dotdot_slash_stat-1

subst_directory:
		link	a6,#pad
		movem.l	d3-d7/a2-a4,-(a7)
		move.l	a1,dest_top(a6)
		move.l	d1,dest_size(a6)
		move.l	d1,d6
		move.l	#MAXWORDLEN,d5
		movea.l	a0,a2
		tst.b	flag_noglob(a5)
		bne	subst_directory_dup_remainder

		move.b	(a0)+,d0
		cmp.b	#'~',d0
		beq	maybe_home_directory

		cmp.b	#'=',d0
		bne	subst_directory_dup_remainder
****************
****************
maybe_directory_stack:
		move.b	(a0),d0
		cmp.b	#'-',d0
		beq	maybe_directory_stack_bottom

		bsr	isdigit
		beq	maybe_directory_stack_n

		*  which command

		lea	subst_directory_command_not_found(pc),a3
		move.l	a1,-(a7)
		lea	command_name(a6),a1
		moveq	#1,d0
		bsr	search_command_0
		movea.l	(a7)+,a1
		tst.l	d0
		bmi	subst_directory_nomatch

		bsr	strfor1
		movea.l	a0,a2
		lea	command_name(a6),a0
		bsr	strlen
		sub.l	d0,d5
		bcs	subst_directory_too_long

		addq.l	#1,d0
		sub.l	d0,d6
		bcs	subst_directory_buffer_over

		exg	a0,a1
		bsr	strmove
		movea.l	a2,a1
		bra	subst_directory_dup_remainder_done

maybe_directory_stack_n:
		bsr	atou
		bmi	subst_directory_dup_remainder
		bra	maybe_directory_stack_check_slash

maybe_directory_stack_bottom:
		addq.l	#1,a0
		move.l	a0,-(a7)
		movea.l	dirstack(a5),a0
		moveq	#0,d1
		move.w	dirstack_nelement(a0),d1	*  D1.L : ディレクトリ・スタックの要素数
		movea.l	(a7)+,a0
		moveq	#0,d0
maybe_directory_stack_check_slash:
		move.l	d0,d4
		bsr	check_slash
		bne	subst_directory_dup_remainder

		lea	dstack_not_deep(pc),a3
		tst.l	d4
		bne	subst_directory_nomatch

		move.b	d0,slash(a6)
		move.l	d1,d0
		beq	subst_directory_cwd

		move.l	d2,-(a7)
		bsr	get_dstack_d0
		move.l	d2,d0
		move.l	(a7)+,d2
		tst.l	d0
		bmi	subst_directory_nomatch

		movea.l	a0,a2
		movea.l	dirstack(a5),a0
		lea	(a0,d0.l),a0
		bra	subst_directory_copy_dir
****************
subst_directory_cwd:
		movea.l	a0,a2
		lea	cwd(a5),a0
		bra	subst_directory_copy_dir
****************
****************
maybe_home_directory:
skip_username_loop:
		move.b	(a0)+,d0
		bsr	iscsym
		beq	skip_username_loop

		cmp.b	#'-',d0
		beq	skip_username_loop

		subq.l	#1,a0
		bsr	check_slash
		bne	subst_directory_dup_remainder

		move.b	d0,slash(a6)
		move.l	a2,d0
		addq.l	#1,d0
		cmp.l	a0,d0
		beq	subst_directory_myhome

		*  A0 : ユーザ名の次
		lea	subst_directory_unknown_user(pc),a3
		bsr	open_passwd
		bmi	subst_directory_nomatch		*  パスワード・ファイルが無い

		move.l	d0,tmpfd(a5)
		move.b	(a0),d1
		clr.b	(a0)
		movem.l	d1/a0-a2,-(a7)
		lea	tmppwbuf,a0
		lea	tmppwline,a1
		addq.l	#1,a2
		move.l	#PW_LINESIZE,d1
		bsr	fgetpwnam
		movem.l	(a7)+,d1/a0-a2
		move.b	d1,(a0)
		bsr	close_tmpfd
		tst.l	d0
		bne	subst_directory_nomatch

		movea.l	a0,a2
		lea	tmppwbuf,a0
		movea.l	PW_DIR(a0),a0
		bra	subst_directory_copy_dir
****************
subst_directory_myhome:
		lea	subst_directory_no_home(pc),a3
		lea	word_home,a0
		bsr	get_shellvar
		beq	subst_directory_nomatch

		addq.l	#1,a2
subst_directory_copy_dir:
		bsr	copy_dir
		bmi	subst_directory_return

		tst.b	d3
		beq	subst_directory_dup_remainder

		tst.b	slash(a6)
		beq	subst_directory_dup_remainder

		move.b	(a2)+,d0
		cmp.b	#'\',d0
		bne	subst_directory_dup_remainder

		addq.l	#1,a2
subst_directory_dup_remainder:
		movea.l	a2,a0
		bsr	strlen
		sub.l	d0,d5
		bcs	subst_directory_too_long

		addq.l	#1,d0
		sub.l	d0,d6
		bcs	subst_directory_buffer_over

		exg	a0,a1
		bsr	strmove
subst_directory_dup_remainder_done:
		move.l	a1,source_ptr(a6)
		move.l	a0,dest_bot(a6)
		move.l	d6,dest_remain(a6)

		*  ~ と = の展開は完了．

		*  ここで，symlinks=expand であれば，
		*    エスケープされていない .. があり，その前後が / か \ か空であれば
		*    .. までの部分を正規化する．

		tst.b	flag_noglob(a5)
		bne	subst_directory_ok

		cmpi.b	#3,flag_symlinks(a5)		*  set symlinks=expand ?
		bne	subst_directory_ok

		sf	dotdot_substed(a6)
		movea.l	dest_top(a6),a2			*  A2 : sourceポインタ
		lea	subst_tmpword1,a3		*  A3 : destバッファポインタ
		move.l	a3,subst_dotdot_top(a6)
		move.l	#MAXWORDLEN,d5			*  D5.L : バッファ容量カウンタ
		move.b	#1,dotdot_slash_stat(a6)
subst_dotdot_loop:
		tst.b	dotdot_slash_stat(a6)
		beq	subst_dotdot_not_dotdot

		cmpi.b	#'.',(a2)
		bne	subst_dotdot_not_dotdot

		cmpi.b	#'.',1(a2)
		bne	subst_dotdot_not_dotdot

		lea	2(a2),a0
		bsr	check_slash
		bne	subst_dotdot_not_dotdot

		*  .. である
		addq.l	#2,a2
		move.b	d0,slash(a6)
		move.l	a3,d0
		tst.b	dotdot_slash_stat(a6)
		bpl	subst_dotdot_terminate

		move.l	subst_dotdot_bot(a6),d0
subst_dotdot_terminate:
		movea.l	subst_dotdot_top(a6),a1
		sub.l	a1,d0
		lea	subst_tmpword2,a0
		bsr	memmovi
		clr.b	(a0)
		tst.b	dotdot_substed(a6)
		bne	subst_dotdot_non_first

		*  最初の .. 置換
		lea	subst_tmpword2,a0
		bsr	subst_dotdot_check_root
		beq	subst_dotdot_abs

		*  [?:]/ で始まっていない ... cwd または `getcdd` から始める．
		lea	cwd(a5),a0
		moveq	#0,d0
		move.b	d1,d0
		beq	subst_dotdot_rel_copy_dir

		bsr	toupper
		move.l	d0,d1
		cmp.b	(a0),d0
		beq	subst_dotdot_rel_copy_dir

		bsr	drvchk
		bmi	subst_dotdot_bad_drive

		move.l	d1,d0
		lea	pathname_buf,a0
		bsr	getcdd
subst_dotdot_rel_copy_dir:
		movea.l	subst_dotdot_top(a6),a1
		moveq	#-1,d6
		bsr	copy_dir
		bmi	subst_directory_return

		move.b	d3,dotdot_slash_stat(a6)
		movea.l	a1,a0
		lea	subst_tmpword2,a1
		bra	subst_dotdot_fair_loop

subst_dotdot_abs:
		lea	subst_tmpword2,a1
		move.l	a0,d0
		sub.l	a1,d0
		movea.l	subst_dotdot_top(a6),a0
		bsr	memmovi
		st	dotdot_slash_stat(a6)
		bra	subst_dotdot_fair_loop

subst_dotdot_non_first:
		movea.l	subst_dotdot_top(a6),a0
		clr.b	(a0)
		lea	subst_tmpword1,a0
		bsr	subst_dotdot_check_root
		tst.b	(a0)
		seq	dotdot_slash_stat(a6)
		lea	subst_tmpword2,a1
		bsr	subst_dotdot_find_slashes
		move.b	d0,slash(a6)
		movea.l	subst_dotdot_top(a6),a0
subst_dotdot_fair_loop:
		bsr	subst_dotdot_skip_slashes
		beq	subst_dotdot_fair_done

		movea.l	a1,a3
		bsr	get_1char_a1
		beq	subst_dotdot_fair_done

		cmp.b	#'.',d0
		bne	subst_dotdot_fair_dup

		bsr	get_1char_a1
		beq	subst_dotdot_fair_done

		bsr	is_slash_or_backslash
		bne	subst_dotdot_fair_dup

		move.b	d0,slash(a6)
		bra	subst_dotdot_fair_loop

subst_dotdot_fair_dup:
		tst.b	dotdot_slash_stat(a6)
		bne	subst_dotdot_fair_dup_3

		move.b	slash(a6),d0
		cmp.b	#'\',d0
		bne	subst_dotdot_fair_dup_1

		subq.l	#1,d5
		bcs	subst_directory_too_long

		move.b	#'\',(a0)+
		bra	subst_dotdot_fair_dup_2

subst_dotdot_fair_dup_1:
		moveq	#'/',d0
subst_dotdot_fair_dup_2:
		subq.l	#1,d5
		bcs	subst_directory_too_long

		move.b	d0,(a0)+
subst_dotdot_fair_dup_3:
		bsr	subst_dotdot_find_slashes
		move.b	d0,slash(a6)
		exg	a1,a3
		move.l	a3,d0
		sub.l	a1,d0
		bsr	memmovi
		sf	dotdot_slash_stat(a6)
		bra	subst_dotdot_fair_loop

subst_dotdot_fair_done:
		clr.b	(a0)
		lea	subst_tmpword1,a0
		bsr	subst_dotdot_check_root
		movea.l	a0,a1
		move.b	#3,dotdot_slash_stat(a6)
		bra	subst_dotdot_set_cutpos_1

subst_dotdot_set_cutpos:
		clr.b	dotdot_slash_stat(a6)
subst_dotdot_set_cutpos_1:
		movea.l	a1,a3
		bsr	subst_dotdot_skip_slashes
		beq	subst_dotdot_done_one

		bsr	subst_dotdot_find_slashes
		bne	subst_dotdot_set_cutpos
subst_dotdot_done_one:
		st	dotdot_substed(a6)
		lea	subst_tmpword1,a0
		move.l	a0,d5
		add.l	#MAXWORDLEN,d5
		sub.l	a3,d5
		move.l	a3,subst_dotdot_top(a6)
		tst.b	dotdot_slash_stat(a6)
		beq	subst_dotdot_not_dotdot

		bsr	get_1char
		beq	subst_dotdot_done

		move.l	a3,subst_dotdot_bot(a6)
		move.b	#-1,dotdot_slash_stat(a6)
		bra	subst_dotdot_loop

subst_dotdot_not_dotdot:
		move.b	(a2)+,d0
		cmp.b	#'"',d0
		beq	subst_dotdot_quote

		cmp.b	#"'",d0
		beq	subst_dotdot_quote

		cmp.b	#'`',d0
		beq	subst_dotdot_quote

		sf	d4
		cmp.b	#'\',d0
		bne	subst_dotdot_not_escape

		move.b	(a2)+,d0
		beq	subst_dotdot_done

		st	d4
subst_dotdot_not_escape:
		bsr	subst_dotdot_dup1
		bcs	subst_directory_too_long
		bne	subst_dotdot_loop
		bra	subst_dotdot_done

subst_dotdot_quote:
		move.b	d0,d1
		st	d4
subst_dotdot_quote_loop:
		move.b	(a2)+,d0
		cmp.b	d1,d0
		beq	subst_dotdot_loop

		bsr	subst_dotdot_dup1
		bcs	subst_directory_too_long
		bne	subst_dotdot_quote_loop
subst_dotdot_done:
		tst.b	dotdot_substed(a6)
		beq	subst_directory_ok

		clr.b	(a3)
		lea	subst_tmpword1,a0
		bsr	strlen
		addq.l	#1,d0
		sub.l	dest_size(a6),d0
		bhi	subst_directory_buffer_over

		move.l	d0,dest_remain(a6)
		movea.l	a0,a1
		movea.l	dest_top(a6),a0
		bsr	strmove
		move.l	a0,dest_bot(a6)
subst_directory_ok:
		movea.l	source_ptr(a6),a0
		movea.l	dest_bot(a6),a1
		move.l	dest_remain(a6),d1
		moveq	#0,d0
subst_directory_return:
		movem.l	(a7)+,d3-d7/a2-a4
		unlk	a6
		tst.l	d0
		rts

subst_directory_buffer_over:
		moveq	#-2,d0
		bra	subst_directory_return

subst_directory_too_long:
		moveq	#-3,d0
		bra	subst_directory_return

subst_dotdot_bad_drive:
		btst	#0,d2
		bne	subst_directory_return_4

		bsr	perror_command_name
		lea	subst_tmpword2,a0
		bsr	perror
		bra	subst_directory_return_4
****************
subst_directory_nomatch:
		move.b	flag_nonomatch(a5),d0
		beq	subst_directory_error_4

		subq.b	#1,d0
		bne	subst_directory_dup_remainder	*  set nonomatch .. 単語をコピーする

		*  set nonomatch=drop .. 単語を捨てる
		movea.l	a2,a0
		bsr	strfor1
		move.l	d6,d1
		moveq	#1,d0
		bra	subst_directory_return

subst_directory_error_4:
		btst	#0,d2
		bne	subst_directory_return_4

		jsr	(a3)
subst_directory_return_4:
		moveq	#-4,d0
		bra	subst_directory_return
****************
subst_directory_no_home:
		lea	msg_no_home,a0
		bra	command_error
****************
subst_directory_unknown_user:
		bsr	perror_command_name
		exg	a0,a2
		move.b	(a2),d0
		clr.b	(a2)
		addq.l	#1,a0
		bsr	pre_perror
		move.b	d0,(a2)
		lea	msg_unknown_user,a0
		bra	enputs
****************
subst_directory_command_not_found:
		bsr	perror_command_name
		lea	1(a2),a0
		bsr	ecputs
		lea	msg_is,a0
		bsr	eputs
		lea	msg_not_found,a0
		bra	enputs
****************************************************************
subst_dotdot_dup1:
		tst.b	d0
		beq	subst_dotdot_dup1_return	*  終わり; CC:CC,Z

		subq.l	#1,d5
		bcs	subst_dotdot_dup1_return	*  バッファ不足; CC:CS

		bsr	is_slash_or_backslash
		bne	subst_dotdot_dup1_not_slash

		tst.b	dotdot_slash_stat(a6)
		bmi	subst_dotdot_dup1_not_sjis

		cmpi.b	#1,dotdot_slash_stat(a6)
		beq	subst_dotdot_dup1_root

		cmpi.b	#2,dotdot_slash_stat(a6)
		beq	subst_dotdot_dup1_root

		move.l	a3,subst_dotdot_bot(a6)
		move.b	#-1,dotdot_slash_stat(a6)
		bra	subst_dotdot_dup1_not_sjis

subst_dotdot_dup1_root:
		move.b	#3,dotdot_slash_stat(a6)
		bra	subst_dotdot_dup1_not_sjis

subst_dotdot_dup1_not_slash:
		cmp.b	#':',d0
		bne	subst_dotdot_dup1_not_colon

		tst.b	dotdot_slash_stat(a6)
		bne	subst_dotdot_dup1_not_colon

		move.l	a2,-(a7)
		lea	subst_tmpword1,a2
		bsr	get_1char
		cmpa.l	a3,a2				*  2文字目か?
		movea.l	(a7)+,a2
		bne	subst_dotdot_dup1_not_colon

		move.b	#2,dotdot_slash_stat(a6)
		moveq	#':',d0
		bra	subst_dotdot_dup1_not_sjis

subst_dotdot_dup1_not_colon:
		clr.b	dotdot_slash_stat(a6)
		bsr	issjis
		beq	subst_dotdot_dup1_sjis
subst_dotdot_dup1_not_sjis:
		tst.b	d4
		beq	subst_dotdot_dup1_2

		lea	characters_to_be_escaped_3,a0
		bsr	strchr
		beq	subst_dotdot_dup1_2

		move.b	#'\',(a3)+
		bra	subst_dotdot_dup1_1

subst_dotdot_dup1_sjis:
		move.b	d0,(a3)+
		move.b	(a2)+,d0
		beq	subst_dotdot_dup1_return	*  終わり; CC:CC,Z
subst_dotdot_dup1_1:
		subq.l	#1,d5
		bcs	subst_dotdot_dup1_return	*  バッファ不足; CC:CS
subst_dotdot_dup1_2:
		move.b	d0,(a3)+			*  CC:CC,NZ
subst_dotdot_dup1_return:
		rts
****************************************************************
* subst_dotdot_check_root - 文字列 が [?:]/ で始まっているかどうか調べる
*
* CALL
*      A0     文字列
*
* RETURN
*      A0     [?:]/ の次のアドレス（[?:]/ で始まっていなければ不定）
*      D1.L   ドライブ名（なければ 0）
*      CCR    [?:]/ で始まっていれば EQ
*      D0.L   破壊
****************************************************************
subst_dotdot_check_root:
		move.l	a2,-(a7)
		movea.l	a0,a2
		moveq	#0,d1
		bsr	get_1char
		beq	subst_dotdot_check_root_drive_ok

		move.b	d0,d1
		movea.l	a2,a0
		bsr	get_1char
		cmp.b	#':',d0
		bne	subst_dotdot_check_root_no_drive

		bsr	get_1char
		bra	subst_dotdot_check_root_drive_ok

subst_dotdot_check_root_no_drive:
		move.b	d1,d0
		movea.l	a0,a2
		moveq	#0,d1
subst_dotdot_check_root_drive_ok:
		movea.l	a2,a0
		movea.l	(a7)+,a2
		bsr	is_slash_or_backslash
		rts
****************************************************************
* subst_dotdot_skip_slashes - / か \ をスキップする
*
* CALL
*      A1     文字列
*
* RETURN
*      A1     最初の / でも \ でもない文字の位置
*      D0     最初の / でも \ でもない文字
*      CCR    TST.B D0
****************************************************************
subst_dotdot_skip_slashes:
		move.b	(a1),d0
		beq	subst_dotdot_find_slashes_done

		cmp.b	#'\',d0
		bne	subst_dotdot_skip_slashes_1

		move.b	1(a1),d0
		beq	subst_dotdot_find_slashes_done
subst_dotdot_skip_slashes_1:
		bsr	is_slash_or_backslash
		bne	subst_dotdot_find_slashes_done

		bsr	get_1char_a1
		bra	subst_dotdot_skip_slashes
****************************************************************
* subst_dotdot_find_slashes - / か \ を探す
*
* CALL
*      A1     文字列
*
* RETURN
*      A1     最初の / か \ か NUL の位置
*      D0     最初の / か \ か NUL
*      CCR    TST.B D0
****************************************************************
subst_dotdot_find_slashes:
		move.b	(a1),d0
		beq	subst_dotdot_find_slashes_done

		cmp.b	#'\',d0
		bne	subst_dotdot_find_slashes_1

		move.b	1(a1),d0
		beq	subst_dotdot_find_slashes_done
subst_dotdot_find_slashes_1:
		bsr	is_slash_or_backslash
		beq	subst_dotdot_find_slashes_done

		bsr	get_1char_a1
subst_dotdot_find_slashes_continue:
		bsr	issjis
		bne	subst_dotdot_find_slashes

		move.b	(a1)+,d0
		bne	subst_dotdot_find_slashes

		subq.l	#1,a1
subst_dotdot_find_slashes_done:
		tst.b	d0
		rts
****************************************************************
get_1char_a1:
		exg	a1,a2
		bsr	get_1char
		exg	a1,a2
		rts
****************************************************************
* copy_dir
*
* CALL
*      A0     source
*      A1     destination
*      D5.L   destination の規定容量（単語の長さカウンタ）
*      D6.L   destination の許容量（バッファ容量カウンタ）
*
* RETURN
*      D0.L    0  OK
*             -2  バッファの容量を超えた
*             -3  単語の長さが規定を超えた
*
*      D3.B   / か \ で終わったならば 非0
*
*      A1     進む
*
*      D4-D7/A0/A3     破壊
****************************************************************
copy_dir:
		movea.l	a0,a3
		sf	d4				*  D4.B : sjis flag
		clr.b	d7				*  D7.B : slash
		st	d3
		tst.b	flag_refersysroot(a5)
		bne	copy_dir_loop_1
copy_dir_loop:
		move.b	slash(a6),d7
copy_dir_loop_1:
		move.b	(a3)+,d0
		beq	copy_dir_done

		sf	d3
		tst.b	d4
		sf	d4
		bne	copy_dir_1

		st	d3
		cmp.b	#'/',d0
		beq	copy_dir_slash

		cmp.b	#'\',d0
		beq	copy_dir_backslash

		sf	d3
		jsr	issjis
		seq	d4
		beq	copy_dir_1

		lea	characters_to_be_escaped_3,a0
		bsr	strchr
		beq	copy_dir_1
		bra	copy_dir_escape

copy_dir_backslash:
		cmp.b	#'/',d7
		bne	copy_dir_escape

		move.b	d7,d0
		bra	copy_dir_1

copy_dir_slash:
		cmp.b	#'\',d7
		bne	copy_dir_1

		move.b	d7,d0
copy_dir_escape:
		subq.l	#1,d6
		bcs	copy_dir_buffer_over

		subq.l	#1,d5
		bcs	copy_dir_too_long

		move.b	#'\',(a1)+
copy_dir_1:
		subq.l	#1,d6
		bcs	copy_dir_buffer_over

		subq.l	#1,d5
		bcs	copy_dir_too_long

		move.b	d0,(a1)+
		bra	copy_dir_loop

copy_dir_done:
		moveq	#0,d0
		rts

copy_dir_buffer_over:
		moveq	#-2,d0
		rts

copy_dir_too_long:
		moveq	#-3,d0
		rts
****************************************************************
* unpack_wordlist - 引数並びの各語について {} ~ = .. を展開する
*
* CALL
*      A0     格納領域の先頭．引数並びと重なっていても良い．
*      A1     引数並びの先頭
*      D0.W   語数
*
* RETURN
*      (tmpline)   破壊される
*
*      D0.L   正数ならば成功．下位ワードは展開後の語数
*             負数ならばエラー
*      CCR    TST.L D0
****************************************************************
.xdef unpack_wordlist

unpack_wordlist:
		movem.l	d1-d4/a0-a2,-(a7)
		movea.l	a0,a2			*  格納するアドレスをA2に待避
		movea.l	a1,a0			*  A0 : 単語リスト
		lea	tmpline(a5),a1		*  一旦 {} を一時領域に展開する
		move.l	#MAXWORDLISTSIZE,d1	*  D1 : 最大文字数
		move.w	#MAXWORDS,d2
		bsr	unpack_words
		bmi	unpack_wordlist_error

		move.w	d0,d3			*  D3.W : {}展開後の単語数
		moveq	#0,d4			*  D4 : 単語数カウンタ
		lea	tmpline(a5),a0
		movea.l	a2,a1
		move.l	#MAXWORDLISTSIZE,d1	*  D1.L : 最大文字数
		moveq	#0,d2
		bra	subst_dir_wordlist_continue

subst_dir_wordlist_loop:
		bsr	subst_directory
		bmi	unpack_wordlist_error
		bne	subst_dir_wordlist_continue

		addq.l	#1,d4
subst_dir_wordlist_continue:
		dbra	d3,subst_dir_wordlist_loop

		move.l	d4,d0
unpack_wordlist_return:
		movem.l	(a7)+,d1-d4/a0-a2
		tst.l	d0
		rts
****************
unpack_wordlist_error:
		cmp.l	#-1,d0
		beq	unpack_wordlist_too_many_words

		cmp.l	#-2,d0
		beq	unpack_wordlist_buffer_over

		cmp.l	#-3,d0
		bne	unpack_wordlist_error_return

		bsr	too_long_word
		bra	unpack_wordlist_error_return

unpack_wordlist_buffer_over:
		bsr	too_long_line
		bra	unpack_wordlist_error_return

unpack_wordlist_too_many_words:
		bsr	too_many_words
unpack_wordlist_error_return:
		moveq	#-1,d0
		bra	unpack_wordlist_return

.data

msg_cannot_unpack:	dc.b	' {} を展開できません',0
msg_unknown_user:	dc.b	'このようなユーザは登録されていません',0
msg_no_home:		dc.b	'シェル変数 home が定義されていません',0

.end
