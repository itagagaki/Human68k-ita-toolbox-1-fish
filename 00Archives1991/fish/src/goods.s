*****************************************************************
*								*
*	developer's goods					*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h
.include ../src/fish.h

.xref isupper
.xref islower
.xref issjis
.xref strlen
.xref strcpy
.xref stpcpy
.xref utoa
.xref tailptr
.xref str_newline
.xref err_table

.xdef ask_yes,crlf_skip,date_out
.xdef dos_err
.xdef files
.xdef g_fullpath
.xdef tolower,toupper
.xdef makename,makenaxt,make_dest
.xdef str_blk_copy
.xdef time_out
.xdef wild,wildcheck

.text

pathbuf		=	-280
itoawork	=	-12
wildbuf		=	-NAMEBUF
filebuf		=	-54
strbuf		=	-30
*****************************************************************
* malloc - メモリーを確保する
*
* CALL
*      D0.L   確保するバイト数
*
* RETURN
*      D0.L   確保したメモリー・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*      CCR    TST.L D0
*****************************************************************
.xdef malloc

malloc:
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bpl	malloc_done

		moveq	#0,d0
malloc_done:
		rts
*****************************************************************
* xmallocp - メモリーを確保する
*
* CALL
*      D0.L   確保するバイト数
*      A0     確保したメモリー・ブロックの先頭アドレスを格納するポインターのアドレス
*
* RETURN
*      D0.L   確保したメモリー・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*      (A0)   D0.L
*      CCR    TST.L D0
*
* DESCRIPTION
*      (A0) != 0 ならば malloc せず、(A0) を持って帰る
*****************************************************************
.xdef xmallocp

xmallocp:
		tst.l	(a0)
		bne	xmallocp_done

		bsr	malloc
		move.l	d0,(a0)
xmallocp_done:
		move.l	(a0),d0
		rts
*****************************************************************
* free, xfree - 確保したメモリーを解放する
*
* CALL
*      D0.L   メモリー・ブロックの先頭アドレス
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* DESCRIPTION
*      xfree では、D0.L == 0 のときには何もしない
*****************************************************************
.xdef xfree
.xdef free

xfree:
		tst.l	d0
		beq	free_return
free:
		move.l	d0,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		tst.l	d0
free_return:
		rts
*****************************************************************
* xfreep - 確保したメモリーを解放する
*
* CALL
*      A0     メモリー・ブロックの先頭アドレスが格納されているポインターのアドレス
*
* RETURN
*      D0.L   エラー・コード
*      (A0)   エラーでなければクリアされる
*      CCR    TST.L D0
*
* DESCRIPTION
*      (A0) == 0 のときには何もしない
*****************************************************************
.xdef xfreep

xfreep:
		move.l	(a0),d0
		bsr	xfree
		bne	xfreep_return

		clr.l	(a0)
xfreep_return:
		rts
*****************************************************************
*								*
*	convert upper case character to lower case		*
*								*
*	in.	d0.b	source character			*
*	out.	d0.b	result character			*
*								*
*****************************************************************
tolower:
		bsr	isupper
		bne	tolower_done

		add.b	#$20,d0
tolower_done:
		rts
*****************************************************************
*								*
*	convert lower case character to upper case		*
*								*
*	in.	d0.b	source character			*
*	out.	d0.b	result character			*
*								*
*****************************************************************
toupper:
		bsr	islower
		bne	toupper_done

		sub.b	#$20,d0
toupper_done:
		rts
*****************************************************************
*								*
*	make direct path name					*
*								*
*	in.	a0.l	path name pointer (must be correct)	*
*	out.	(a0)	direct path name			*
*								*
*****************************************************************
g_fullpath:
		link	a6,#pathbuf
		movem.l	d0-d2/a0-a3,-(a7)
		lea	pathbuf(a6),a1
		move.l	a0,-(a7)
		clr.w	d1
		move.b	1(a0),d0
		cmp.b	#':',d0
		bne	fph_drv

		move.b	(a0)+,d0	*d1=drive number(1=a,2=b..)
		bsr	toupper
		move.b	d0,(a1)+
		sub.b	#'A'-1,d0
		move.b	(a0)+,(a1)+
		move.w	d0,d1
		bra	fph_n10
