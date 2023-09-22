* cmddirs.s
* This contains built-in command 'cd'('chdir'), 'dirs', 'popd', 'pushd'.
*
* Itagaki Fumihiko 06-Oct-90  Create.

.include limits.h
.include ../src/fish.h

.xref for1str
.xref rotate
.xref putc
.xref chdir
.xref chdirx
.xref find_shellvar
.xref getcwd
.xref set_svar
.xref perror
.xref strlen
.xref command_error
.xref bad_arg
.xref strcmp
.xref puts
.xref put_space
.xref echo
.xref put_newline
.xref usage
.xref atou
.xref fornstrs
.xref memmove_dec
.xref strcpy
.xref memmove_inc
.xref isabsolute
.xref toupper
.xref issjis
.xref tolower
.xref too_many_args
.xref word_home
.xref msg_no_home
.xref dstack

.text

cwdbuf = -(((MAXPATH+1)+1)>>1<<1)

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
		cmp.w	#1,d0			* 引数が
		beq	cd_arg			* １つあるならば指定のディレクトリにchdirする
		bhi	too_many_args		* ２つ以上あればエラー

		lea	word_home,a0		* シェル変数 home を
		bsr	find_shellvar		* 探す
		beq	no_home			* 無ければエラー

		lea	2(a0),a0
		move.w	(a0)+,d1		* D1.W : 単語数  A0 : 値
		beq	no_home

		bsr	for1str			* $home[1]に
		tst.b	(a0)
		beq	no_home

		bsr	chdir			* chdirする
		bmi	fail
		bra	chdir_success
****************
cd_arg:
		cmpi.b	#'+',(a0)		* 引数が'+'で始まらないならば
		bne	cd_name			* 処理cd_nameへ

		bsr	get_dstack_element	* 数値-1をD1.Lに、示す要素のアドレスをA0に得る
		bne	cd_return

		bsr	popd_sub		* そこに移動してその要素を削除する
		bne	cd_return

		tst.l	d1
		beq	cd_dirs_done		* 既に巡回されている

		addq.w	#1,d1
		movea.l	dstack,a1
		cmp.w	8(a1),d1
		bhi	cd_dirs_done		* 既に巡回されている

		exg	a0,a1
		move.l	4(a0),d0
		lea	(a0,d0.l),a2		* A2 := 現在の末尾アドレス（＋１）
		lea	10(a0),a0		* A0 := 先頭の要素
		bsr	rotate			* 要素を巡回する
cd_dirs_done:
		bsr	print_dirs		* ディレクトリ・スタックを表示
		bra	chdir_success
****************
cd_name:
		bsr	chdirx			* 指定のディレクトリにchdirxする
		bmi	fail			* 失敗したならばエラー処理へ
		beq	chdir_success

		bsr	pwd
chdir_success:
		moveq	#0,d0
****************
cd_return:
reset_cwd:
		link	a6,#cwdbuf
		movem.l	d0/a0,-(a7)
		lea	cwdbuf(a6),a0
		bsr	getcwd
		movea.l	a0,a1
		lea	word_cwd,a0
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
		movem.l	(a7)+,d0/a0
		unlk	a6
		rts
****************
fail:
		bsr	perror
		moveq	#1,d0
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
		move.w	d0,d1			* argc をセーブ

		lea	cwdbuf(a6),a0		* cwdbufに
		bsr	getcwd			* カレントディレクトリを得て
		bsr	strlen			* その長さを
		addq.l	#1,d0
		move.l	d0,d7			* D7.Lに保存する

		move.w	d1,d0			* argc をポップ
		beq	exchange		* 引数が無いなら先頭要素とカレントを交換する

		cmp.w	#1,d0			* 引数が２つ以上あれば
		bhi	pushd_too_many_args	* 'Too many args'エラーへ

		cmpi.b	#'+',(a1)		* 引数が'+'で始まらないならば
		bne	push_new		* 処理push_newへ

		movea.l	a1,a0
		bsr	get_dstack_element	* 数値が示す要素のアドレスをA0に得る
		bne	cmd_pushd_return	* 失敗したならおしまい

		movem.l	d1/a0,-(a7)
		bsr	pushd_exchange_sub	* A0が示す要素とカレント・ディレクトリを交換
		movem.l	(a7)+,d1/a0
		bne	cmd_pushd_return	* 失敗したならおしまい

		*  スタックの要素を巡回する
		bsr	for1str
		movea.l	a0,a1

		addq.w	#1,d1
		movea.l	dstack,a0
		cmp.w	8(a0),d1
		bhs	cmd_pushd_done		* 既に巡回されている

		move.l	4(a0),d0
		lea	(a0,d0.l),a2		* A2 := 現在の末尾アドレス（＋１）
		lea	10(a0),a0		* A0 := 先頭の要素
		bsr	rotate			* 前半と後半を入れ替える
		bra	cmd_pushd_done
****************
exchange:
		movea.l	dstack,a0
		tst.w	8(a0)			* スタックに要素が無いならば
		beq	pushd_empty		* エラー

		lea	10(a0),a0		* 先頭の要素と
		bsr	pushd_exchange_sub	* カレント・ディレクトリを交換する
		bne	cmd_pushd_return	* 失敗したならおしまい

		bra	cmd_pushd_done
