* b_dirs.s
* This contains built-in command 'cd'('chdir'), 'dirs', 'popd', 'pushd', 'cdd'.
*
* Itagaki Fumihiko 06-Oct-90  Create.

.include doscall.h
.include error.h
.include limits.h
.include ../src/fish.h
.include ../src/dirstack.h

.xref toupper
.xref atou
.xref utoa
.xref strlen
.xref strcmp
.xref strcpy
.xref strfor1
.xref strforn
.xref rotate
.xref memmovd
.xref memmovi
.xref isfullpath
.xref cat_pathname
.xref bsltosl
.xref putc
.xref puts
.xref nputs
.xref eputs
.xref enputs1
.xref put_tab
.xref put_space
.xref put_newline
.xref printu
.xref chdir
.xref getcwd
.xref drvchk
.xref is_under_home
.xref xmalloc
.xref free
.xref find_shellvar
.xref set_shellvar
.xref get_shellvar
.xref fish_getenv
.xref fish_setenv
.xref get_var_value
.xref perror
.xref perror_command_name
.xref command_error
.xref usage
.xref bad_arg
.xref too_many_args
.xref dstack_not_deep
.xref insufficient_memory
.xref word_cdpath
.xref word_home
.xref pathname_buf

.xref dirstack
.xref cwd_changed
.xref command_name
.xref flag_pushdsilent

cwdbuf = -(((MAXPATH+1)+1)>>1<<1)

.text

****************************************************************
var_value_a1:
		beq	var_value_a1_nul

		bsr	get_var_value
		bne	var_value_a1_ok
var_value_a1_nul:
		lea	str_nul,a0
var_value_a1_ok:
		movea.l	a0,a1
		rts
****************************************************************
.xdef reset_cwd

reset_cwd:
		link	a6,#cwdbuf
		movem.l	d0-d1/a0-a1,-(a7)
		lea	cwdbuf(a6),a0
		bsr	getcwd
		movea.l	a0,a1
		lea	word_cwd,a0
		moveq	#1,d0
		sf	d1
		bsr	set_shellvar
		lea	word_upper_pwd,a0
		bsr	fish_setenv
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
		rts
****************************************************************
.xdef set_oldcwd

set_oldcwd:
		movem.l	d0-d1/a0-a1,-(a7)
		*
		*  $@cwd -> $@oldcwd
		*
		lea	word_cwd,a0
		bsr	find_shellvar
		bsr	var_value_a1
		lea	word_oldcwd,a0
		moveq	#1,d0
		sf	d1
		bsr	set_shellvar
		*
		*  $%PWD -> $%OLDPWD
		*
		lea	word_upper_pwd,a0
		bsr	fish_getenv
		bsr	var_value_a1
		lea	word_upper_oldpwd,a0
		bsr	fish_setenv
		*
		*  $@cwd と $%PWD をセットする
		*
		bsr	reset_cwd
		*
		st	cwd_changed(a5)
		*
		movem.l	(a7)+,d0-d1/a0-a1
		rts
****************************************************************
* fish_chdir - カレント作業ディレクトリを変更する
*
* CALL
*      A0     ドライブ・ディレクトリ名
*
* RETURN
*      D0.L   エラーならば負数（ＯＳエラー・コード）
*             成功ならば 0．
*
*      CCR    TST.L D0
*
* DESCRIPTION
*      成功したならば，シェル変数 oldcwd, cwd，環境変数 PWD,
*      OLDPWD をセットし，内部フラグ cwd_changed をセットする．
****************************************************************
fish_chdir:
		bsr	chdir
		bmi	return

		bsr	set_oldcwd
return_0:
		moveq	#0,d0
return:
		rts
****************************************************************
* test_var - 変数を調べる
*
* CALL
*      A0     変数名
*
* RETURN
*      A0     もしあれば変数の値．さもなくば破壊
*
*      D0.L   破壊
*
*      CCR    NE ならば シェル変数が無いか，値の単語が無いか，
*             最初の単語が空か，完全パス名でない．
*             さもなくば EQ．
****************************************************************
test_var:
		bsr	get_shellvar
		beq	return_1

		bra	isfullpath
****************************************************************
* chdir_var - Change current working drive/directory to $varname
*
* CALL
*      A0     変数名
*
* RETURN
*      A0     もしあれば変数の値．さもなくば破壊
*
*      D0.L   1 ならば シェル変数が無いか，値の単語が無いか，
*             最初の単語が空か，完全パス名でない．
*             さもなくば，ＯＳのエラーコード
*
*      CCR    TST.L D0
****************************************************************
chdir_var:
		bsr	test_var
		beq	fish_chdir
