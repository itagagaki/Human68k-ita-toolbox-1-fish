*****************************************************************
*								*
*	file copy command					*
*								*
*	COPY [source file(s)] <destination file(s)> <switch>	*
*								*
*	switch list						*
*		/b	append copy with binary mode		*
*		/v	write verify				*
*		/q	copy with ask a question		*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h
.include ../src/fish.h

.xref strmove
.xref issjis
.xref for1str
.xref makenaxt
.xref wildcheck
.xref test_drive_path_perror
.xref work_area
.xref files
.xref msg_maxfiles
.xref enputs
.xref strcpy
.xref test_drive_perror
.xref tailptr
.xref wild
.xref make_dest
.xref g_fullpath
.xref tolower
.xref nputs
.xref puts
.xref ask_yes
.xref errs_print
.xref msg_nodir
.xref too_few_args
.xref too_many_args
.xref bad_arg
.xref dos_err
.xref malloc_or_abort
.xref strchr

.text

copy_from	= -280
copy_to		= -280+copy_from
copy_to0	= -30+copy_to
copy_from_list	= -280+copy_to0
chkname1	= -280+copy_from_list
chkname2	= -280+chkname1
to_fhd		= -2+chkname2
from_fhd	= -2+to_fhd
copywork	= -4+from_fhd
worksize	= -4+copywork
ask_sw		= -2+worksize
from_wild	= -2+ask_sw
append_flag	= -2+from_wild
binary_sw	= -2+append_flag
verify_sw	= -2+binary_sw
verify_flag	= -2+verify_sw

*****************************************************************
*								*
*	copy command entry					*
*								*
*****************************************************************
.xdef cmd_copy

cmd_copy:
		link	a6,#verify_flag
		clr.b	ask_sw(a6)
		clr.b	verify_sw(a6)
		clr.b	binary_sw(a6)
		move.w	#-1,to_fhd(a6)
		move.w	d0,d1
	**
	**  オプションフラグを解釈する
	**
sw_lp:
		tst.w	d1
		beq	copy_n

		cmpi.b	#'-',(a0)
		bne	copy_n

		subq.w	#1,d1
		addq.l	#1,a0
sw_lp1:	
		move.b	(a0)+,d0
		beq	sw_lp

		cmp.b	#'v',d0		*verify switch?
		beq	v_switch

		cmp.b	#'b',d0		*binary switch?
		beq	b_switch

		cmp.b	#'q',d0		*question switch?
		bne	cmd_copy_bad_arg
q_switch:
		move.b	#1,ask_sw(a6)
		bra	sw_lp1

v_switch:
		move.b	#1,verify_sw(a6)
		bra	sw_lp1

b_switch:
		move.b	#1,binary_sw(a6)
		bra	sw_lp1
copy_n:
	**
	**  引数1 を copy_from にコピー
	**
		tst.w	d1
		beq	cmd_copy_too_few_args

		cmp.w	#2,d1
		bhi	cmd_copy_too_many_args

		movea.l	a0,a1
		lea	copy_from(a6),a0
		bsr	strmove
	**
	**  引数2 を copy_to にコピー
	**
		lea	copy_to(a6),a0
		clr.b	(a0)
		cmp.w	#2,d1
		blo	cmd_copy_1

		bsr	strmove
cmd_copy_1:
	**
	**  copy_from の + を NUL に変えて copy_from_list にコピー
	**
		lea	copy_from(a6),a1
		lea	copy_from_list(a6),a0
list_make_lop1:
		move.b	(a1)+,d0
list_make_lop2:
		move.b	d0,(a0)+
		beq	list_make_end

		bsr	issjis
		beq	list_make_sjis

		cmp.b	#'+',d0
		bne	list_make_lop1

		clr.b	-1(a0)
list_make_lop3:
		move.b	(a1)+,d0
		cmp.b	#'+',d0
		beq	list_make_lop3

		bra	list_make_lop2

list_make_sjis:
		move.b	(a1)+,d0
		move.b	d0,(a0)+
		bne	list_make_lop1
list_make_end:
		clr.b	(a0)
	**
	**  引数1 が + で始まっていたならばエラー
	**
		lea	copy_from_list(a6),a0
		tst.b	(a0)
		beq	cmd_copy_bad_arg
	**
	**  copy_from_list が複数ファイルならば append_flag を 非ゼロ にする
	**
		bsr	for1str
		move.b	(a0),append_flag(a6)
	**
	**  copy_from_list から copy_from に順ぐりにコピーして、コピーする
	**
		lea	copy_from_list(a6),a4
