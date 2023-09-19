* fgetc.s
* Itagaki Fumihiko 23-Feb-91  Create.

.include doscall.h
.include chrcode.h

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
*
* NOTE
*      D0.L==0 の場合、最後の改行は削除されている
*      いずれの場合にもバッファは NUL で終端されている
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
		moveq	#0,d0
fgets_return:
		clr.b	(a0)
		addq.l	#2,a7
		tst.l	d0
		rts

fgets_over:
		moveq	#1,d0
		bra	fgets_return

.end