return_1:
		moveq	#1,d0
		rts
****************************************************************
* chdir_home - Change current working directory and drive to $home
*
* CALL
*      none
*
* RETURN
*      A0     破壊
*
*      D0.L   $home[1]に chdir できたならば 0
*             さもなくば非0（エラー・メッセージを出力する）
*
*      CCR    TST.L D0
****************************************************************
chdir_home:
		lea	word_home,a0
		bsr	chdir_var
		beq	return
		bmi	perror
chdir_home_error:
		lea	msg_no_home,a0
		bra	command_error
****************************************************************
* chdirx - Change current working directory and/or drive.
*
* CALL
*      A0     ドライブ・ディレクトリ名
*
* RETURN
*      D0.L   エラーならば -1．（エラー・メッセージを出力する）
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
****************************************************************
chdirx:
		movem.l	d1-d3/a0-a3,-(a7)
		tst.b	(a0)
		bne	chdirx_try

		bsr	chdir_home
		bne	chdirx_error
		bra	chdirx_done1

chdirx_try:
		bsr	fish_chdir			*  カレント・ディレクトリを変更する
		bpl	chdirx_done			*  成功したなら帰る

		cmpi.b	#':',1(a0)			*  ドライブ指定がある場合は
		beq	chdirx_perror			*  これ以上トライしない

		movea.l	a0,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
chdirx_1:
		cmpi.b	#'/',(a1)			*  / ./ ../ ならば
		beq	chdirx_perror			*  これ以上トライしない

		cmpi.b	#'\',(a1)			*  \ .\ ..\ ならば
		beq	chdirx_perror			*  これ以上トライしない
****************
		movea.l	a0,a2				*  A2 : dirname
		lea	word_cdpath,a0
		bsr	find_shellvar
		beq	try_varname

		bsr	get_var_value
		move.w	d0,d1				*  D1.W : $#cdpath
		movea.l	a0,a1				*  A1 : cdpath の単語並び
		lea	pathname_buf,a0
		bra	try_cdpath_continue

try_cdpath_loop:
		tst.b	(a1)
		beq	try_cdpath_next

		bsr	cat_pathname
		bmi	try_cdpath_continue

		bsr	fish_chdir
		bmi	try_cdpath_continue
chdirx_done1:
		moveq	#1,d0
		bra	chdirx_done

try_cdpath_next:
		exg	a0,a1
		bsr	strfor1
		exg	a0,a1
try_cdpath_continue:
		dbra	d1,try_cdpath_loop
****************
try_varname:
		movea.l	a2,a0
		bsr	chdir_var
		beq	chdirx_done1
		bmi	chdirx_perror

		movea.l	a2,a0
		moveq	#ENODIR,d0
chdirx_perror:
		bsr	perror
chdirx_error:
		moveq	#-1,d0
chdirx_done:
		movem.l	(a7)+,d1-d3/a0-a3
test_return:
		tst.l	d0
		rts
****************************************************************
*  Name
*       cdd - change directory of drive
*
*  Synopsis
*       cdd           print current directory of current drive
*       cdd d:        print current directory of drive d
*	cdd dir       change current directory of current drive to dir
*	cdd d:dir     change current directory of drive d to dir
****************************************************************
.xdef cmd_cdd

cmd_cdd:
		move.w	d0,-(a7)
		DOS	_CURDRV
		add.b	#'A',d0			*  D0 : カレント・ドライブ名
		cmp.w	#1,(a7)+		*  引数が
		bhi	too_many_args		*  2つ以上あればエラー
		blo	cdd_print

		move.b	(a0),d1
		beq	cdd_print

		cmpi.b	#':',1(a0)
		bne	cdd_change_cwd

		exg	d0,d1
		bsr	toupper
		cmp.b	d1,d0
		bne	cdd_other_drive

		tst.b	2(a0)
		beq	cdd_print
cdd_change_cwd:
		bsr	fish_chdir
		bra	cdd_check_result

cdd_other_drive:
		move.b	d0,d1
		bsr	drvchk
		bmi	perror

		move.b	d1,d0
		tst.b	2(a0)
		bne	cdd_change
