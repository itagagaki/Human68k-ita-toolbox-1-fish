*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by ‚d‚˜‚”(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : Cmdump.s			*
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
	.xref	lake_top_area
*
	.xdef	_debug_mdump
*
_debug_mdump:
	lea	lake_top_area,a5
	bra	dumpout_memory_reg_saved
*
	.end
