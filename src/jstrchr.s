* jstrchr.s
* Itagaki Fumihiko 23-Sep-90  Create.

.xref scanchar2

.text

****************************************************************
* jstrchr - シフトJISコードを含む文字列から文字を探し出す
*
* CALL
*      A0     文字列の先頭アドレス
*
*      D0.W   検索文字
*             シフトJISコードまたは ANKコード（上位バイトは 0）
*
* RETURN
*      A0     最初に検索文字が現れる位置を指す
*             検索文字が見つからなかった場合には，最後のNUL文字を指す
*
*      CCR    TST.B (A0)
*****************************************************************
.xdef jstrchr

jstrchr:
		movem.l	d0-d1/a1,-(a7)
		move.w	d0,d1
jstrchr_loop:
		movea.l	a0,a1
		bsr	scanchar2
		beq	jstrchr_eos

		cmp.w	d1,d0
		bne	jstrchr_loop

		bra	jstrchr_found

jstrchr_eos:
		lea	-1(a0),a1
jstrchr_found:
		movea.l	a1,a0
		movem.l	(a7)+,d0-d1/a1
		tst.b	(a0)
		rts

.end