cdd_print:
		link	a6,#cwdbuf
		lea	cwdbuf(a6),a0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		move.b	#'/',(a0)+
		move.l	a0,-(a7)
		sub.b	#'@',d0
		move.w	d0,-(a7)
		DOS	_CURDIR
		addq.l	#6,a7
		lea	cwdbuf(a6),a0
		bsr	bsltosl
		bsr	nputs
		unlk	a6
		bra	cdd_return_0

cdd_change:
		move.l	a0,-(a7)
		DOS	_CHDIR
		addq.l	#4,a7
		tst.l	d0
cdd_check_result:
		bmi	perror
cdd_return_0:
		moveq	#0,d0
		rts
****************************************************************
* getopt - cd/pushd/popd/dirs/pwd のオプションを得る
*
* CALL
*      A0     引数リストの先頭
*      D0.W   引数の数
*
* RETURN
*      A0     非オプション引数の先頭
*      D0.W   非オプション引数の数
*      A3     ディレクトリ出力ルーチン・エントリ・アドレス
*      A4     ディレクトリ間のセパレータ出力ルーチン・エントリ・アドレス
*      D4.B   bit0:-l, bit1:-v, bit2:-s
*      CCR    引数が正しければ EQ
****************************************************************
getopt:
		lea	print_directory(pc),a3
		lea	put_space(pc),a4
		moveq	#0,d4
getopt_loop1:
		tst.w	d0
		beq	getopt_ok

		cmpi.b	#'-',(a0)
		bne	getopt_ok

		tst.b	1(a0)
		beq	getopt_ok

		subq.w	#1,d0
		addq.l	#1,a0
getopt_loop2:
		move.b	(a0)+,d2
		beq	getopt_loop1

		cmp.b	#'l',d2
		beq	getopt_l

		cmp.b	#'v',d2
		beq	getopt_v

		cmp.b	#'s',d2
		bne	getopt_return

		bset	#2,d4
		bra	getopt_loop2

getopt_v:
		bset	#1,d4
		lea	put_newline(pc),a4
		bra	getopt_loop2

getopt_l:
		bset	#0,d4
		lea	puts(pc),a3
		bra	getopt_loop2

getopt_ok:
		cmp.w	d0,d0
getopt_return:
		rts
****************************************************************
test_arg_minus:
		cmpi.b	#'-',(a0)
		bne	test_arg_plus

		tst.b	1(a0)
		bne	test_arg_plus

		lea	word_oldcwd,a0
		bsr	test_var
		beq	arg_minus_ok

		lea	word_home,a0
		bsr	test_var
		bne	chdir_home_error	*  D0.L := 1 .. error
arg_minus_ok:
						*  A0 == value of var
arg_name:
		moveq	#-1,d0			*  D0.L == -1 .. <name>
		rts
****************************************************************
test_arg_plus:
		cmpi.b	#'+',(a0)
		bne	arg_name		*  D0.L := -1 .. <name>

		addq.l	#1,a0			*  + に続く
		bsr	atou			*  数値をスキャンする
		bmi	dirs_bad_arg		*  エラー（数字が無い） .. D0.L := 1 .. error
		bne	dstack_not_deep		*  エラー（オーバーフロー） .. D0.L := 1 .. error

		cmpi.b	#'.',(a0)
		seq	d3			*  D3.B : dextract flag
		bne	get_dstack_arg

		addq.l	#1,a0
get_dstack_arg:
		tst.b	(a0)
		bne	dirs_bad_arg		*  D0.L := 1 .. error

		move.l	d1,d0			*  数値が 0 ならばエラー
		beq	dirs_bad_arg		*  D0.L := 1 .. error

		bsr	get_dstack_d0		*  D2.L := 要素のオフセット
		bmi	dstack_not_deep		*  D0.L := 1 .. error

		subq.l	#1,d1			*  D1.L := n-1
		moveq	#0,d0			*  D0.L := 0 .. +<n>
		rts
****************************************************************
check_not_empty:
		moveq	#0,d0
		movea.l	dirstack(a5),a0
		tst.w	dirstack_nelement(a0)		*  スタックに要素が無いならば
		bne	test_return			*  D0 == 0

		bsr	perror_command_name
		lea	msg_directory_stack,a0
		bsr	eputs
		lea	msg_dstack_empty,a0
		bra	enputs1				*  D0 == 1
****************************************************************
*  Name
*       cd - change working directory
*
*  Synopsis
*       cd                go to home directory
*       cd +n             rotate to n'th be top
*	cd +n.            extract n'th directory and go to it
*	cd name           go to name
****************************************************************
.xdef cmd_cd

