* echo.s
* Itagaki Fumihiko 19-Jul-90  Create.

.text

****************************************************************
* echo - 単語並びの各単語を、間に１文字の空白を挿みながら順に出力する
*
* CALL
*      A0     単語並びの先頭アドレス
*      A1     単語を出力するサブ・ルーチンのエントリ・アドレス
*      A2     単語並びを出力し終えた後に１度だけ呼び出すサブ・ルーチンの
*             エントリ・アドレス（0L ならば呼び出さない）
*      D0.W   単語数
*
* RETURN
*      無し
****************************************************************
.xdef echo

echo:
		tst.w	d0
		beq	return

		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
		bra	start

loop:
		move.l	a0,-(a7)
		lea	str_space,a0
		jsr	(a1)
		move.l	(a7)+,a0
		bsr	for1str
start:
		jsr	(a1)
		dbra	d0,loop

		cmpa.l	#0,a2
		beq	done

		jsr	(a2)
done:
		movem.l	(a7)+,d0/a0
return:
		rts

.end
