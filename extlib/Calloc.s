*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : Calloc.s			*
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
*
	.xdef	_malloc
	.xdef	lake_top_area
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
	.end
