* skippar.s
* Itagaki Fumihiko 10-Nov-90  Create.

.xref strfor1

.text

****************************************************************
* skip_paren - 現在位置の ( に対応する ) の位置を返す
*
* CALL
*      A0     単語並びの先頭アドレス
*      D0.W   単語数
*
* RETURN
*      A0     対応する ) のアドレス
*      D0.W   対応する ) 以降の単語数
*      CCR    TST.W D0
*****************************************************************
.xdef skip_paren

skip_paren:
		tst.w	d0
		beq	skip_paren_return

		bra	next
loop:
		cmpi.b	#')',(a0)
		bne	not_close_paren

		tst.b	1(a0)
		beq	skip_paren_return

not_close_paren:
		cmpi.b	#'(',(a0)
		bne	next

		tst.b	1(a0)
		bne	next

		bsr	skip_paren
		beq	skip_paren_return
next:
		bsr	strfor1
		subq.w	#1,d0
		bne	loop
skip_paren_return:
		tst.w	d0
		rts

.end