cmd_cd:
		lea	msg_cd_pushd_usage,a1
		bsr	getopt
		bne	dirs_bad_arg

		subq.w	#1,d0
		bcs	chdir_home			*  引数が 0個なら $home に chdir する
		bne	dirs_too_many_args		*  引数が 2個以上ならエラー

		bsr	test_arg_minus
		bmi	cmd_cd_name
		bne	return
*  cd +<n>[.]
cmd_cd_plus:
		*  D1.L:n-1, D2.L:要素のオフセット
		bsr	popd				*  そこに移動し、成功したなら要素を削除する
		bmi	return				*  エラーならおしまい

		bra	rotate_and_return		*  要素を循環送りする
*  cd <name>
cmd_cd_name:
		bsr	chdirx				*  指定のディレクトリにchdirxする
		bmi	return
		beq	return_0

		bra	pushd_popd_done
****************************************************************
*  Name
*       pushd - push directory stack
*
*  Synopsis
*       pushd               exchange current and top
*       pushd +n            rotate to let n'th be top
*       pushd +n.           extract n'th and push it to top
*	pushd directory     push current and chdir to directory
****************************************************************
.xdef cmd_pushd

cmd_pushd:
		lea	msg_cd_pushd_usage,a1
		bsr	getopt
		bne	dirs_bad_arg

		subq.w	#1,d0
		bcs	cmd_pushd_exchange		*  引数が 0個なら先頭要素とカレントを交換
		bne	dirs_too_many_args		*  引数が 2個以上ならエラー

		bsr	test_arg_minus
		bmi	cmd_pushd_name
		bne	return
*  pushd +<n>[.]
		*  D1.L:n-1, D2.L:要素のオフセット
		bra	cmd_pushd_exchange_1

*  pushd (no arg)
cmd_pushd_exchange:
		bsr	check_not_empty
		bne	return

		st	d3
		moveq	#0,d1
		move.l	#dirstack_top,d2
cmd_pushd_exchange_1:
		bsr	push_cwd			*  元のカレント・ディレクトリをプッシュする
		beq	cmd_pushd_error_return

		add.l	d0,d2
		bsr	popd
		bne	cmd_pushd_fail

		addq.w	#1,d1
rotate_and_return:
		tst.b	d3				*  抽出モードなら
		bne	pushd_popd_done			*  循環送りしない

		tst.l	d1				*  既に先頭となっているならば
		beq	pushd_popd_done			*  循環送りの必要なし

		movea.l	dirstack(a5),a0
		cmp.w	dirstack_nelement(a0),d1
		bhs	pushd_popd_done			*  循環送りの必要なし

		lea	(a0,d2.l),a1			*  A1 : 先頭となるべきアドレス
		move.l	dirstack_bottom(a0),d0
		lea	(a0,d0.l),a2			*  A2 : 現在の末尾アドレス(+1)
		lea	dirstack_top(a0),a0		*  A0 : 先頭の要素
		bsr	rotate				*  要素を循環送りする
		bra	pushd_popd_done
*  pushd <name>
cmd_pushd_name:
		movea.l	dirstack(a5),a1
		cmpi.w	#MAXWORDS-1,dirstack_nelement(a1)
		bhs	pushd_too_many_elements

		bsr	push_cwd			*  元のカレント・ディレクトリをプッシュする
		beq	cmd_pushd_error_return

		bsr	chdirx				*  引数に指定されたディレクトリにchdirxする
		bpl	pushd_popd_done
cmd_pushd_fail:
		move.l	#dirstack_top,d2		*  プッシュした先頭の要素を
		bsr	delete_element			*  削除する
cmd_pushd_error_return:
		moveq	#1,d0
		rts
****************
pushd_too_many_elements:
		bsr	perror_command_name
		lea	msg_directory_stack,a0
		bsr	eputs
		lea	msg_too_deep,a0
		bra	enputs1
