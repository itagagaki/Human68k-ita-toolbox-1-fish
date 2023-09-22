* file.s
* Itagaki Fumihiko 23-Feb-91  Create.
*
* This contains file controll routines.

.include doscall.h
.include chrcode.h

.xref isspace
.xref test_drive_path

.text

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
*
* NOTE
*      ドライブの検査は行わない
*****************************************************************
.xdef create_normal_file

create_normal_file:
		move.w	#$20,-(a7)
		move.l	a0,-(a7)
		DOS	_CREATE
		addq.l	#6,a7
		tst.l	d0
		rts
*****************************************************************
* fopen - ファイルをオープンする
*
* CALL
*      A0     オープンするファイルのパス名
*      D0.W   オープンモード
*
* RETURN
*      D0.L   負: エラー・コード
*             正: 下位ワードが、オープンしたファイルのファイル・ハンドルを示す
*
*      CCR    TST.L D0
*
* NOTE
*      オープンする前にドライブを検査する
*****************************************************************
.xdef fopen

fopen:
		move.w	d0,-(a7)
		move.l	a0,-(a7)
		bsr	test_drive_path
		bne	fopen_return

		DOS	_OPEN
fopen_return:
		addq.l	#6,a7
		tst.l	d0
		rts
*****************************************************************
* fclose - ファイルをクローズする
*
* CALL
*      D0.W   ファイル・デスクリプタ
*
* fclosex - ファイル・デスクリプタが正ならばファイルをクローズする
*
* CALL
*      D0.L   ファイル・デスクリプタ
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef fclosex
.xdef fclose

fclosex:
		tst.w	d0
		bmi	fclose_return
fclose:
		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		tst.l	d0
fclose_return:
		rts
*****************************************************************
* remove - ファイルを削除する
*
* CALL
*      A0     削除するファイルのパス名
*
* RETRUN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* NOTE
*      ドライブの検査は行わない
*****************************************************************
.xdef remove

remove:
		move.l	a0,-(a7)
		DOS	_DELETE
		addq.l	#4,a7
		tst.l	d0
		rts
*****************************************************************
.xdef redirect

redirect:
		subq.l	#2,a7
		move.w	d0,-(a7)		* リダイレクトされるfdの
		DOS	_DUP			* コピーを
		move.w	d0,2(a7)		* 取っておく
		bmi	cannot_redirect

		move.w	d1,-(a7)		* リダイレクト先にリダイレクトするファイルを
		DOS	_DUP2			* コピーする
		addq.l	#2,a7
cannot_redirect:
		addq.l	#2,a7
		move.w	(a7)+,d0
		rts
*****************************************************************
.xdef unredirect

unredirect:
		tst.w	d1
		bmi	unredirect_done

		move.w	d0,-(a7)
		move.w	d1,-(a7)
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,a7
unredirect_done:
		moveq	#-1,d0
		rts
*****************************************************************
* fgetc - ファイルから1文字読み取る
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コード
*             正: 下位バイトが読み取った文字を保持している
*
*      CCR    TST.L D0
*****************************************************************
.xdef fgetc

fgetc:
		move.w	d0,-(a7)
		DOS	_FGETC
		addq.l	#2,a7
		tst.l	d0
		bmi	fgetc_return

		cmp.b	#EOT,d0
		bne	fgetc_return

		moveq	#-1,d0
fgetc_return:
		tst.l	d0
		rts
*****************************************************************
fskip_until_LF:
		move.w	d7,d0
		bsr	fgetc
		bmi	fskip_until_LF_return

		cmp.b	#LF,d0
		bne	fskip_until_LF
fskip_until_LF_return:
		tst.l	d0
		rts
*****************************************************************
* fgets - ファイルから1行読み取る
*
* CALL
*      A0     入力バッファの先頭アドレス
*      D0.W   ファイル・ハンドル
*      D1.W   入力最大バイト数（最後の NUL の分は勘定しない）
*
* RETURN
*      A0     入力文字数分進む
*
*      D0.L   負: エラー・コード
*             0 : 入力有り
*             1 : バッファ・オーバー
*
*      D1.W   残り入力可能バイト数（最後の NUL の分は勘定しない）
*
*      CCR    TST.L D0
*****************************************************************
.xdef fgets

