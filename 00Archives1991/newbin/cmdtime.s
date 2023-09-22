*****************************************************************
*								*
*	time command						*
*								*
*	TIME <set time string>					*
*								*
*	set time string						*
*		HH:MM:SS					*
*								*
*		HH	00 - 11 => 00 - 11 A.M.			*
*			12 - 23 => 00 - 11 P.M.			*
*			0  - 9  => 00 - 09 A.M.			*
*		MM	0  - 9  => 00 - 09			*
*			10 - 59 => 10 - 59			*
*		SS	0  - 9  => 00 - 09			*
*			10 - 59 => 10 - 59			*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

.text

cmd_time:
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
		bne	cmd_time_set

		lea	msg_datetime1(pc),a0
		bsr	print
		lea	msg_datetime2(pc),a0
		bsr	print
		DOS	_GETTIM2
		bsr	time2_out
		lea	msg_datetime3(pc),a0
		bsr	print
		lea	input_buf(pc),a0
		move.b	#255,(a0)+
		clr.b	(a0)+
		clr.b	(a0)
		bra	cmd_time_ask
****************
reask:
		bsr	print_crlf
		lea	msg_time(pc),a0
		bsr	print
		lea	msg_datetime5(pc),a0
		bsr	print
****************
cmd_time_ask:
		lea	msg_time(pc),a0
		bsr	print
		lea	msg_datetime4(pc),a0
		bsr	print
		pea	input_buf(pc)
		DOS	_GETS
		addq.l	#4,a7
		bsr	print_crlf
		lea	input_buf+1(pc),a0
		tst.b	(a0)+
		beq	cmd_time_ok
****************
cmd_time_set:
		bsr	asc_time
		tst.l	d0
		bmi	reask

		move.l	d0,-(a7)
		DOS	_SETTIM2
		addq.l	#4,a7
		tst.l	d0
		bmi	reask
****************
cmd_time_ok:
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
atoi:		clr.l	d0
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
atoi_e1:	not.l	d4
atoi_e:		tst.b	d3
		beq	atoi_exit
		neg.l	d0
atoi_exit:	move.l	d4,d1
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
*****************************************************************
*								*
*	display time string type 2				*
*								*
*	in.	d0.l	time binary				*
*		(0000_0000_000H_HHHH_00MM_MMMM_00SS_SSSS)	*
*								*
*		example						*
*			12:00:00				*
*			12:00:01				*
*			12:00:02				*
*								*
*****************************************************************
time2_out:
		move.l	a0,-(a7)
		lea	strbuf(pc),a0
		bsr	time2_asc
		bsr	print
		move.l	(a7)+,a0
		rts
*****************************************************************
*								*
*	convert time binary to string type 2			*
*								*
*	in.	d0.l	time binary				*
*		(0000_0000_000H_HHHH_00MM_MMMM_00SS_SSSS)	*
*		a0.l	string pointer				*
*								*
*		example						*
*			12:00:00				*
*			12:00:01				*
*			12:00:02				*
*								*
*****************************************************************
time2_asc:
		movem.l	d0-d1/a0-a1,-(a7)
		movea.l	a0,a1
		move.l	d0,d1		*hour
		lea	itoa_buf(pc),a0
		lsr.l	#8,d0
		lsr.l	#8,d0
		and.l	#$001f,d0
		bsr	g_itoa
		addq.l	#8,a0
		exg	a0,a1
		bsr	stpcpy
		move.b	#$3a,(a0)+
		movea.l	a0,a1
		move.l	d1,d0		*minute
		lea	itoa_buf(pc),a0
		lsr.l	#8,d0
		and.l	#$003f,d0
		bsr	g_itoa0
		addq.l	#8,a0
		exg	a0,a1
		bsr	stpcpy
		move.b	#$3a,(a0)+
		movea.l	a0,a1
		move.l	d1,d0		*second
		lea	itoa_buf(pc),a0
		and.l	#$003f,d0
		bsr	g_itoa0
		addq.l	#8,a0
		exg	a0,a1
		bsr	strcpy
		movem.l	(a7)+,d0-d1/a0-a1
		rts
*****************************************************************
*								*
*	convert time string to binary				*
*								*
*	in.	a0.l	time string pointer			*
*	out.	d0.l	time binary				*
*		(plus=0000_0000_000H_HHHH_00MM_MMMM_00SS_SSSS)	*
*		(minus=error)					*
*								*
*		example						*
*			1987/09/28				*
*			1987-09-28				*
*			87/09/28				*
*			87-09-28				*
*								*
*****************************************************************
asc_time:	movem.l	a0/d1-d4,-(a7)
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_time_error
		cmp.l	#2,d1
		bhi	asc_time_error
		cmp.l	#23,d0
		bhi	asc_time_error
		move.l	d0,d2
		cmp.b	#':',-1(a0)
		bne	asc_time_error
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_time_error
		cmp.l	#2,d1
		bhi	asc_time_error
		cmp.l	#59,d0
		bhi	asc_time_error
		move.l	d0,d3
		cmp.b	#':',-1(a0)
		bne	asc_time_error
		bsr	g_atoi
		bsr	skipnum
		tst.l	d1
		beq	asc_time_error
		cmp.l	#2,d1
		bhi	asc_time_error
		cmp.l	#59,d0
		bhi	asc_time_error
		subq.l	#1,a0
		bsr	skip_space
		tst.b	(a0)
		bne	asc_time_error
		move.l	d0,d4
		and.l	#$003f,d4
		move.l	d4,d0
		and.l	#$003f,d3
		lsl.l	#8,d3
		or.l	d3,d0
		and.l	#$1f,d2
		lsl.l	#8,d2
		lsl.l	#8,d2
		or.l	d2,d0
		and.l	#$1f3f3f,d0
		bra	asc_time_end
asc_time_error:	moveq.l	#-1,d0
asc_time_end:	movem.l	(a7)+,a0/d1-d4
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

msg_datetime1:	dc.b	'åªç›ÇÃ'
msg_time:	dc.b	'éûçè',NUL
msg_datetime2:	dc.b	'ÇÕ ',NUL
msg_datetime3:	dc.b	' Ç≈Ç∑',CR,LF,NUL
msg_datetime4:	dc.b	'Çì¸óÕÇµÇƒÇ≠ÇæÇ≥Ç¢: ',NUL
msg_datetime5:	dc.b	'ÇÃéwíËÇ™à·Ç¢Ç‹Ç∑'
msg_crlf:	dc.b	CR,LF,NUL

.bss

input_buf:	ds.b	2+256
strbuf:		ds.b	30
itoa_buf:	ds.b	12

.end cmd_time