****************
push_new:
		movea.l	dstack,a0
		cmpi.w	#MAXWORDS,8(a0)
		bhs	pushd_too_many_elements

		move.l	4(a0),d0		* スタックの長さに
		add.l	d7,d0			* カレント・ディレクトリの長さを加えると
		cmp.l	(a0),d0			* スタックの容量を超えるならば
		bhi	pushd_stack_full	* エラー

		movea.l	a1,a0			* 指定されたディレクトリに
		bsr	chdirx			* 移動する
		bmi	pushd_perror_return

		bsr	push_cwd		* 以前のカレント・ディレクトリをプッシュする
cmd_pushd_done:
		bsr	print_dirs		* スタックを表示する
cmd_pushd_return:
		bsr	reset_cwd
		unlk	a6
		rts
****************
pushd_too_many_args:
		bsr	too_many_args
		bra	cmd_pushd_return
****************
pushd_too_many_elements:
		lea	msg_too_deep,a0
		bsr	command_error
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
		bsr	perror
		moveq.l	#1,d0
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
		cmp.w	#1,d0			* 引数が２つ以上あれば
		bhi	too_many_args		* エラー
		blo	pop			* 引数が無いならポップ

		cmpi.b	#'+',(a0)		* 引数が'+'で始まらないならば
		bne	bad_arg			* エラー

		movea.l	a0,a1
		bsr	get_dstack_element	* 数値が示す要素のアドレスをA0に得る
		bne	popd_return		* エラーならばおしまい

		bsr	popd_sub_delete		* 要素を削除する
		bra	pop_done

pop:
		movea.l	dstack,a0
		lea	8(a0),a0
		tst.w	(a0)+			* スタックに要素が無いならば
		beq	dstack_empty		* エラー

		bsr	popd_sub		* 要素に移動して削除する
		bne	popd_return		* 失敗ならば帰る
pop_done:
		bsr	print_dirs		* スタックを表示
popd_return:
		bra	reset_cwd
****************************************************************
*  Name
*       dirs - print directory stack
*
*  Synopsis
*       dirs [ -l ]
****************************************************************
.xdef cmd_dirs

cmd_dirs:
		cmp.w	#1,d0
		blo	print_dirs
		bhi	pwd_dirs_too_many_args

		lea	word_switch_l,a1
		bsr	strcmp
		bne	pwd_dirs_bad_arg

		lea	puts(pc),a1
		bra	print_dirs_l

print_dirs:
		lea	print_directory(pc),a1
print_dirs_l:
		bsr	print_cwd
		movea.l	dstack,a0
		move.w	8(a0),d0
		beq	print_dirs_done

		bsr	put_space
		lea	10(a0),a0
		clr.l	a2
		bsr	echo
print_dirs_done:
put_newline_return_0:
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
*  Name
*       pwd - print current working directory
*
*  Synopsis
*       pwd [ -l ]
****************************************************************
.xdef cmd_pwd

cmd_pwd:
		cmp.w	#1,d0
		blo	pwd
		bhi	pwd_dirs_too_many_args

		lea	word_switch_l,a1
		bsr	strcmp
		bne	pwd_dirs_bad_arg

		lea	puts(pc),a1
		bra	pwd_l

pwd:
		lea	print_directory(pc),a1
pwd_l:
		bsr	print_cwd
		bra	put_newline_return_0
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
		addq.l	#1,a0			* '+'に続く
		bsr	atou			* 数値をスキャンする
		tst.b	(a0)			* NULでなければ
		bne	bad_arg			* エラー

		tst.l	d0
		bmi	bad_arg			* エラー
		bne	dstack_not_deep

		tst.l	d1			* 0ならば
		beq	bad_arg			* エラー

		subq.l	#1,d1
		movea.l	dstack,a0
		lea	8(a0),a0
		moveq	#0,d0
		move.w	(a0)+,d0
		cmp.l	d0,d1
		bhs	dstack_not_deep		* エラー

		move.w	d1,d0
		bsr	fornstrs
		bra	return_0
****************************************************************
*  A0が示す要素とカレント・ディレクトリを交換する
pushd_exchange_sub:
		movea.l	dstack,a1
		move.l	4(a1),d1		* スタックの現在の長さから
		bsr	strlen			* 要素の長さ
		addq.l	#1,d0
		sub.l	d0,d1			* を引き
		add.l	d7,d1			* カレント・ディレクトリの長さを加えると
		cmp.l	(a1),d1			* スタックの容量を超えるならば
		bhi	stack_full		* エラー

		bsr	popd_sub		* (A0)に移動し、（成功したら）削除する
		bne	return			* 失敗ならば帰る

		bsr	push_cwd		* 以前のカレント・ディレクトリをプッシュする
		bra	return_0		* 成功
