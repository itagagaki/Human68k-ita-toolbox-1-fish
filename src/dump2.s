*************************************************
*						*
*   malloc Ext version Ver 0.01			*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : dump.s				*
*   author    : T.Kawamoto			*
*   date      : 91/9/23				*
*   functions : dumpout_memory_reg_saved	*
*             : dumpout_memory			*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*             : 91/9/23	large size support	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
dumpout_memory:
		movem.l	d0-d4/d6/a0-a2/a4/a6,-(sp)
		move.l	lake_top(a5),d6
		bra	lake_entry
*
lake_loop:
		move.l	next_lake_ptr(a4),d6
lake_entry:
		beq	lake_end

		move.l	d6,a4
		move.l	lake_size(a4),d3		*  D3 : ‚±‚Ì lake ‚ÌƒTƒCƒY
		move.l	d3,d4
		tst.w	head_pool+next_pool_offset(a4)
		beq	pool_end

		moveq	#0,d4
		lea	head_pool(a4),a6
		move.l	a6,a2
pool_loop:
		cmp.l	a6,a2
		bne	free_skip

		move.w	next_free_offset(a2),d2
		lea	(a2,d2.w),a2
free_skip:
		move.w	next_pool_offset(a6),d6
		lea	(a6,d6.w),a6
		moveq	#0,d0
		move.w	next_pool_offset(a6),d0
		add.l	d0,d4
		tst.w	d0
		bne	pool_loop
pool_end:
		bra	lake_loop

lake_end:
		movem.l	(sp)+,d0-d4/d6/a0-a2/a4/a6
		rts
*
	.end