fph_drv:
		DOS	_CURDRV
		move.b	d0,d1		*d1=drive number
		addq.b	#1,d1
		add.b	#'A',d0
		move.b	d0,(a1)+
		move.b	#':',(a1)+
fph_n10:
		move.l	a0,a2
		moveq	#0,d2
fph_lp10:
		move.b	(a2)+,d0
		beq	fph_n20

		tst.b	d2
		beq	fph_lp10nn

		moveq	#0,d2
		bra	fph_lp10

fph_lp10nn:
		bsr	issjis
		bne	fph_lp10nk

		moveq	#1,d2
		bra	fph_lp10

fph_lp10nk:
		cmp.b	#'/',d0
		beq	fph_existp

		cmp.b	#'\',d0
		beq	fph_existp

		bra	fph_lp10
fph_existp:
		cmp.b	#'/',(a0)
		beq	fph_n30

		cmp.b	#'\',(a0)
		beq	fph_n30
fph_n20:
		move.b	#'/',(a1)+
		move.l	a1,-(a7)
		move.w	d1,-(a7)
		DOS	_CURDIR
		addq.l	#6,a7
		move.l	a1,a2
fph_lp15:
		tst.b	(a1)+
		bne	fph_lp15

		subq.l	#1,a1
		cmp.l	a1,a2
		beq	fph_n30

		move.b	#'/',(a1)+
fph_n30:
		move.b	(a0)+,(a1)+
		bne	fph_n30

		moveq	#0,d2
		move.l	(a7)+,a0
		lea	pathbuf(a6),a1
		lea	(a7),a3
		clr.l	-(a7)
fph_lp20:
		move.b	(a1)+,d0
		tst.b	d2
		beq	fph_lp20ck

		moveq	#0,d2
		bra	fph_lp20n

fph_lp20ck:
		bsr	issjis
		bne	fph_lp20nk

		moveq	#1,d2
		bra	fph_lp20n

fph_lp20nk:
		cmp.b	#'/',d0
		beq	fph_lp20i1

		cmp.b	#'\',d0
		beq	fph_lp20i1

		bra	fph_lp20n
fph_lp20i1:
		*  /

		cmp.b	#'.',(a1)
		bne	fph_lp20n1

		*  /.

		cmp.b	#'/',1(a1)
		beq	fph_lp20nn		*  /./

		cmp.b	#'\',1(a1)
		beq	fph_lp20nn		*  /./

		cmp.b	#'.',1(a1)
		bne	fph_lp20n1

		*  /..

		cmp.b	#'/',2(a1)
		beq	fph_lp20i2		*  /../

		cmp.b	#'\',2(a1)
		beq	fph_lp20i2		*  /../

		bra	fph_lp20n1
fph_lp20i2:
		*  /../
		move.l	(a7)+,d1
		beq	fph_lp20n

		move.l	d1,a0
		addq.l	#2,a1
		bra	fph_lp20
fph_lp20nn:
		addq.l	#1,a1
		bra	fph_lp20
fph_lp20n1:
		move.l	a0,-(a7)
fph_lp20n:
		move.b	d0,(a0)+
		bne	fph_lp20

		lea	(a3),a7
		movem.l	(a7)+,d0-d2/a0-a3
		unlk	a6
		rts
*****************************************************************
* xcputs -
*
* CALL
*      A0     points string
*      A1     function pointer prints normal character
*      A2     function pointer prints conroll character
*****************************************************************
xcputs:
		movem.l	d0/a0,-(a7)
