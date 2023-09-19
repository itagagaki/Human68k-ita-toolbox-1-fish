* file.s
* Itagaki Fumihiko 23-Feb-91  Create.
*
* This contains file controll routines.

.include doscall.h
.include chrcode.h

.xref isspace
.xref fclose
.xref drvchkp

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

fclosex:
		tst.l	d0
		bpl	fclose

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
		tst.l	d1
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
		move.w	d0,-(a7)
fgets_loop:
		DOS	_FGETC
		tst.l	d0
		bmi	fgets_return

		cmp.b	#LF,d0
		beq	fgets_lf

		cmp.b	#CR,d0
		bne	fgets_input_one

		DOS	_FGETC
		tst.l	d0
		bmi	fgets_return

		cmp.b	#LF,d0
		beq	fgets_lf

		subq.w	#1,d1
		bcs	fgets_over

		move.b	#CR,(a0)+
fgets_input_one:
		subq.w	#1,d1
		bcs	fgets_over

		move.b	d0,(a0)+
		bra	fgets_loop

fgets_lf:
		clr.b	(a0)
		moveq	#0,d0
fgets_return:
		addq.l	#2,a7
		tst.l	d0
		rts

fgets_over:
		moveq	#1,d0
		bra	fgets_return
*****************************************************************
* fforline - ファイルを次の行の先頭にシークする
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コードあるいは EOF
*             正: 次の行の先頭にシークした
*
*      CCR    TST.L D0
*****************************************************************
.xdef fforline

fforline:
		move.w	d0,-(a7)
fforline_loop:
		DOS	_FGETC
		tst.l	d0
		bmi	fforline_return

		cmp.b	#LF,d0
		bne	fforline_loop
fforline_return:
		addq.l	#2,a7
		tst.l	d0
		rts
*****************************************************************
* fforfield - ファイルを次のフィールドの先頭にシークする
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   負: エラー・コードあるいは EOF
*             正: D0.B:LF:  次の行の先頭にシークした
*                 D0.B:';'  次のフィールドの先頭にシークした
*
*      CCR    TST.L D0
*****************************************************************
.xdef fforfield

fforfield:
		move.w	d0,-(a7)
fforfield_loop:
		DOS	_FGETC
		tst.l	d0
		bmi	fforfield_return

		cmp.b	#';',d0
		beq	fforfield_return

		cmp.b	#LF,d0
		bne	fforfield_loop
fforfield_return:
		addq.l	#2,a7
		tst.l	d0
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

		bsr	isspace
		beq	fskip_space_loop
fskip_space_return:
		addq.l	#2,a7
		tst.l	d0
		rts
.if 0
*****************************************************************
* fmemcmp - ストリームとメモリを照合する
*
* CALL
*      D0.W   ファイル・ハンドル
*      D1.W   照合する長さ
*      A0     メモリ・アドレス
*
* RETURN
*      D0.L   負: エラー・コードあるいは EOF
*             0 : 一致した
*             1 : 一致しない
*
*      CCR    TST.L D0
*****************************************************************
.xdef fmemcmp

fmemcmp:
		movem.l	d1/a0,-(a7)
		move.w	d0,-(a7)
		tst.l	d1
		beq	fmemcmp_matched
fmemcmp_loop:
		DOS	_FGETC
		tst.l	d0
		bmi	fmemcmp_return

		cmp.b	(a0)+,d0
		bne	fmemcmp_fail

		subq.l	#1,d1
		bne	fmemcmp_loop
fmemcmp_matched:
		moveq	#0,d0
fmemcmp_return:
		addq.l	#2,a7
		movem.l	(a7)+,d1/a0
		tst.l	d0
		rts

fmemcmp_fail:
		moveq	#1,d0
		bra	fmemcmp_return
*****************************************************************
.endif

.end
