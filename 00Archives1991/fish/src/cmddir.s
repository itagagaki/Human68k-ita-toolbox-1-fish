*****************************************************************
*								*
*	directory command					*
*								*
*	DIR [ <switch> ] [ <path name> ]			*
*								*
*	switch:							*
*		-n	name sort				*
*		-l	length sort				*
*		-t	time sort				*
*		-r	reverse	sort				*
*		-w	wide switch				*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h
.include ../src/fish.h

.xref issjis
.xref toupper
.xref utoa
.xref strcpy
.xref putc
.xref puts
.xref nputs
.xref enputs
.xref put_space
.xref put_newline
.xref test_drive_path_perror
.xref makename
.xref g_fullpath
.xref files
.xref date_out
.xref time_out
.xref too_many_args
.xref bad_arg
.xref msg_nodir
.xref msg_dirnofile
.xref msg_maxfiles
.xref work_area

.text

findpath   = -((MAXWORDLEN+1+1)>>1<<1)
file_buf   = -60+findpath
itoa_buf   = -12+file_buf
switch_n   = -2+itoa_buf
switch_l   = -2+switch_n
switch_t   = -2+switch_l
switch_r   = -2+switch_t
wide_count = -2+switch_r
wide_flag  = -2+wide_count
wide_max   = -2+wide_flag
nfiles     = -4+wide_max

.xdef cmd_dir

cmd_dir:
		link	a6,#nfiles
		move.w	d0,d1
		clr.w	wide_flag(a6)
		clr.w	switch_n(a6)
		clr.w	switch_l(a6)
		clr.w	switch_t(a6)
		clr.w	switch_r(a6)
sw_lp:
		tst.w	d1
		beq	dir_nn

		cmpi.b	#'-',(a0)
		bne	dir_nn

		subq.w	#1,d1
		addq.l	#1,a0
sw_lp1:
		move.b	(a0)+,d0
		beq	sw_lp

		cmp.b	#'n',d0		*sort name?
		beq	sw_n_set

		cmp.b	#'l',d0		*sort length?
		beq	sw_l_set

		cmp.b	#'t',d0		*sort time?
		beq	sw_t_set

		cmp.b	#'r',d0		*sort reverse?
		beq	sw_r_set

		cmp.b	#'w',d0		*wide switch?
		beq	sw_w_set

		bsr	bad_arg
		lea	msg_usage,a0
		bra	dir_perror_return

sw_w_set:
		move.b	#-1,wide_flag(a6)
		clr.b	wide_count(a6)
		bra	sw_lp1

sw_r_set:
		move.b	#-1,switch_r(a6)
		bra	sw_lp1

sw_n_set:
		tst.b	switch_n(a6)
		bne	sw_lp1

		bsr	inc_switch
		move.b	#1,switch_n(a6)
		bra	sw_lp1

sw_l_set:
		tst.b	switch_l(a6)
		bne	sw_lp1

		bsr	inc_switch
		move.b	#1,switch_l(a6)
		bra	sw_lp1

sw_t_set:
		tst.b	switch_t(a6)
		bne	sw_lp1

		bsr	inc_switch
		move.b	#1,switch_t(a6)
		bra	sw_lp1
****************
dir_nn:
		movea.l	a0,a1
		lea	findpath(a6),a0
		clr.b	(a0)
		cmp.w	#1,d1
		bhi	dir_too_many_args
		blo	dir_svn2

		tst.b	(a1)
		beq	dir_svn2

		exg	a0,a1
		bsr	test_drive_path_perror
		exg	a0,a1
		bne	dir_error_return
dir_svn1:
		bsr	strcpy
dir_svn2:
		bsr	makename
		bsr	g_fullpath
****************
		move.l	a0,-(a7)
dir_palp:
		move.b	(a0)+,d0
		beq	dir_path_e

		bsr	issjis
		bne	dir_path_nk

		move.b	(a0)+,d0
		beq	dir_path_e

		bra	dir_palp

dir_path_nk:
		cmp.b	#'/',d0
		beq	dir_path_slash

		cmp.b	#'\',d0
		bne	dir_palp
dir_path_slash:
		move.l	a0,(a7)
		bra	dir_palp

dir_path_e:
		movea.l	(a7)+,a0
		cmpi.b	#':',-2(a0)
		beq	dir_path

		subq.l	#1,a0
