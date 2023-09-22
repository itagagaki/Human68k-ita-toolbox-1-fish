*****************************************************************
*								*
*	rename command						*
*								*
*	REN [old file name] [new file name] <switch>		*
*	RENAME [old file name] [new file name] <switch>		*
*								*
*	switch list						*
*		/q	rename with ask a question		*
*								*
*****************************************************************

.include doscall.h
.include ../src/fish.h

.xref tolower
.xref strcpy
.xref strmove
.xref tailptr
.xref enputs
.xref makenaxt
.xref test_drive_path_perror
.xref wildcheck
.xref work_area
.xref files
.xref wild
.xref make_dest
.xref ask_yes
.xref test_drive_perror
.xref g_fullpath
.xref bad_arg
.xref command_error
.xref msg_nodir
.xref msg_maxfiles

.text

ren_from	=	-280
ren_to		=	-280+ren_from
ren_to0		=	-30+ren_to
chkname1	=	-280+ren_to0
chkname2	=	-280+chkname1
yes_no_sw	=	-2+chkname2

.xdef	cmd_ren

cmd_ren:
		link	a6,#yes_no_sw
		clr.w	yes_no_sw(a6)
		move.w	d0,d1
sw_lp:
		tst.w	d1
		beq	ren_nn

		cmpi.b	#'-',(a0)
		bne	ren_nn

		subq.w	#1,d1
		addq.l	#1,a1
sw_lp1:
		move.b	(a0)+,d0
		beq	sw_lp

		cmp.b	#'q',d0
		bne	ren_errp
q_switch:
		move.w	#-1,yes_no_sw(a6)
		bra	sw_lp1
ren_nn:
		cmp.w	#2,d1
		bne	ren_errp

		movea.l	a0,a1
		lea	ren_from(a6),a0
		bsr	strmove
		lea	ren_to(a6),a0
		bsr	strcpy
		lea	ren_from(a6),a0
		bsr	makenaxt
		lea	ren_from(a6),a0
		bsr	test_drive_path_perror
		bne	ren_error_exit
chk_wild:
		bsr	wildcheck
		tst.b	d0
		bne	files_get

		clr.w	yes_no_sw(a6)
files_get:
		lea	ren_from(a6),a0
		movea.l	work_area,a1	*allocated work
		bsr	files
		cmp.l	#-1,d0
		beq	ren_errdx

		cmp.w	#MAXFILES,d0
		bls	max_ren_ok

		lea	msg_maxfiles(pc),a0
		bsr	enputs
max_ren_ok:
		lea	ren_to(a6),a0
		bsr	makenaxt
		bsr	tailptr
		movea.l	a0,a3
		lea	ren_to(a6),a0
		cmp.b	#':',1(a0)
		bne	path_add_1

		addq.l	#2,a0
path_add_1:
		movea.l	a0,a2
		bsr	tailptr
		cmpa.l	a0,a2
		bne	path_no_add

		movea.l	a0,a1
		lea	ren_to0(a6),a0
		bsr	strcpy
		lea	ren_from(a6),a1
		cmp.b	#':',1(a1)
		bne	path_add_2

		addq.l	#2,a1
path_add_2:
		movea.l	a2,a0
		bsr	strcpy
		bsr	tailptr
		lea	ren_to0(a6),a1
		bsr	strcpy
		bra	path_add_ok

path_no_add:
		movea.l	a3,a0
path_add_ok:
		bsr	wild
		movea.l	a0,a1		*a1 is name pointer
		lea	ren_to0(a6),a0
		bsr	strcpy
		moveq	#0,d2
		movea.l	work_area,a0
ren_lp0:
		tst.b	(a0)
		beq	ren_end

		btst	#4,FNAMELEN+EXTLEN+2(a0)
		bne	ren_next

		move.b	#'.',FNAMELEN(a0)
		move.l	a0,-(a7)
		lea	ren_from(a6),a0
		bsr	tailptr
		movea.l	(a7)+,a1
		bsr	strcpy
		lea	ren_to(a6),a0
		bsr	tailptr
		exg	a0,a1
		lea	ren_to0(a6),a2
		bsr	make_dest
		tst.w	yes_no_sw(a6)
		beq	check_equ

		pea	ren_from(a6)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	a0,-(a7)
		lea	msg_ren_ask(pc),a0
		bsr	ask_yes
		movea.l	(a7)+,a0
		beq	ren_next
