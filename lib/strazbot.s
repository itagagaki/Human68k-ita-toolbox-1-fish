* strazbot.s
* Itagaki Fumihiko 16-Jul-90  Create.

.xref strfor1

.text

****************************************************************
* strazbot - NUL文字列で終端された文字列並びの末尾アドレスを得る
*
* CALL
*      A0     文字列並びの先頭アドレス
*
* RETURN
*      A0     終端の NUL文字列のアドレス
****************************************************************
.xdef strazbot

strazbot:
strazbot_loop:
		tst.b	(a0)
		beq	strazbot_done

		jsr	strfor1
		bra	strazbot_loop

strazbot_done:
		rts

.end
