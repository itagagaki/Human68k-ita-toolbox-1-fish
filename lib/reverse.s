* reverse.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* reverse - 文字配列を反転する
*
* CALL
*      A0     反転させる配列の先頭アドレス
*      A1     反転させる配列の最終アドレス＋１
*
* RETURN
*      なし
*****************************************************************
.xdef reverse

reverse:
		movem.l	d0/a0-a1,-(a7)
loop:
		cmpa.l	a0,a1
		bls	done

		move.b	-(a1),d0
		move.b	(a0),(a1)
		move.b	d0,(a0)+
		bra	loop

done:
		movem.l	(a7)+,d0/a0-a1
		rts

.end
