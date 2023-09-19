*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : debug.s				*
*   author    : T.Kawamoto			*
*   date      : 91/9/22				*
*   functions : interface C and assembler	*
*             : dummy a5 handling		*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
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
	.xdef	_mfree
	.xdef	_mdump
*
lake_top equ	0
_lake_top:
	dc.l	0
*
_malloc:
	move.l	4(sp),d0
	lea	_lake_top,a5
	jmp	allocate_memory_reg_saved
*
_mfree:
	move.l	4(sp),d0
	lea	_lake_top,a5
	jmp	free_memory_reg_saved
*
_mdump:
	lea	_lake_top,a5
	jmp	dumpout_memory_reg_saved
*
	.end
