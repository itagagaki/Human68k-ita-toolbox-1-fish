* rotate.s
* Itagaki Fumihiko 16-Jul-90  Create.

.text

****************************************************************
* rotate - 配列を巡回する
*
* CALL
*      A0     巡回させる配列の先頭アドレス
*      A1     巡回後先頭となる要素のアドレス
*      A2     巡回させる配列の最終アドレス＋１
*
* RETURN
*      なし
*****************************************************************
.xdef rotate

rotate:
		bsr	reverse			* 前半を反転する
		exg	a0,a1
		exg	a1,a2
		bsr	reverse			* 後半を反転する
		exg	a0,a2
		bsr	reverse			* 全体を反転する
						* これで前半と後半が入れ替わるのだ！
		exg	a1,a2
		rts

.end
