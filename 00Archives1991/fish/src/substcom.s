* substcom.s
* Itagaki Fumihiko 25-Nov-90  Create.

.include doscall.h
.include limits.h
.include chrcode.h
.include ../src/fish.h

.xref issjis
.xref not_execute
.xref isspace
.xref fgetc
.xref dup1
.xref dup1_with_escaping
.xref dup1_with_escaping_in_quote
.xref eputc
.xref msg_unmatched
.xref enputs
.xref strchr
.xref dup1_2
.xref tmpfile
.xref redirect
.xref fork
.xref unredirect
.xref perror
.xref fclose
.xref remove
.xref tmpline
.xref copy_wordlist
.xref too_many_words
.xref too_long_word
.xref too_long_line

.text

****************************************************************
is_separator:
		tst.b	d0
		beq	is_separator_return

		jmp	(a4)

is_separator_return:
		rts
****************************************************************
* subst_command - コマンド置換をする
*
* CALL
*      A0     ソースとなる単語の先頭アドレス
*      A1     格納するバッファの先頭アドレス
*      D0.W   展開語数の限度．D2.Bが0のときには無効
*      D1.W   バッファの容量
*
* RETURN
*      A0     ソースの終端の次の位置
*             ただしエラーのときには保証されない
*
*      A1     バッファの次の格納位置
*             ただしエラーのときには保証されない
*
*      D0.L   正数ならば成功．下位ワードは展開語数
*             負数ならばエラー．
*                  -1  展開語数が限度を超えた
*                  -2  バッファの容量を超えた
*                  -3  単語の長さが規定を超えた
*                  -4  入出力エラー，コマンドエラー等（メッセージを表示する）
*
*      D1.L   下位ワードは残りバッファ容量
*             ただしエラーのときには保証されない
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef subst_command

tmpfilename = -(((MAXPATH+1)+1)>>1<<1)
tmpfiledesc = tmpfilename-4
quote_char = tmpfiledesc-2

subst_command:
		link	a6,#quote_char
		movem.l	d2-d7/a2-a4,-(a7)
		move.w	#MAXWORDLEN,d2			* D2.W : 単語の長さの最大値
		move.w	d0,d3				* D3.W : 単語数の上限
		moveq	#0,d4				* D4.W : 生成した単語数カウンタ
		moveq	#1,d5				* D5.B : 「新たな語とする」フラグ
		move.l	#-1,tmpfiledesc(a6)		* 一時ファイルデスクリプタ
		clr.w	quote_char(a6)			* クオート・フラグ
subst_command_loop:
		move.b	(a0)+,d0
		beq	subst_command_done

		bsr	issjis
		beq	subst_command_dup2

		tst.b	quote_char(a6)
		beq	subst_command_not_in_quote

		cmp.b	quote_char(a6),d0
		beq	subst_command_quote

		cmpi.b	#'"',quote_char(a6)
		beq	subst_command_check_accent
		bra	subst_command_dup1

subst_command_quote:
		eor.b	d0,quote_char(a6)
		bra	subst_command_dup1

subst_command_not_in_quote:
		cmp.b	#'\',d0
		beq	subst_command_escape

		cmp.b	#'"',d0
		beq	subst_command_quote

		cmp.b	#"'",d0
		beq	subst_command_quote
subst_command_check_accent:
		cmp.b	#'`',d0
		bne	subst_command_dup1
********************************
		movea.l	a0,a2
subst_command_search_bottom:
		move.b	(a0)+,d0
		cmp.b	quote_char(a6),d0		* Nice kludge!
		beq	unmatched

		cmp.b	#'`',d0
		bne	subst_command_search_bottom

		move.l	a0,d0
		subq.l	#1,d0
		sub.l	a2,d0
		tst.b	not_execute
		bne	subst_command_loop

		movem.l	a0-a1,-(a7)
		movea.l	a2,a0
		lea	tmpfilename(a6),a1
		bsr	subst_command_redirect
		movem.l	(a7)+,a0-a1
		bmi	subst_command_return

		move.l	d0,tmpfiledesc(a6)
		moveq	#0,d7				* D7 : first flag
		movea.l	a0,a3
		lea	isspace(pc),a4
		tst.b	quote_char(a6)
		beq	subst_command_input_loop

		lea	iscrlf(pc),a4
