* scanch2.s
* Itagaki Fumihiko 23-Sep-90  Create.

.xref issjis

.text

****************************************************************
* scanchar2 - メモリから文字を1文字取り出す
*
* CALL
*      A0     アドレス
*
* RETRUN
*      D0.L   取り出した文字
*             上位ワードは常に0
*             さらにANKでは上位バイトは0
*             上位バイトが非0ならばシフトJISコードである
*
*      A0     次のアドレス
*
*      CCR    TST.B D0
****************************************************************
.xdef scanchar2

scanchar2:
		moveq	#0,d0
		move.b	(a0)+,d0
		bsr	issjis
		bne	done

		lsl.w	#8,d0
		move.b	(a0)+,d0
done:
		tst.b	d0
		rts

.end
