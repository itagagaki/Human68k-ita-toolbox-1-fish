* enterhis.s
* Itagaki Fumihiko 29-Jul-90  Create.
* Itagaki Fumihiko 19-Aug-91  イベント毎に時刻を記憶するようにした．

.include doscall.h
.include ../src/history.h

.xref memmovi
.xref wordlistlen
.xref xmalloc
.xref free
.xref parse_history_value
.xref cannot_because_no_memory

.xref history_top
.xref history_bot
.xref current_eventno
.xref loop_top_eventno
.xref in_history_ptr
.xref keep_loop
.xref loop_fail

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
		movem.l	d0-d2/a0-a2,-(a7)
		move.w	d0,d1				*  D1.W : 単語数
		beq	enter_history_return		*  単語数が 0 ならば登録しない

		bsr	delete_old_history
		movea.l	a0,a1				*  A1 : 単語並びの先頭アドレス
		bsr	wordlistlen
		move.l	d0,d2				*  D2.L : 単語並びのバイト数
		add.l	#HIST_BODY,d0			*  このイベントに必要なバイト数を
		bsr	xmalloc				*  確保する
		beq	no_space

		movea.l	d0,a0
		movea.l	history_bot(a5),a2
		move.l	a2,HIST_PREV(a0)
		bne	enter_history_1

		move.l	a0,history_top(a5)
		bra	enter_history_2

enter_history_1:
		move.l	a0,HIST_NEXT(a2)
enter_history_2:
		clr.l	HIST_NEXT(a0)
		move.l	a0,history_bot(a5)
		move.l	current_eventno(a5),d0
		move.l	d0,HIST_EVENTNO(a0)
		move.l	d0,HIST_REFNO(a0)
		move.w	d1,HIST_NWORDS(a0)
		DOS	_GETTIM2
		move.l	d0,HIST_TIME(a0)
		lea	HIST_BODY(a0),a0
		move.l	d2,d0
		bsr	memmovi
		addq.l	#1,current_eventno(a5)		*  履歴イベント番号をインクリメントする
enter_history_return:
		movem.l	(a7)+,d0-d2/a0-a2
		rts

no_space:
		sf	loop_fail(a5)
		lea	msg_cannot_enter_history,a0
		bsr	cannot_because_no_memory
		bra	enter_history_return
****************************************************************
.xdef delete_old_history

delete_old_history:
		movem.l	d0-d1/a0-a2,-(a7)
		tst.l	in_history_ptr(a5)
		bne	delete_old_history_done

		bsr	parse_history_value		*  D1.L : $history
		neg.l	d0
		bmi	delete_old_history_done		*  $history == inf.

		movea.l	history_top(a5),a2
delete_old_history_loop:
		cmpa.l	#0,a2
		beq	delete_old_history_done

		tst.b	keep_loop(a5)
		beq	try_delete_history

		move.l	HIST_EVENTNO(a2),d0		*  このイベントの番号が
		cmp.l	loop_top_eventno(a5),d0		*  ループ先頭のイベント番号と
		beq	delete_old_history_done		*  一致したら終了する
try_delete_history:
		movea.l	HIST_NEXT(a2),a1		*  A1 : 次のイベント
		move.l	current_eventno(a5),d0		*  （現在のイベント番号）
		sub.l	HIST_REFNO(a2),d0		*    －（参照カウント）
		cmp.l	d1,d0				*    ≧ （$history） ？
		blo	delete_old_history_next

		movea.l	HIST_PREV(a2),a0
		cmpa.l	#0,a0
		bne	delete_history_1

		move.l	a1,history_top(a5)
		bra	delete_history_2

delete_history_1:
		move.l	a1,HIST_NEXT(a0)
delete_history_2:
		cmpa.l	#0,a1
		bne	delete_history_3

		move.l	a0,history_bot(a5)
		bra	delete_history_4

delete_history_3:
		move.l	a0,HIST_PREV(a1)
delete_history_4:
		move.l	a2,d0
		bsr	free
delete_old_history_next:
		movea.l	a1,a2
		bra	delete_old_history_loop

delete_old_history_done:
		movem.l	(a7)+,d0-d1/a0-a2
		rts
****************************************************************
.data

msg_cannot_enter_history:	dc.b	'履歴登録できません',0
****************************************************************
.end
