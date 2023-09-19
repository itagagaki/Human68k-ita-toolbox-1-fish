* glob.s
* Itagaki Fumihiko 02-Sep-90  Create.

.include doscall.h
.include limits.h
.include stat.h
.include ../src/fish.h

.xref issjis
.xref strlen
.xref strcpy
.xref stpcpy
.xref strmove
.xref strpcmp
.xref strfor1
.xref sort_wordlist
.xref copy_wordlist
.xref escape_quoted
.xref strip_quotes
.xref strip_excessive_slashes
.xref is_slash_or_backslash
.xref drvchkp
.xref no_match
.xref too_many_words
.xref too_long_line
.xref dos_allfile
.xref builtin_table

.xref tmpword1
.xref pathname_buf
.xref doscall_pathname

.xref tmpline
.xref flag_ciglob
.xref flag_nonomatch

.text

****************************************************************
* check_wildcard - 語にワイルドカードが含まれているかどうか調べる
*
* CALL
*      A0     語 (may be contains ", ', and/or \)
*
* DESCRIPTION
*      語にワイルドカードが含まれているかどうか調べ、もしあれば
*      最初に見つかったワイルドカード文字を返し、無ければ 0 を
*      返す。
*
* RETURN
*      D0.L   下位バイトは最初に見つかったワイルドカード文字
*      CCR    TST.L D0
****************************************************************
.xdef check_wildcard

check_wildcard:
		movem.l	d1/a0,-(a7)
		moveq	#0,d1
check_wildcard_loop:
		move.b	(a0)+,d0
		beq	no_wildcard

		bsr	issjis
		beq	check_wildcard_skip1

		tst.b	d1
		beq	check_wildcard_1

		cmp.b	d1,d0
		bne	check_wildcard_loop
check_wildcard_quote:
		eor.b	d0,d1
		bra	check_wildcard_loop

check_wildcard_1:
		cmp.b	#'*',d0
		beq	check_wildcard_done

		cmp.b	#'?',d0
		beq	check_wildcard_done

		cmp.b	#'[',d0
		beq	check_wildcard_done

		cmp.b	#'"',d0
		beq	check_wildcard_quote

		cmp.b	#"'",d0
		beq	check_wildcard_quote

		cmp.b	#'\',d0
		bne	check_wildcard_loop

		move.b	(a0)+,d0
		beq	no_wildcard

		bsr	issjis
		bne	check_wildcard_loop
check_wildcard_skip1:
		move.b	(a0)+,d0
		bne	check_wildcard_loop
no_wildcard:
		moveq	#0,d0
		bra	check_wild_return

check_wildcard_done:
		moveq	#-1,d1
		move.b	d0,d1
		exg	d0,d1
check_wild_return:
		movem.l	(a7)+,d1/a0
		tst.l	d0
		rts
****************************************************************
.xdef get_1char

get_1char:
		move.b	(a2)+,d0
		cmp.b	#'\',d0
		bne	get_1char_done

		move.b	(a2)+,d0
get_1char_done:
		tst.b	d0
		rts
****************************************************************
copychar:
		move.l	d1,-(a7)
		move.l	d0,d1
		beq	copychar_done

copychar_loop:
		bsr	get_1char
		move.b	d0,(a0)+
		subq.l	#1,d1
		bne	copychar_loop
copychar_done:
		move.l	(a7)+,d1
		rts
****************************************************************
glob_skip_slashes:
		move.l	d1,-(a7)
		moveq	#0,d1
		subq.l	#4,a7
glob_skip_slashes_loop:
		move.l	a2,(a7)
		addq.l	#1,d1
		bsr	get_1char
		bsr	is_slash_or_backslash
		beq	glob_skip_slashes_loop

		subq.l	#1,d1
		move.l	d1,d0
		movea.l	(a7)+,a2
		move.l	(a7)+,d1
		rts
****************************************************************
* globsub
*
* CALL
*      (pathname_buf)  検索するディレクトリのパス名．
*                      MAXPATH+1バイトの容量が必要．
*      A0     pathname_bufにセットされた文字列のケツ
*      A2     検索するファイル名（may be contains \）
*      D2.W   再帰の深さ．最初は0
*      A3     適合したファイル名を格納するバッファを指す
*      D3.W   展開する個数の限度
*      D4.W   バッファの容量
*
* RETURN
*      D0.L   負数ならば正常．
*                  0: パス名のディレクトリが深過ぎる or パス名が長過ぎる
*                  1: 最大語数を超えた
*                  2: バッファの容量が足りない
*                  4: その他のエラー。（] がないなど）メッセージが表示される。
*
*      D1.W   適合した数だけ増加する
*             D1>D3 となったら D0.L に 1 をセットして処理を中止する
*
*      D4.W   バッファに追加した分だけ減少する
*             足りなくなったら D0.L に 2 をセットして処理を中止する
*
*      A3     バッファの次の格納位置
*
*      D5/A0-A2     破壊
*
* NOTE
*      33回めまで再帰する．スタックに注意！
*
*      参考までに書いておくと，Human68kでは，絶対パス名のディレクトリ部
*      （ドライブ名は含まない．最初の / から最後の / まで）の長さは，
*      最大64文字という制限がある．
*      ということは，ルート・ディレクトリを1世とすると，サブディレクトリは
*      31世までしか無い．（32世だと，続くファイル名を記述できない）
*      したがって，32回のディレクトリ検索と1回のファイル検索，すなわち，33回
*      の再帰で充分な筈である．
*
*      なお，絶対パスは制限内であっても，相対パスだと制限を超える場合もある
*      が，それは認めず，相対パスであっても絶対パスの制限をそのまま適用する
*      ことにした．（スタックやバッファを静的に安全に確保するため）
****************************************************************
curdot   = -4
curbot   = curdot-4
slashlen = curbot-4
dirlen   = slashlen-4
statbuf  = dirlen-STATBUFSIZE

