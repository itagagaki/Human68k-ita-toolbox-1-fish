* unpack.s
* Itagaki Fumihiko 23-Sep-90  Create.

.include limits.h
.include pwd.h
.include ../src/fish.h

.xref iscsym
.xref atou
.xref qstrchr
.xref strfor1
.xref memmovi
.xref no_close_brace
.xref open_passwd
.xref fgetpwnam
.xref close_tmpfd
.xref getcwd
.xref get_dstack_d0
.xref word_home
.xref find_shellvar
.xref get_var_value
.xref copyhead
.xref strlen
.xref pre_perror
.xref enputs
.xref too_long_word
.xref too_long_line
.xref too_many_words
.xref dstack_not_deep

.xref tmpline

.xref tmpfd

.text

****************************************************************
* unpack1 - unpack_word の再帰部分
*
* CALL
*      A0     展開する語の位置を指す
*      A1     展開するバッファの位置を指す
*      A2     処理中の，展開した語の先頭を指す
*      D6.W   展開するバッファの残り容量
*      D7.W   展開する個数の限度
*
* RETURN
*      D0.L    0  成功
*             -1  展開個数が限度を超えた
*             -2  バッファの容量を超えた
*             -4  } が無い（メッセージが表示される）
*
*      D1.W   展開した数だけ増加する
*             D1>D7 となるようならば D0.L に 1 をセットして処理を中止する
*
*      D6.W   展開するバッファの残り容量
*      A1     バッファの次の格納位置
*      A0     破壊
*      CCR    TST.L D0
*
* NOTE
*      無制限に再帰する．スタックに注意！
****************************************************************
unpack1:
		move.l	a0,-(a7)
		moveq	#'{',d0
		bsr	qstrchr
		move.l	a0,d0
		movea.l	(a7)+,a0
		sub.l	a0,d0
		sub.w	d0,d6
		bcs	unpack1_buffer_over

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		tst.b	(a0)+
		bne	after_brace

		subq.w	#1,d6
		bcs	unpack1_buffer_over

		clr.b	(a1)+
		addq.w	#1,d1
		moveq	#0,d0
		rts

unpack1_buffer_over:
		moveq	#-2,d0
		rts

after_brace:
		movem.l	d2-d3/a2-a3,-(a7)
		move.l	a1,d2
		sub.l	a2,d2
		movea.l	a0,a3
		moveq	#'}',d0
		bsr	qstrchr
		exg	a0,a3
		move.l	a3,d3
		tst.b	(a3)
		beq	exp_brace_no_close_brace

		addq.l	#1,d3
exp_brace_1:
		move.l	a0,-(a7)
		move.b	(a3),d0
		move.w	d0,-(a7)
		clr.b	(a3)
		moveq	#',',d0
		bsr	qstrchr
		move.w	(a7)+,d0
		move.b	d0,(a3)
		move.l	a0,d0
		movea.l	(a7)+,a0
		sub.l	a0,d0
		sub.w	d0,d6
		bcs	exp_brace_buffer_over

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1

		move.l	a0,-(a7)
		movea.l	d3,a0
		bsr	unpack1
		movea.l	(a7)+,a0
		bne	exp_brace_return

		cmpa.l	a3,a0
		beq	exp_brace_done

		cmp.w	d7,d1
		bhs	exp_brace_too_many

		sub.w	d2,d6
		bcs	exp_brace_buffer_over

		addq.l	#1,a0
		move.l	a0,-(a7)
		movea.l	a1,a0
		movea.l	a2,a1
		move.l	d2,d0
		movea.l	a0,a2
		bsr	memmovi
		movea.l	a0,a1
		movea.l	(a7)+,a0
		bra	exp_brace_1

exp_brace_done:
		tst.b	(a0)
		beq	exp_brace_return

		addq.l	#1,a0
exp_brace_return:
		movem.l	(a7)+,d2-d3/a2-a3
		tst.l	d0
		rts

exp_brace_too_many:
		moveq	#-1,d0
		bra	exp_brace_return

exp_brace_buffer_over:
		moveq	#-2,d0
		bra	exp_brace_return

exp_brace_no_close_brace:
		bsr	no_close_brace
		moveq	#-4,d0
		bra	exp_brace_return
