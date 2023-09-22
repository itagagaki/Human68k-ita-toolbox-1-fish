* setenv.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strlen
.xref stpcpy
.xref strmove
.xref memmove_dec
.xref for1str
.xref str_blk_copy
.xref getenv
.xref command_error

.xref envwork

.text

*****************************************************************
* setenv - set environment
*
* CALL
*      A0       name
*      A1       value
*
* RETURN
*      D0.L	成功なら 0  容量が足りなければ 1
*      CCR      TST.L D0
*****************************************************************
.xdef setenv

setenv:
		movem.l	d1/a0-a4,-(a7)
		movea.l	envwork,a3
		movea.l	a1,a2
		movea.l	a0,a1
		movea.l	a3,a0
		bsr	getenv			* name を探す
		bne	change_value		* 見つかれば change_value

		movea.l	a1,a0			* nameの
		bsr	strlen			*   長さ
		move.l	d0,d1			*   ＋
		movea.l	a2,a0			*   valueの
		bsr	strlen			*   長さ
		add.l	d0,d1			*   ＋
		addq.l	#2,d1			*   ２（'='とNULの分）をD1にセット

		lea	4(a3),a0		* 環境の
		bsr	find_env_bottom		*   末尾＋１をA0に
		move.l	a3,d0			* 環境の
		add.l	(a3),d0			*   底＋１をD0に
		sub.l	a0,d0			* 空き容量は
		bcs	setenv_full		* ない

		cmp.l	d1,d0			* D1バイトは
		blo	setenv_full		* ない

		subq.l	#1,a0			* A0は環境の末尾
		bsr	stpcpy			* 名前をコピー
		move.b	#'=',(a0)+		* = でつなげて
		movea.l	a2,a1			* 値を
		bsr	strmove			* コピー
		clr.b	(a0)			* 環境の終わりのマークをセット
		bra	setenv_success		* 終わり

change_value:
		move.l	a0,d2			* d2 := 既存の環境の名前のポインタ
		movea.l	d0,a4			* A4 := 現在の値を指すポインタ
		movea.l	a2,a0			* 新たな値の
		bsr	strlen			* 長さ
		move.l	d0,d1			* から
		movea.l	a4,a0			* 現在の値の
		bsr	strlen			* 長さを
		sub.l	d0,d1			* 引く
		beq	setenv_just_change_value	* 長さが同じならば書き換えるのみ
		blo	setenv_change_and_trunc		* 余裕があれば書き換えた後に切り詰める

		* D1バイト足りない
		movea.l	d2,a0			* 環境の現在の
		bsr	find_env_bottom		*   末尾＋１をA0にセット
		move.l	a3,d0			* 環境の
		add.l	(a3),d0			*   底＋１
		sub.l	a0,d0			* 空き容量は
		bcs	setenv_full		* ない

		cmp.l	d1,d0			* D1バイトは
		blo	setenv_full		* ない

		movea.l	a0,a1			* 環境の現在の末尾＋１をA1（ソース）に
		movea.l	d2,a0			* 現在の環境の要素の
		bsr	for1str			*   次の要素のアドレスをA0に
		move.l	a1,d0			* 環境の現在の末尾＋１から
		sub.l	a0,d0			* A0を引けば、転送するサイズ
		movea.l	a1,a0			* ソース
		adda.l	d1,a0			*   ＋D1がデスティネーション
		bsr	memmove_dec		* 後方ブロック転送
setenv_just_change_value:
		bsr	setenv_change_value	* 値を書き換える
		bra	setenv_success		* 終わり

setenv_change_and_trunc:
		movea.l	d2,a0			* 現在の環境の要素の
		bsr	for1str			*   次の要素のアドレスを
		move.l	a0,-(a7)		*   セーブ
		bsr	setenv_change_value	* 値を書き換える
		move.l	(a7)+,a1		* 次の要素のアドレス
		bsr	str_blk_copy		* 切り詰める
setenv_success:
		moveq	#0,d0
setenv_return:
		movem.l	(a7)+,d1/a0-a4
		rts

setenv_full:
		lea	msg_full(pc),a0
		bsr	command_error
		bra	setenv_return
****************************************************************
setenv_change_value:
		movea.l	a4,a0
		movea.l	a2,a1
		bra	strmove
****************************************************************
find_env_bottom:
find_env_bottom_loop:
		tst.b	(a0)+
		beq	find_env_bottom_done

		bsr	for1str
		bra	find_env_bottom_loop

find_env_bottom_done:
		rts
****************************************************************
.data

msg_full:	dc.b	'環境の容量が足りません',0

.end
