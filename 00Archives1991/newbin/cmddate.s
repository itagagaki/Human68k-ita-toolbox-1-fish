*****************************************************************
*								*
*	date command						*
*								*
*	DATE <set date string>					*
*								*
*	set date string						*
*		YY/MM/DD					*
*		YY-MM-DD					*
*		YYYY/MM/DD					*
*		YYYY-MM-DD					*
*								*
*		YY	80 - 99 => 1980 - 1999			*
*			00 - 79 => 2000 - 2079			*
*			0  - 9  => 2000 - 2009			*
*		MM	1  - 9  => 01   - 09			*
*			10 - 12 => 10   - 12			*
*		DD	1  - 9  => 01   - 09			*
*			10 - 31 => 10   - 31			*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

.text

cmd_date:
		movea.l	a2,a1
		clr.l	d0
		move.b	(a1)+,d0
		lea	input_buf+1(pc),a0
		move.b	d0,(a0)+
		bsr	memmove_inc
		clr.b	(a0)
		lea	input_buf+2(pc),a0
		bsr	skip_space
		tst.b	(a0)
		bne	cmd_date_set

		lea	msg_datetime1(pc),a0
		bsr	print
		lea	msg_datetime2(pc),a0
		bsr	print
		DOS	_GETDATE
		bsr	date2_out
		lea	msg_datetime3(pc),a0
		bsr	print
		lea	input_buf(pc),a0
		move.b	#255,(a0)+
		clr.b	(a0)+
		clr.b	(a0)
		bra	cmd_date_ask
****************
reask:
		bsr	print_crlf
		lea	msg_date(pc),a0
		bsr	print
		lea	msg_datetime5(pc),a0
		bsr	print
****************
cmd_date_ask:
		lea	msg_date(pc),a0
		bsr	print
		lea	msg_datetime4(pc),a0
		bsr	print
		pea	input_buf(pc)
		DOS	_GETS
		addq.l	#4,a7
		bsr	print_crlf
		lea	input_buf+1(pc),a0
		tst.b	(a0)+
		beq	cmd_date_ok
****************
cmd_date_set:
		bsr	asc_date
		tst.l	d0
		bmi	reask

		move.w	d0,-(a7)
		DOS	_SETDATE
		addq.l	#2,a7
		tst.l	d0
		bmi	reask
****************
cmd_date_ok:
		clr.w	-(a7)
		DOS	_EXIT2
****************************************************************
* skip_space - returns first non-white-space character point
*
* CALL
*      A0     string point
*
* RETURN
*      A0     points first non-white-space character point
*****************************************************************
skip_space:
		move.w	d0,-(a7)
skip_space_loop:
		move.b	(a0)+,d0
		bsr	isspace
		beq	skip_space_loop

		subq.l	#1,a0
		move.w	(a7)+,d0
		rts
****************************************************************
* isspace - is space character
*
* CALL
*      D0.B   character
*
* RETURN
*      ZF     1 on true
*****************************************************************
isspace:
		cmp.b	#' ',d0
		beq	return

		cmp.b	#HT,d0
		beq	return

		cmp.b	#CR,d0
		beq	return

		cmp.b	#LF,d0
		beq	return

		cmp.b	#VT,d0
return:
		rts
****************************************************************
print:
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	(a7)+,d0
		rts
*****************************************************************
*								*
*	display date string type 2				*
*								*
*	in.	d0.l	date binary				*
*		(0000_0000_0000_0000_YYYY_YYYM_MMMD_DDDD)	*
*								*
*		example						*
*			1987-09-28 (åé)				*
*								*
*****************************************************************
date2_out:
		move.l	a0,-(a7)
		lea	strbuf(pc),a0
		bsr	date2_asc
		bsr	print
		move.l	(a7)+,a0
		rts
****************************************************************
* strcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      D0.L   copied length (not counts NUL)
*****************************************************************
strcpy:
		movem.l	a0-a1,-(a7)
strcpy_loop:
		move.b	(a1)+,(a0)+
		bne	strcpy_loop

		move.l	a0,d0
		movem.l	(a7)+,a0-a1
		sub.l	a0,d0
		subq.l	#1,d0
		rts