copy_apnd_loop:
		lea	copy_from(a6),a0
		exg	a1,a4
		bsr	strmove
		exg	a1,a4
	**
	**  コピー元ファイル名を決定する
	**
		lea	copy_from(a6),a0
		bsr	makenaxt
		move.b	#1,from_wild(a6)
		bsr	wildcheck
		tst.b	d0
		bne	copy_wild

		clr.b	ask_sw(a6)
		clr.b	from_wild(a6)
copy_wild:
		lea	copy_from(a6),a0
		bsr	test_drive_path_perror
		bne	copy_error_exit
files_get:
		movea.l	work_area,a1	*allocated work
		bsr	files
		cmp.l	#-1,d0
		beq	cmd_copy_nodir

		cmp.w	#MAXFILES,d0
		bls	max_ok

		lea	msg_maxfiles,a0
		bsr	enputs
max_ok:
		movea.l	work_area,a1	*allocated work
wildcard_copy_loop:
		tst.b	(a1)
		beq	files_dir_chke

		btst	#4,FNAMELEN+EXTLEN+2(a1)
		beq	copy_ok_file

		lea	FNAMELEN+EXTLEN+11(a1),a1
		bra	wildcard_copy_loop

files_dir_chke:
		move.w	#$3f,-(a7)
		pea	copy_from(a6)
		pea	chkname2(a6)	*temp_work
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bpl	source_file_not_found
copy_ok_file:
	**
	**  コピー先ファイル名を決定する
	**
		lea	copy_to(a6),a1
		lea	chkname2(a6),a0
		bsr	strcpy
		movea.l	a0,a2
		movea.l	a1,a0
		movea.l	a2,a1
		lea	copy_from(a6),a2
		tst.b	(a1)
		beq	no_to_name

		cmp.b	#':',1(a1)
		beq	to_drive_check
no_to_name:
		cmp.b	#':',1(a2)
		bne	no_drv

		DOS	_CURDRV
		add.b	#'A',d0
		move.b	d0,(a0)+
		move.b	1(a2),(a0)+	*drive name copy
		bsr	strcpy
		subq.l	#2,a0
		movea.l	a0,a2
		movea.l	a1,a0
		movea.l	a2,a1
		bsr	strcpy
		bra	no_drv

to_drive_check:
		move.b	(a1),d0
		bsr	test_drive_perror
		bne	copy_error_exit
no_drv:
		lea	copy_to(a6),a0
		bsr	makenaxt
		bsr	tailptr
		bsr	wild
		movea.l	a0,a1		*a1 is name pointer
		lea	copy_to0(a6),a0
		bsr	strcpy
		tst.b	append_flag(a6)
		bne	no_to_wild

		tst.b	from_wild(a6)
		beq	no_to_wild

		bsr	wildcheck
		tst.b	d0
		bne	no_to_wild

		move.b	#1,append_flag(a6)
no_to_wild:
	**
	**  ベリファイフラグを（もし指示されたならば）設定する
	**
		tst.b	verify_sw(a6)
		beq	copy_no_vrfy

		DOS	_VERIFYG
		move.w	d0,verify_flag(a6)
		move.w	#1,-(a7)
		DOS	_VERIFY
		addq.l	#2,a7
copy_no_vrfy:
	**
	**  コピー元がファイルかデバイスかを調べる
	**
		movea.l	work_area,a0
		tst.b	(a0)
		bne	copy_lp0

		move.w	#21,d0		*22 byte
copy_dev_1:
		move.b	#' ',(a0)+
		dbra	d0,copy_dev_1

		clr.b	(a0)
		lea	copy_from(a6),a0
		bsr	tailptr
		movea.l	a0,a2
		movea.l	work_area,a0
copy_dev_2:
		move.b	(a2)+,d0
		beq	copy_dev_ok

		cmp.b	#'.',d0
		beq	copy_dev_3

		move.b	d0,(a0)+
		bra	copy_dev_2
copy_dev_3:
		movea.l	work_area,a0
		lea	FNAMELEN+1(a0),a0
copy_dev_4:
		move.b	(a2)+,d0
		beq	copy_dev_ok

		move.b	d0,(a0)+
		bra	copy_dev_4
