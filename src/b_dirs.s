* b_dirs.s
* This contains built-in command 'cd'('chdir'), 'dirs', 'popd', 'pushd'.
*
* Itagaki Fumihiko 06-Oct-90  Create.

.include error.h
.include limits.h
.include ../src/fish.h

.xref atou
.xref strlen
.xref strcmp
.xref strcpy
.xref for1str
.xref fornstrs
.xref rotate
.xref memmovd
.xref memmovi
.xref isabsolute
.xref cat_pathname
.xref slash_to_backslash
.xref putc
.xref puts
.xref eputs
.xref enputs1
.xref put_space
.xref put_newline
.xref echo
.xref chdir
.xref getcwd
.xref is_under_home
.xref find_shellvar
.xref set_svar
.xref setenv
.xref perror1
.xref perror_command_name
.xref command_error
.xref usage
.xref no_space_for
.xref bad_arg
.xref too_many_args
.xref word_cdpath
.xref word_home
.xref pathname_buf

.xref dstack

cwdbuf = -(((MAXPATH+1)+1)>>1<<1)

.text

****************************************************************
* chdir_var - Change current working drive/directory to $varname
*
* CALL
*      A0     varname
*
* RETURN
*      D0.L   エラーならば負数（ＯＳのエラー・コード）
*             シェル変数が無いか，値の単語が無いか，最初の単語が空ならば 1
*             $varname[1]に chdir できたならば 0
*
*      CCR    TST.L D0
*****************************************************************
.xdef chdir_var

chdir_var:
		move.l	a0,-(a7)
		bsr	find_shellvar
		beq	chdir_var_fail			*  変数が無い

		lea	2(a0),a0
		move.w	(a0)+,d1			*  D1.W : 単語数  A0 : 値
		beq	chdir_var_fail			*  単語が無い

		bsr	for1str
		bsr	isabsolute
		bne	chdir_var_fail			*  最初の単語が空

		bsr	chdir
		bmi	chdir_var_done

		moveq	#0,d0
chdir_var_done:
		movea.l	(a7)+,a0
chdir_home_return:
		rts

chdir_var_fail:
		moveq	#1,d0
		bra	chdir_var_done
****************************************************************
* chdir_home - Change current working directory and drive to $home
*
* CALL
*      none
*
* RETURN
*      D0.L   エラーならば負数（ＯＳのエラー・コード）
*             シェル変数 home が無いか，値が無いか，最初の値が空ならば 1
*             $home[1]に chdir できたならば 0
*
*      CCR    TST.L D0
*
*      A0     破壊
*****************************************************************
chdir_home:
		lea	word_home,a0		*  シェル変数 home を
		bsr	chdir_var
		beq	chdir_home_return
		bmi	chdir_home_return

		lea	msg_no_home,a0
		bra	command_error		*  D0.L は 1 になる．