****************************************************************
* stpcpy - copy a string.
*
* CALL
*      A0     destination
*      A1     source (NUL-terminated string pointer)
*
* RETURN
*      A0     points copied NUL of destination
*      D0.L   copied length (not counts NUL)
*****************************************************************
stpcpy:
		bsr	strcpy
		adda.l	d0,a0
		rts
*****************************************************************
*								*
*	output <CR><LF>						*
*								*
*****************************************************************
print_crlf:
		movem.l	d0/a0,-(a7)
		lea	msg_crlf(pc),a0
		bsr	print
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
*								*
*	convert date string to binary				*
*								*
*	in.	a0.l	date string pointer			*
*	out.	d0.l	date binary				*
*		(plus=0000_0000_0000_0000_YYYY_YYYM_MMMD_DDDD)	*
*		(minus=error)					*
*								*
*		example						*
*			1987/09/28				*
*			1987-09-28				*
*			87/09/28				*
*			87-09-28				*
*								*
*****************************************************************
asc_date:
		movem.l	a0/d1-d4,-(a7)
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_date_error

		cmp.l	#100,d0
		bcs	asc_date_1

		cmp.l	#4,d1
		bne	asc_date_error

		cmp.l	#1980,d0
		bcs	asc_date_error

		cmp.l	#2079,d0
		bhi	asc_date_error

		sub.l	#1980,d0
		move.l	d0,d2
		bra	asc_date_2
asc_date_1:
		cmp.l	#2,d1
		bhi	asc_date_error

		cmp.l	#79,d0
		bhi	asc_date_3

		add.l	#20,d0
		move.l	d0,d2
		bra	asc_date_2
asc_date_3:
		sub.l	#80,d0
		move.l	d0,d2
asc_date_2:
		cmp.b	#'-',-1(a0)
		beq	asc_date_n1

		cmp.b	#'/',-1(a0)
		bne	asc_date_error
asc_date_n1:
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_date_error

		cmp.l	#2,d1
		bhi	asc_date_error

		tst.l	d0
		beq	asc_date_error

		cmp.l	#12,d0
		bhi	asc_date_error

		move.l	d0,d3
		cmp.b	#'-',-1(a0)
		beq	asc_date_n2

		cmp.b	#'/',-1(a0)
		bne	asc_date_error
asc_date_n2:
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_date_error
		cmp.l	#2,d1
		bhi	asc_date_error
		tst.l	d0
		beq	asc_date_error
		cmp.l	#31,d0
		bhi	asc_date_error

		subq.l	#1,a0
		bsr	skip_space
		tst.b	(a0)
		bne	asc_date_error

		move.l	d0,d4
		cmp.l	#2,d3
		bne	asc_date_4

		cmp.l	#29,d4
		bhi	asc_date_error
		bcs	asc_date_5

		btst.l	#0,d2
		bne	asc_date_error

		btst.l	#1,d2
		bne	asc_date_error

		bra	asc_date_5
asc_date_4:
		cmp.l	#31,d4
		bne	asc_date_5

		cmp.l	#8,d3
		bcs	asc_date_6

		btst.l	#0,d3
		bne	asc_date_error

		bra	asc_date_5
asc_date_6:
		btst.l	#0,d3
		beq	asc_date_error
asc_date_5:
		clr.l	d0
		and.w	#$001f,d4
		move.w	d4,d0
		and.w	#$000f,d3
		lsl.w	#5,d3
		or.w	d3,d0
		and.w	#$7f,d2
		lsl.w	#8,d2
		lsl.w	#1,d2
		or.w	d2,d0
asc_date_end:
		movem.l	(a7)+,a0/d1-d4
		rts

asc_date_error:
		moveq.l	#-1,d0
		bra	asc_date_end
*****************************************************************
*								*
*	convert ascii string to signed long number		*
*								*
*	in.	(a0)	buffer pointer (limit 10 letters)	*
*	out.	d0.l	signed long number			*
*		d1.l	status (mi=error,pl=number string len)	*
*		example						*
*			'1'<EOS>  => 00000001			*
*			'-1'<EOS> => ffffffff			*
*								*
*****************************************************************
g_atoi:		movem.l	d2-d4/a0-a1,-(a7)
		bsr	atoi
		movem.l	(a7)+,d2-d4/a0-a1
		rts
