* isfullpath.s
* Itagaki Fumihiko 26-Aug-91  Create.

.text

*****************************************************************
* isfullpath - パス名がドライブ名を含むフルパス名であるか
*              どうかを検査する
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      CCR    フルパス名ならば EQ
*****************************************************************
.xdef isfullpath

isfullpath:
		tst.b	(a0)
		beq	isnot

		cmpi.b	#':',1(a0)
		bne	return

		cmpi.b	#'/',2(a0)
		beq	return

		cmpi.b	#'\',2(a0)
return:
		rts

isnot:
		cmpi.b	#1,(a0)
		rts

.end