globsub:
		link	a6,#statbuf

		move.l	a2,curdot(a6)
scan_subdir:
		move.l	a2,curbot(a6)
		bsr	get_1char
		beq	scan_subdir_done

		bsr	is_slash_or_backslash
		beq	scan_subdir_done

		bsr	issjis
		bne	scan_subdir

		tst.b	(a2)+
		bne	scan_subdir

		subq.l	#1,a2
scan_subdir_done:
		movea.l	curbot(a6),a2
		bsr	glob_skip_slashes
		move.l	d0,slashlen(a6)
		*
		move.l	a0,d0
		lea	pathname_buf,a1
		sub.l	a1,d0
		cmp.l	#MAXHEAD,d0
		bhi	globsub_error0

		move.l	d0,dirlen(a6)
		lea	doscall_pathname,a0
		bsr	stpcpy
		lea	dos_allfile,a1
		bsr	strcpy
		lea	doscall_pathname,a0
		bsr	strip_excessive_slashes
		move.w	#MODEVAL_ALL,-(a7)
		move.l	a0,-(a7)
		pea	statbuf(a6)
		DOS	_FILES
		lea	10(a7),a7
globsub_loop:
		tst.l	d0
		bmi	globsub_return

		move.b	statbuf+ST_MODE(a6),d0
		btst	#MODEBIT_DIR,d0			*  ディレクトリなら
		bne	globsub_mode_ok			*  よし

		btst	#MODEBIT_VOL,d0			*  ボリューム・ラベルは
		bne	globsub_next			*  除外
globsub_mode_ok:
		lea	statbuf+ST_NAME(a6),a0
		movea.l	curdot(a6),a1
		cmpi.b	#'.',(a0)
		bne	globsub_compare

		cmpi.b	#'.',(a1)
		beq	globsub_compare

		cmpi.b	#'\',(a1)
		bne	globsub_next

		cmpi.b	#'.',1(a1)
		bne	globsub_next
