*****************************************************************
*  DecHUPAIR.s
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
*  このモジュールに含まれている サブルーチン DecodeHUPAIR は，
*  HUPAIR に従ってコマンドライン上にエンコードされた引数並び
*  をデコードするものです．
*
*  以下に例を示します．
*
*	start:					*  start : 実行開始アドレス
*			bra.s	start1		*  2Byte
*			dc.b	'#HUPAIR',0	*  実行開始アドレス+2 にこのデータを
*						*  置いて，HUPAIR適合コマンドである
*						*  ことを親プロセスに示す．
*	start1:
*			lea	stack(a6),a7
*			lea	1(a2),a0	*  A0 : コマンドラインの文字列のアドレス
*			bsr	DecodeHUPAIR	*  デコードする
*
*			*  ここで，A0 は引数並びの先頭アドレス，
*			*  D0.W は引数の数である．A0 からのアド
*			*  レスには，$00 で終端された文字列
*			*  （1つの引数）が D0.W が示す数だけ，
*			*  隙間無く続いている．
*
*			*  たとえば，引数を 1行に 1つずつ表示するには，
*
*			move.w	d0,d1
*			bra	print_args_continue
*
*	print_args_loop:
*			*
*			*  引数を 1つ表示する
*			*
*			move.l	a0,-(a7)
*			DOS	_PRINT
*			addq.l	#4,a7
*			move.w	#$0d,-(a7)
*			DOS	_PUTCHAR
*			move.w	#$0a,(a7)
*			DOS	_PUTCHAR
*			addq.l	#2,a7
*			*
*			*  ポインタを次の引数に進める
*			*
*	skip_1_arg:
*			tst.b	(a0)+
*			bne	skip_1_arg
*			*
*			*  引数の数だけ繰り返す
*			*
*	print_args_continue:
*			dbra	d1,print_args_loop
*				.
*				.
*				.
*		.END	start
*
*****************************************************************
* DecodeHUPAIR - コマンドラインを HUPAIR に従ってデコードして
*                引数並びを得る
*
* CALL
*      A0     引数並びが HUPAIR に従ってエンコードされている
*             文字列の先頭アドレス
*             （コマンド・ラインの先頭アドレス＋１）
*
* RETURN
*      A0     デコードされた引数並びの先頭アドレス
*      D0.W   引数の数（無符号）
*      CCR    TST.W D0
*
* STACK
*      16 Bytes
*
* DESCRIPTION
*      A0レジスタが指すアドレスから始まり $00コードで終端され
*      ている文字列を HUPAIR に従ってデコードして引数並びを得
*      る．ここで得られる引数並びの構造は，$00コードで終端さ
*      れた文字列（引数）が順番に隙間無く並んでいるものである．
*
*      リターン時の A0レジスタは引数並びの先頭アドレスを指し
*      ているであるが，これは呼び出し時の A0レジスタの値と同
*      じである．すなわち，元の文字列は失われる．
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      12 Mar. 1991   板垣 史彦         作成
*****************************************************************

	.TEXT

	.XDEF	DecodeHUPAIR

DecodeHUPAIR:
		movem.l	d1-d2/a0-a1,-(a7)
		clr.w	d0
		movea.l	a0,a1
		moveq	#0,d2
global_loop:
skip_loop:
		move.b	(a1)+,d1
		cmp.b	#' ',d1
		beq	skip_loop

		tst.b	d1
		beq	done

		addq.w	#1,d0
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
		move.b	d1,(a0)+
		beq	done
dup_continue:
		move.b	(a1)+,d1
		bra	dup_loop

terminate:
		clr.b	(a0)+
		bra	global_loop

done:
		movem.l	(a7)+,d1-d2/a0-a1
		tst.w	d0
		rts
*****************************************************************

	.END
