* strpcmp.s
* Itagaki Fumihiko 02-Sep-90  Create.

.xref issjis
.xref toupper
.xref scanchar2
.xref enputs

.text

****************************************************************
scanchar2c:
		bsr	scanchar2
		beq	scanchar2c_return

		tst.b	d2
		beq	scanchar2c_return

		cmp.w	#$100,d0
		bsr	toupper
scanchar2c_return:
		tst.b	d0
		rts
****************************************************************
* strpcmp - compare string and pattern
*
* CALL
*      A0     points string (contsins no escape or quoting character)
*      A1     points pattern string (may be contains \)
*      D0.B   0: case dependent  otherwise: case independent
*
* RETURN
*      D0.L   0 if matches, 1 if not match, -1 if error
*      CCR    TST.L D0
*****************************************************************
*
* (A1) のメタシーケンス :
*	?		任意の1文字にマッチする
*	*		0文字以上の任意の綴りにマッチする
*	[list]		list中の任意の1文字にマッチする
*	[^list]		listに含まれない任意の1文字にマッチする
*
* list のメタシーケンス :
*	-		直前の文字より大きく直後の文字より小さいすべての文字集合
*
*  すべての場合において 1個のシフトJISコード文字は 1個の文字として扱われる
*  どのシフトJISコード文字も、どの ANK文字より大きい
*
*  文字 \ は続く文字をエスケープする
*  エスケープされていない [ または [^ の直後では - と ] は特別な意味を持たない
*  特別な意味を持つ - に続く - と ] は特別な意味を持たない
*
*  Ｃシェルとまったく同じではないので要注意
*
*  * の数だけ再帰するから気をつけること
*
*****************************************************************
.xdef strpcmp

strpcmp:
		movem.l	d1-d6/a0-a1,-(a7)
		move.b	d0,d2			* D2.B : case independent フラグ
ismatch_loop:
		move.b	(a1)+,d0
		beq	ismatch_tail

		cmp.b	#'*',d0
		beq	ismatch_asterisk

		cmp.b	#'?',d0
		beq	ismatch_question

		cmp.b	#'[',d0
		beq	ismatch_list

		cmp.b	#'\',d0
		bne	ismatch_char

		move.b	(a1)+,d0
		beq	ismatch_tail
****************
ismatch_char:
		move.b	(a0)+,d1
		bsr	issjis
		beq	ismatch_sjis

		tst.b	d2
		beq	ismatch_char_comp

		exg	d0,d1
		bsr	toupper
		exg	d0,d1
		bsr	toupper
ismatch_char_comp:
		cmp.b	d1,d0
		bne	ismatch_false

		bra	ismatch_loop
****************
ismatch_sjis:
		cmp.b	d1,d0
		bne	ismatch_false

		move.b	(a1)+,d0
		beq	ismatch_tail

		cmp.b	(a0)+,d0
		bne	ismatch_false

		bra	ismatch_loop
****************
ismatch_list:
		bsr	scanchar2c
		beq	ismatch_false

		move.w	d0,d1

		moveq	#0,d3			* D3.B : 「マッチした」フラグ
		moveq	#0,d4			* D4.B : ^ フラグ
		moveq	#0,d5			* D5.B : 0:最初  -1:-の次  1:文字の次
		cmpi.b	#'^',(a1)
		bne	ismatch_list_loop

		moveq	#1,d4
		addq.l	#1,a1
ismatch_list_loop:
		moveq	#0,d0
		move.b	(a1)+,d0
		beq	ismatch_list_missing_blaket

		tst.b	d5
		beq	ismatch_list_no_special
		bmi	ismatch_list_no_special

		cmp.b	#'-',d0
		bne	ismatch_list_not_minus

		moveq	#-1,d5
		bra	ismatch_list_loop

ismatch_list_not_minus:
		cmp.b	#']',d0
		beq	ismatch_list_done_scan
ismatch_list_no_special:
		cmp.b	#'\',d0
		bne	ismatch_list_char

		move.b	(a1)+,d0
		beq	ismatch_list_missing_blaket
ismatch_list_char:
		subq.l	#1,a1
		exg	a0,a1
		bsr	scanchar2c
		exg	a0,a1
		beq	ismatch_list_missing_blaket

		cmp.w	d0,d1				* 今取った文字と比較
		beq	ismatch_list_matched

		tst.b	d5				* ‘-’の次ならば…
		bpl	ismatch_list_not_matched_yet

		cmp.w	d6,d1				* lower と比較
		blo	ismatch_list_not_matched_yet

		cmp.w	d0,d1				* upper（今取った文字）と比較
		bhi	ismatch_list_not_matched_yet
ismatch_list_matched:
		moveq	#1,d3
ismatch_list_not_matched_yet:
		move.w	d0,d6
		moveq	#1,d5
		bra	ismatch_list_loop

ismatch_list_done_scan:
		eor.b	d4,d3
		bra	ismatch_question_1
****************
ismatch_question:
		bsr	scanchar2
ismatch_question_1:
		beq	ismatch_false

		bra	ismatch_loop
****************
ismatch_asterisk:
		move.b	(a1)+,d0
		cmp.b	#'*',d0
		beq	ismatch_asterisk

		cmp.b	#'?',d0
		bne	ismatch_asterisk_2

		bsr	scanchar2
		beq	ismatch_false

		bra	ismatch_asterisk

ismatch_asterisk_2:
		subq.l	#1,a1
ismatch_aster_loop2:
		move.b	d2,d0
		bsr	strpcmp
		bmi	ismatch_return
		beq	ismatch_return

		bsr	scanchar2
		beq	ismatch_false
		bra	ismatch_aster_loop2
****************
ismatch_tail:
		tst.b	(a0)
		bne	ismatch_false

		moveq	#0,d0
		bra	ismatch_return
ismatch_false:
		moveq	#1,d0
ismatch_return:
		movem.l	(a7)+,d1-d6/a0-a1
		rts

ismatch_list_missing_blaket:
		lea	msg_missing_blaket,a0
		bsr	enputs
		moveq	#-1,d0
		bra	ismatch_return
****************************************************************
.data

msg_missing_blaket:	dc.b	'] がありません',0

.end