subst_command_input_loop:

subst_command_input_loop_1:
		move.l	tmpfiledesc(a6),d0
		bsr	fgetc
		bmi	subst_command_input_done

		bsr	is_separator
		beq	subst_command_input_loop_1

		tst.b	d7
		beq	subst_command_input_loop_2

		move.b	d0,d6
		tst.b	quote_char(a6)
		beq	subst_command_terminate_word_1

		moveq	#'"',d0
		bsr	dup1
		bmi	subst_command_return
subst_command_terminate_word_1:
		moveq	#0,d0
		moveq	#1,d2
		bsr	dup1
		bmi	subst_command_return

		moveq	#1,d5
		tst.b	quote_char(a6)
		beq	subst_command_terminate_word_2

		moveq	#'"',d0
		bsr	dup1
		bmi	subst_command_return
subst_command_terminate_word_2:
		move.b	d6,d0
subst_command_input_loop_2:
		tst.b	quote_char(a6)
		bne	i_check_character_2

		cmp.b	#'\',d0
		beq	i_dup1_with_escaping

		cmp.b	#"'",d0
		beq	i_dup1_with_escaping
i_check_character_2:
		cmp.b	#'"',d0
		bne	i_dup1
i_dup1_with_escaping:
		tst.b	quote_char(a6)
		bne	i_escape_in_quote

		bsr	dup1_with_escaping
		bra	i_dup1_1

i_escape_in_quote:
		bsr	dup1_with_escaping_in_quote
		bra	i_dup1_1

i_dup1:
		bsr	dup1
i_dup1_1:
		bmi	subst_command_return

		move.l	tmpfiledesc(a6),d0
		bsr	fgetc
		bmi	subst_command_input_done

		bsr	is_separator
		bne	subst_command_input_loop_2

		moveq	#1,d7
		bra	subst_command_input_loop
****************
subst_command_input_done:
		move.l	tmpfiledesc(a6),d0
		lea	tmpfilename(a6),a0
		bsr	erase_tmp
		move.l	#-1,tmpfiledesc(a6)
		movea.l	a3,a0
		bra	subst_command_loop
********************************
subst_command_escape:
		bsr	dup1
		bmi	subst_command_return

		move.b	(a0)+,d0
		beq	subst_command_done

		bsr	issjis
		bne	subst_command_dup1
subst_command_dup2:
		bsr	dup1
		bmi	subst_command_return

		move.b	(a0)+,d0
		beq	subst_command_done
subst_command_dup1:
		bsr	dup1
		bmi	subst_command_return

		bra	subst_command_loop
********************************
subst_command_done:
		move.w	d4,d0
		tst.b	d5
		bne	subst_command_return

		moveq	#0,d0
		moveq	#1,d2
		bsr	dup1
		bmi	subst_command_return

		move.w	d4,d0
subst_command_return:
		tst.l	tmpfiledesc(a6)
		bmi	subst_command_return1

		movem.l	d0/a0,-(a7)
		move.l	tmpfiledesc(a6),d0
		lea	tmpfilename(a6),a0
		bsr	erase_tmp
		movem.l	(a7)+,d0/a0
subst_command_return1:
		movem.l	(a7)+,d2-d7/a2-a4
		unlk	a6
		tst.l	d0
		rts
********************************
subst_command_buffer_over:
		moveq	#-2,d0
		bra	subst_command_return
****************
unmatched:
		bsr	eputc
		bsr	eputc
		lea	msg_unmatched,a0
		bsr	enputs
subst_command_error:
		moveq	#-4,d0
		bra	subst_command_return
