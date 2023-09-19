.include doscall.h
.include ../src/fish.h

.xref issjis
.xref toupper
.xref strcpy
.xref eputs
.xref eput_newline
.xref tailptr
.xref drvchk
.xref drvchkp
.xref perror

pathbuf = -280
wildbuf = -NAMEBUF
filebuf = -54

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
.xdef ask_yes

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
* test_drive_perror - ドライブを検査し、
*                     エラーならばメッセージを表示する
*
* CALL
*      D0.B   ドライブ名
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef test_drive_perror

test_drive_perror:
		bsr	drvchk
test_drive_perror_1:
		bpl	return

		link	a6,#-2
		move.l	a0,-(a7)
		lea	-2(a6),a0
		move.b	d0,(a0)
		clr.b	1(a0)
		bsr	perror
		movea.l	(a7)+,a0
		unlk	a6
		tst.l	d0
return:
		rts
*****************************************************************
* test_drive_path_perror - パス名がドライブ名を持っているならば、
*                          そのドライブを検査し、
*                          エラーならばメッセージを表示する
*
* CALL
*      A0     パス名
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef test_drive_path_perror

test_drive_path_perror:
		bsr	drvchkp
		bra	test_drive_perror_1
*****************************************************************
*								*
*	make file name and extension				*
*								*
*	in.	a0.l	buffer pointer				*
*	out.	(a0)	result					*
*								*
*****************************************************************
.xdef makenaxt

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
.xdef makename

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
.xdef wildcheck

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
*****************************************************************
*								*
*	convert wild card string				*
*								*
*	in.	a0.l	filename pointer			*
*	out.	(a0)	result					*
*		d0.l	0=ok,-1=error				*
*								*
*****************************************************************
.xdef wild

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
.xdef files

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
.xdef files

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
*	make direct path name					*
*								*
*	in.	a0.l	path name pointer (must be correct)	*
*	out.	(a0)	direct path name			*
*								*
*****************************************************************
.xdef g_fullpath

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
*								*
*	source file name and wild card string to file name	*
*								*
*	in.	a0.l	source file name			*
*		a1.l	buffer pointer				*
*		a2.l	wild card string			*
*	out.	(a1)	destination file name			*
*								*
*****************************************************************
.xdef make_dest

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
.data

.xdef msg_maxfiles

msg_maxfiles:			dc.b	'ファイル数がシェルの処理能力を超えているので、'
				dc.b	'超えた分を無視します',0

.end
