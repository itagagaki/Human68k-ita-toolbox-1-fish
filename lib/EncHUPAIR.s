*  Revision 2 : 24 Jan 1993   コメント修正

*****************************************************************
*  EncHUPAIR.s
*
*  Copyright(C)1991-93 by Itagaki Fumihiko
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


*  このモジュールに含まれている 2つのサブルーチン
*  EncodeHUPAIR と SetHUPAIR は，HUPAIRに従って引数列をコマン
*  ドライン上にエンコードするものです．
*
*  以下に例を示します．
*
*	*  A0 にコマンドラインの先頭アドレスを，D0.L にコマ
*	*  ンドラインの容量（バイト数）をセットする．
*
*		lea	cmdline,a0
*		move.l	#CMDLINE_SIZE,d0
*
*	*  A1 にエンコードしたい引数列の先頭アドレスを，D1.L
*	*  にその単語数をセットして，EncodeHUPAIR を呼び出す．
*
*		lea	wordlist_1,a1
*		move.l	nwords_1,d1
*		bsr	EncodeHUPAIR
*		bmi	too_long	*  負が返ったらエラー
*
*	*  この操作は連続して繰り返し行うことができる．つま
*	*  り，エンコードしたい引数列は複数の領域に分割され
*	*  ていても良い．
*
*		lea	wordlist_2,a1
*		move.l	nwords_2,d1
*		bsr	EncodeHUPAIR
*		bmi	too_long
*			.
*			.
*			.
*
*	*  EncodeHUPAIR の繰り返しを終えたら，最後に
*	*  SetHUPAIR を呼び出してコマンドラインを完成させる．
*	*  ここまでの間，A0 と D0.L を破壊してはならない．
*
*		lea	cmdline,a1
*		lea	cmdname,a2
*		move.l	#CMDLINE_SIZE,d1
*		bsr	SetHUPAIR
*		bmi	too_long	*  負が返ったらエラー
*
*	*  ここで，D0.L はコマンドラインの文字列の長さ，D1.L
*	*  は実際にコマンドラインの 1バイト目にセットした値
*	*  である．コマンドラインの文字列が255バイトを超えた
*	*  ことを検知するには，
*
*		cmp.l	#255,d0
*		bhi	huge_arg
*
*		* あるいは
*
*		cmp.l	d1,d0
*		bne	huge_arg
*
*	*  とすれば良い．
*
*		.data
*	cmdname:	dc.b	'cmd',0
*
*		.even
*	nwords_1:	dc.l	2
*	wordlist_1:	dc.b	'arg1',0
*			dc.b	'arg2',0
*
*		.even
*	nwords_2:	dc.l	3
*	wordlist_2:	dc.b	'arg3',0
*			dc.b	'arg4',0
*			dc.b	'arg5',0
*
*		.bss
*			ds.b	8		*  ここには '#HUPAIR',0 が書き込まれる．
*	cmdline:	ds.b	CMDLINE_SIZE



*****************************************************************
* EncodeHUPAIR - 引数列をHUPAIRに従ってバッファにエンコードする
*
* CALL
*      A0     バッファのアドレス
*      D0.L   バッファの容量（バイト数）（符号付き．正数であること）
*      A1     エンコードする引数列
*      D1.L   エンコードする引数の数（無符号）
*
* RETURN
*      A0     続いてEncodeHUPAIRまたはSetHUPAIRを呼び出す際に
*             渡すべきA0の値（バッファの書き込みポインタ）．
*
*      D0.L   正数ならば，続いてEncodeHUPAIRまたはSetHUPAIRを
*             呼び出す際に渡すべきD0.Lの値（バッファの残り容量）．
*             負数ならばエラー（容量不足）．
*
*      CCR    TST.L D0
*
* STACK
*      20 Bytes
*
* DESCRIPTION
*      $00 で終端された文字列が D1.L個だけ隙間無く並んでいる引
*      数列をエンコードしてバッファに書き込む．書き込む先頭位
*      置は呼び出し時に A0レジスタで指定し，その位置からの容量
*      を D0.Lレジスタで示す．リターン時の A0レジスタと D0.Lレ
*      ジスタの値は，続けて EncodeHUPAIR または SetHUPAIR を呼
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
*       3 Jan. 1992   板垣 史彦         数の制限を除去
*****************************************************************

	.text
	.xdef	EncodeHUPAIR

