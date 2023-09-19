*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : homy.s				*
*   author    : T.Kawamoto			*
*   date      : 92/4/15				*
*   functions : interface C and assembler	*
*             : dummy a5 handling		*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*   ver 0.04  : 91/10/8	rewrite for C interface	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	allocate_memory_reg_saved
	.xref	free_memory_reg_saved
*
	.xdef	_malloc
	.xdef	_free
*
lake_top equ	0
lake_top_area:
	dc.l	0
*
_malloc:
	move.l	4(sp),d0
	beq	malloc_error
	move.l	a5,-(sp)
	lea	lake_top_area,a5
	bsr	allocate_memory_reg_saved
	move.l	(sp)+,a5
malloc_error:
	rts
*
_free:
	move.l	4(sp),d0
	move.l	a5,-(sp)
	lea	lake_top_area,a5
	bsr	free_memory_reg_saved
	move.l	(sp)+,a5
	rts
*
	.end