fgets:
		move.w	d7,-(a7)
		move.w	d0,d7
fgets_loop:
		move.w	d7,d0
		bsr	fgetc
		bmi	fgets_return

		cmp.b	#CR,d0
		beq	fgets_cr

		subq.w	#1,d1
		bcs	fgets_over

		move.b	d0,(a0)+
		bra	fgets_loop

fgets_cr:
		bsr	fskip_until_LF
		bmi	fgets_return

		clr.b	(a0)
		moveq	#0,d0
fgets_return:
		move.w	(a7)+,d7
		tst.l	d0
		rts

fgets_over:
		moveq	#1,d0
		bra	fgets_return
*****************************************************************
* fseek_nextline - ファイルを次の行の先頭にシークする
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コード
*             0 : 次の行の先頭にシークした
*
*      CCR    TST.L D0
*****************************************************************
.xdef fseek_nextline

fseek_nextline:
		move.w	d7,-(a7)
		move.w	d0,d7
fseek_nextline_loop:
		move.w	d7,d0
		bsr	fgetc
		bmi	fseek_nextline_return

		cmp.b	#CR,d0
		bne	fseek_nextline_loop

		bsr	fskip_until_LF
		bmi	fseek_nextline_return

		moveq	#0,d0
fseek_nextline_return:
		move.w	(a7)+,d7
		tst.l	d0
		rts
*****************************************************************
* fseek_nextline - ファイルを次のフィールドの先頭にシークする
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コード
*             1 : 次の行の先頭にシークした
*             0 : 次のフィールドの先頭にシークした
*
*      CCR    TST.L D0
*****************************************************************
.xdef fseek_nextfield

fseek_nextfield:
		move.w	d7,-(a7)
		move.w	d0,d7
fseek_nextfield_loop:
		move.w	d7,d0
		bsr	fgetc
		bmi	fseek_nextfield_return

		cmp.b	#';',d0
		beq	fseek_nextfield_rearched

		cmp.b	#CR,d0
		bne	fseek_nextfield_loop

		bsr	fskip_until_LF
		bmi	fseek_nextfield_return

		moveq	#1,d0
		bra	fseek_nextfield_return

fseek_nextfield_rearched:
		moveq	#0,d0
fseek_nextfield_return:
		move.w	(a7)+,d7
		tst.l	d0
		rts
*****************************************************************
* fskip_space - ファイルの空白を読み飛ばす
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コードあるいはＥＯＦ
*              0: CR
*             正: 最下位バイトは最初の空白以外の文字
*
*      CCR    TST.L D0
*****************************************************************
.xdef fskip_space

fskip_space:
		move.w	d1,-(a7)
		move.w	d0,d1
fskip_space_loop:
		move.w	d1,d0
		bsr	fgetc
		bmi	fskip_space_return

		cmp.b	#CR,d0
		beq	fskip_space_cr

		bsr	isspace
		beq	fskip_space_loop

		bra	fskip_space_return

fskip_space_cr:
		moveq	#0,d0
fskip_space_return:
		move.w	(a7)+,d1
		tst.l	d0
		rts
*****************************************************************
* fmemcmp - ストリームとメモリを照合する
*
* CALL
*      D0.W   ファイル・ハンドル
*      D1.W   照合する長さ
*      A0     メモリ・アドレス
*
* RETURN
*      D0.L   負: エラー・コード
*             0 : 一致した
*             1 : 一致しない
*
*      CCR    TST.L D0
*****************************************************************
.xdef fmemcmp

fmemcmp:
		movem.l	d1-d2/a0,-(a7)
		move.w	d0,d2
		tst.l	d1
		beq	fmemcmp_matched
fmemcmp_loop:
		move.w	d2,d0
		bsr	fgetc
		bmi	fmemcmp_return

		cmp.b	(a0)+,d0
		bne	fmemcmp_fail

		subq.l	#1,d1
		bne	fmemcmp_loop
fmemcmp_matched:
		moveq	#0,d0
fmemcmp_return:
		movem.l	(a7)+,d1-d2/a0
		rts

fmemcmp_fail:
		moveq	#1,d0
		bra	fmemcmp_return
*****************************************************************

.end