****************************************************************
* subst_command_2 - コマンド置換をする
*
* CALL
*      A0     ソースとなる単語の先頭アドレス
*      A1     格納するバッファの先頭アドレス
*      D1.W   バッファの容量（最後に置かれるNUL分は含まない）
*
* RETURN
*      A0     ソースの終端の次の位置
*             ただしエラーのときには保証されない
*
*      A1     バッファの次の格納位置
*             ただしエラーのときには保証されない
*
*      D0.L   0ならば成功
*             負数ならばエラー
*                  -1  展開語数が限度を超えた
*                  -2  バッファの容量を超えた
*                  -3  単語の長さが規定を超えた
*                  -4  入出力エラー，コマンドエラー等（メッセージを表示する）
*
*      D1.L   下位ワードは残りバッファ容量
*             ただしエラーのときには保証されない
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef subst_command_2

tmpfilename = -(((MAXPATH+1)+1)>>1<<1)

subst_command_2:
		link	a6,#tmpfilename
		movem.l	d7/a2-a4,-(a7)
		moveq	#-1,d7				* D7.L : 一時ファイルデスクリプタ
subst_command_2_loop:
		move.b	(a0)+,d0
		beq	subst_command_2_done

		bsr	issjis
		beq	subst_command_2_dup2

		cmp.b	#'\',d0
		beq	subst_command_2_escape

		cmp.b	#'`',d0
		bne	subst_command_2_dup1
********************************
		movea.l	a0,a2
		moveq	#'`',d0
		bsr	strchr
		beq	unmatched_2

		move.l	a0,d0
		sub.l	a2,d0
		addq.l	#1,a0
		tst.b	not_execute
		bne	subst_command_2_loop

		movem.l	a0-a1,-(a7)
		movea.l	a2,a0
		lea	tmpfilename(a6),a1
		bsr	subst_command_redirect
		movem.l	(a7)+,a0-a1
		bmi	subst_command_2_return

		move.l	d0,d7
		movea.l	a0,a3
		movea.l	a1,a4
subst_command_2_read_loop:
		move.w	d7,d0
		bsr	fgetc
		bmi	subst_command_2_read_done

		bsr	dup1_2
		bmi	subst_command_2_return

		cmp.b	#CR,d0
		bne	subst_command_2_read_loop

		movea.l	a1,a4
		subq.l	#1,a4
		bra	subst_command_2_read_loop

subst_command_2_read_done:
		cmpi.b	#CR,(a4)
		bne	subst_command_2_input_done

		clr.b	(a1)
		movea.l	a4,a0
		moveq	#LF,d0
		bsr	strchr
		tst.b	(a0)+
		beq	subst_command_2_erase_last_newline

		tst.b	(a0)
		bne	subst_command_2_input_done
subst_command_2_erase_last_newline:
		move.l	a1,d0
		sub.l	a4,d0
		add.w	d0,d1
		movea.l	a4,a1
subst_command_2_input_done:
		move.w	d7,d0
		lea	tmpfilename(a6),a0
		bsr	erase_tmp
		moveq	#-1,d7
		movea.l	a3,a0
		bra	subst_command_2_loop

subst_command_2_escape:
		move.b	(a0)+,d0
		cmp.b	#'`',d0
		beq	subst_command_2_dup1

		cmp.b	#'\',d0
		beq	subst_command_2_dup1

		subq.l	#1,a0
		moveq	#'\',d0
		bra	subst_command_2_dup1

subst_command_2_dup2:
		bsr	dup1_2
		bmi	subst_command_2_return

		move.b	(a0)+,d0
		beq	subst_command_2_done
subst_command_2_dup1:
		bsr	dup1_2
		bmi	subst_command_2_return

		bra	subst_command_2_loop

subst_command_2_done:
		clr.b	(a1)+
		moveq	#0,d0
subst_command_2_return:
		tst.l	d7
		bmi	subst_command_2_return1

		movem.l	d0/a0,-(a7)
		move.w	d7,d0
		lea	tmpfilename(a6),a0
		bsr	erase_tmp
		movem.l	(a7)+,d0/a0