****************************************************************
* unpack_word - {} の省略記法を展開する
*
* CALL
*      A0     {} を含む語の先頭アドレス．語は ', " and/or \ によるクオートが可．
*             語の長さは MAXWORDLEN 以内であること．
*
*      A1     展開するバッファのアドレス
*      D0.W   展開する個数の限度
*      D1.W   バッファの容量
*
* RETURN
*      A1     バッファの次の格納位置
*
*      D0.L   正数ならば成功．このとき下位ワードは展開した数．
*             負数ならばエラー．
*                  -1  展開個数が限度を超えた
*                  -2  バッファの容量を超えた
*                  -4  } が無い（メッセージが表示される）
*
*      D1.L   下位ワードは残りバッファ容量
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef unpack_word

unpack_word:
		movem.l	d6-d7/a0/a2,-(a7)
		move.w	d0,d7
		moveq	#-1,d0
		tst.w	d7
		beq	unpack_word_return

		moveq	#2,d6
		cmpi.b	#'{',(a0)
		bne	unpack_word_go

		tst.b	1(a0)
		beq	unpack_word_dont

		cmpi.b	#'}',1(a0)
		bne	unpack_word_go

		tst.b	2(a0)
		bne	unpack_word_go

		addq.w	#1,d6
unpack_word_dont:
		moveq	#-2,d0
		sub.w	d6,d1
		bcs	unpack_word_return

		move.l	d6,d0
		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		moveq	#1,d0
		bra	unpack_word_return

unpack_word_go:
		move.w	d1,d6
		movea.l	a1,a2
		moveq	#0,d1
		bsr	unpack1
		bne	unpack_word_success

		move.w	d1,d0
unpack_word_success:
		move.w	d6,d1
unpack_word_return:
		movem.l	(a7)+,d6-d7/a0/a2
		tst.l	d0
		rts
****************************************************************
check_slash:
		move.b	(a0),d0
		beq	check_slash_return

		cmp.b	#'\',d0
		bne	check_slash_1

		move.b	1(a0),d0
check_slash_1:
		cmp.b	#'/',d0
		beq	check_slash_return

		cmp.b	#'\',d0
check_slash_return:
		rts
****************************************************************
* expand_tilde - ~ と = を展開する
*
* CALL
*      A0     ~ または = で始まっている（かもしれない）単語の先頭アドレス
*      A1     展開するバッファのアドレス
*      D1.W   バッファの容量
*      D2.B   0 ならば、エラーコード -4 のエラー・メッセージ出力を抑止する
*
* RETURN
*      A0     次の単語の先頭アドレス
*      A1     バッファの次の格納位置
*
*      D0.L
*              0  OK
*             -2  バッファの容量を超えた
*             -3  単語の長さが規定を超えた
*             -4  その他のエラー（メッセージが表示される）
*
*      D1.L   下位ワードは残りバッファ容量
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef expand_tilde

pwd_buf = -(((PW_SIZE+1)+1)>>1<<1)
cwd_buf = pwd_buf-(((MAXPATH+1)+1)>>1<<1)

expand_tilde:
		link	a6,#cwd_buf
		movem.l	d4-d6/a2-a3,-(a7)
		move.w	d1,d6
		move.w	#MAXWORDLEN,d5
		movea.l	a0,a2

		move.b	(a0)+,d0
		cmp.b	#'~',d0
		beq	maybe_home_directory

		cmp.b	#'=',d0
		bne	expand_tilde_go
****************
****************
maybe_directory_stack:
		bsr	atou
		bmi	expand_tilde_go

		move.l	d0,d4
		bsr	check_slash
		bne	expand_tilde_go

		tst.l	d4
		bne	expand_tilde_dstack_not_deep

		movea.l	a0,a2
		move.l	d1,d0
		beq	expand_tilde_cwd

		bsr	get_dstack_d0
		bhi	expand_tilde_dstack_not_deep

		bra	expand_tilde_copy_dir
****************
expand_tilde_cwd:
		lea	cwd_buf(a6),a0
		bsr	getcwd
		bra	expand_tilde_copy_dir
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
		bne	expand_tilde_go

		addq.l	#1,a2				*  A2 は ~ の次を指す
		move.l	a0,d1
		sub.l	a2,d1				*  D1.L : username の長さ
		beq	expand_tilde_myhome
