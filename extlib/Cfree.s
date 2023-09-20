*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : Cfree.s				*
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
	.xref	free_memory_reg_saved
	.xref	lake_top_area
*
	.xdef	_free
*
_free:
	move.l	4(sp),d0
	beq	free_OK
	move.l	a5,-(sp)
	lea	lake_top_area,a5
	bsr	free_memory_reg_saved
	move.l	(sp)+,a5
free_OK:
	rts
*
	.end
