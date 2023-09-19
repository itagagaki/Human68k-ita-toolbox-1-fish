* getpass.s
* Itagaki Fumihiko 16-Jun-91  Create.

.include doscall.h
.include chrcode.h

.text

****************************************************************
* getpass - 標準入力からエコー無しで1行入力する（CR まで）
*
* CALL
*      A0     入力バッファ
*      D0.L   最大入力バイト数（CRは含まない）
*      A1     プロンプト文字列の先頭アドレス
*
* RETURN
*      D0.L   入力文字数（CRは含まない）
*      CCR    TST.L D0
****************************************************************
.xdef getpass

getpass:
		movem.l	d1-d2/a0,-(a7)
		moveq	#0,d1
		move.l	d0,d2
		move.l	a1,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
getpass_loop:
		cmp.l	d2,d1
		beq	getpass_done

		clr.w	-(a7)
		DOS	_FGETC
		addq.l	#2,a7
		tst.l	d0
		bmi	getpass_done

		cmp.b	#CR,d0
		beq	getpass_done

		move.b	d0,(a0)+
		addq.l	#1,d1
		bra	getpass_loop

getpass_done:
		move.l	d1,d0
		movem.l	(a7)+,d1-d2/a0
		rts

.end