****************************************************************
* chdirx - Change current working directory and/or drive.
*
* CALL
*      A0     （ドライブ名＋）ディレクトリ名
*
* RETURN
*      D0.L   エラーならば負数（ＯＳのエラー・コード）．
*             指定のディレクトリに移動したならば 0．
*             指定の名前から補完されたディレクトリに移動したならば 1．
*
*      CCR    TST.L D0
*
* DESCRIPTION
*      name が空文字列なら
*           chdir($home)
*      さもなくば
*           chdir(name)
*           失敗したなら（name がドライブ名を持たず
*           ./ や ../ で始まっていない場合に限り）
*                chdir(concat($cdpath[1], name))
*                chdir(concat($cdpath[2], name))
*                             :
*                chdir(concat($cdpath[$#cdpath], name))
*                chdir($name)
*****************************************************************
chdirx:
		movem.l	d1-d3/a0-a3,-(a7)
		tst.b	(a0)
		bne	chdirx_try

		bsr	chdir_home
		bmi	chdirx_done
		bra	chdirx_done1

chdirx_try:
		bsr	chdir				*  カレント・ディレクトリを変更する．
		bpl	chdirx_done0			*  成功したなら帰る．

		cmpi.b	#':',1(a0)			*  ドライブ指定がある場合は
		beq	chdirx_done			*  これ以上トライしない．

		movea.l	a0,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
chdirx_1:
		cmpi.b	#'/',(a1)
		beq	chdirx_done

		cmpi.b	#'\',(a1)
		beq	chdirx_done

		movea.l	a0,a2				*  A2 : dirname
		lea	word_cdpath,a0
		bsr	find_shellvar
		beq	try_varname

		addq.l	#2,a0
		move.w	(a0)+,d1			*  D1.W : cdpath の単語数
		bsr	for1str
		movea.l	a0,a1				*  A1 : cdpath の単語並び
		lea	pathname_buf,a0
		bra	try_cdpath_continue

try_cdpath_loop:
		bsr	cat_pathname
		bmi	try_cdpath_continue

		bsr	chdir
		bpl	chdirx_done1
try_cdpath_continue:
		dbra	d1,try_cdpath_loop
****************
try_varname:
		movea.l	a2,a0
		bsr	chdir_var
		beq	chdirx_done1
		bmi	chdirx_done

		moveq	#ENODIR,d0
chdirx_done:
		movem.l	(a7)+,d1-d3/a0-a3
		tst.l	d0
		rts

chdirx_done0:
		moveq	#0,d0
		bra	chdirx_done

chdirx_done1:
		moveq	#1,d0
		bra	chdirx_done
****************************************************************
*  Name
*       cd - change working directory
*
*  Synopsis
*       cd                go to home directory
*       cd +n             go to n'th of directory stack
*	cd name           go to name
****************************************************************
.xdef cmd_cd
.xdef reset_cwd

cmd_cd:
		cmp.w	#1,d0			*  引数が
		bhi	too_many_args		*  2つ以上あればエラー．
		blo	cd_home			*  1つも無いなら $home に chdir する．

		cmpi.b	#'+',(a0)		*  引数が + で始まらないならば
		bne	cd_name			*  処理 cd_name へ

		bsr	get_dstack_element	*  D1.L : 数値-1  A0 : 要素のアドレス
		bne	cd_return		*  エラならおしまい．

		bsr	popd_sub		*  そこに移動してその要素を削除する．
		bne	cd_return		*  エラーならおしまい．

		tst.l	d1
		beq	cd_dirs_done		*  循環送りの必要なし．

		addq.w	#1,d1
		movea.l	dstack(a5),a1
		cmp.w	8(a1),d1
		bhi	cd_dirs_done		*  循環送りの必要なし．

		exg	a0,a1
		move.l	4(a0),d0
		lea	(a0,d0.l),a2		*  A2 : 現在の末尾アドレス(+1)
		lea	10(a0),a0		*  A0 : 先頭の要素
		bsr	rotate			*  要素を循環送りする．
cd_dirs_done:
		bsr	print_dirs		*  ディレクトリ・スタックを表示する．
		bra	chdir_success
****************
cd_name:
		bsr	chdirx			*  指定のディレクトリに chdirx する．
		bmi	cd_fail			*  失敗したならばエラー処理へ．
		beq	cd_return

		lea	print_directory(pc),a1
		bsr	print_cwd
		bsr	put_newline
chdir_success:
		moveq	#0,d0
		bra	cd_return
****************
cd_home:
		bsr	chdir_home
		bmi	cd_fail
cd_return:
reset_cwd:
		link	a6,#cwdbuf
		movem.l	d0-d1/a0-a1,-(a7)
		lea	cwdbuf(a6),a0
		bsr	getcwd
		movea.l	a0,a1
		lea	word_cwd,a0
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
		movea.l	a1,a0
		bsr	slash_to_backslash
		lea	word_upper_pwd,a0
		bsr	setenv
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
		rts
****************
cd_fail:
		bsr	perror1
		bra	cd_return
****************************************************************
*  Name
*       pushd - push directory stack
*
*  Synopsis
*       pushd             exchange current and top
*       pushd +n          rotate to let n'th be top
*	pushd directory   push current and chdir to directory
****************************************************************
.xdef cmd_pushd

cmd_pushd:
		link	a6,#cwdbuf
		movea.l	a0,a1
		move.w	d0,d1			*  argc をセーブする．

		lea	cwdbuf(a6),a0		*  cwdbufに
		bsr	getcwd			*  カレントディレクトリを得て
		bsr	strlen			*  その長さ(+1)を
		addq.l	#1,d0
		move.l	d0,d7			*  D7.Lに保存する．

		move.w	d1,d0			*  argc をポップする．
		beq	exchange		*  引数が無いなら先頭要素とカレントを交換．

		cmp.w	#1,d0			*  引数が 2つ以上あれば
		bhi	pushd_too_many_args	*  'Too many args' エラーへ．

		cmpi.b	#'+',(a1)		*  引数が + で始まらないならば
		bne	push_new		*  処理 push_new へ．

		movea.l	a1,a0
		bsr	get_dstack_element	*  D1.L : 数値-1  A0 : 要素のアドレス
		bne	cmd_pushd_return	*  エラーならおしまい．

		bsr	pushd_exchange_sub	*  A0が示す要素にポップし，カレントをプッシュする．
		bne	cmd_pushd_return	*  エラーならおしまい．

		*  スタックの要素を巡回する
		movea.l	a0,a1

		addq.w	#1,d1
		movea.l	dstack(a5),a0
		cmp.w	8(a0),d1
		bhs	cmd_pushd_done		*  循環送りの必要なし．

		move.l	4(a0),d0
		lea	(a0,d0.l),a2		*  A2 : 現在の末尾アドレス(+1)
		lea	10(a0),a0		*  A0 : 先頭の要素
		bsr	rotate			*  要素を循環送りする．
		bra	cmd_pushd_done
****************
exchange:
		movea.l	dstack(a5),a0
		tst.w	8(a0)			*  スタックに要素が無いならば
		beq	pushd_empty		*  エラー．

		lea	10(a0),a0		*  先頭の要素と
		bsr	pushd_exchange_sub	*  カレント・ディレクトリを交換する．
		bne	cmd_pushd_return	*  失敗したならおしまい．

		bra	cmd_pushd_done
****************
push_new:
		movea.l	dstack(a5),a0
		cmpi.w	#MAXWORDS,8(a0)
		bhs	pushd_too_many_elements

		move.l	4(a0),d0		*  スタックの長さに
		add.l	d7,d0			*  カレント・ディレクトリの長さ(+1)を加えると
		cmp.l	(a0),d0			*  スタックの容量を超えるならば
		bhi	pushd_stack_full	*  エラー．

		movea.l	a1,a0			*  指定されたディレクトリに
		bsr	chdirx			*  chdirx する．
		bmi	pushd_perror_return

		bsr	push_cwd		*  元のカレント・ディレクトリをプッシュする．
cmd_pushd_done:
		bsr	print_dirs		*  ディレクトリ・スタックを表示する．
cmd_pushd_return:
		bsr	reset_cwd		*  cwd を setして
		unlk	a6
		rts				*  終了．
****************
pushd_too_many_args:
		bsr	too_many_args
		bra	cmd_pushd_return
****************
pushd_too_many_elements:
		bsr	perror_command_name
		lea	msg_directory_stack,a0
		bsr	eputs
		lea	msg_too_deep,a0
		bsr	enputs1
		bra	cmd_pushd_return
****************
pushd_stack_full:
		bsr	stack_full
		bra	cmd_pushd_return
****************
pushd_empty:
		bsr	dstack_empty
		bra	cmd_pushd_return
****************
pushd_perror_return:
		bsr	perror1
		bra	cmd_pushd_return
****************************************************************
*  Name
*       popd - pop directory stack
*
*  Synopsis
*       popd       pop top
*       popd +n    drop n'th
****************************************************************
.xdef cmd_popd

cmd_popd:
		cmp.w	#1,d0			*  引数が２つ以上あれば
		bhi	too_many_args		*  エラー．
		blo	pop			*  引数が無いならポップ．

		cmpi.b	#'+',(a0)		*  引数が + で始まらないならば
		bne	bad_arg			*  エラー．

		movea.l	a0,a1
		bsr	get_dstack_element	*  A0 : 数値が示す要素のアドレス
		bne	popd_return		*  エラーならばおしまい．

		bsr	popd_sub_delete		*  要素を削除する．
		bra	pop_done		*  スタックを表示し，cwd を setして終了．

pop:
		movea.l	dstack(a5),a0
		lea	8(a0),a0
		tst.w	(a0)+			*  スタックに要素が無いならば
		beq	dstack_empty		*  エラー．

		bsr	popd_sub		*  要素に移動して削除する
		bne	popd_return		*  失敗ならばおしまい．
pop_done:
		bsr	print_dirs		*  ディレクトリ・スタックを表示する．
popd_return:
		bra	reset_cwd		*  cwd を setして終了．
****************************************************************
*  Name
*       pwd/dirs - print current working directory / directory stack
*
*  Synopsis
*       pwd [ -l ]
*       dirs [ -l ]
****************************************************************
.xdef cmd_pwd
.xdef cmd_dirs

cmd_pwd:
		sf	d1
		bra	cmd_pwd_dirs

cmd_dirs:
		st	d1
cmd_pwd_dirs:
		cmp.w	#1,d0
		blo	print_dirs_1
		bhi	pwd_dirs_too_many_args

		lea	word_switch_l,a1
		bsr	strcmp
		bne	pwd_dirs_bad_arg

		lea	puts(pc),a1
		bra	print_dirs_2

print_dirs:
		st	d1
print_dirs_1:
		lea	print_directory(pc),a1
print_dirs_2:
		bsr	print_cwd
		tst.b	d1
		beq	print_dirs_done

		movea.l	dstack(a5),a0
		move.w	8(a0),d0
		beq	print_dirs_done

		bsr	put_space
		lea	10(a0),a0
		clr.l	a2
		bsr	echo
print_dirs_done:
		bsr	put_newline
		bra	return_0

pwd_dirs_bad_arg:
		bsr	bad_arg
		bra	pwd_dirs_usage

pwd_dirs_too_many_args:
		bsr	too_many_args
pwd_dirs_usage:
		lea	msg_pwd_dirs_usage,a0
		bra	usage
****************************************************************
* get_dstack_element
*
* CALL
*      A0     "+n" の '+' を指している
*
* RETURN
*      A0     ディレクトリ・スタックの n 番目の要素（dstackの n-1 番目の単語）のアドレス
*      D0.L   エラーならば 1  さもなくば 0
*      D1.L   n-1
*      CCR    TST.L D0
*****************************************************************
get_dstack_element:
		addq.l	#1,a0			*  + に続く
		bsr	atou			*  数値をスキャンする．
		tst.b	(a0)			*  NULでなければ
		bne	bad_arg			*  エラー．

		tst.l	d0
		bmi	bad_arg			*  エラー．
		bne	dstack_not_deep

		tst.l	d1			*  数値が 0 ならば
		beq	bad_arg			*  エラー．

		subq.l	#1,d1
		movea.l	dstack(a5),a0
		lea	8(a0),a0
		moveq	#0,d0
		move.w	(a0)+,d0		*  ディレクトリ・スタックの要素数よりも
		cmp.l	d0,d1			*  数値が大きいならば
		bhs	dstack_not_deep		*  エラー．

		move.w	d1,d0
		bsr	fornstrs
		bra	return_0
****************************************************************
* pushd_exchange_sub - ディレクトリ・スタック上のディレクトリに
*                      移動して，そのディレクトリを削除し，元の
*                      カレント・ディレクトリをディレクトリ・ス
*                      タックの先頭にプッシュする
*
* CALL
*      A0    移動するディレクトリ要素のアドレス
*      D7.L  カレント・ディレクトリの長さ(+1)
*
* RETURN
*      A0     （成功したならば）次のディレクトリ要素のアドレス
*      D0.L   成功ならば 0
*      CCR    TST.L D0
****************************************************************
pushd_exchange_sub:
		movem.l	d1/a1,-(a7)
		movea.l	dstack(a5),a1
		move.l	4(a1),d1		*  スタックの現在の長さから
		bsr	strlen			*  要素の長さ
		addq.l	#1,d0
		sub.l	d0,d1			*  を引き
		add.l	d7,d1			*  カレント・ディレクトリの長さ(+1)を加えると
		cmp.l	(a1),d1			*  スタックの容量を超えるならば
		movem.l	(a7)+,d1/a1
		bhi	stack_full		*  エラー．

		bsr	popd_sub		*  (A0)に移動し，（成功したら）削除する．
		bne	pushd_exchange_sub_return	*  失敗ならば帰る．

		adda.l	d7,a0			*  次にプッシュすることでずれる分を補正する．
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* push_cwd -  以前のカレント・ディレクトリをプッシュする
*
* CALL
*      D7.L  カレント・ディレクトリの長さ(+1)
*
* RETURN
*      D0.L  0
*      CCR   TST.L D0
***************************************************************
push_cwd:
		movem.l	a0-a2,-(a7)
		movea.l	dstack(a5),a2
		move.l	4(a2),d0		*  D0.L : 現在のスタックの長さ
		lea	(a2,d0.l),a1		*  A1(source) : 転送元の末尾(+1)
		lea	(a1,d7.l),a0		*  A0(destination)はさらに空ける文字数分先
		sub.l	#10,d0
		bsr	memmovd			*  シフトする．
		lea	cwdbuf(a6),a1		*  以前のカレント・ディレクトリを
		lea	10(a2),a0		*  スタックの先頭に
		bsr	strcpy			*  置く．
		add.l	d7,4(a2)		*  バイト数を更新する．
		addq.w	#1,8(a2)		*  要素数をインクリメントする．
		movem.l	(a7)+,a0-a2
		moveq	#0,d0
pushd_exchange_sub_return:
		rts
****************************************************************
* popd_sub - A0 が指す要素のディレクトリに移動し，その要素を削除する
*
* CALL
*      A0     移動するディレクトリ要素のアドレス
*
* RETURN
*      D0.L   成功ならば 0
*      CCR    TST.L D0
****************************************************************
popd_sub:
		bsr	chdir			*  ディレクトリに移動する．
		bmi	perror1
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* popd_sub_delete - A0 が指すディレクトリ要素を削除する
*
* CALL
*      A0     削除するディレクトリ要素のアドレス
*
* RETURN
*      D0.L   0
*      CCR    TST.L D0
****************************************************************
popd_sub_delete:
		movem.l	d1/a0-a2,-(a7)
		movea.l	dstack(a5),a2
		move.l	4(a2),d0
		lea	(a2,d0.l),a1
		move.l	a1,d0			*  D0.L : 現在の末尾アドレス（の次）
		movea.l	a0,a1
		bsr	for1str
		exg	a0,a1			*  A1 : 次の要素のアドレス
		sub.l	a1,d0			*  D0 : 移動するバイト数
		move.l	a1,d1
		sub.l	a0,d1			*  D1.L : 削除するバイト数
		bsr	memmovi
		sub.l	d1,4(a2)		*  現在のバイト数を更新する．
		subq.w	#1,8(a2)		*  要素数をデクリメントする．
		movem.l	(a7)+,d1/a0-a2
return_0:
		moveq	#0,d0
		rts
****************************************************************
print_cwd:
		link	a6,#cwdbuf
		lea	cwdbuf(a6),a0
		bsr	getcwd
		jsr	(a1)
		unlk	a6
		rts
****************************************************************
print_directory:
		movem.l	d0/a0,-(a7)
		bsr	is_under_home
		beq	print_directory_1

		add.l	d0,a0
		moveq	#'~',d0
		bsr	putc
print_directory_1:
		bsr	puts
		movem.l	(a7)+,d0/a0
		rts
****************************************************************
dstack_not_deep:
		bsr	perror_command_name
		lea	msg_directory_stack,a0
		bsr	eputs
		lea	msg_not_deep,a0
		bra	enputs1
****************************************************************
dstack_empty:
		bsr	perror_command_name
		lea	msg_directory_stack,a0
		bsr	eputs
		lea	msg_dstack_empty,a0
		bra	enputs1
****************************************************************
stack_full:
		lea	msg_directory_stack,a0
		bra	no_space_for
****************************************************************
.data

.xdef word_cwd
.xdef msg_directory_stack

word_upper_pwd:		dc.b	'PWD',0
word_cwd:		dc.b	'cwd',0
word_switch_l:		dc.b	'-l',0
msg_pwd_dirs_usage:	dc.b	'[ -l ]',0
msg_directory_stack:	dc.b	'ディレクトリ・スタック',0
msg_dstack_empty:	dc.b	'は空です',0
msg_not_deep:		dc.b	'はそんなに深くありません',0
msg_too_deep:		dc.b	'の要素数が制限一杯です',0
msg_no_home:		dc.b	'シェル変数 home が未定義か空です',0

.end