****************
		exg	a0,a2				*  A0 : ユーザ名の先頭  A2 : ユーザ名の次

		bsr	open_passwd
		bmi	expand_tilde_unknown_user	*  パスワード・ファイルが無い

		move.l	d0,tmpfd(a5)
		movem.l	a0-a1,-(a7)
		movea.l	a0,a1
		lea	pwd_buf(a6),a0
		bsr	fgetpwnam
		movem.l	(a7)+,a0-a1
		bsr	close_tmpfd
		tst.l	d0
		bne	expand_tilde_unknown_user

		lea	pwd_buf(a6),a0
		lea	PW_DIR(a0),a0
		bra	expand_tilde_copy_dir
****************
expand_tilde_myhome:
		lea	word_home,a0			*  シェル変数 home が
		bsr	find_shellvar			*  定義されて
		beq	expand_tilde_go			*  いなければ、~以降をコピーするのみ

		bsr	get_var_value
		beq	expand_tilde_go			*  $#home が 0 ならば、~以降をコピーするのみ
****************
expand_tilde_copy_dir:
		move.w	d6,d0
		exg	a0,a1
		bsr	copyhead			*  ホーム・ディレクトリ名をバッファにコピーする
		exg	a0,a1
		tst.l	d0
		bmi	expand_tilde_buffer_over

		move.w	d6,d4
		sub.w	d0,d4
		sub.w	d4,d5
		bcs	expand_tilde_too_long

		move.w	d0,d6				*  D6.W : バッファの残り容量
		btst	#0,d1				*  / で終わって
		beq	expand_tilde_go			*  いないならば ~以降を結合する

		tst.b	(a2)				*  ~以降が空ならば
		beq	expand_tilde_go			*  結合する

		*  最後の / を削除して ~ 以降を結合する
		subq.l	#1,a1
		addq.w	#1,d6
		addq.w	#1,d5
****************
expand_tilde_go:
		movea.l	a2,a0
		bsr	strlen
		sub.w	d0,d5
		bcs	expand_tilde_too_long

		addq.l	#1,d0
		sub.w	d0,d6
		bcs	expand_tilde_buffer_over

		exg	a0,a1
		bsr	memmovi
		exg	a0,a1
		moveq	#0,d0
expand_tilde_return:
		move.w	d6,d1
		movem.l	(a7)+,d4-d6/a2-a3
		unlk	a6
		tst.l	d0
		rts

expand_tilde_buffer_over:
		moveq	#-2,d0
		bra	expand_tilde_return

expand_tilde_too_long:
		moveq	#-3,d0
		bra	expand_tilde_return

expand_tilde_unknown_user:
		tst.b	d2
		beq	expand_tilde_passwd_error_1

		move.b	(a2),d0
		clr.b	(a2)
		bsr	pre_perror
		move.b	d0,(a2)
		lea	msg_unknown_user,a0
		bsr	enputs
expand_tilde_passwd_error_1:
		movea.l	a2,a0
		moveq	#-4,d0
		bra	expand_tilde_return

expand_tilde_dstack_not_deep:
		bsr	dstack_not_deep
		bra	expand_tilde_passwd_error_1
****************************************************************
* unpack_wordlist - 引数並びの各語について ~ {} を展開する
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
		movea.l	a0,a2			* 格納するアドレスをA2に待避
		movea.l	a1,a0			* A0 : 引数並び
		lea	tmpline(a5),a1		* 一旦 {} を一時領域に展開する
		move.w	#MAXWORDLISTSIZE,d1	* D1 : 最大文字数
		move.w	d0,d4			* D4 : 引数カウンタ
		moveq	#0,d3			* D3 : 展開後の語数
		bra	unpack_wordlist_continue

unpack_wordlist_loop:
		move.w	#MAXWORDS,d0
		sub.w	d3,d0
		bsr	unpack_word
		bmi	unpack_wordlist_error

		add.w	d0,d3
		bsr	strfor1
unpack_wordlist_continue:
		dbra	d4,unpack_wordlist_loop
****************
		lea	tmpline(a5),a0
		movea.l	a2,a1
		move.w	#MAXWORDLISTSIZE,d1	* D1 : 最大文字数
		move.w	d3,d4			* D4 : 引数カウンタ
		moveq	#1,d2			* D2 = 1 : Unknown user メッセージを抑止しない
		bra	expand_tilde_wordlist_continue

expand_tilde_wordlist_loop:
		bsr	expand_tilde
		bmi	unpack_wordlist_error

expand_tilde_wordlist_continue:
		dbra	d4,expand_tilde_wordlist_loop
****************
		moveq	#0,d0
		move.w	d3,d0
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

msg_unknown_user:	dc.b	'このようなユーザは登録されていません',0

.end