*****************************************************************
*								*
*	convert ascii to signed long				*
*								*
*****************************************************************
atoi:
		clr.l	d0
		clr.b	d3
		clr.l	d4
		move.b	#10,d2
		cmp.b	#'-',(a0)
		bne	atoi_0
		addq.l	#1,a0
		move.b	#-1,d3
atoi_0:		cmp.b	#'0',(a0)
		bne	atoi_l1
atoi_1:		cmp.b	#'0',(a0)+
		beq	atoi_1
		move.b	-(a0),d1
		cmp.b	#'1',d1
		bcs	atoi_11
		cmp.b	#'9',d1
		bls	atoi_l1
atoi_11:	subq.l	#1,a0
atoi_l1:	tst.b	d2
		beq	atoi_e
		move.b	(a0)+,d1
		beq	atoi_e
		cmp.b	#'0',d1
		bcs	atoi_e1
		cmp.b	#'9',d1
		bhi	atoi_e1
		sub.b	#'0',d1
		and.l	#$f,d1		*unsigned d1.b => unsigned d1.l
		add.l	d0,d0
		bcs	atoi_err
		move.l	d0,-(a7)
		add.l	d0,d0
		bcs	atoi_err1
		add.l	d0,d0
		bcs	atoi_err1
		add.l	(a7)+,d0
		bcs	atoi_err
		add.l	d1,d0
		bcs	atoi_err
		addq.l	#1,d4
		sub.b	#1,d2
		bra	atoi_l1
atoi_err1:	addq.l	#4,a7
atoi_err:	moveq	#11,d4
		bra	atoi_exit

atoi_e1:
		not.l	d4
atoi_e:
		tst.b	d3
		beq	atoi_exit

		neg.l	d0
atoi_exit:
		move.l	d4,d1
		rts
*****************************************************************
*								*
*	skip numeral character					*
*								*
*	in.	a0.l	string pointer				*
*	out.	a0.l	next string pointer			*
*		d1.l	skip character letters			*
*								*
*****************************************************************
skipnum:	movem.l	d0,-(a7)
		clr.l	d1
skipnum_lp:	move.b	(a0)+,d0
		cmp.b	#'0',d0
		bcs	skipnum_end
		cmp.b	#'9',d0
		bhi	skipnum_end
		addq.l	#1,d1
		bra	skipnum_lp
skipnum_end:	movem.l	(a7)+,d0
		rts
*****************************************************************
*								*
*	convert date binary to string type 2			*
*								*
*	in.	d0.l	date binary				*
*		(0000_0000_0000_0000_YYYY_YYYM_MMMD_DDDD)	*
*		a0.l	string pointer				*
*								*
*		example						*
*			1987-09-28 (åé)				*
*								*
*****************************************************************
date2_asc:
		movem.l	d0-d1/a0-a1,-(a7)
		movea.l	a0,a1
		move.l	d0,d1		*year
		lea	itoa_buf(pc),a0
		lsr.l	#8,d0
		lsr.l	#1,d0
		and.l	#$007f,d0
		add.l	#1980,d0
		bsr	g_itoa
		addq.l	#6,a0
		exg	a0,a1
		bsr	stpcpy
		bsr	date_cnv_sub
		move.b	#$20,(a0)+
		move.b	#$28,(a0)+
		move.l	d1,d0
		lsr.l	#8,d0
		lsr.l	#7,d0
		and.l	#$000e,d0
		lea	date_tbl(pc),a1
		add.l	d0,a1
		move.b	(a1)+,(a0)+
		move.b	(a1)+,(a0)+
		move.b	#$29,(a0)+
		clr.b	(a0)
		movem.l	(a7)+,d0-d1/a0-a1
		rts
*****************************************************************
*								*
*	convert unsigned long to ascii string 10 letters	*
*					with zero suppress	*
*								*
*	in.	d0.l	unsigned long number			*
*		a0.l	buffer pointer (need 11 bytes)		*
*	out.	(a0)	result					*
*								*
*****************************************************************
g_itoa:		movem.l	d0-d2/a0/a1,-(a7)
		bsr	itoa
		bsr	zerosp
		movem.l	(a7)+,d0-d2/a0/a1
		rts