globsub_compare:
		movea.l	curbot(a6),a2
		move.b	(a2),d5
		clr.b	(a2)
		move.b	flag_ciglob(a5),d0
		bsr	strpcmp
		move.b	d5,(a2)
		tst.l	d0
		bmi	globsub_error4
		bne	globsub_next

		bsr	strlen
		add.l	slashlen(a6),d0
		add.l	dirlen(a6),d0
		cmp.l	#MAXPATH,d0
		bhi	globsub_error0

		movea.l	a0,a1
		lea	pathname_buf,a0
		add.l	dirlen(a6),a0
		bsr	stpcpy
		move.l	slashlen(a6),d0
		bsr	copychar
		clr.b	(a0)
		tst.b	(a2)
		beq	globsub_terminal

		addq.w	#1,d2
		cmp.w	#MAXDIRDEPTH,d2
		bhi	globsub_error0

		bsr	globsub				***!! 再帰 !!***
		subq.w	#1,d2
		tst.l	d0
		bpl	globsub_return
		bra	globsub_next

globsub_terminal:
		moveq	#1,d0
		addq.w	#1,d1
		cmp.w	d3,d1
		bhi	globsub_return

		lea	pathname_buf,a1
		move.l	a0,d0
		addq.l	#1,d0
		sub.l	a1,d0
		sub.l	d0,d4
		bcs	globsub_buffer_full

		movea.l	a3,a0
		bsr	strmove
		movea.l	a0,a3
globsub_next:
		pea	statbuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		bra	globsub_loop

globsub_buffer_full:
		moveq	#2,d0
globsub_return:
		unlk	a6
		rts

globsub_error0:
		moveq	#0,d0
		bra	globsub_return

globsub_error4:
		moveq	#4,d0
		bra	globsub_return
****************************************************************
* glob - evaluate filename with wildcard
*
* CALL
*      A0     ワイルドカードを含むファイル名．', " and/or \ によるクオートが可
*      A1     適合したファイル名を格納するバッファを指す
*      D0.W   展開する個数の限度
*      D1.W   バッファの容量
*
* RETURN
*      A1     バッファの次の格納位置
*
*      D0.L   正数ならば成功．下位ワードは適合した数．
*             負数ならばエラー．
*                  -1  適合するものの個数が限度を超えた
*                  -2  バッファの容量を超えた
*                  -4  その他のエラー．メッセージが表示される．
*                           パス名のディレクトリが深過ぎる or パス名が長過ぎる．
*
*      D1.L   下位ワードは残りバッファ容量
*             上位ワードは破壊
*
*      CCR    TST.L D0
*****************************************************************
.xdef glob

glob:
		movem.l	d2-d6/a0/a2-a4,-(a7)
		move.w	d0,d3			* D3.W : 最大展開個数
		moveq	#0,d4
		move.w	d1,d4			* D4.L : バッファ容量
		move.w	d1,d5
		movea.l	a1,a4			* A4 : 展開バッファの先頭
		movea.l	a1,a3			* A3 : 展開バッファ
		lea	tmpword1,a1
		bsr	escape_quoted		* A1 : クオートをエスケープに代えた検索文字列
		moveq	#0,d1			* D1.W : 適合した個数を得る

		movea.l	a1,a2
		bsr	get_1char
		cmp.b	#'~',d0
		bne	glob_real

		bsr	get_1char
		cmp.b	#'~',d0
		bne	glob_real

		bsr	get_1char
		bsr	is_slash_or_backslash
		bne	glob_real
****************
glob_builtin:
		bsr	glob_skip_slashes
		addq.l	#3,d0				*  3 == strlen("~~/")
		move.l	d0,d2
		exg	a1,a2
		movem.l	a0/a4,-(a7)
		lea	builtin_table,a4
