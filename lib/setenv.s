* setenv.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strlen
.xref stpcpy
.xref strmove
.xref memmovd
.xref strfor1
.xref strazcpy
.xref strazbot
.xref getenv

.text

*****************************************************************
* setenv - 環境変数をセットする
*
* CALL
*      A0       変数名の先頭アドレス
*      A1       値の文字列の先頭アドレス
*      A3       環境ブロックの先頭アドレス
*
* RETURN
*      D0.L	成功なら 0  容量が足りなければ 1
*      CCR      TST.L D0
*****************************************************************
.xdef setenv

setenv:
		movem.l	d1-d2/a0-a2/a4,-(a7)
		cmpa.l	#-1,a3
		beq	nospace

		movea.l	a1,a2			*  A2 : value
		movea.l	a0,a1			*  A1 : name
		jsr	getenv			*  name を探す
		bne	setenv_change_value	*  見つかれば change_value

		movea.l	a1,a0			*  nameの
		jsr	strlen			*    長さ
		move.l	d0,d1			*    ＋
		movea.l	a2,a0			*    valueの
		jsr	strlen			*    長さ
		add.l	d0,d1			*    ＋
		addq.l	#2,d1			*    ２（'='とNULの分）をD1にセット

		lea	4(a3),a0		*  環境の
		bsr	find_env_bottom		*    末尾＋１をA0に
		move.l	a3,d0			*  環境の
		add.l	(a3),d0			*    底＋１をD0に
		sub.l	a0,d0			*  空き容量は
		bcs	nospace			*  ない

		cmp.l	d1,d0			*  D1バイトは
		blo	nospace			*  ない

		subq.l	#1,a0			*  A0は環境の末尾
		jsr	stpcpy			*  名前をコピー
		move.b	#'=',(a0)+		*  = でつなげて
		movea.l	a2,a1			*  値を
		jsr	strmove			*  コピー
		clr.b	(a0)			*  環境の終わりのマークをセット
		bra	success			*  終わり

setenv_change_value:
		move.l	a0,d2			*  D2 := 既存の環境の名前のポインタ
		movea.l	d0,a4			*  A4 := 現在の値を指すポインタ
		movea.l	a2,a0			*  新たな値の
		jsr	strlen			*  長さ
		move.l	d0,d1			*  から
		movea.l	a4,a0			*  現在の値の
		jsr	strlen			*  長さを
		sub.l	d0,d1			*  引く
		beq	just_change_value	*  長さが同じならば書き換えるのみ
		blo	setenv_change_and_trunc	*  余裕があれば書き換えた後に切り詰める

		* D1バイト足りない
		movea.l	d2,a0			*  環境の現在の
		bsr	find_env_bottom		*    末尾＋１をA0にセット
		move.l	a3,d0			*  環境の
		add.l	(a3),d0			*    底＋１
		sub.l	a0,d0			*  空き容量は
		bcs	nospace			*  ない

		cmp.l	d1,d0			*  D1バイトは
		blo	nospace			*  ない

		movea.l	a0,a1			*  環境の現在の末尾＋１をA1（ソース）に
		movea.l	d2,a0			*  現在の環境の要素の
		jsr	strfor1			*    次の要素のアドレスをA0に
		move.l	a1,d0			*  環境の現在の末尾＋１から
		sub.l	a0,d0			*  A0を引けば、転送するサイズ
		movea.l	a1,a0			*  ソース
		adda.l	d1,a0			*    ＋D1がデスティネーション
		jsr	memmovd			*  後方ブロック転送
just_change_value:
		bsr	change_value		*  値を書き換える
		bra	success			*  終わり

setenv_change_and_trunc:
		movea.l	d2,a0			*  現在の環境の要素の
		jsr	strfor1			*    次の要素のアドレスを
		move.l	a0,-(a7)		*    セーブ
		bsr	change_value		*  値を書き換える
		move.l	(a7)+,a1		*  次の要素のアドレス
		jsr	strazcpy		*  切り詰める
success:
		moveq	#0,d0
return:
		movem.l	(a7)+,d1-d2/a0-a2/a4
		rts

nospace:
		moveq	#1,d0
		bra	return
****************************************************************
change_value:
		movea.l	a4,a0
		movea.l	a2,a1
		jmp	strmove
****************************************************************
find_env_bottom:
		jsr	strazbot
		addq.l	#1,a0
		rts
****************************************************************

.end
