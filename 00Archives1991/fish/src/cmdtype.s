*****************************************************************
*								*
*	type text file command					*
*								*
*	TYPE file ...						*
*								*
*****************************************************************

.include doscall.h
.include limits.h
.include chrcode.h
.include ../src/fish.h

.xref strcpy
.xref tailptr
.xref for1str
.xref enputs
.xref test_drive_path_perror
.xref makenaxt
.xref work_area
.xref files
.xref wildcheck
.xref dos_err
.xref errs_print
.xref command_error
.xref too_few_args
.xref msg_nofile
.xref msg_nodir
.xref msg_maxfiles
.xref msg_disk_full
.xref tmpline

.text
*****************************************************************
*								*
*	type command entry					*
*								*
*****************************************************************
.xdef cmd_type

print_flag	= -2
nfiles		= -4+print_flag
filebuf		= -60+nfiles
file_name	= -280+filebuf

cmd_type:
		move.w	d0,d5				* 引数が無ければ
		beq	too_few_args			* エラー

		link	a6,#file_name
		subq.w	#1,d5				* D5 はループ・カウンタ
		movea.l	a0,a4
		clr.w	print_flag(a6)
		cmp.w	#1,d0
		beq	arg_loop

		move.w	#1,print_flag(a6)
****************
arg_loop:
		movea.l	a4,a1
		lea	file_name(a6),a0
		bsr	strcpy
		exg	a0,a4
		bsr	for1str
		exg	a0,a4
		bsr	test_drive_path_perror
		bne	type_error_return

		bsr	makenaxt
		movea.l	work_area,a1	*allocated work
		bsr	files
		cmp.l	#-1,d0
		beq	type_err_dir

		cmp.l	#MAXFILES,d0
		bls	nfiles_ok

		lea	msg_maxfiles(pc),a0
		bsr	enputs
		move.l	#MAXFILES,d0
nfiles_ok:
		move.l	d0,nfiles(a6)
		tst.w	print_flag(a6)
		bne	type_pr_ok_1

		lea	file_name(a6),a0
		bsr	wildcheck
		tst.b	d0
		beq	type_pr_ok_1

		move.w	#1,print_flag(a6)
type_pr_ok_1:
		moveq	#0,d4
		tst.l	nfiles(a6)
		bne	globbed_files_loop
		*
		*  files で１個も検索されなかった
		*
		move.w	#$3f,-(a7)			* 全てのモードのエントリを
		pea	file_name(a6)
		pea	filebuf(a6)
		DOS	_FILES				* 検索してみる
		lea	10(a7),a7
		tst.l	d0
		bpl	one_arg_done			* 見つかったならば無視する
		*
		*  デバイス名を調べてみる
		*
		move.l	#1,nfiles(a6)
		movea.l	work_area,a2
		clr.b	FNAMELEN+EXTLEN+11(a2)
		move.w	#21,d0		*22 byte
type_dev_1:
		move.b	#' ',(a2)+
		dbra	d0,type_dev_1

		clr.b	(a2)
		lea	file_name(a6),a0
		bsr	tailptr
		movea.l	a0,a3
		movea.l	work_area,a0
type_dev_2:
		move.b	(a3)+,d0
		beq	type_dev_ok

		cmp.b	#'.',d0
		beq	type_dev_3

		move.b	d0,(a0)+
		bra	type_dev_2

type_dev_3:
		movea.l	work_area,a0
		adda.l	#FNAMELEN+1,a0
type_dev_4:
		move.b	(a3)+,d0
		beq	type_dev_ok

		move.b	d0,(a0)+
		bra	type_dev_4
****************
globbed_files_loop:
		movea.l	work_area,a2
		move.b	FNAMELEN+EXTLEN+2(a2),d0
		and.b	#$1e,d0
		bne	next_globbed_files

		move.b	#'.',FNAMELEN(a2)
		bra	type_file

type_dev_ok:
		movea.l	work_area,a2
		move.b	#'.',FNAMELEN(a2)
type_file:
		lea	file_name(a6),a0
		bsr	tailptr
		movea.l	a2,a1
		bsr	strcpy
		tst.w	print_flag(a6)
		beq	type_pr_skip_1

		lea	file_name(a6),a0
		bsr	enputs
type_pr_skip_1:
		moveq	#1,d4
		clr.w	-(a7)		*read open
		pea	file_name(a6)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bmi	type_error

		move.w	d0,d1
		lea	tmpline,a0
one_file_loop:
		move.l	#MAXLINELEN,-(a7)
		move.l	a0,-(a7)
		move.w	d1,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	one_file_done
		beq	one_file_done

		subq.w	#1,d0		* MAXLINELENは16bit以内だからD0も必ず16bit以内なのだ
		movea.l	a0,a1
		moveq	#0,d3
one_file_find_eot:
		cmpi.b	#EOT,(a1)+
		dbeq	d0,one_file_find_eot

		bne	one_file_no_eot

		subq.l	#1,a1
		moveq	#1,d3
one_file_no_eot:
		move.l	a1,d2
		sub.l	a0,d2
		move.l	d2,-(a7)
		move.l	a0,-(a7)
		move.w	#1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	one_file_write_error

		cmp.l	d2,d0
		blt	one_file_write_fail

		tst.b	d3
		beq	one_file_loop
one_file_done:
		move.w	d1,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
next_globbed_files:
		adda.l	#FNAMELEN+EXTLEN+11,a2
		subq.l	#1,nfiles(a6)
		bne	globbed_files_loop
one_arg_done:
		tst.b	d4
		beq	type_error

		dbra	d5,arg_loop

		moveq	#0,d0
type_return:
		unlk	a6
		rts
*****************************************************************
type_err_dir:
		lea	msg_nodir(pc),a0
		bra	type_err

one_file_write_error:
		bsr	dos_err
		bsr	errs_print
		bra	type_error_return

one_file_write_fail:
		lea	msg_disk_full(pc),a0
		bsr	command_error
		bra	type_return

type_error:
		lea	msg_nofile(pc),a0
type_err:
		bsr	enputs
type_error_return:
		moveq	#1,d0
		bra	type_return

.end