subst_command_2_return1:
		movem.l	(a7)+,d7/a2-a4
		unlk	a6
		tst.l	d0
		rts
********************************
unmatched_2:
		bsr	eputc
		bsr	eputc
		lea	msg_unmatched,a0
		bsr	enputs
		moveq	#-4,d0
		bra	subst_command_2_return
****************************************************************
subst_command_redirect:
		movem.l	d1-d3,-(a7)
		move.l	d0,d3
		exg	a0,a1
		bsr	tmpfile
		exg	a0,a1
		bmi	subst_command_redirect_error

		move.l	d0,d2
		move.w	d0,d1
		moveq	#1,d0				* 標準出力を
		bsr	redirect			* リダイレクト
		bmi	subst_command_redirect_perror

		movem.l	d0-d2/d4-d7/a0-a6,-(a7)
		move.w	d3,d0
		moveq	#0,d1
		bsr	fork
		move.l	d0,d3
		movem.l	(a7)+,d0-d2/d4-d7/a0-a6
		move.w	d0,d1
		moveq	#1,d0
		bsr	unredirect
		tst.l	d3
		bne	subst_command_fork_error

		clr.w	-(a7)				* 先頭
		clr.l	-(a7)				* 　まで
		move.w	d2,-(a7)			* 　
		DOS	_SEEK				* 　シークする
		addq.l	#8,a7
		move.l	d2,d0				* ファイル・ハンドルを返す
subst_command_redirect_return:
		movem.l	(a7)+,d1-d3
		rts

subst_command_fork_error:
		move.l	d2,d0
		exg	a0,a1
		bsr	erase_tmp
		exg	a0,a1
		bra	subst_command_redirect_error

subst_command_redirect_perror:
		bsr	perror
subst_command_redirect_error:
		moveq	#-4,d0
		bra	subst_command_redirect_return
****************************************************************
erase_tmp:
		bsr	fclose
		bra	remove
****************************************************************
iscrlf:
		cmp.b	#CR,d0
		beq	return

		cmp.b	#LF,d0
return:
		rts
****************************************************************
* subst_command_wordlist - 単語並びの各単語についてコマンド置換をする
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
*
*      CCR    TST.L D0
****************************************************************
.xdef subst_command_wordlist

subst_command_wordlist:
		movem.l	d1-d3/a0-a1,-(a7)
		move.w	#MAXWORDLISTSIZE,d1	* D1 : 最大文字数
		moveq	#0,d3			* D3 : 展開後の語数
		move.w	d0,d2			* D2 : 引数カウンタ
		move.l	a0,-(a7)
		lea	tmpline,a0		* 一時領域に
		bsr	copy_wordlist		* 引数並びを一旦コピーしてこれをソースとする
		movea.l	(a7)+,a1
		bra	subst_wordlist_continue

subst_wordlist_loop:
		move.w	#MAXWORDS,d0
		sub.w	d3,d0
		bsr	subst_command
		bmi	subst_wordlist_subst_error

		add.w	d0,d3
subst_wordlist_continue:
		dbra	d2,subst_wordlist_loop

		moveq	#0,d0
		move.w	d3,d0
subst_wordlist_return:
		movem.l	(a7)+,d1-d3/a0-a1
		tst.l	d0
		rts


subst_wordlist_subst_error:
		cmp.l	#-1,d0
		beq	subst_wordlist_too_many_words

		cmp.l	#-2,d0
		beq	subst_wordlist_too_long_line

		cmp.l	#-3,d0
		beq	subst_wordlist_too_long_word

		bra	subst_wordlist_error

subst_wordlist_too_many_words:
		bsr	too_many_words
		bra	subst_wordlist_error

subst_wordlist_too_long_word:
		bsr	too_long_word
		bra	subst_wordlist_error

subst_wordlist_too_long_line:
		bsr	too_long_line
subst_wordlist_error:
		moveq	#-1,d0
		bra	subst_wordlist_return

.end