****************************************************************
* push_cwd -  カレント・ディレクトリをプッシュする
*
* CALL
*      none
*
* RETURN
*      D0.L  成功ならば、プッシュしたカレント・ディレクトリの長さ(+1)
*            エラーならば 0
*
*      CCR   TST.L D0
****************************************************************
push_cwd:
		link	a6,#cwdbuf
		movem.l	d1/a0-a2,-(a7)
		lea	cwdbuf(a6),a0
		bsr	getcwd
		bsr	strlen
		addq.l	#1,d0
		move.l	d0,d1				*  D1.L : strlen(cwd) + 1
		bsr	realloc_dirstack
		beq	push_cwd_fail

		movea.l	dirstack(a5),a2
		move.l	dirstack_bottom(a2),d0		*  D0.L : 現在のスタックの長さ
		lea	(a2,d0.l),a1			*  A1(source) : 転送元の末尾(+1)
		lea	(a1,d1.l),a0			*  A0(destination)はさらに空ける文字数分先
		subq.l	#dirstack_top,d0
		bsr	memmovd				*  シフトする
		lea	cwdbuf(a6),a1			*  以前のカレント・ディレクトリを
		lea	dirstack_top(a2),a0		*  スタックの先頭に
		bsr	strcpy				*  置く
		add.l	d1,dirstack_bottom(a2)		*  バイト数を更新する
		addq.w	#1,dirstack_nelement(a2)	*  要素数をインクリメントする
		move.l	d1,d0
push_cwd_return:
		movem.l	(a7)+,d1/a0-a2
		unlk	a6
		rts

push_cwd_fail:
		bsr	perror_command_name
		bsr	insufficient_memory
		moveq	#0,d0
		bra	push_cwd_return
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
		lea	msg_popd_usage,a1
		bsr	getopt
		bne	dirs_bad_arg

		subq.w	#1,d0
		bcs	cmd_popd_noarg			*  引数が 0個ならポップ
		bne	dirs_too_many_args		*  引数が 2個以上ならエラー

		bsr	test_arg_plus
		bne	dirs_bad_arg
*  popd +<n>[.]
		*  D2.L:数値が示す要素のオフセット
		bsr	delete_element			*  要素を削除する
		bra	pushd_popd_done

*  popd (no arg)
cmd_popd_noarg:
		bsr	check_not_empty
		bne	return

		move.l	#dirstack_top,d2		*  先頭の
		bsr	popd				*  要素に移動し、成功したなら要素を削除する
		bmi	return				*  エラー
pushd_popd_done:
		tst.b	flag_pushdsilent(a5)
		bne	return_0

		btst	#2,d4
		bne	return_0

		bra	print_dirstack
****************************************************************
*  Name
*       dirs - print directory stack
*
*  Synopsis
*       dirs [ -lv ]
****************************************************************
.xdef cmd_dirs

cmd_dirs:
		lea	msg_dirs_usage,a1
		bsr	getopt
		bne	dirs_bad_arg

		btst	#2,d4				*  bit2以上は
		bne	dirs_bad_arg			*  無効

		tst.w	d0
		bne	dirs_too_many_args
print_dirstack:
		moveq	#0,d2
		bsr	print_stacklevel
		bsr	print_cwd
		movea.l	dirstack(a5),a0
		move.w	dirstack_nelement(a0),d7
		beq	print_dirs_done

		subq.w	#1,d7
		jsr	(a4)
		lea	dirstack_top(a0),a0
		bra	print_dirs_start

print_dirs_loop:
		bsr	strfor1
		jsr	(a4)
print_dirs_start:
		bsr	print_stacklevel
		jsr	(a3)
		dbra	d7,print_dirs_loop
print_dirs_done:
		bsr	put_newline
		bra	return_0


dirs_bad_arg:
		bsr	bad_arg
		bra	dirs_usage

dirs_too_many_args:
		bsr	too_many_args
dirs_usage:
		movea.l	a1,a0
		bra	usage
****************************************************************
print_stacklevel:
		btst	#1,d4
		beq	print_stack_level_done

		movem.l	d0-d4,-(a7)
		move.l	d2,d0					*  番号を
		moveq	#1,d1					*  左詰めで
		moveq	#1,d3					*  少なくとも 1文字の幅に
		moveq	#1,d4					*  少なくとも 1桁の数字を
		bsr	printu					*  表示する
		movem.l	(a7)+,d0-d4
		bsr	put_tab
		addq.l	#1,d2
print_stack_level_done:
		rts
****************************************************************
*  Name
*       pwd - print current working directory
*
*  Synopsis
*       pwd [ -l ]
****************************************************************
.xdef cmd_pwd

cmd_pwd:
		lea	msg_pwd_usage,a1
		bsr	getopt
		bne	dirs_bad_arg

		cmp.b	#2,d4				*  bit1以上は
		bhs	dirs_bad_arg			*  無効

		tst.w	d0
		bne	dirs_too_many_args

		bsr	print_cwd
		bsr	put_newline
		bra	return_0