copy_dev_ok:
		movea.l	work_area,a0
		move.b	#'.',FNAMELEN(a0)
		clr.w	-(a7)
		move.l	a0,-(a7)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bmi	source_file_not_found

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
********************************
*  デバイスからのコピー
********************************
		move.l	a0,-(a7)
		lea	copy_from(a6),a0
		bsr	tailptr
		movea.l	a1,a2		*save
		movea.l	(a7)+,a1
		bsr	strcpy
		movea.l	a1,a0
		movea.l	a2,a1
		lea	copy_to0(a6),a2
		bsr	make_dest
		bsr	filecopy
		bne	copy_errs

		bra	copy_end
********************************
*  ファイルからのコピー
********************************
copy_lp0:
		tst.b	(a0)
		beq	copy_end

		btst	#4,FNAMELEN+EXTLEN+2(a0)
		bne	copy_next

		move.b	#'.',FNAMELEN(a0)
		move.l	a0,-(a7)
		lea	copy_from(a6),a0
		bsr	tailptr
		movea.l	a1,a2		*save
		movea.l	(a7)+,a1
		bsr	strcpy
		movea.l	a1,a0
		movea.l	a2,a1
		lea	copy_to0(a6),a2
		bsr	make_dest
	**
	**  コピー元とコピー先が同一ファイルでないかどうか調べる
	**
		movem.l	a0-a2,-(a7)
		lea	copy_to(a6),a1
		lea	chkname2(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		clr.b	(a0)
		lea	copy_from(a6),a1
		lea	chkname1(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		clr.b	(a0)
		lea	chkname1(a6),a0
		lea	chkname2(a6),a1
p_cmp_loop:
		move.b	(a0),d0
		beq	p_cmp_end_c

		bsr	issjis
		bne	p_cmp_ank

		cmp.b	(a0)+,(a1)+
		bne	p_cmp_end

		cmp.b	(a0)+,(a1)+
		bne	p_cmp_end

		bra	p_cmp_loop
****************
p_cmp_ank:
		cmp.b	#' ',d0
		beq	p_cmp_skip

		bsr	tolower
		move.b	d0,d1
		move.b	(a1),d0
		bsr	tolower
		cmp.b	d0,d1
		beq	p_cmp_ank_equ

		moveq	#-1,d0
		bra	p_cmp_end
****************
p_cmp_ank_equ:
		addq.l	#1,a0
		addq.l	#1,a1
		bra	p_cmp_loop
****************
p_cmp_skip:
		addq.l	#1,a0
p_cmp_skip_lop:
		cmpi.b	#' ',(a1)
		bne	p_cmp_loop

		addq.l	#1,a1
		bra	p_cmp_skip_lop
****************
p_cmp_end_c:
		move.b	(a1),d0
p_cmp_end:
		movem.l	(a7)+,a0-a2
		tst.b	d0
		bne	copy_one_file

		movem.l	a0-a2,-(a7)
		lea	copy_to(a6),a1
		lea	chkname2(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		bsr	ext_add
		movea.l	a0,a2
		lea	copy_from(a6),a1
		lea	chkname1(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		bsr	ext_add
		movea.l	a2,a1
n_cmp_loop:
		move.b	(a0),d0
		beq	n_cmp_end_c

		bsr	issjis
		bne	n_cmp_ank

		cmp.b	(a0)+,(a1)+
		bne	n_cmp_end

		cmp.b	(a0)+,(a1)+
		bne	n_cmp_end

		bra	n_cmp_loop
****************
n_cmp_ank:
		cmp.b	#' ',d0
		beq	n_cmp_skip

		bsr	tolower
		move.b	d0,d1
		move.b	(a1),d0
		bsr	tolower
		cmp.b	d0,d1
		beq	n_cmp_ank_equ

		moveq	#-1,d0
		bra	n_cmp_end

n_cmp_ank_equ:
		addq.l	#1,a0
		addq.l	#1,a1
		bra	n_cmp_loop
****************
n_cmp_skip:
		addq.l	#1,a0
n_cmp_skip_lop:
		cmpi.b	#' ',(a1)
		bne	n_cmp_loop

		addq.l	#1,a1
		bra	n_cmp_skip_lop
****************
n_cmp_end_c:
		move.b	(a1),d0
n_cmp_end:
		movem.l	(a7)+,a0-a2
		tst.b	d0
		bne	copy_one_file

		lea	copy_from(a6),a0
		bsr	nputs
		bra	same_path
****************
copy_one_file:
		tst.b	ask_sw(a6)
		beq	do_copy

		move.l	a0,-(a7)
		lea	copy_from(a6),a0
		bsr	puts
		lea	msg_copy_ask,a0
		bsr	ask_yes
		movea.l	(a7)+,a0
		beq	copy_next
do_copy:
		bsr	filecopy
		bne	copy_errs
copy_next:
		lea	FNAMELEN+EXTLEN+11(a0),a0
		bra	copy_lp0
****************
copy_end:
		tst.b	(a4)
		bne	copy_apnd_loop

		moveq	#0,d0
copy_exit:
		move.l	d0,-(a7)
		tst.b	append_flag(a6)
		beq	no_end_close

		move.w	to_fhd(a6),d0
		bmi	no_end_close

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
no_end_close:
		tst.b	verify_sw(a6)
		beq	copy_return

		move.w	verify_flag(a6),-(a7)
		DOS	_VERIFY
		addq.l	#2,a7
copy_return:
		move.l	(a7)+,d0
		unlk	a6
		rts
*****************************************************************
copy_errs:
		bsr	errs_print
		bra	copy_exit

cmd_copy_nodir:
		lea	msg_nodir,a0
		bra	copy_errpr

source_file_not_found:
		lea	msg_ropen_err,a0
		bra	copy_errpr

cmd_copy_too_few_args:
		bsr	too_few_args
		bra	copy_exit

cmd_copy_too_many_args:
		bsr	too_many_args
		bra	copy_exit

cmd_copy_bad_arg:
		bsr	bad_arg
		bra	copy_exit

same_path:
		lea	msg_copyequ,a0
copy_errpr:
		bsr	enputs
copy_error_exit:
		moveq	#1,d0
		bra	copy_exit
*****************************************************************
*****************************************************************
filecopy:
		movem.l	d1-d4/a0,-(a7)
		move.w	#-1,from_fhd(a6)
		tst.b	append_flag(a6)
		bne	skip_tofhd_clr

		move.w	#-1,to_fhd(a6)
skip_tofhd_clr:
	**
	**  確保可能な最大メモリを確保する
	**
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		sub.l	#$81000000,d0
		move.l	d0,d1
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		move.l	d0,copywork(a6)
		bmi	copy_err

		move.l	d1,worksize(a6)
	**
	**  コピーする原ファイルをオープンする
	**
		move.w	#0,-(a7)
		pea	copy_from(a6)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bmi	copy_err

		move.w	d0,from_fhd(a6)
	**
	**  コピー先ファイルを作成する
	**
		tst.w	to_fhd(a6)
		bpl	skip_dest_open

		tst.b	append_flag(a6)
		bne	normal_mode

		move.w	#-1,-(a7)
		pea	copy_from(a6)
		DOS	_CHMOD
		addq.l	#6,a7
		tst.l	d0
		bpl	mode_ok
normal_mode:
		move.w	#$20,d0
mode_ok:
		move.w	d0,-(a7)
		pea	copy_to(a6)
		DOS	_CREATE
		addq.l	#6,a7
		tst.l	d0
		bpl	open_dest_ok

		move.l	d0,d1
		move.w	#1,-(a7)
		pea	copy_to(a6)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bpl	open_dest_ok

		move.l	d1,d0
		bra	copy_err

open_dest_ok:
		move.w	d0,to_fhd(a6)
****************
skip_dest_open:
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
from_file:
		move.w	to_fhd(a6),-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		btst	#7,d0
		beq	to_file

		moveq	#1,d4
		btst	#5,d0
		bne	to_file

		btst	#1,d0
		beq	to_file

		moveq	#1,d3
to_file:
		move.w	from_fhd(a6),-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		btst	#7,d0
		beq	copy_loop

		btst	#2,d0
		bne	check_text_eof

		btst	#5,d0
		bne	copy_loop

		moveq	#1,d2
copy_loop:
		move.l	worksize(a6),-(a7)
		move.l	copywork(a6),-(a7)
		move.w	from_fhd(a6),-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	copy_err
		beq	check_text_eof

		move.l	d0,d1
		tst.b	d2
		beq	copy_write_1

		movea.l	copywork(a6),a0
		lea	-1(a0,d1.l),a0
		cmpi.b	#EOT,(a0)
		bne	copy_write_1

		tst.b	d3
		beq	copy_end_write

		subq.l	#1,d1
		bra	copy_end_write

copy_write_1:
		tst.b	d3
		beq	copy_write

		movea.l	copywork(a6),a0
		moveq	#0,d0
copy_write_3:
		tst.l	d1
		beq	copy_write_2

		cmpi.b	#EOT,(a0)+
		beq	copy_end_wrt_1

		addq.l	#1,d0
		subq.l	#1,d1
		bra	copy_write_3

copy_write_2:
		move.l	d0,d1
		beq	check_text_eof
copy_write:
		move.l	d1,-(a7)
		move.l	copywork(a6),-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	copy_err

		cmp.l	d1,d0
		blt	copy_full
		bra	copy_loop

copy_end_wrt_1:
		move.l	d0,d1
copy_end_write:
		tst.l	d1
		beq	check_text_eof

		move.l	d1,-(a7)
		move.l	copywork(a6),-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	copy_err

		cmp.l	d1,d0
		blt	copy_full
check_text_eof:
		tst.b	d4
		bne	copy_complete

		tst.b	append_flag(a6)
		beq	copy_complete

		tst.b	binary_sw(a6)
		bne	copy_complete
read_bttm_lop:
		move.w	#1,-(a7)
		move.l	#-1,-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	copy_complete

		movea.l	copywork(a6),a0
		move.l	#1,-(a7)
		move.l	a0,-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_READ
		lea	10(a7),a7
		cmpi.b	#EOT,(a0)
		bne	copy_complete

		move.w	#1,-(a7)
		move.l	#-1,-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		bra	read_bttm_lop

copy_complete:
	**
	**  タイムスタンプをセットする
	**
		move.w	to_fhd(a6),-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		btst	#7,d0
		bne	copy_ok_end

		move.w	from_fhd(a6),-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		btst	#7,d0
		bne	copy_ok_end

		clr.l	-(a7)
		move.w	from_fhd(a6),-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
		cmp.l	#$ffff0000,d0
		bcc	copy_err

		tst.b	append_flag(a6)
		bne	copy_ok_end

		move.l	d0,-(a7)
		move.w	to_fhd(a6),-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
		cmp.l	#$ffff0000,d0
		bcc	copy_err
copy_ok_end:
		moveq	#0,d0
		bra	copy_ending

copy_full:
		move.w	to_fhd(a6),-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		tst.l	d0
		bmi	copy_err

		pea	copy_to(a6)
		DOS	_DELETE
		addq.l	#4,a7
		tst.l	d0
		bmi	copy_err

		move.w	#-1,to_fhd(a6)
		move.l	#$505,d0
		bra	copy_ending

copy_err:
		bsr	dos_err
copy_ending:
		move.l	d0,-(a7)
		move.l	copywork(a6),d0
		bmi	copy_not_free

		move.l	d0,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
copy_not_free:
		move.w	from_fhd(a6),d0
		bmi	copy_e1

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
copy_e1:
		tst.b	append_flag(a6)
		bne	copy_e2

		move.w	to_fhd(a6),d0
		bmi	copy_e2

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		move.w	#-1,to_fhd(a6)
copy_e2:
		move.l	(a7)+,d0
		movem.l	(a7)+,d1-d4/a0
		tst.l	d0
		rts
*****************************************************************
*								*
*	long file name suppress					*
*								*
*	in.	a0.l	file name pointer			*
*		example						*
*			'abcdefghijk.lmn' -> 'abcdefgh.lmn'	*
*								*
*****************************************************************
ext_add:
		movem.l	a0-a1/d0-d1,-(a7)
		movea.l	a0,a1
		moveq	#'.',d0
		bsr	strchr
		move.l	a0,d0
		sub.l	a1,d0
		cmp.l	#8,d0
		bls	ext_add_1

		exg	a0,a1
		addq.l	#8,a0
		bsr	strcpy
ext_add_1:
.if 0
		tst.b	(a0)
		beq	ext_add_2

		tst.b	1(a0)
		bne	ext_add_2

		clr.b	(a0)
.else
		tst.b	(a0)
		bne	ext_add_2

		move.b	#'.',(a0)+
		clr.b	(a0)
.endif
ext_add_2:
		movem.l	(a7)+,a0-a1/d0-d1
		rts
*****************************************************************
.data

msg_copy_ask:	dc.b	'をコピーしますか？ ',0
msg_copyequ:	dc.b	'コピ－元とコピ－先が同一です',0
msg_ropen_err:	dc.b	'コピ－元ファイルが見つかりません',0

.end
