*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : large.s				*
*   author    : T.Kawamoto			*
*   date      : 91/9/23				*
*   functions : allocate_large_memory		*
*   history   : 				*
*   ver 0.01  : 91/9/23	large size support	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xdef	allocate_large_memory
*
allocate_large_memory:
* input
*  d0	必要なバイトサイズ
*  a5	pointer to local BSS
* output
*  d0	アドレス or -1
* destroy
*  d1	バイトサイズ
*  a4	lake head へのポインタ
*
	move.l	d0,d1
	add.l	#head_pool+pool_buffer_head,d1
	move.l	d1,-(sp)
	dc.w	$ff48		* MALLOC
	addq.l	#4,sp
	tst.l	d0
	bmi	alloc_large_error
	move.l	d0,a4
	move.l	d1,lake_size(a4)
	move.l	lake_top(a5),next_lake_ptr(a4)
	move.l	a4,lake_top(a5)
	move.w	#0,head_pool+next_pool_offset(a4)
	lea	head_pool+pool_buffer_head(a4),a4
	move.l	a4,d0
	rts
*
alloc_large_error:
	moveq.l	#-1,d0
	rts
*
	.end
