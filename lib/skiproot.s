* skiproot.s
* Itagaki Fumihiko 27-Mar-93  Create.

.text

****************************************************************
* skiproot - パス名の先頭の ?:[/\\] をスキップする
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      A0     ?:[/\\] をスキップしたアドレス
*      D0.B   (A0)
*      CCR    TST.B (A0)
*****************************************************************
.xdef skip_root

skip_root:
		tst.b	(a0)
		beq	return

		cmpi.b	#':',1(a0)
		bne	drive_ok

		addq.l	#2,a0
drive_ok:
		cmpi.b	#'/',(a0)
		beq	do_skip_root

		cmpi.b	#'\',(a0)
		bne	return
do_skip_root:
		addq.l	#1,a0
return:
		move.b	(a0),d0
		rts

.end
