*  Revision 2 : 24 Jan 1993   コメント修正

*****************************************************************
*  DecHUPAIR.s
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


*  このモジュールに含まれている サブルーチン DecodeHUPAIR は，
*  HUPAIR に従ってコマンドライン上にエンコードされた引数列を
*  デコードするものです．
*
*  以下に例を示します．
*
*		.text
*
*	start:				*  start : 実行開始アドレス
*		bra.s	start1		*  2 Byte
*		dc.b	'#HUPAIR',0	*  実行開始アドレス+2 にこのデータを置くことにより，
*					*  HUPAIR適合コマンドであることを示すことができる．
*	start1:
*		lea	stack_bottom,a7
*
*	*  引数列格納領域を確保する
*
*		movea.l	a0,a5		*  A5 := プログラムのメモリ管理ポインタのアドレス
*		movea.l	a7,a1		*  A1 := 引数列を格納する領域の先頭アドレス
*		lea	1(a2),a0	*  A0 := コマンドラインの文字列の先頭アドレス
*		bsr	strlen		*  D0.L に A0 が示す文字列の長さ（$00 の直前までのバ
*					*  イト数）を求め，
*		add.l	a1,d0		*    格納エリアの容量を
*		bcs	insufficient_memory
*		cmp.l	8(a5),d0	*    チェックする．
*		bhs	insufficient_memory
*
*			*  この例では，プロセス起動時に最大メモリ・ブロックが割り当てられてい
*			*  ることを利用して，その中に引数格納領域を割いている．一旦メモリ・ブ
*			*  ロックを setblockで切り詰めてから malloc するのも良いだろう．
*
*		*  ここで，
*		*       A0 : コマンドラインの文字列の先頭アドレス
*		*       A1 : 引数列を格納する領域の先頭アドレス
*
*	*  コマンドラインをデコードして引数列を得る
*
*		bsr	DecodeHUPAIR
*
*		*  ここで，D0.L は引数の数．A1 が指す領域には，D0.L が示す個数だけ，単一の引数
*		*  （$00で終端された文字列）が隙間無く並んでいる．
*
*	*  たとえば，引数を 1行に 1つずつ表示するには，
*
*		move.l	d0,d1
*		bra	print_args_continue
*
*	print_args_loop:
*		*
*		*  引数を 1つ表示する
*		*
*		move.l	a1,-(a7)
*		DOS	_PRINT
*		addq.l	#4,a7
*		move.w	#$0d,-(a7)
*		DOS	_PUTCHAR
*		move.w	#$0a,(a7)
*		DOS	_PUTCHAR
*		addq.l	#2,a7
*		*
*		*  ポインタを次の引数に進める
*		*
*	skip_1_arg:
*		tst.b	(a1)+
*		bne	skip_1_arg
*		*
*		*  引数の数だけ繰り返す
*		*
*	print_args_continue:
*               subq.l	#1,d1
*		bcc	print_args_loop
*			.
*			.
*			.
*
*		.bss
*		.ds.b	STACKSIZE
*		.even
*	stack_bottom:
*
*		.END	start



*****************************************************************
* DecodeHUPAIR - HUPAIRに従ってコマンドラインをデコードし，引数
*                列を得る
*
* CALL
*      A0     HUPAIRに従ってエンコードされた引数の先頭アドレス
*             （コマンドラインの先頭アドレス + 1）
*
*      A1     デコードした引数列を書き込むエリアの先頭アドレス
*
* RETURN
*      A0     コマンドラインの文字列の最後の $00 の次のアドレス
*      D0.L   引数の数（無符号）
*      CCR    TST.L D0
*
* STACK
*      12 Bytes
*
* DESCRIPTION
*      A0レジスタが指すアドレスから始まる文字列（source）を
*      HUPAIR に従ってデコードして引数列を得，A1レジスタが指す
*      アドレスから始まるエリア（destination）に格納する．
*
*      destination には，戻り値D0.Lが示す個数だけ，単一の引数
*      （$00で終端された文字列）が順番に隙間無く並ぶ．
*
*      destination には最大 source の長さだけの容量が必要である．
*
*      もしコマンドラインの先頭-8からの8バイトが '#HUPAIR',0
*      であるならば，リターン時の A0 が指しているアドレスには
*      arg0 がある．ただしこのサブルーチンでは '#HUPAIR',0 は
*      チェックしない．
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      12 Mar. 1991   板垣 史彦         作成
*       7 Oct. 1991   板垣 史彦         sourceとdestinationを分離
*       3 Jan. 1992   板垣 史彦         A0を戻り置として加える
*                                       戻り置 D0.W を D0.L に変更
*****************************************************************

	.text

	.xdef	DecodeHUPAIR

DecodeHUPAIR:
		movem.l	d1-d2/a1,-(a7)
		moveq	#0,d0
		moveq	#0,d2
global_loop:
skip_loop:
		move.b	(a0)+,d1
		cmp.b	#' ',d1
		beq	skip_loop

		tst.b	d1
		beq	done

		addq.l	#1,d0				*  オーバーフローは有り得ない
dup_loop:
		tst.b	d2
		beq	not_in_quote

		cmp.b	d2,d1
		bne	dup_one
quote:
		eor.b	d1,d2
		bra	dup_continue

not_in_quote:
		cmp.b	#'"',d1
		beq	quote

		cmp.b	#"'",d1
		beq	quote

		cmp.b	#' ',d1
		beq	terminate
dup_one:
		move.b	d1,(a1)+
		beq	done
dup_continue:
		move.b	(a0)+,d1
		bra	dup_loop

terminate:
		clr.b	(a1)+
		bra	global_loop

done:
		movem.l	(a7)+,d1-d2/a1
		tst.l	d0
		rts
*****************************************************************

	.end