dir_path:
*****************************************************************
*								*
*	search and set files buffer				*
*								*
*****************************************************************
dir_a:
		lea	findpath(a6),a0
		movea.l	work_area,a1	*buffer
		bsr	files
		cmp.l	#-1,d0
		beq	dir_nodir

		cmp.l	#MAXFILES,d0
		bls	max_dir_ok

		lea	msg_maxfiles,a0
		bsr	enputs
		move.l	#MAXFILES,d0
*****************************************************************
*								*
*	print disk information					*
*								*
*****************************************************************
max_dir_ok:
		move.l	d0,nfiles(a6)
		lea	itoa_buf(a6),a0
		and.l	#$ffff,d0
		bsr	utoa
		addq.l	#5,a0
		bsr	puts
		lea	msg_files,a0
		bsr	puts
		pea	file_buf(a6)
		clr.w	d0
		move.b	findpath(a6),d0
		bsr	toupper
		sub.b	#'@',d0
		move.w	d0,-(a7)
		DOS	_DSKFRE
		addq.l	#6,a7
		lsr.l	#7,d0
		move.l	d0,-(a7)	*save free
		moveq	#0,d0
		moveq	#0,d1
		move.w	file_buf+4(a6),d0
					*sector/cluster
		move.w	file_buf+6(a6),d1
					*bytes/sector
		mulu	d1,d0
		lsr.l	#7,d0
		moveq	#0,d1
		move.w	file_buf+2(a6),d1
		mulu	d1,d0
		sub.l	(a7),d0		*used
		lsr.l	#3,d0
		lea	itoa_buf(a6),a0
		bsr	utoa
		addq.l	#1,d0
		bsr	puts
		lea	msg_use,a0
		bsr	puts
		lea	msg_used,a0
		bsr	puts
		move.l	(a7)+,d0	*get free
		lsr.l	#3,d0
		lea	itoa_buf(a6),a0
		bsr	utoa
		addq.l	#1,a0
		bsr	puts
		lea	msg_use,a0
		bsr	puts
		lea	msg_free,a0
		bsr	puts
*****************************************************************
*								*
*	sort files						*
*								*
*****************************************************************
		movea.l	work_area,a0
		move.l	nfiles(a6),d0
		bsr	sort
*****************************************************************
*								*
*	print file name						*
*								*
*****************************************************************
		tst.l	nfiles(a6)
		beq	dir_nothing

		move.w	#-1,-(a7)
		move.w	#16,-(a7)
		DOS	_CONCTRL
		addq.l	#4,a7
		move.b	#64-23,wide_max(a6)
		cmp.b	#1,d0
		bhi	width_get_end

		move.b	#96-23,wide_max(a6)
width_get_end:
dir_next:
		subq.l	#1,nfiles(a6)
		bcs	dir_success_return

		bsr	puts
		tst.w	wide_flag(a6)
		beq	dir_normal
*****************************************************************
*								*
*	wide display						*
*								*
*****************************************************************
		lea	32(a0),a0
		addi.b	#24,wide_count(a6)
		move.b	wide_max(a6),d0
		cmp.b	wide_count(a6),d0
		bcc	wide_2

		clr.b	wide_count(a6)
wide_22:
		bsr	put_newline
		bra	dir_next

wide_2:
		tst.l	nfiles(a6)
		beq	wide_22

		move.b	#$81,d0
		bsr	putc
		move.b	#$62,d0
		bsr	putc
		bra	dir_next
*****************************************************************
*								*
*	normal display						*
*								*
*****************************************************************
dir_normal:
		lea	FNAMELEN+1+EXTLEN+1(a0),a0
		bsr	put_space
		btst.b	#4,(a0)+
		beq	dir_len

		movea.l	a0,a1
		lea	msg_dir,a0
		bsr	puts
		lea	4(a1),a0
		bra	dir_year

dir_len:
		move.l	(a0)+,d0
		movea.l	a0,a1
		lea	itoa_buf(a6),a0
		bsr	utoa
		addq.l	#1,a0
		bsr	puts
		movea.l	a1,a0
		bsr	put_space
		bsr	put_space
dir_year:
		move.w	(a0)+,d1
		beq	date_skip

		move.w	d1,d0
		bsr	date_out
		bsr	put_space
		bsr	put_space
date_skip:
		move.w	(a0)+,d0
		beq	time_skip

		tst.w	d1
		beq	time_skip

		bsr	time_out
time_skip:
		bsr	put_newline
		bra	dir_next

dir_nothing:
		lea	msg_dirnofile,a0
		bsr	nputs
		bra	dir_success_return