EncodeHUPAIR:
		movem.l	d1-d3/a1-a2,-(a7)
		move.l	d0,d2			*  D2.L : バッファの残り容量
		bmi	encode_return
encode_continue:
		subq.l	#1,d1
		bcc	encode_loop
encode_return:
		move.l	d2,d0
		movem.l	(a7)+,d1-d3/a1-a2
		rts

encode_loop:
		subq.l	#1,d2
		bmi	encode_return

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

		cmp.b	#$09,d0			*  本来 HUPAIR では $09～$0d（ht, nl(lf), vt,
		blo	prescan			*  ff, cr）はクオート不要だが，HUPAIR に準拠
						*  していないプログラムに対しても引数がうま
		cmp.b	#$0d,d0			*  く伝わることが少しでも多くなることを期待
		bhi	prescan			*  してクオートする．
found_white_space:
	*  空白文字を見つけた
		st	d3			*  空白文字を見つけたことを覚えておいて
		bra	prescan			*  先読みを続ける

prescan_done:
	*  先読み終了
		tst.b	d3			*  空白文字があったならば
		bne	begin_quote		*  " でクオートを開始する

	*  もうクオートすべき文字は無いので，単語の残りを一気にコピーする
dup_loop:
		move.b	(a1)+,d0
		beq	encode_continue

		subq.l	#1,d2
		bmi	encode_return

		move.b	d0,(a0)+
		bra	dup_loop

begin_quote:
	*  D0.B が " ならば ' で，そうでなければ " でクオートを開始する
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
		bmi	encode_return

		move.b	d0,(a0)+
		bra	quoted_loop

close_quote:
		subq.l	#1,d2
		bmi	encode_return

		move.b	d3,(a0)+
		bra	encode_one_loop

*****************************************************************
* SetHUPAIR - コマンドラインを完成する
*
* CALL
*      A0     最後の EncodeHUPAIR 呼び出し後の A0 の値
*             （バッファの書き込みポインタ）
*
*      D0.L   最後の EncodeHUPAIR 呼び出し後の D0.L の値
*             （バッファの残り容量）
*
*      A1     最初の EncodeHUPAIR 呼び出し時に渡した A0 の値
*             （コマンドラインの先頭アドレス）
*
*      D1.L   最初の EncodeHUPAIR 呼び出し時に渡した D0.L の値
*             （コマンドラインの全容量）
*
*      A2     arg0 の先頭アドレス
*
* RETURN
*      D0.L   正数ならば，コマンドラインの文字列の長さ（バイト
*             数）．負数ならば容量不足を示す．
*
*      D1.L   コマンドラインの 1バイト目にセットした，文字列の
*             長さ．ただし D0.L が負数のときには不定．
*
*      A0     バッファに arg0 + $00 をセットしたその次のアドレス
*
*      CCR    TST.L D0
*
* STACK
*      8 Bytes
*
* DESCRIPTION
*      EncodeHUPAIR の繰り返しを終えた後に呼び出してコマンド
*      ラインを完成させるものである．
*
*      コマンドラインの後ろには A2レジスタで示される arg0 が
*      格納される．
*
*      A1レジスタで与えられるコマンドラインの前には8バイトの
*      余白がなければならない．この8バイトの余白には '#HUPAIR',0
*      が書き込まれる．
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      11 Aug. 1991   板垣 史彦         作成
*      24 Nov. 1991   板垣 史彦         '#HUPAIR',0 をセット
*       3 Jan. 1992   板垣 史彦         数の制限を除去，arg0 をセット
*****************************************************************

	.text
	.xdef	SetHUPAIR

SetHUPAIR:
		movem.l	d2/a2,-(a7)
		tst.l	d0
		bmi	set_return

		sub.l	d0,d1
		beq	set_noarg

		move.l	d1,d2
		subq.l	#1,d2
		move.l	#255,d1
		cmp.l	d1,d2
		bhi	set_length
		bra	set_length_d2

set_noarg:
		subq.l	#1,d0
		bmi	set_return

		lea	1(a1),a0
		moveq	#0,d2
set_length_d2:
		move.l	d2,d1
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

		subq.l	#1,d0
		bmi	set_return

		clr.b	(a0)+
set_arg0_loop:
		subq.l	#1,d0
		bmi	set_return

		move.b	(a2)+,(a0)+
		bne	set_arg0_loop

		move.l	d2,d0
set_return:
		movem.l	(a7)+,d2/a2
		rts
*****************************************************************

	.end
