*****************************************************************
*  EncHUPAIR.s
*
*  Copyright(C)1991 by Itagaki Fumihiko
*
*  本モジュールは，上記の版権表示を含む全体を一切改変しないこ
*  とを条件に，使用，組み込み，複製，公開，再配布することを，
*  それがいかなる目的であっても認めます。ただし著作者は法の定
*  めるほかは本モジュールについて一切保証しません。本モジュー
*  ルは現状のまま無保証にて提供され，本モジュールにかかるリス
*  クはすべて使用者が自ら負うものとします。著作者は，本モジュー
*  ルを使用し，あるいは使用できなかったことによる直接的あるい
*  は間接的な損害や紛争について一切関知せず，本モジュールに欠
*  陥，不都合，誤りがあってもそれを修正する義務を負いません。
*****************************************************************
*
*  このモジュールに含まれている 2つのサブルーチン
*  EncodeHUPAIR と SetHUPAIR は，HUPAIR に従って引数並びをコ
*  マンドライン上にエンコードするものです．
*
*  以下に例を示します．
*
*		* A0 にコマンドラインの先頭アドレスを，D0.W に
*		* コマンドラインの容量（バイト数）をセットする．
*
*		lea	cmdline,a0
*		move.w	#CMDLINE_SIZE,d0
*
*		* A1 にエンコードしたい引数並びの先頭アドレスを，
*		* D1.W にその単語数をセットして，EncodeHUPAIR
*		を呼び出す．
*
*		lea	wordlist_1,a1
*		move.w	nwords_1,d1
*		bsr	EncodeHUPAIR
*		bmi	too_long	*  負が返ったらエラー
*
*		* この操作は連続して繰り返し行うことができる．
*		* つまり，エンコードしたい引数並びは複数の領域
*		* に分割されていても良い．
*
*		lea	wordlist_2,a1
*		move.w	nwords_2,d1
*		bsr	EncodeHUPAIR
*		bmi	too_long
*			.
*			.
*			.
*
*		* EncodeHUPAIR の繰り返しを終えたら，最後に
*		* SetHUPAIR を呼び出してコマンドラインを完成さ
*		* せる．
*
*		lea	cmdline,a1
*		move.w	#CMDLINE_SIZE,d1
*		bsr	SetHUPAIR
*		bmi	too_long	*  負が返ったらエラー
*
*		* ここで，D0.W はコマンドラインの文字列の長さ，
*		* D1.W は実際にコマンドラインの 1バイト目にセッ
*		* トした値である．コマンドラインの文字列が255
*		* バイトを超えたことを検知するには，
*
*		cmp.w	#255,d0
*		bhi	huge_arg
*
*		* あるいは
*
*		cmp.w	d1,d0
*		bne	huge_arg
*
*		* とすれば良い．
*
*
*	.DATA
*	.EVEN
*	nwords_1:	dc.w	2
*	wordlist_1:	dc.b	'arg1',0
*			dc.b	'arg2',0
*
*	.EVEN
*	nwords_2:	dc.w	3
*	wordlist_2:	dc.b	'arg3',0
*			dc.b	'arg4',0
*			dc.b	'arg5',0
*
*	hupair_
*
*	.BSS
*			ds.b	8		*  ここには 'HUPAIR>',0 が書き込まれる．
*	cmdline:	ds.b	CMDLINE_SIZE
*
*****************************************************************
* EncodeHUPAIR - 引数並びを HUPAIR に従ってバッファにエンコードする
*
* CALL
*      A0     バッファのアドレス
*
*      D0.W   バッファの容量（バイト数）
*
*      A1     エンコードする引数並び
*
*      D1.W   エンコードする引数の数（無符号）
*
* RETURN
*      A0     続いて EncodeHUPAIR または SetHUPAIR を呼び出す際に
*             渡すべき A0 の値．
*             （バッファの書き込みポインタ）
*
*      D0.L   正数ならば，下位ワードは続いて EncodeHUPAIR または
*             SetHUPAIR を 呼び出す際に 渡すべき D0.W の値．
*             （バッファの残り容量）
*             負数ならば容量不足を示す．
*
*      CCR    TST.L D0
*
* STACK
*      20 Bytes
*
* DESCRIPTION
*      $00 で終端された文字列が隙間無く並んでいる《引数並び》
*      をエンコードしてバッファに書き込む．書き込む先頭位置は
*      呼び出し時に A0レジスタで指定し，その位置からの容量を
*      D0.Wレジスタで示す．リターン時の A0レジスタと D0.Wレジ
*      スタの値は，続けて EncodeHUPAIR または SetHUPAIR を呼
*      ぶ際に使用される．
*      リターン時に D0.Lレジスタの値が負数になっているならば，
*      それはバッファの容量が不足したことを示している．
*
* NOTE
*      エンコードする引数の数が 0 でなければ，最初に空白（$20）
*      が 1文字置かれる．
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      12 Mar. 1991   板垣 史彦         作成
*       2 Nov. 1991   板垣 史彦         クオート範囲を最長とする
*****************************************************************

	.TEXT
	.XDEF	EncodeHUPAIR

EncodeHUPAIR:
		movem.l	d1-d3/a1-a2,-(a7)
		moveq	#0,d2
		move.w	d0,d2			*  D2.L : バッファの残り容量
