* b_echo.s
* This contains built-in command 'echo'.
*
* Itagaki Fumihiko 19-Jul-90  Create.
* Itagaki Fumihiko 17-Aug-91  -e を加え，無効なフラグ引数から単語並びとするようにした．

.xref puts
.xref eputs
.xref putse
.xref eputse
.xref put_newline
.xref eput_newline
.xref echo

.text

****************************************************************
*  Name
*       echo - echo arguments
*
*  Synopsis
*       echo [ -2cnre ] [ - ] [ word ... ]
****************************************************************
.xdef cmd_echo

cmd_echo:
		moveq	#0,d1				*  D1.B : -c-n
		moveq	#0,d2
decode_opt_loop1:
		movea.l	a0,a1
		subq.w	#1,d0
		bcs	decode_opt_done

		cmpi.b	#'-',(a0)+
		bne	decode_opt_done

		move.b	(a0)+,d7
		beq	decode_opt_done0
decode_opt_loop2:
		cmp.b	#'2',d7
		beq	opt_2

		cmp.b	#'r',d7
		beq	opt_r

		cmp.b	#'e',d7
		beq	opt_e

		cmp.b	#'n',d7
		beq	opt_n

		cmp.b	#'c',d7
		bne	decode_opt_done
opt_c:
		bset	#1,d1
		bra	decode_opt_nextch

opt_n:
		bset	#0,d1
		bra	decode_opt_nextch

opt_r:
		bclr	#3,d2
		bra	decode_opt_nextch

opt_e:
		bset	#3,d2
		bra	decode_opt_nextch

opt_2:
		bset	#2,d2
decode_opt_nextch:
		move.b	(a0)+,d7
		bne	decode_opt_loop2
		bra	decode_opt_loop1

decode_opt_done:
		movea.l	a1,a0
		addq.w	#1,d0
decode_opt_done0:
		move.w	d0,d3
		lea	funcs,a2
		movea.l	(a2,d2.l),a1
		bsr	echo			*  単語並びをechoする

		btst	#0,d1			*  -n が指定されているならば
		bne	echo_done		*  決して改行しない

		tst.w	d3			*  単語数は 0 か？
		bne	echo_newline_1
	*
	*  単語数は 0 である
	*  -c が指定されているならば改行しない
	*
		btst	#1,d1			*  -c ?
		bra	echo_newline_2

echo_newline_1:
	*
	*  単語数は 0 ではない
	*  -e が指定され、かつ、\c があったならば改行しない
	*
		btst	#3,d2			*  -e ?
		beq	do_echo_newline

		tst.b	d0			*  \c ?
echo_newline_2:
		bne	echo_done
do_echo_newline:
		bclr	#3,d2
		movea.l	16(a2,d2.l),a1
		jsr	(a1)
echo_done:
		moveq	#0,d0
		rts
****************************************************************
.data

funcs:
		dc.l	puts
		dc.l	eputs
		dc.l	putse
		dc.l	eputse
		dc.l	put_newline
		dc.l	eput_newline

.end