xcputs_loop:
		move.b	(a0)+,d0
		beq	xcputs_done

		bsr	issjis
		beq	xcputs_sjis

		jsr	(a2)
		bra	xcputs_loop

xcputs_sjis:
		tst.b	(a0)
		beq	xcputs_done

		jsr	(a1)
		move.b	(a0)+,d0
		jsr	(a1)
		bra	xcputs_loop

xcputs_done:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef cputc
.xdef putc

cputc:
		cmp.b	#HT,d0
		beq	putc

		cmp.b	#$7f,d0
		beq	cputc_c

		cmp.b	#$20,d0
		bhs	putc
cputc_c:
		move.l	d0,-(a7)
		moveq	#'^',d0
		bsr	putc
		move.l	(a7),d0
		add.b	#$40,d0
		and.b	#$7f,d0
		bsr	putc
		move.l	(a7)+,d0
		rts

putc:
		move.l	d0,-(a7)
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef ecputc
.xdef eputc

ecputc:
		cmp.b	#$20,d0
		bhs	eputc

		cmp.b	#HT,d0
		beq	eputc

		move.l	d0,-(a7)
		moveq	#'^',d0
		bsr	eputc
		move.l	(a7),d0
		add.b	#$40,d0
		bsr	eputc
		move.l	(a7)+,d0
		rts

