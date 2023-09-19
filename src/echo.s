* echo.s
* Itagaki Fumihiko 19-Jul-90  Create.
* Itagaki Fumihiko 17-Aug-91  仕様変更

.xref strfor1
.xref str_space

.text

****************************************************************
* echo - 単語並びの各単語を，間に１文字の空白を挿みながら順に出力する
*
* CALL
*      A0     単語並びの先頭アドレス
*      A1     単語を出力するサブルーチンのエントリ・アドレス
*             このサブルーチンを呼び出す際，D0.L はクリアする．
*      D0.W   単語数
*
* RETURN
*      D0.L   A1 が示すサブルーチンから戻ったときの D0.L の 総OR
*      CCR    TST.L D0
****************************************************************
.xdef echo

echo:
		movem.l	d1-d2/a0,-(a7)
		moveq	#0,d1
		move.w	d0,d2			*  D2.W : ループ・カウンタ
		beq	done

		subq.w	#1,d2
		bra	start

loop:
		move.l	a0,-(a7)
		lea	str_space,a0
		jsr	(a1)
		move.l	(a7)+,a0
		bsr	strfor1
start:
		moveq	#0,d0
		jsr	(a1)
		or.l	d0,d1
		dbra	d2,loop
done:
		move.l	d1,d0
		movem.l	(a7)+,d1-d2/a0
		rts

.end