****************************************************************
*  以前のカレント・ディレクトリをプッシュする
push_cwd:
		movea.l	dstack,a2
		move.l	4(a2),d0		* D0 := 現在のスタックの長さ
		lea	(a2,d0.l),a1		* A1(source) := 転送元の末尾（＋１）
		lea	(a1,d7.l),a0		* A0(destination)は、さらに空ける文字数分、先
		sub.l	#10,d0
		bsr	memmove_dec		* シフトする
		lea	cwdbuf(a6),a1		* 以前のカレント・ディレクトリを
		lea	10(a2),a0		* スタックの先頭に
		bsr	strcpy			* 置く
		add.l	d7,4(a2)		* バイト数を更新
		addq.w	#1,8(a2)		* 要素数をインクリメント
		rts
****************************************************************
*  A0 が示す要素をカレント・ディレクトリとし、要素を削除する
*  D0/CCR は戻り値
popd_sub:
		bsr	chdir			* ディレクトリに移動する
		bmi	popd_sub_error
popd_sub_delete:
		movem.l	d1/a0-a2,-(a7)
		movea.l	dstack,a2
		move.l	4(a2),d0
		lea	(a2,d0.l),a1
		move.l	a1,d0			* D0.L : 現在の末尾アドレス（の次）
		movea.l	a0,a1
		bsr	for1str
		exg	a0,a1			* A1 : 次の要素のアドレス
		sub.l	a1,d0			* D0 : 移動するバイト数
		move.l	a1,d1
		sub.l	a0,d1			* D1 : 削除するバイト数
		bsr	memmove_inc
		sub.l	d1,4(a2)		* 現在のバイト数を更新
		subq.w	#1,8(a2)		* 要素数をデクリメント
		movem.l	(a7)+,d1/a0-a2
return_0:
		moveq	#0,d0
return:
		rts

popd_sub_error:
		bsr	perror
		moveq	#1,d0
		rts
****************************************************************
print_cwd:
		link	a6,#cwdbuf
		move.l	a0,-(a7)
		lea	cwdbuf(a6),a0
		bsr	getcwd
		jsr	(a1)
		movea.l	(a7)+,a0
		unlk	a6
		rts
****************************************************************
print_directory:
		movem.l	d0-d1/a0-a2,-(a7)
		movea.l	a0,a2			* A2 : 表示するディレクトリ名の先頭
		bsr	isabsolute
		bne	print_directory_9	* 絶対パスでない…省略しない

		lea	word_home,a0
		bsr	find_shellvar
		beq	print_directory_9	* $?homeは0である…省略できない

		addq.l	#2,a0
		tst.w	(a0)+
		beq	print_directory_9	* $#homeは0である…省略できない

		bsr	for1str			* A0 : $home[1]
		bsr	isabsolute
		bne	print_directory_9	* $home[1]は絶対パス名でない…省略できない

		move.b	(a0),d0
		bsr	toupper
		move.b	d0,d1
		move.b	(a2),d0
		bsr	toupper
		cmp.b	d1,d0
		bne	print_directory_9

		movea.l	a2,a1
		addq.l	#3,a1
		addq.l	#3,a0
compare_loop:
		move.b	(a0)+,d0
		beq	check_bottom

		bsr	issjis
		beq	compare_sjis

		bsr	tocompare
		cmp.b	#'/',d0
		bne	compare_ank

		tst.b	(a0)
		beq	check_bottom
compare_ank:
		move.b	d0,d1
		move.b	(a1)+,d0
		bsr	tolower
		cmp.b	d1,d0
		bra	check_one

compare_sjis:
		move.b	d0,d1
		move.b	(a1)+,d0
		bsr	issjis
		bne	print_directory_9

		cmp.b	d1,d0
		bne	print_directory_9

		move.b	(a0)+,d0
		beq	print_directory_9

		cmp.b	(a1)+,d0
check_one:
		bne	print_directory_9

		bra	compare_loop

check_bottom:
		move.b	(a1),d0
		beq	match

		cmp.b	#'/',d0
		beq	match

		cmp.b	#'\',d0
		bne	print_directory_9
match:
		moveq	#'~',d0
		bsr	putc
		movea.l	a1,a2
print_directory_9:
		movea.l	a2,a0
		bsr	puts
		movem.l	(a7)+,d0-d1/a0-a2
		rts
****************************************************************
tocompare:
		cmp.b	#'\',d0
		bne	tolower

		moveq	#'/',d0
		rts
****************************************************************
dstack_not_deep:
		lea	msg_not_deep,a0
		bra	command_error
****************************************************************
dstack_empty:
		lea	msg_dstack_empty,a0
		bra	command_error
****************************************************************
stack_full:
		lea	msg_full,a0
		bra	command_error
****************************************************************
no_home:
		lea	msg_no_home,a0
		bra	command_error
****************************************************************
.data

word_cwd:		dc.b	'cwd',0
word_switch_l:		dc.b	'-l',0
msg_pwd_dirs_usage:	dc.b	'[ -l ]',0
msg_dstack_empty:	dc.b	'ディレクトリ・スタックは空です',0
msg_not_deep:		dc.b	'ディレクトリ・スタックはそんなに深くありません',0
msg_full:		dc.b	'ディレクトリ・スタックの容量が足りません',0
msg_too_deep:		dc.b	'ディレクトリ・スタックの要素数が制限一杯です',0

.end
