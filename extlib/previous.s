*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : previous.s			*
*   author    : T.Kawamoto			*
*   date      : 91/9/22				*
*   functions : is_previous_free		*
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
	.xdef	is_previous_free
*
is_previous_free:
*
* input
*  a4	pointer to lake head
*  a6	pointer to pool head
*  a5	pointer to local BSS
* output
*  Z	set if true
*  a2	pointer to previous pool head
* destroy
*  d7	ワークレジスタ
*  a1	ワークポインタ
*
	lea	head_pool(a4),a1
	move.l	a1,a2
	move.w	next_free_offset(a1),d7
	lea	(a1,d7.w),a1
	cmp.l	a6,a1
	bcs	find_free_loop
	moveq.l	#1,d7
	rts
*
find_free_loop:
	move.l	a1,a2
	move.w	next_free_offset(a1),d7
	lea	(a1,d7.w),a1
	cmp.l	a6,a1
	bcs	find_free_loop
	move.w	next_pool_offset(a2),d7
	lea	(a2,d7.w),a1
	cmp.l	a6,a1
	rts
*
