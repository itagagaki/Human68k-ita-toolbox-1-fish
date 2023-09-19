* tmpfile.s
* Itagaki Fumihiko 01-Sep-90  Create.

.include doscall.h
.include error.h
.include chrcode.h
.include stat.h

.xref get_shellvar
.xref strfor1
.xref cat_pathname
.xref drvchkp
.xref stat
.xref strcpy
.xref enputs
.xref perror
.xref create_normal_file
.xref word_temp

.text

****************************************************************
* tmpname - 一時ファイル名を生成する
*
* CALL
*      A0     生成した一時ファイル名を格納する領域（MAXPATH+1バイト必要）
*
* RETURN
*      D0.L   成功したならば0
*      CCR    TST.L D0
*****************************************************************
statbuf = -STATBUFSIZE

tmpname:
		link	a6,#statbuf
		movem.l	d1-d2/a1-a4,-(a7)
		movea.l	a0,a2
		lea	word_temp,a0
		bsr	get_shellvar
		beq	notemp

		tst.b	(a0)
		beq	notemp
****************
		movea.l	a0,a4				* A4 : $temp[1]
		movea.l	a0,a1				* A1 : $temp[1]
		movea.l	a2,a0				* A0 : buffer
		lea	suffix,a2			* A2 : suffix
		bsr	cat_pathname
		movea.l	a0,a2
		bmi	invalid_temp

		bsr	drvchkp
		bmi	invalid_temp

		movea.l	a3,a0
		bra	put_pid

invalid_temp:
		lea	msg_invalid_temp,a0
		bra	tmpname_errorp
****************
notemp:
		suba.l	a4,a4
		movea.l	a2,a0
		DOS	_CURDRV
		add.b	#'A',d0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		move.b	#'/',(a0)+
		lea	suffix,a1
		bsr	strcpy
****************
put_pid:
		lea	3(a0),a1
		lea	hexa_decimal_table,a3
		move.l	a7,d0
		rol.l	#8,d0
		moveq	#0,d1
		moveq	#4,d2
put_pid_loop:
		rol.l	#4,d0
		move.b	d0,d1
		and.b	#$0f,d1
		move.b	(a3,d1.l),(a1)+
		dbra	d2,put_pid_loop
scanloop:
		lea	statbuf(a6),a1
		exg	a0,a2
		bsr	stat
		exg	a0,a2
		bmi	tmpname_fixed

		moveq	#1,d0
		lea	11(a0),a1
increment:
		addi.b	#1,-(a1)
		cmpi.b	#'9',(a1)
		bls	scanloop

		move.b	#'0',(a1)
		dbra	d0,increment
tmpname_error:
		lea	msg_cannot_create_tmpname,a0
tmpname_errorp:
		bsr	enputs
		bra	tmpname_return_1

tmpname_fixed:
		cmp.l	#ENOFILE,d0
		beq	tmpname_return_0

		move.l	a4,d1
		beq	tmpname_error

		movea.l	a4,a0
		bsr	perror
tmpname_return_1:
		moveq	#1,d0
		bra	tmpname_return

tmpname_return_0:
		moveq	#0,d0
tmpname_return:
		movea.l	a2,a0
		movem.l	(a7)+,d1-d2/a1-a4
		unlk	a6
		rts
****************************************************************
* tmpfile - 一時ファイルを生成する
*
* CALL
*      A0     生成した一時ファイル名を格納する領域（MAXPATH+1バイト必要）
*
* RETURN
*      D0.L   生成した一時ファイルのファイルハンドル
*             エラーならば負
*
*      CCR    TST.L D0
*****************************************************************
.xdef tmpfile

tmpfile:
		bsr	tmpname
		bne	tmpfile_error

		bsr	create_normal_file
		bpl	tmpfile_return

		bsr	perror
tmpfile_error_return:
		clr.b	(a0)
tmpfile_return:
		tst.l	d0
		rts

tmpfile_error:
		moveq	#-1,d0
		bra	tmpfile_error_return
****************************************************************
.data

suffix:				dc.b	'#sh00000.00#',0
hexa_decimal_table:		dc.b	'0123456789ABCDEF',0
msg_cannot_create_tmpname:	dc.b	'一時ファイル名を生成できません',0
msg_invalid_temp:		dc.b	'シェル変数 temp の設定が無効です',0

.end