****************************************************************
print_cwd:
		link	a6,#cwdbuf
		lea	cwdbuf(a6),a0
		bsr	getcwd
		jsr	(a3)
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
* get_dstack_d0
*
* CALL
*      D0.L   要素番号（1以上であること）
*
* RETURN
*      D2.L   ディレクトリ・スタックの D0.L番目の要素（dstackの n-1 番目の単語）のオフセット
*             D0.Lが要素数よりも大きいならば -1
*      CCR    TST.L D2
****************************************************************
.xdef get_dstack_d0

get_dstack_d0:
		move.l	a0,-(a7)
		moveq	#-1,d2
		cmp.l	#MAXWORDS-1,d0
		bhi	get_dstack_d0_return

		movea.l	dirstack(a5),a0
		cmp.w	dirstack_nelement(a0),d0	*  ディレクトリ・スタックの要素数よりも
		bhi	get_dstack_d0_return		*  数値が大きいならばエラー．

		move.l	a0,-(a7)
		lea	dirstack_top(a0),a0
		subq.l	#1,d0
		bsr	strforn
		addq.l	#1,d0
		move.l	a0,d2
		sub.l	(a7)+,d2
		cmp.w	d0,d0
get_dstack_d0_return:
		movea.l	(a7)+,a0
		tst.l	d2
		rts
****************************************************************
* delete_element - D2.L が指すディレクトリ要素を削除する
*
* CALL
*      D2.L   削除するディレクトリ要素のオフセット
*
* RETURN
*      D0-D1/A0-A2   破壊
****************************************************************
delete_element:
		movea.l	dirstack(a5),a2
		move.l	dirstack_bottom(a2),d0
		lea	(a2,d0.l),a1
		move.l	a1,d0				*  D0.L : 現在の末尾アドレス（の次）
		lea	(a2,d2.l),a0
		bsr	strfor1
		movea.l	a0,a1				*  A1 : 削除する要素の次の要素のアドレス
		lea	(a2,d2.l),a0			*  A0 : 削除する要素のアドレス
		sub.l	a1,d0				*  D0 : 移動するバイト数
		move.l	a1,d1
		sub.l	a0,d1				*  D1.L : 削除するバイト数
		bsr	memmovi
		sub.l	d1,dirstack_bottom(a2)		*  現在のバイト数を更新する
		subq.w	#1,dirstack_nelement(a2)	*  要素数をデクリメントする
		moveq	#0,d0
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
realloc_dirstack:
		movem.l	a0-a1,-(a7)
		movea.l	dirstack(a5),a1
		add.l	dirstack_bottom(a1),d0
		bsr	xmalloc
		beq	realloc_dirstack_return

		move.l	d0,dirstack(a5)
		move.l	d0,-(a7)
		movea.l	d0,a0
		move.l	dirstack_bottom(a1),d0
		move.l	a1,-(a7)
		bsr	memmovi
		move.l	(a7)+,d0
		bsr	free
		move.l	(a7)+,d0
realloc_dirstack_return:
		movem.l	(a7)+,a0-a1
		rts
****************************************************************
* popd - D2.L が指す要素のディレクトリに移動し，その要素を削除する
*
* CALL
*      D2.L   移動するディレクトリ要素のオフセット
*
* RETURN
*      D0.L   成功すれば 0．移動できなかったならば負
*      CCR    TST.L D0
*      A0     破壊
****************************************************************
popd:
		move.l	dirstack(a5),a0
		lea	(a0,d2.l),a0
		bsr	fish_chdir		*  ディレクトリに移動する．
		bmi	perror

		bsr	delete_element
		moveq	#0,d0
		rts
****************************************************************
.data

.xdef word_cwd

word_upper_oldpwd:	dc.b	'OLD'
word_upper_pwd:		dc.b	'PWD',0
word_oldcwd:		dc.b	'old'
word_cwd:		dc.b	'cwd'
str_nul:		dc.b	0
msg_cd_pushd_usage:	dc.b	'[-lvs] [-|<名前>|+<n>[.]]',0
msg_popd_usage:		dc.b	'[-lvs] [+<n>]',0
msg_dirs_usage:		dc.b	'[-lv]',0
msg_pwd_usage:		dc.b	'[-l]',0
msg_directory_stack:	dc.b	'ディレクトリ・スタック',0
msg_dstack_empty:	dc.b	'は空です',0
msg_too_deep:		dc.b	'の要素数が制限一杯です',0
msg_no_home:		dc.b	'シェル変数 home の設定が無効です',0

.end
