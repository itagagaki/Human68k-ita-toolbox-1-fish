* strforn.s
* Itagaki Fumihiko 18-Aug-91  Create.

.xref strfor1

****************************************************************
* strforn - 文字列をn個スキップする
*
* CALL
*      A0     文字列並びの先頭アドレス
*
* RETURN
*      A0     n個スキップしたアドレス
*****************************************************************
.xdef strforn

strforn:
		tst.w	d0
		beq	strforn_done

		move.w	d0,-(a7)
		subq.w	#1,d0
strforn_loop:
		jsr	strfor1
		dbra	d0,strforn_loop

		move.w	(a7)+,d0
strforn_done:
		rts

.end