check_equ:
		movem.l	a0-a2,-(a7)
		lea	ren_to(a6),a1
		lea	chkname2(a6),a0
		bsr	strcpy
		movea.l	a0,a2
		movea.l	a1,a0
		movea.l	a2,a1
		lea	ren_from(a6),a2
		cmp.b	#':',1(a1)
		beq	to_drive_check

		cmp.b	#':',1(a2)
		bne	ren_chk1

		move.b	(a2)+,(a0)+
		move.b	(a2)+,(a0)+	*drive name copy
		bsr	strcpy
		subq.l	#2,a0
		movea.l	a0,a2
		movea.l	a1,a0
		movea.l	a2,a1
		bsr	strcpy
		bra	ren_chk1

to_drive_check:
		move.b	(a1),d0
		bsr	test_drive_perror
		bne	ren_error_exit
ren_chk1:
		lea	chkname2(a6),a0
		bsr	g_fullpath
		bsr	tailptr
		clr.b	(a0)
		lea	ren_from(a6),a1
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

		cmp.b	#$80,d0
		bcs	p_cmp_ank

		cmp.b	#$a0,d0
		bcs	p_cmp_knj

		cmp.b	#$e0,d0
		bcs	p_cmp_ank
p_cmp_knj:
		cmp.b	(a0)+,(a1)+
		bne	p_cmp_end

		cmp.b	(a0)+,(a1)+
		bne	p_cmp_end

		bra	p_cmp_loop

p_cmp_ank:
		cmp.b	#' ',d0
		beq	p_cmp_skip

		bsr	tolower
		move.b	d0,d1
		move.b	(a1),d0
		bsr	tolower
		cmp.b	d0,d1
		beq	p_cmp_ank_equ

		moveq	#1,d0
		bra	p_cmp_end

p_cmp_ank_equ:
		addq.l	#1,a0
		addq.l	#1,a1
		bra	p_cmp_loop
p_cmp_skip:
		addq.l	#1,a0
p_cmp_skip_lop:
		cmp.b	#' ',(a1)
		bne	p_cmp_loop

		addq.l	#1,a1
		bra	p_cmp_skip_lop
p_cmp_end_c:
		move.b	(a1),d0
p_cmp_end:
		movem.l	(a7)+,a0-a2
		tst.b	d0
		bne	ren_errd
ren_chk2:
		movem.l	a0-a2,-(a7)
		lea	ren_to(a6),a1
		lea	chkname2(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		movea.l	a0,a2
		lea	ren_from(a6),a1
		lea	chkname1(a6),a0
		bsr	strcpy
		bsr	g_fullpath
		bsr	tailptr
		movea.l	a2,a1
n_cmp_loop:
		move.b	(a0),d0
		beq	n_cmp_end_c

		cmp.b	#$80,d0
		bcs	n_cmp_ank

		cmp.b	#$a0,d0
		bcs	n_cmp_knj

		cmp.b	#$e0,d0
		bcs	n_cmp_ank
n_cmp_knj:
		cmp.b	(a0)+,(a1)+
		bne	n_cmp_end

		cmp.b	(a0)+,(a1)+
		bne	n_cmp_end
		bra	n_cmp_loop
n_cmp_ank:
		cmp.b	#' ',d0
		beq	n_cmp_skip

		cmp.b	(a1),d0
		bne	n_cmp_end
n_cmp_ank_equ:
		addq.l	#1,a0
		addq.l	#1,a1
		bra	n_cmp_loop
n_cmp_skip:
		addq.l	#1,a0
n_cmp_skip_lop:
		cmp.b	#' ',(a1)
		bne	n_cmp_loop

		addq.l	#1,a1
		bra	n_cmp_skip_lop
n_cmp_end_c:
		move.b	(a1),d0
n_cmp_end:
		movem.l	(a7)+,a0-a2
		tst.b	d0
		beq	ren_errf
ren_ok:
		pea	ren_to(a6)
		pea	ren_from(a6)
		DOS	_RENAME
		addq.l	#8,a7
		tst.l	d0
		bne	ren_errf

		moveq	#1,d2
ren_next:
		lea	FNAMELEN+EXTLEN+11(a0),a0
		bra	ren_lp0

ren_errdx:
		lea	msg_nodir(pc),a0
		bsr	enputs
ren_error_exit:
		moveq	#1,d0
		bra	ren_exit

ren_errp:
		bsr	bad_arg
		bra	ren_exit

ren_errd:
		lea	msg_rendirerr(pc),a0
		bra	ren_command_error

ren_errf:
		lea	msg_renequ(pc),a0
ren_command_error:
		bsr	command_error
		bra	ren_exit

ren_end:
		tst.b	d2
		beq	ren_errf

		moveq	#0,d0
ren_exit:
		unlk	a6
		rts

.data

msg_rendirerr:	dc.b	'新ファイル名と旧ファイル名のドライブ名、パス名が違います',0
msg_renequ:	dc.b	'ファイルが見つからないか、ファイル名が重複しています',0
msg_ren_ask:	dc.b	'をリネームしますか？ ',0

.end
