****************************************************************
* DecodeFishArgs - コマンドラインをデコードして引数並びを得る
*
* CALL
*      A0     コマンド・ラインの先頭アドレス＋１
*
* RETURN
*      A0     引数並びの先頭アドレス
*      D0.W   引数の数
*      CCR    破壊
*
* DESCRIPTION
*      A0 が指すアドレスから始まり $00 で終端されている文字列を
*      fish仕様に基づいてデコードして引数並びを得る。引数並びは
*      $00 で終端された引数が、順番に隙間無く並んでいるものであ
*      る。
*
*      返す A0 は引数並びの先頭アドレスであるが、これは呼び出し
*      時と同じである。すなわち、元の文字列は失われる。
*
*      返す D0.W は引数の数である。
*
* AUTHOR
*      板垣 史彦
*
* REVISION
*      12 Mar. 1991   板垣 史彦         作成
****************************************************************

	.TEXT

	.XDEF	DecodeFishArgs

DecodeFishArgs:
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
		rts

	.END