eputc:
		move.l	d0,-(a7)
		move.l	#1,-(a7)
		pea	7(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef puts

puts:
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef eputs

eputs:
		move.l	d0,-(a7)
		bsr	strlen
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef enputs
.xdef eput_newline

enputs:
		bsr	eputs
eput_newline:
		move.l	d0,-(a7)
		move.l	#2,-(a7)
		pea	str_newline(pc)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef cputs

cputs:
		movem.l	a1-a2,-(a7)
		lea	putc(pc),a1
		lea	cputc(pc),a2
		bsr	xcputs
		movem.l	(a7)+,a1-a2
		rts
*****************************************************************
.xdef ecputs

ecputs:
		movem.l	a1-a2,-(a7)
		lea	eputc(pc),a1
		lea	ecputc(pc),a2
		bsr	xcputs
		movem.l	(a7)+,a1-a2
		rts
*****************************************************************
.xdef nputs
.xdef put_newline

nputs:
		bsr	puts
put_newline:
		movem.l	d0/a0,-(a7)
		lea	str_newline(pc),a0
		bsr	puts
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef put_space

put_space:
		move.l	d0,-(a7)
		moveq	#$20,d0
		bsr	putc
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef put_tab

put_tab:
		move.l	d0,-(a7)
		move.w	#HT,d0
		bsr	putc
		move.l	(a7)+,d0
		rts
*****************************************************************
*								*
*	copy string block (move increment repeat)		*
*								*
*	in.	a0.l	to top of string block			*
*		a1.l	from top of string block		*
*								*
*****************************************************************
str_blk_copy:
		move.b	(a1)+,(a0)+
		beq	str_b_cpy_exit
b_str_copy:
		move.b	(a1)+,(a0)+
		bne	b_str_copy

		bra	str_blk_copy
str_b_cpy_exit:
		rts
*****************************************************************
*								*
*	skip <CR><LF>						*
*								*
*	in.	a0.l	text pointer				*
*	out.	a0.l	next pointer				*
*		d0.b	$0a=<CR><LF> skip,$00=found <EOF>	*
*								*
*****************************************************************
crlf_skip:
		move.b	(a0),d0
		beq	crlf_skip_eof

		cmp.b	#EOT,d0
		beq	crlf_skip_eof

		addq.l	#1,a0
		cmp.b	#LF,d0
		bne	crlf_skip
crlf_skip_eof:
		rts
*****************************************************************
* ask_yes
*
* CALL
*      A0     message
*
* RETURN
*      D0.L   'y' or 'Y' if it respond, otherwise 0.
*      CCR    TST.L D0
*****************************************************************
ask_yes:
		bsr	eputs
		move.w	#_GETCHAR.and.$ff,-(a7)
		DOS	_KFLUSH
		addq.l	#2,a7
		cmp.b	#'y',d0
		beq	ask_yes_done

		cmp.b	#'Y',d0
		beq	ask_yes_done

		moveq	#0,d0
ask_yes_done:
		bsr	eput_newline
		tst.l	d0
		rts
*****************************************************************
*								*
*	display date string type 1				*
*								*
*	in.	d0.l	date binary				*
*		(0000_0000_0000_0000_YYYY_YYYM_MMMD_DDDD)	*
*								*
*		example						*
*			87-09-28				*
*								*
*****************************************************************
date_out:
		link	a6,#strbuf
		move.l	a0,-(a7)
		lea	strbuf(a6),a0
		bsr	date_asc
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	(a7)+,a0
		unlk	a6
		rts
*****************************************************************
*								*
*	convert date binary to string type 1			*
*								*
*	in.	d0.l	date binary				*
*		(0000_0000_0000_0000_YYYY_YYYM_MMMD_DDDD)	*
*		a0.l	string pointer				*
*								*
*		example						*
*			87-09-28				*
*								*
*****************************************************************
date_asc:
		link	a6,#itoawork
		movem.l	d0-d1/a0-a1,-(a7)
		move.l	a0,a1
		move.l	d0,d1		*year
		lea	itoawork(a6),a0
		lsr.l	#8,d0
		lsr.l	#1,d0
		and.l	#$007f,d0
		add.l	#80,d0
		bsr	utoa
		lea	9(a0),a0
		exg	a0,a1
		bsr	stpcpy
		bsr	date_cnv_sub
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
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
.xdef date_cnv_sub

date_cnv_sub:
		move.b	#'-',(a0)+
		move.l	a0,a1
		lea	itoawork(a6),a0
		move.l	d1,d0		*month
		lsr.l	#5,d0
		and.l	#%1111,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		exg	a0,a1
		bsr	stpcpy
		move.b	#'-',(a0)+
		move.l	a0,a1
		lea	itoawork(a6),a0
		move.l	d1,d0		*day
		and.l	#%11111,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		exg	a0,a1
		bra	stpcpy
*****************************************************************
*								*
*	display time string type 1				*
*								*
*	in.	d0.l	time binary				*
*		(0000_0000_0000_0000_HHHH_HMMM_MMMS_SSSS)	*
*								*
*		example						*
*			12:00:00				*
*			12:00:02				*
*			12:00:04				*
*								*
*****************************************************************
time_out:	link	a6,#strbuf
		move.l	a0,-(a7)
		lea	strbuf(a6),a0
		link	a6,#itoawork
		movem.l	d0-d1/a0-a1,-(a7)
		move.l	a0,a1
		move.l	d0,d1		*hour
		lea	itoawork(a6),a0
		lsr.l	#8,d0
		lsr.l	#3,d0
		and.l	#%11111,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		exg	a0,a1
		bsr	stpcpy
		move.b	#':',(a0)+
		move.l	a0,a1
		move.l	d1,d0		*minute
		lea	itoawork(a6),a0
		lsr.l	#5,d0
		and.l	#%111111,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		exg	a0,a1
		bsr	stpcpy
		move.b	#':',(a0)+
		move.l	a0,a1
		move.l	d1,d0		*second
		lea	itoawork(a6),a0
		and.l	#%11111,d0
		lsl.l	#1,d0
		bsr	utoa
		lea	9(a0),a0
		bsr	zerofill
		exg	a0,a1
		bsr	strcpy
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	(a7)+,a0
		unlk	a6
		rts
*****************************************************************
.xdef zerofill

zerofill:
		move.l	a0,-(a7)
zerofill_loop:
		cmpi.b	#' ',(a0)
		bne	zerofill_done

		move.b	#'0',(a0)+
		bra	zerofill_loop

zerofill_done:
		movea.l	(a7)+,a0
		rts
*****************************************************************
*								*
*	convert wild card string				*
*								*
*	in.	a0.l	filename pointer			*
*	out.	(a0)	result					*
*		d0.l	0=ok,-1=error				*
*								*
*****************************************************************
wild:
		link	a6,#wildbuf
		movem.l	d1/a0-a1,-(a7)
		movem.l	a0,-(a7)
		lea	wildbuf(a6),a1
		move.w	#FNAMELEN,d1
wild_lp1:
		move.b	(a0)+,d0
		cmp.b	#'*',d0
		beq	wild_a

		cmp.b	#'.',d0
		beq	wild_ext

		move.b	d0,(a1)+
		dbra	d1,wild_lp1

		bra	wild_error

wild_a:
		subq.w	#1,d1
		bcs	wild_lp3
wild_lp2:
		move.b	#'?',(a1)+	*set '?'
		dbra	d1,wild_lp2
wild_lp3:
		move.b	(a0)+,d0
		beq	wild_ext

		cmp.b	#'.',d0
		bne	wild_lp3
wild_ext:
		move.b	-1(a0),(a1)+
		move.w	#EXTLEN,d1
wild_lp5:
		move.b	(a0)+,d0
		beq	wild_end

		cmp.b	#'*',d0
		beq	wild_d

		move.b	d0,(a1)+
		dbra	d1,wild_lp5

		bra	wild_error

wild_d:
		subq.w	#1,d1
		bcs	wild_lp7
wild_lp6:
		move.b	#'?',(a1)+	*set '?'
		dbra	d1,wild_lp6
wild_lp7:
		move.b	(a0)+,d0
		bne	wild_lp7
wild_end:
		clr.b	(a1)
		movem.l	(a7)+,a0
		lea	wildbuf(a6),a1
		bsr	strcpy
		moveq	#0,d0
		bra	wild_exit

wild_error:
		moveq	#-1,d0
		movem.l	(a7)+,a0
wild_exit:
		movem.l	(a7)+,d1/a0-a1
		unlk	a6
		rts
*****************************************************************
*								*
*	source file name and wild card string to file name	*
*								*
*	in.	a0.l	source file name			*
*		a1.l	buffer pointer				*
*		a2.l	wild card string			*
*	out.	(a1)	destination file name			*
*								*
*****************************************************************
make_dest:
		movem.l	d0/a0-a2,-(a7)
make_dest_lop:
		move.b	(a0)+,d0
		beq	make_dest_3

		move.b	(a2)+,d1
		cmp.b	#'?',d1
		bne	make_dest_1

		cmp.b	#' ',-1(a0)
		beq	make_dest_lop

		move.b	d0,(a1)+
		bra	make_dest_lop

make_dest_1:
		move.b	d1,(a1)+
		cmp.b	#'.',d1
		bne	make_dest_lop
make_dest_2:
		tst.b	d0
		beq	make_dest_3

		cmp.b	#'.',d0
		beq	make_dest_lop

		move.b	(a0)+,d0
		bra	make_dest_2

make_dest_3:
		clr.b	(a1)
		movem.l	(a7)+,d0/a0-a2
		rts
*****************************************************************
*								*
*	make file name and extension				*
*								*
*	in.	a0.l	buffer pointer				*
*	out.	(a0)	result					*
*								*
*****************************************************************
makenaxt:
		link	a6,#filebuf
		movem.l	d0-d4/a1-a2,-(a7)
		moveq	#1,d2
		bra	mkn_a
*****************************************************************
*								*
*	make file name						*
*								*
*	in.	a0.l	buffer pointer				*
*	out.	(a0)	result					*
*								*
*****************************************************************
makename:
		link	a6,#filebuf
		movem.l	d0-d4/a1-a2,-(a7)
		moveq	#0,d2
mkn_a:
		movea.l	a0,a1
		bsr	strlen
		move.w	d0,d1
		beq	mkn_nopath
****************
		moveq	#0,d3
mkn_lp_1:
		move.b	(a1)+,d0
		beq	mkn_lp_1e

		tst.b	d3
		beq	mkn_lp_c

		cmp.b	#1,d3
		beq	mkn_lp_k2

		cmp.b	#'.',d0
		beq	mkn_lp_1

		moveq	#0,d3
mkn_lp_c:
		bsr	issjis
		bne	mkn_lp_1

		moveq	#1,d3
		bra	mkn_lp_1

mkn_lp_k2:
		moveq	#2,d3
		bra	mkn_lp_1

mkn_lp_1e:
		subq.l	#1,a1
****************
		tst.b	d3
		bne	mkn_s

		cmp.b	#'/',-1(a1)
		beq	mkn_ss

		cmp.b	#'\',-1(a1)
		bne	mkn_s
mkn_ss:
		cmp.w	#1,d1
		beq	mkn_nopath	*  /  \  →  *.* を付加

		cmp.b	#':',-2(a1)
		beq	mkn_nopath	*  ～:/  ～:\  →  *.* を付加

		clr.b	-(a1)		*  ～/  ～\  →  ～
mkn_s:
		cmp.b	#':',-1(a1)
		beq	mkn_nopath

		tst.b	d3
		bne	mkn_slps

		cmp.b	#'.',-1(a1)
		bne	mkn_slps

		cmp.w	#1,d1
		beq	mkn_adda	*  .  →  *.*

		cmp.b	#':',-2(a1)
		beq	mkn_adda	*  ～:.  →  ～:*.*

		cmp.b	#'/',-2(a1)
		beq	mkn_adda	*  ～/.  →  ～/*.*

		cmp.b	#'\',-2(a1)
		beq	mkn_adda	*  ～\.  →  ～\*.*
mkn_slps:
		bsr	wildcheck
		tst.b	d0
		bne	mkn_file

		move.w	#$10,-(a7)
		move.l	a0,-(a7)
		pea	filebuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bmi	mkn_file

		btst	#4,filebuf+$15(a6)		*directory?
		bne	mkn_dir
mkn_file:
****************
		move.l	a0,a2
		moveq	#0,d3
		moveq	#0,d4
mkn_flp:
		move.b	(a2)+,d0
		beq	mkn_flp_e

		bsr	issjis
		bne	mkn_flp_nk

		move.b	(a2)+,d0
		beq	mkn_flp_e

		moveq	#' ',d3
		bra	mkn_flp

mkn_flp_nk:
		cmp.b	#'.',d0
		bne	mkn_flp_nnfd

		tst.b	d3
		beq	mkn_flp_fd1

		cmp.b	#':',d3
		beq	mkn_flp_fd1

		cmp.b	#'/',d3
		beq	mkn_flp_fd1

		cmp.b	#'\',d3
		beq	mkn_flp_fd1

		cmp.b	#'.',d3
		bne	mkn_flp_nnfd
mkn_flp_fd1:
		tst.b	(a2)
		beq	mkn_dir		*  .  ～:.  ～/.  ～\.  ～..  →  /*.* を付加
mkn_flp_nnfd:
		cmp.b	#'/',(a2)
		beq	mkn_flp_e0

		cmp.b	#'\',(a2)
		bne	mkn_flp_e1
mkn_flp_e0:
		tst.b	1(a2)
		beq	mkn_nopath	*  ～/  ～\  →  *.* を付加
mkn_flp_e1:
		move.b	d0,d3
		cmp.b	#'.',d0
		beq	mkn_flp_e2

		cmp.b	#'/',d0
		beq	mkn_flp_e2

		cmp.b	#'\',d0
		bne	mkn_flp
mkn_flp_e2:
		move.b	d0,d4
		bra	mkn_flp

mkn_flp_e:
****************
		cmp.b	#'.',d4		* extension exists?
		beq	makename_done

		bra	mkn_ext		*  . または .* を付加

mkn_adda:
		subq.l	#1,a1
		bra	mkn_nopath

mkn_dir:
		move.b	#'/',(a1)+
mkn_nopath:
		move.b	#'*',(a1)+
		moveq	#0,d2
mkn_ext:
		move.b	#'.',(a1)+
		tst.b	d2
		bne	mkn_x

		move.b	#'*',(a1)+
mkn_x:
		clr.b	(a1)
makename_done:
		movem.l	(a7)+,d0-d4/a1-a2
		unlk	a6
		rts
*****************************************************************
*								*
*	wild card string check					*
*								*
*	in.	a0.l	file name node pointer			*
*	out.	d0.b	status (zero=no wild,'*' or '?'=wild)	*
*								*
*****************************************************************
wildcheck:
		movem.l	a0,-(a7)
		bsr	tailptr
wildcheck_loop:
		move.b	(a0)+,d0
		beq	wildcheck_end

		cmp.b	#'*',d0
		beq	wildcheck_end

		cmp.b	#'?',d0
		bne	wildcheck_loop
wildcheck_end:
		movem.l	(a7)+,a0
		rts

.if 1

*****************************************************************
*								*
*	files buffer create					*
*								*
*	in.	a0.l	path name				*
*		a1.l	buffer					*
*	out.	d0.l	file count				*
*		(a1,a1+32,...)					*
*		  +0:filename					*
*		  +23:attribute					*
*		  +24:length					*
*		  +28:date					*
*		  +30:time					*
*								*
*****************************************************************
files:
		link	a6,#filebuf
		movem.l	d1-d2/a0-a2,-(a7)
		movea.l	a1,a2		*allocated work
		moveq	#0,d2		*files
		move.w	#$35,-(a7)	*serach type
		move.l	a0,-(a7)
		pea	filebuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bmi	fls_nothing
fls_lp10:
		lea	filebuf+30(a6),a0
		cmp.b	#'.',(a0)
		bne	fis_normal

		move.b	1(a0),d0
		beq	fis_skip

		cmp.b	#'.',d0
		beq	fis_skip
fis_normal:
		move.b	filebuf+21(a6),d0
		and.b	#%001110,d0
		bne	fis_skip

		addq.w	#1,d2
		cmp.w	#MAXFILES,d2
		bhi	fls_ending

		move.w	#FNAMELEN+EXTLEN,d1
		movea.l	a2,a1
fls_lp11:
		move.b	#' ',(a1)+
		dbra	d1,fls_lp11

		clr.b	(a1)
		move.w	#FNAMELEN-1,d1
		move.l	a2,a1
fls_lp12:
		move.b	(a0)+,d0
		beq	fls_lp13e

		cmp.b	#'.',d0
		beq	fls_lp12n

		move.b	d0,(a1)+
		dbra	d1,fls_lp12
fls_lp12el:
		move.b	(a0)+,d0
		beq	fls_lp13e

		cmp.b	#'.',d0
		bne	fls_lp12el
fls_lp12n:
		move.w	#EXTLEN-1,d1
		lea	FNAMELEN+1(a2),a1
fls_lp13:
		move.b	(a0)+,d0
		beq	fls_lp13e

		move.b	d0,(a1)+
		dbra	d1,fls_lp13
fls_lp13e:
		lea	FNAMELEN+EXTLEN+2(a2),a2
		move.b	filebuf+21(a6),(a2)+
		move.l	filebuf+26(a6),(a2)+
		move.w	filebuf+24(a6),(a2)+
		move.w	filebuf+22(a6),(a2)+
fis_skip:
		pea	filebuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		bpl	fls_lp10
fls_nothing:
		cmp.l	#-2,d0
		beq	fls_ending

		cmp.l	#-18,d0
		beq	fls_ending

		moveq	#-1,d2
fls_ending:
		clr.b	(a2)
		move.l	d2,d0
		movem.l	(a7)+,d1-d2/a0-a2
		unlk	a6
		rts

.else

*****************************************************************
*								*
*	files buffer create					*
*								*
*	in.	a0.l	search pattern				*
*		a1.l	buffer					*
*	out.	d0.l	file count				*
*		(a1,a1+24,...)					*
*		  +0:filename					*
*                +23:mode					*
*								*
*****************************************************************
files:
		link	a6,#filebuf
		movem.l	d1-d2/a0-a2,-(a7)
		movea.l	a1,a2		*allocated work
		moveq	#0,d2		*files
		move.w	#$35,-(a7)	*search type
		move.l	a0,-(a7)
		pea	filebuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bmi	fls_nothing
fls_lp10:
		lea	filebuf+30(a6),a0
		cmp.b	#'.',(a0)
		bne	fis_normal

		move.b	1(a0),d0
		beq	fis_skip

		cmp.b	#'.',d0
		beq	fis_skip
fis_normal:
		move.b	filebuf+21(a6),d0
		and.b	#$e,d0
		bne	fis_skip

		addq.w	#1,d2
		cmp.w	#MAXFILES,d2
		bhi	fls_ending

		move.w	#FNAMELEN+EXTLEN,d1
		movea.l	a2,a1
fls_lp11:
		move.b	#' ',(a1)+
		dbra	d1,fls_lp11

		clr.b	(a1)
		move.w	#FNAMELEN-1,d1
		move.l	a2,a1
fls_lp12:
		move.b	(a0)+,d0
		beq	fls_lp13e

		cmp.b	#'.',d0
		beq	fls_lp12n

		move.b	d0,(a1)+
		dbra	d1,fls_lp12
fls_lp12el:
		move.b	(a0)+,d0
		beq	fls_lp13e

		cmp.b	#'.',d0
		bne	fls_lp12el
fls_lp12n:
		move.w	#EXTLEN-1,d1
		lea	FNAMELEN+1(a2),a1
fls_lp13:
		move.b	(a0)+,d0
		beq	fls_lp13e

		move.b	d0,(a1)+
		dbra	d1,fls_lp13
fls_lp13e:
		lea	FNAMELEN+1+EXTLEN+1(a2),a2
		move.b	filebuf+21(a6),(a2)+
fis_skip:
		pea	filebuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		bpl	fls_lp10
fls_nothing:
		cmp.l	#-2,d0
		beq	fls_ending

		cmp.l	#-18,d0
		beq	fls_ending

		moveq	#-1,d2
fls_ending:
		clr.b	(a2)
		move.l	d2,d0
		movem.l	(a7)+,d1-d2/a0-a2
		unlk	a6
		rts

.endif

*****************************************************************
*								*
*	dos function error return				*
*								*
*	in.	d0.l	dos function error code			*
*	out.	d0.l	command interpreter errorlevel		*
*								*
*****************************************************************
dos_err:
		movem.l	d1/a0,-(a7)
		move.l	d0,d1
		and.l	#$ff000000,d1
		cmp.l	#$81000000,d1
		beq	dos_err_3

		cmp.l	#$82000000,d1
		beq	dos_err_2

		neg.l	d0
		cmp.l	#$20,d0
		bcc	dos_err_1

		lea	err_table,a0
		move.b	(a0,d0.l),d0
		add.l	#$500,d0
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
*
*	normal error
*
dos_err_1:
		move.l	#$50f,d0
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
*
*	memory allocation error
*
dos_err_2:
		move.l	#$507,d0
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
*
*	out of memory error
*
dos_err_3:
		move.l	#$508,d0
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
.data

.xdef itoa_tbl

.even

itoa_tbl:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	1
	dc.l	0

.end