encode_continue:
		dbra	d1,encode_loop
encode_return:
		move.l	d2,d0
		movem.l	(a7)+,d1-d3/a1-a2
		rts

encode_loop:
		subq.l	#1,d2
		bcs	encode_return

		move.b	#' ',(a0)+		*  １文字のスペースを置いて、続く単語を区切る

		move.b	(a1),d0			*  単語が空なら
		beq	begin_quote		*  クオートする
encode_one_loop:
		*  先読みしてクオートすべき文字を探す
		movea.l	a1,a2
		sf	d3			*  D3.B : 空白文字を見つけたことを覚えるフラグ
prescan:
		move.b	(a2)+,d0
		beq	prescan_done		*  → 先読み終了

		cmp.b	#'"',d0			*  " を見つけたら
		beq	begin_quote		*  ' でクオートを開始する

		cmp.b	#"'",d0			*  ' を見つけたら
		beq	begin_quote		*  " でクオートを開始する

		cmp.b	#' ',d0
		beq	found_white_space	*  → 空白文字を見つけた

		cmp.b	#$09,d0
		blo	prescan

		cmp.b	#$0d,d0
		bhi	prescan
found_white_space:
	*  空白文字を見つけた
		st	d3			*  空白文字を見つけたことを覚えておいて
		bra	prescan			*  先読みを続ける

prescan_done:
	*  先読み終了
		tst.b	d3			*  空白文字があったならば
		bne	begin_quote		*  " でクオートを開始する

	*  もうクオートすべき文字は無いので、単語の残りを一気にコピーする。
		subq.l	#1,a2
		move.l	a2,d0
		sub.l	a1,d0			*  D0.L : コピーするバイト数
		sub.l	d0,d2
		bcs	encode_return
dup_loop:
		move.b	(a1)+,d0
		beq	encode_continue

		move.b	d0,(a0)+
		bra	dup_loop

begin_quote:
	*  D0.B が " ならば ' で、そうでなければ " でクオートを開始する
		moveq	#'"',d3
		cmp.b	d0,d3
		bne	insert_quote_char

		moveq	#"'",d3
insert_quote_char:
		move.b	d3,d0
		bra	quoted_insert

quoted_loop:
		move.b	(a1),d0
		beq	close_quote		*  単語の終わりならクオートを閉じる

		cmp.b	d3,d0			*  クオート文字が現われたなら
		beq	close_quote		*  クオートを一旦閉じる

		addq.l	#1,a1
quoted_insert:
		subq.l	#1,d2
		bcs	encode_return

		move.b	d0,(a0)+
		bra	quoted_loop

close_quote:
		subq.l	#1,d2
		bcs	encode_return

		move.b	d3,(a0)+
		bra	encode_one_loop
*****************************************************************
* SetHUPAIR - コマンドラインを完成する
*
* CALL
*      A0     最後の EncodeHUPAIR 呼び出し後の A0 の値
*             （バッファの書き込みポインタ）
*
*      D0.W   最後の EncodeHUPAIR 呼び出し後の D0.W の値
*             （バッファの残り容量）
*
*      A1     最初の EncodeHUPAIR 呼び出し時に渡した A0 の値
*             （コマンドラインの先頭アドレス）
*
*      D1.W   最初の EncodeHUPAIR 呼び出し時に渡した D0.W の値
*             （コマンドラインの全容量）
*
* RETURN
*      D0.L   正数ならば，下位ワードはコマンドラインの文字列の
*             長さ（バイト数）．
*             負数ならば容量不足を示す．
*
*      D1.W   コマンドラインの 1バイト目にセットした，文字列の
*             長さ．ただし D0.L が負数のときには不定．
*
*      CCR    TST.L D0
*
* STACK
*      0 Bytes
*
* DESCRIPTION
*      EncodeHUPAIR の繰り返しを終えた後に呼び出してコマンド
*      ラインを完成させるものである．
*
*      A1レジスタで与えられるコマンドラインの前には8バイトの
*      余白がなければならない．この8バイトの余白には 'HUPAIR>',0
*      が書き込まれる．
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      11 Aug. 1991   板垣 史彦         作成
*      24 Nov. 1991   板垣 史彦         'HUPAIR>',0 をセット
*****************************************************************

	.TEXT
	.XDEF	SetHUPAIR

SetHUPAIR:
		tst.w	d0
		beq	set_over

		sub.w	d0,d1
		moveq	#0,d0
		move.w	d1,d0
		beq	set_noarg

		clr.b	(a0)
		subq.w	#1,d0
		move.w	#255,d1
		cmp.w	d1,d0
		bhi	set_length

		move.w	d0,d1
		bra	set_length

set_noarg:
		clr.b	1(a1)
set_length:
		move.b	d1,(a1)
		subq.l	#8,a1
		move.b	#'#',(a1)+
		move.b	#'H',(a1)+
		move.b	#'U',(a1)+
		move.b	#'P',(a1)+
		move.b	#'A',(a1)+
		move.b	#'I',(a1)+
		move.b	#'R',(a1)+
		clr.b	(a1)+
		tst.l	d0
		rts

set_over:
		moveq	#-1,d0
		rts
*****************************************************************

	.END
