*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : Crealloc.s			*
*   author    : T.Kawamoto			*
*   date      : 92/4/15				*
*   functions : interface C and assembler	*
*             : dummy a5 handling		*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*   ver 0.04  : 91/10/8	rewrite for C interface	*
*   ver 0.14  : 92/5/17	add _realloc		*
*   ver 1.00  : 94/8/7	fix realloc errors	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	realloc_memory_reg_saved
	.xref	lake_top_area
*
	.xdef	_realloc
*
_realloc:
	move.l	4(sp),d0
	move.l	8(sp),d1
	beq	realloc_error
	move.l	a5,-(sp)
	lea	lake_top_area,a5
	bsr	realloc_memory_reg_saved
	move.l	(sp)+,a5
	cmpi.l	#-1,d0
	bne	realloc_normal
realloc_error:
	moveq.l	#0,d0
realloc_normal
	rts
*
	.end
