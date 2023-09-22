* enterhis.s
* Itagaki Fumihiko 29-Jul-90  Create.

.text

*****************************************************************
* enter_history - 単語並びを履歴リストに登録する
*
* CALL
*      A0     単語並びの先頭アドレス
*      D0.W   単語数
*
* RETURN
*      none
*****************************************************************
.xdef enter_history

enter_history:
		movem.l	d0-d5/a0-a2,-(a7)
		move.w	d0,d5			* D5.W : 単語数
		beq	enter_history_return

		movea.l	a0,a2			* A2 : 単語並びの先頭アドレス
		move.l	his_nlines_now,d0
		addq.l	#1,d0
		move.l	d0,his_nlines_now
		sub.l	his_nlines_max,d0
		ble	his_add_ok

		add.l	d0,his_toplineno
		movea.l	hiswork,a0
		addq.l	#4,a0
		bsr	forward_var
		bsr	his_del
		move.l	his_nlines_max,d0
		move.l	d0,his_nlines_now
his_add_ok:
		movea.l	a2,a0
		move.w	d5,d0
		bsr	wordlistlen
		move.l	d0,d4			* D4.L = 語並びのバイト数
		bsr	calc_var_size
		move.l	d0,d3			* D3.L = この行の占めるバイト数
		movea.l	hiswork,a0
		move.l	a0,d1
		add.l	(a0),d1			* D1 = 履歴バッファの末尾
		move.l	a0,d2
		add.l	his_end,d2		* D2 = 現在の履歴の末尾
		add.l	d2,d0
		addq.l	#2,d0			* D0 = 追加後の末尾+終端マーク2B分
		sub.l	d0,d1			* D1 = 余裕
		bcc	his_add

		neg.l	d1
		moveq	#0,d2
		addq.l	#4,a0
his_del_loop:
		addq.l	#1,d2
		moveq	#0,d0
		move.w	(a0),d0
		beq	enter_history_return		* Shuck!

		adda.l	d0,a0				* ポインタを次の行に移動
		sub.l	d0,d1
		bcc	his_del_loop

		add.l	d2,his_toplineno
		sub.l	d2,his_nlines_now
		bsr	his_del
his_add:
		move.l	his_end,d0
		move.l	d0,his_old
		move.l	d0,d1
		add.l	d3,d1
		move.l	d1,his_end
		movea.l	hiswork,a0
		adda.l	d1,a0
		move.w	d3,-2(a0)
		clr.w	(a0)
		movea.l	hiswork,a0
		adda.l	d0,a0
		move.w	d3,(a0)+
		move.w	d5,(a0)+
		movea.l	a2,a1
		move.l	d4,d0
		bsr	memmove_inc
enter_history_return:
		movem.l	(a7)+,d0-d5/a0-a2
		rts
****************************************************************
his_del:
		movea.l	a0,a1
		movea.l	hiswork,a0
		move.l	a0,d0
		add.l	his_end,d0
		sub.l	a1,d0
		addq.l	#4,a0
		bsr	memmove_inc
		clr.w	(a0)
		suba.l	hiswork,a0
		move.l	a0,his_end
		rts
****************************************************************
.xdef forward_var

forward_var:
		movem.l	d0-d1,-(a7)
		tst.l	d0
		beq	forward_var_done
forward_var_loop:
		move.w	(a0),d1
		beq	forward_var_done

		adda.w	d1,a0			* ポインタを次の行に移動　（正しい）
		subq.l	#1,d0
		bne	forward_var_loop
forward_var_done:
		movem.l	(a7)+,d0-d1
		tst.l	(a0)
		rts

.end
