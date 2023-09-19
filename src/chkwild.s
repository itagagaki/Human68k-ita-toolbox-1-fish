* chkwild.s
* Itagaki Fumihiko 02-Sep-90  Create.

.xref issjis

.text

****************************************************************
* check_wildcard - 語にワイルドカードが含まれているかどうか調べる
*
* CALL
*      A0     語 (may be contains ", ', and/or \)
*
* DESCRIPTION
*      語にワイルドカードが含まれているかどうか調べ、もしあれば
*      最初に見つかったワイルドカード文字を返し、無ければ 0 を
*      返す。
*
* RETURN
*      D0.L   下位バイトは最初に見つかったワイルドカード文字
*      CCR    TST.L D0
****************************************************************
.xdef check_wildcard

check_wildcard:
		movem.l	d1/a0,-(a7)
		moveq	#0,d1
check_wildcard_loop:
		move.b	(a0)+,d0
		beq	no_wildcard

		bsr	issjis
		beq	check_wildcard_skip1

		tst.b	d1
		beq	check_wildcard_1

		cmp.b	d1,d0
		bne	check_wildcard_loop
check_wildcard_quote:
		eor.b	d0,d1
		bra	check_wildcard_loop

check_wildcard_1:
		cmp.b	#'*',d0
		beq	check_wildcard_done

		cmp.b	#'?',d0
		beq	check_wildcard_done

		cmp.b	#'[',d0
		beq	check_wildcard_done

		cmp.b	#'"',d0
		beq	check_wildcard_quote

		cmp.b	#"'",d0
		beq	check_wildcard_quote

		cmp.b	#'\',d0
		bne	check_wildcard_loop

		move.b	(a0)+,d0
		beq	no_wildcard

		bsr	issjis
		bne	check_wildcard_loop
check_wildcard_skip1:
		move.b	(a0)+,d0
		bne	check_wildcard_loop
no_wildcard:
		moveq	#0,d0
		bra	check_wild_return

check_wildcard_done:
		moveq	#-1,d1
		move.b	d0,d1
		exg	d0,d1
check_wild_return:
		movem.l	(a7)+,d1/a0
		tst.l	d0
		rts

.end