*****************************************************************
*								*
*	convert unsigned long to ascii string 10 letters	*
*								*
*	in.	d0.l	unsigned long number			*
*		a0.l	buffer pointer (need 11 bytes)		*
*	out.	(a0)	result					*
*								*
*****************************************************************
g_itoa0:	movem.l	d0-d2/a0/a1,-(a7)
		bsr	itoa
		movem.l	(a7)+,d0-d2/a0/a1
		rts
*****************************************************************
*								*
*	convert unsigned long to ascii				*
*								*
*****************************************************************
itoa:		movem.l	a0,-(a7)
		lea	itoa_tbl(pc),a1
itoa_lp10:
		clr.b	d2
		move.l	(a1)+,d1
		beq	itoa_e
itoa_lp20:
		addq.b	#1,d2
		sub.l	d1,d0
		bcc	itoa_lp20

		add.l	d1,d0
		add.b	#$2f,d2
		move.b	d2,(a0)+
		bra	itoa_lp10
itoa_e:
		clr.b	(a0)
		movem.l	(a7)+,a0
		rts
*****************************************************************
*								*
*	ascii number string zero suppress			*
*								*
*****************************************************************
zerosp:
		move.b	(a0)+,d0
		beq	zerosp_end

		cmp.b	#'0',d0
		bne	zerosp_end

		tst.b	(a0)
		beq	zerosp_end

		move.b	#' ',-1(a0)
		bra	zerosp
zerosp_end:
		rts
*****************************************************************
*
*	convert date string subroutine
*
*	in.	d1.l	date binary
*		a0.l	string pointer
*
*		example
*			-09-28
*
date_cnv_sub:
		move.b	#$2d,(a0)+
		movea.l	a0,a1
		lea	itoa_buf(pc),a0
		move.l	d1,d0		*month
		lsr.l	#5,d0
		and.l	#$000f,d0
		bsr	g_itoa0
		addq.l	#8,a0
		exg	a0,a1
		bsr	stpcpy
		move.b	#$2d,(a0)+
		movea.l	a0,a1
		lea	itoa_buf(pc),a0
		move.l	d1,d0		*day
		and.l	#$001f,d0
		bsr	g_itoa0
		addq.l	#8,a0
		exg	a0,a1
		bra	stpcpy
****************************************************************
* memmove_inc - move memory block for forward
*
* CALL
*      A0     destination
*      A1     source
*      D0.L   size
*
* RETURN
*      A0     A0 + size
*      A1     A1 + size
*      D0.L   0
*****************************************************************
memmove_inc:
		tst.l	d0
		beq	memmove_inc_done
memmove_inc_loop:
		move.b	(a1)+,(a0)+
		subq.l	#1,d0
		bne	memmove_inc_loop
memmove_inc_done:
		rts

.data

.even

itoa_tbl:
	dc.l	10*10*10*10*10*10*10*10*10
	dc.l	10*10*10*10*10*10*10*10
	dc.l	10*10*10*10*10*10*10
	dc.l	10*10*10*10*10*10
	dc.l	10*10*10*10*10
	dc.l	10*10*10*10
	dc.l	10*10*10
	dc.l	10*10
	dc.l	10
	dc.l	1
	dc.l	0

date_tbl:
	dc.b	'ì˙åéâŒêÖñÿã‡ìyÅH'

msg_datetime1:	dc.b	'åªç›ÇÃ'
msg_date:	dc.b	'ì˙ït',NUL
msg_datetime2:	dc.b	'ÇÕ ',NUL
msg_datetime3:	dc.b	' Ç≈Ç∑',CR,LF,NUL
msg_datetime4:	dc.b	'Çì¸óÕÇµÇƒÇ≠ÇæÇ≥Ç¢: ',NUL
msg_datetime5:	dc.b	'ÇÃéwíËÇ™à·Ç¢Ç‹Ç∑'
msg_crlf:	dc.b	CR,LF,NUL

.bss

input_buf:	ds.b	2+256
strbuf:		ds.b	30
itoa_buf:	ds.b	12

.end cmd_date