glob_builtin_loop:
		move.l	(a4),d0
		beq	glob_builtin_nomore

		movea.l	d0,a0
		moveq	#0,d0				*  case dependent
		bsr	strpcmp
		tst.l	d0
		bmi	glob_builtin_error4
		bne	glob_builtin_continue

		moveq	#1,d0
		addq.w	#1,d1
		cmp.w	d3,d1
		bhi	glob_builtin_done

		bsr	strlen
		add.l	d2,d0
		addq.l	#1,d0
		sub.l	d0,d4
		bcs	glob_builtin_buffer_full
					* A0:entry     A1:pat(com)  A2:pat(top)  A3:buf
		exg	a0,a3		* A0:buf       A1:pat(com)               A3:entry
		move.l	d2,d0
		move.l	a2,-(a7)
		bsr	copychar
		movea.l	(a7)+,a2
		move.l	a1,-(a7)
		movea.l	a3,a1		*              A1:entry
		bsr	strmove
		movea.l	(a7)+,a1	*              A1:pat(com)
		exg	a0,a3		* A0:entry                               A3:buf
glob_builtin_continue:
		lea	10(a4),a4
		bra	glob_builtin_loop

glob_builtin_error4:
		moveq	#4,d0
		bra	glob_builtin_done

glob_builtin_buffer_full:
		moveq	#2,d0
		bra	glob_builtin_done

glob_builtin_nomore:
		moveq	#-1,d0
glob_builtin_done:
		movem.l	(a7)+,a0/a4
		tst.l	d0
		beq	glob_nothing
		bpl	glob_error

		moveq	#0,d0
		move.w	d1,d0
		movea.l	a4,a0
		bra	glob_done
****************
glob_real:
						* A0 : 元の検索文字列
		movea.l	a1,a2			* A2 : クオートをエスケープに代えた検索文字列
		lea	pathname_buf,a1
		movem.l	d1/a0,-(a7)
		moveq	#MAXPATH,d6
		movea.l	a2,a0
		bsr	get_1char
		beq	get_firstdir_done

		bsr	is_slash_or_backslash
		beq	copy_root

		bsr	issjis
		beq	get_firstdir_done

		move.b	d0,d1
		bsr	get_1char
		cmp.b	#':',d0
		bne	get_firstdir_done

		subq.l	#2,d6
		bcs	get_firstdir_error

		move.b	d1,(a1)+
		move.b	d0,(a1)+
copy_root_loop:
		movea.l	a2,a0
		bsr	get_1char
		bsr	is_slash_or_backslash
		bne	get_firstdir_done
copy_root:
		subq.l	#1,d6
		bcs	get_firstdir_error

		move.b	d0,(a1)+
		bra	copy_root_loop

get_firstdir_done:
		clr.b	(a1)
		movea.l	a0,a2
		cmp.w	d6,d6
get_firstdir_error:
		movem.l	(a7)+,d1/a0
		bcs	glob_error_1

		bclr	#31,d0
		move.l	a0,-(a7)
		lea	pathname_buf,a0
		bsr	drvchkp
		movea.l	(a7)+,a0
		bmi	glob_nothing

		movem.l	d5/a0,-(a7)
		movea.l	a1,a0
		moveq	#0,d2
		bsr	globsub
		movem.l	(a7)+,d5/a0
		tst.l	d0
		beq	glob_nothing
		bpl	glob_error

		moveq	#0,d0
		move.w	d1,d0
		movea.l	a4,a0
		bsr	sort_wordlist
glob_done:
		movea.l	a3,a1
		move.w	d4,d1
		movem.l	(a7)+,d2-d6/a0/a2-a4
		tst.l	d0
		rts

glob_nothing:
		moveq	#0,d0
		move.l	d5,d1
		bra	glob_done

glob_error:
		neg.l	d0
		bra	glob_done

glob_error_1:
		moveq	#-1,d0
		bra	glob_done