dir_nodir:
		lea	msg_nodir,a0
dir_perror_return:
		bsr	enputs
dir_error_return:
		moveq	#1,d0
		bra	dir_return

dir_too_many_args:
		bsr	too_many_args
		bra	dir_return

dir_success_return:
		moveq	#0,d0
dir_return:
		unlk	a6
		rts
****************************************************************
inc_switch:
		tst.b	switch_n(a6)
		beq	inc_switch_1

		addq.b	#1,switch_n(a6)
inc_switch_1:
		tst.b	switch_l(a6)
		beq	inc_switch_2

		addq.b	#1,switch_l(a6)
inc_switch_2:
		tst.b	switch_t(a6)
		beq	inc_switch_3

		addq.b	#1,switch_t(a6)
inc_switch_3:
		rts
****************************************************************
* sort - stat配列をソートする
*
* CALL
*      A0     stat配列ポインタ
*      D0.W   要素数
*
* RETURN
*      なし
*
* NOTE
*      アルゴリズムは単純選択法．遅い．実行時間はpow(N,2)のオーダー．
*****************************************************************
sort:
		movem.l	d0-d3/a0-a3,-(a7)
		move.b	switch_n(a6),d1
		or.b	switch_l(a6),d1
		or.b	switch_t(a6),d1
		or.b	switch_r(a6),d1
		beq	sort_done

		move.w	d0,d1
		lsl.l	#5,d0		*  D0.L *= 32;
		lea	(a0,d0.l),a2
sort_loop2:
		cmp.w	#2,d1
		blo	sort_done

		subq.w	#1,d1
		move.w	d1,d2
		subq.w	#1,d2
		movea.l	a0,a3
		movea.l	a0,a1
sort_loop1:
		lea	32(a0),a0
		bsr	compare
		bhs	sort_loop1_continue

		movea.l	a0,a1
sort_loop1_continue:
		dbra	d2,sort_loop1

		movea.l	a3,a0
		cmpa.l	a0,a1
		beq	sort_loop2_continue

		move.l	#7,d3
exchange_loop:
		move.l	(a0),d0
		move.l	(a1),(a0)+
		move.l	d0,(a1)+
		dbra	d3,exchange_loop

		bra	sort_loop2

sort_loop2_continue:
		lea	32(a0),a0
		bra	sort_loop2

sort_done:
		movem.l	(a7)+,d0-d3/a0-a3
		rts
*****************************************************************
* compare
*
* CALL
*      A0     statbuf1
*      A1     statbuf2
*
* RETURN
*      CCR    比較結果
*****************************************************************
compare:
		movem.l	d0-d3/a2-a3,-(a7)
		move.b	#3,d1
compare_loop:
		move.b	switch_r(a6),d2
		moveq	#0,d3
		move.w	#21,d0
		cmp.b	switch_n(a6),d1
		beq	cmp_sub_3

		move.l	#24,d3
		move.w	#3,d0
		cmp.b	switch_l(a6),d1
		beq	cmp_sub_3

		not.b	d2
		move.l	#28,d3
		move.w	#3,d0
		cmp.b	switch_t(a6),d1
		beq	cmp_sub_3
cmp_sub_0:
		subq.b	#1,d1
		bne	compare_loop

		tst.b	switch_r(a6)
		bne	cmp_sub_1

		cmpa.l	a1,a0
		bra	cmp_sub_2

cmp_sub_1:
		cmpa.l	a0,a1
cmp_sub_2:
		bra	cmp_sub_end

cmp_sub_3:
		lea	(a0,d3.l),a2
		lea	(a1,d3.l),a3
cmp_sub_4:
		tst.b	d2
		bne	cmp_sub_5

		cmpm.b	(a3)+,(a2)+
		bra	cmp_sub_6

cmp_sub_5:
		cmpm.b	(a2)+,(a3)+
cmp_sub_6:
		bne	cmp_sub_end

		dbra	d0,cmp_sub_4

		bra	cmp_sub_0

cmp_sub_end:
		movem.l	(a7)+,d0-d3/a2-a3
		rts
*****************************************************************
.data

msg_files:	dc.b	' ファイル',0
msg_use:	dc.b	'K Byte 使用',0
msg_used:	dc.b	'中',0
msg_free:	dc.b	'可能',CR,LF,0
msg_dir:	dc.b	'<dir>       ',0
msg_usage:	dc.b	'使用法: dir [ -nltrw ] [ <ファイル名> ]',0

.end
