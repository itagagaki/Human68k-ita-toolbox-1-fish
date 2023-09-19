* f_setenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.xref setenv
.xref no_space_for

.xref envwork

.text

*****************************************************************
* setenv - FISH の環境変数をセットする
*
* CALL
*      A0       変数名の先頭アドレス
*      A1       値の文字列の先頭アドレス
*
* RETURN
*      D0.L	成功なら 0 を返す．容量が足りなければ エラー・
*               メッセージを表示して 1 を返す．
*      CCR      TST.L D0
*****************************************************************
.xdef fish_setenv

fish_setenv:
		movem.l	a0/a3,-(a7)
		movea.l	envwork(a5),a3
		bsr	setenv
		beq	fish_setenv_return

		lea	msg_environment,a0
		bsr	no_space_for
fish_setenv_return:
		movem.l	(a7)+,a0/a3
		rts
****************************************************************
.data

msg_environment:	dc.b	'環境',0

.end
