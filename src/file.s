* file.s
* Itagaki Fumihiko 23-Feb-91  Create.
*
* This contains file controll routines.

.include doscall.h
.include limits.h
.include error.h
.include stat.h
.include chrcode.h

.xref isspace3
.xref fair_pathname
.xref tfopen
.xref fclose
.xref stat
.xref drvchkp

.xref doscall_pathname

.text

*****************************************************************
.xdef get_fair_pathname

get_fair_pathname:
		movem.l	d0/a1,-(a7)
		movea.l	a0,a1
		lea	doscall_pathname,a0
		moveq	#MAXPATH,d0
		bsr	fair_pathname
		movem.l	(a7)+,d0/a1
		rts
*****************************************************************
.xdef tfopenx

tfopenx:
		move.l	a0,-(a7)
		bsr	get_fair_pathname
		bcs	tfopenx_fail

		jsr	tfopen
tfopenx_return:
		movea.l	(a7)+,a0
		rts

tfopenx_fail:
		moveq	#ENOFILE,d0
		bra	tfopenx_return
*****************************************************************
* create_normal_file - 通常のファイルを生成する
*
* CALL
*      A0     生成するファイルのパス名
*
* RETRUN
*      D0.L   負: エラー・コード
*             正: 下位ワードが、作成してオープンされたファイル・ハンドルを示す
*
*      CCR    TST.L D0
*****************************************************************
.xdef create_savefile
.xdef create_normal_file

statbuf = -STATBUFSIZE

create_savefile:
		link	a6,#statbuf
		movem.l	d1/a1,-(a7)
		moveq	#$20,d1
		lea	statbuf(a6),a1
		bsr	stat
		bmi	create_savefile_1

		move.b	statbuf+ST_MODE(a6),d1
create_savefile_1:
		move.w	d1,d0
		movem.l	(a7)+,d1/a1
		unlk	a6
		bra	create_file

create_normal_file:
		moveq	#$20,d0
create_file:
		move.l	a0,-(a7)
		bsr	get_fair_pathname
		bcs	create_file_fail

		move.w	d0,-(a7)
		move.l	a0,-(a7)
		bset	#31,d0
		bsr	drvchkp
		bmi	create_file_done

		DOS	_CREATE
create_file_done:
		addq.l	#6,a7
create_file_return:
		movea.l	(a7)+,a0
		tst.l	d0
		rts

create_file_fail:
		moveq	#ENOFILE,d0
		bra	create_file_return
*****************************************************************
.xdef fclosexp

fclosexp:
		move.l	d0,-(a7)
		move.l	(a0),d0
		cmp.l	#4,d0
		ble	fclosexp_done

		bsr	fclose
fclosexp_done:
		move.l	#-1,(a0)
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef redirect

redirect:
		subq.l	#4,a7
		move.w	d0,-(a7)		* リダイレクトされるfdの
		DOS	_DUP			* コピーを
		move.l	d0,2(a7)		* 取っておく
		bmi	cannot_redirect

		move.w	d1,-(a7)		* リダイレクト先にリダイレクトするファイルを
		DOS	_DUP2			* コピーする
		addq.l	#2,a7
cannot_redirect:
		addq.l	#2,a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef unredirect

unredirect:
		move.l	d1,-(a7)
		move.l	(a0),d1
		bmi	unredirect_return

		move.w	d0,-(a7)
		move.w	d1,-(a7)
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,a7
unredirect_return:
		move.l	#-1,(a0)
		move.l	(a7)+,d1
		rts
*****************************************************************
* fskip_space - ファイルの空白を読み飛ばす
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コードあるいは EOF
*             正: 最下位バイトは最初の空白以外の文字（またはLF）
*
*      CCR    TST.L D0
*****************************************************************
.xdef fskip_space

fskip_space:
		move.w	d0,-(a7)
fskip_space_loop:
		DOS	_FGETC
		tst.l	d0
		bmi	fskip_space_return

		cmp.b	#LF,d0
		beq	fskip_space_return

		bsr	isspace3
		beq	fskip_space_loop
fskip_space_return:
		addq.l	#2,a7
		tst.l	d0
		rts

.end