****************************************************************
* glob_wordlist - 引数並びの各語についてファイル名展開をする
*                 ついでにクオートも外してしまう
*
* CALL
*      A0     格納領域の先頭．引数並びと重なっていても良い．
*      A1     引数並びの先頭
*      D0.W   語数
*
* RETURN
*      D0.L   正数ならば成功．下位ワードは展開後の語数
*             負数ならばエラー
*
*      (tmpline)   破壊される
*      (A0)   破壊
*
*      CCR    TST.L D0
****************************************************************
.xdef glob_wordlist

glob_wordlist:
		movem.l	d1-d5/a0-a2,-(a7)
		move.w	#MAXWORDLISTSIZE,d1	*  D1 : 最大文字数
		move.w	d0,d2			*  D2 : 引数カウンタ
		moveq	#0,d3			*  D3 : 展開後の語数
		moveq	#0,d4			*  D4 : glob status := 0 .. ワイルドカードはまだない
		moveq	#-1,d5			*  D5.W := no match のときのアクション
		move.l	a0,-(a7)
		lea	tmpline(a5),a0		*  一時領域に
		bsr	copy_wordlist		*  引数並びを一旦コピーしてこれをソースとする
		movea.l	(a7)+,a1
		bra	glob_wordlist_continue

glob_wordlist_loop:
		bsr	check_wildcard
		beq	glob_wordlist_just_copy

		*  ワイルドカードがある

		move.w	#MAXWORDS,d0
		sub.w	d3,d0
		bsr	glob
		bmi	glob_wordlist_glob_error	*  error
		bne	glob_wordlist_glob_found	*  match found

		*  no match

		tst.w	d5
		bpl	glob_wordlist_glob_1

		moveq	#0,d5
		move.b	flag_nonomatch(a5),d5
glob_wordlist_glob_1:
		beq	glob_wordlist_glob_2		*  unset nonomatch

		moveq	#1,d4				*  D4 := 1 .. ワイルドカードがあった
							*             マッチした（ことにする）
		cmp.b	#1,d5
		bne	glob_wordlist_just_copy		*  set nonomatch .. 単語をコピーする
		*  set nonomatch=drop .. 単語を捨てる
glob_wordlist_glob_2:
		*  unset nonomatch .. 単語を捨てる
		tst.l	d4
		bne	glob_wordlist_glob_next

		moveq	#-1,d4				*  D4 := -1 .. ワイルドカードがあった
							*              マッチするものはまだない
		bra	glob_wordlist_glob_next

glob_wordlist_glob_found:
		add.w	d0,d3
		moveq	#1,d4				*  D4 := 1 .. ワイルドカードがあった
							*             マッチした
glob_wordlist_glob_next:
		bsr	strfor1
		bra	glob_wordlist_continue

glob_wordlist_just_copy:
		movea.l	a0,a2
		bsr	strfor1
		exg	a0,a2
		bsr	strip_quotes
		bsr	strlen
		addq.w	#1,d0
		sub.w	d0,d1
		bmi	glob_wordlist_too_long_line

		cmp.w	#MAXWORDS,d3
		bhs	glob_wordlist_too_many_words

		addq.w	#1,d3
		exg	a0,a1
		bsr	strmove
		exg	a0,a1
		movea.l	a2,a0
glob_wordlist_continue:
		dbra	d2,glob_wordlist_loop

		tst.l	d4
		bmi	glob_wordlist_no_match

		moveq	#0,d0
		move.w	d3,d0
glob_wordlist_return:
		movem.l	(a7)+,d1-d5/a0-a2
		tst.l	d0
		rts

glob_wordlist_glob_error:
		cmp.w	#-1,d0
		beq	glob_wordlist_too_many_words

		cmp.w	#-2,d0
		beq	glob_wordlist_too_long_line

		bra	glob_wordlist_error

glob_wordlist_no_match:
		bsr	no_match
		bra	glob_wordlist_error

glob_wordlist_too_many_words:
		bsr	too_many_words
		bra	glob_wordlist_error

glob_wordlist_too_long_line:
		bsr	too_long_line
glob_wordlist_error:
		moveq	#-1,d0
		bra	glob_wordlist_return

.end
