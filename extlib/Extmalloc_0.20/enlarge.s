*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : enlarge.s			*
*   author    : T.Kawamoto			*
*   date      : 91/9/28				*
*   functions : allocate_lake			*
*             : enlarge_lake			*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*             : 91/9/23	large size support	*
*   ver 0.02  : 91/9/28	rename file name	*
*             : 	from lake to enlarge	*
*   ver 0.10  : 92/3/18	make enlarging only	*
*             : 	2 bytes fatal error	*
*   ver 0.11  : 92/3/24	new lake adds the end	*
*             : 	of the lakes list	*
*   ver 0.11  : 92/3/24	new alloc least size	*
*             : 	of area whom user needs	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	is_previous_free
*
	.xdef	allocate_lake
	.xdef	enlarge_lake
*
allocate_lake:
*
* input
*  d1	バイトサイズ
*  a5	pointer to local BSS
* destroy
*  d0	OS で破壊される
*  d2	ワークレジスタ
*  d7	ワークレジスタ
*  a1	ワークポインタ
*  a2	ワークポインタ
*  a4	pointer to lake head
*  a6	ワークポインタ
*
	move.l	#lake_buffer_head+2+2,d2
	add.l	d1,d2
	move.l	d2,-(sp)
	dc.w	$ff48		* MALLOC
	addq.l	#4,sp
	tst.l	d0
	bmi	alloc_error
	move.l	d0,a4
	move.l	d2,lake_size(a4)
	move.l	#0,next_lake_ptr(a4)
	lea	next_pool_offset-2(a4,d2.l),a2	* last dummy を
	move.w	#0,(a2)			*         設定
	move.w	#free_pool_buffer_head,head_pool+next_pool_offset(a4)
	move.w	#free_pool_buffer_head,head_pool+next_free_offset(a4)
	lea	lake_buffer_head(a4),a6
	move.l	a2,d0			* lake buffer head と last dummy 間の
	sub.l	a6,d0			* オフセットを計算
	move.w	d0,next_pool_offset(a6)	* last free pool の再設定
	move.w	d0,next_free_offset(a6)	*
	lea	lake_top-next_lake_ptr(a5),a6
alloc_end_loop:
	move.l	next_lake_ptr(a6),d0
	beq	alloc_end_end
	move.l	d0,a6
	bra	alloc_end_loop
*
alloc_end_end:
	move.l	a4,next_lake_ptr(a6)
	bsr	enlarge_lake
	moveq	#0,d0
alloc_error:
	rts
*
*
enlarge_lake:
*
* input
*  d1	バイトサイズ
*  a4	pointer to lake head
*  a5	pointer to local BSS
* output
*  d0	エラーコード
* destroy
*  d2	new length
*  d7	ワークレジスタ
*  a1	ワークポインタ
*  a2	ワークポインタ
*  a6	pointer to last free pool
*
	tst.w	head_pool+next_pool_offset(a4)
	beq	no_more_error	* large size の場合は、エラー
	move.l	lake_size(a4),d2
	cmp.l	#$00008000,d2
	beq	no_more_error	* 最大 lake サイズいっぱいだった場合
	lea	next_pool_offset-2(a4,d2.l),a6	* last dummy
	bsr	is_previous_free
	bne	set_skip	* last dummy pool の直前が free なら、
	move.l	a2,a6		* そこが最終アドレス（a6）
set_skip:
*
* new length を算出
*
	add.l	#$00001000,d2
	and.l	#$0000f000,d2
	cmp.l	#$00008000,d2
	bcs	size_skip
	move.l	#$00008000,d2
size_skip:
	move.l	d2,-(sp)	* まず、算出サイズに拡大してみる
	move.l	a4,-(sp)
	dc.w	$ff4a		* SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bpl	enlarge_ok
	move.l	d0,d2		* 拡大に失敗した場合は出来る範囲で拡大する
	andi.l	#$ff000000,d0
	cmpi.l	#$82000000,d0	* 全然拡大不可ならエラー
	beq	no_more_error	*   lake サイズがこれ以上増えない場合
*
* OS が返してきた範囲でリトライ
*
	and.l	#$00ffffff,d2
	move.l	lake_size(a4),d0
	addq.l	#2,d0		* 2 bytes しか余計に確保出来ない場合も
	cmp.l	d2,d0		* 致命的エラー 92/3/18 (Thanks 板垣)
	bcc	no_more_error
	move.l	d2,-(sp)
	move.l	a4,-(sp)
	dc.w	$ff4a		* SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	no_more_error	*  致命的エラー
enlarge_ok:
*
* 拡大に成功したので lake を再設定
*
*  a4	pointer to lake head
*  a6	pointer to last free pool
*
	move.l	d2,lake_size(a4)	* lake size を再設定
	lea	next_pool_offset-2(a4,d2.l),a2	* last dummy を
	move.w	#0,(a2)			*         再設定
	move.l	a2,d0			* last free pool と last dummy 間の
	sub.l	a6,d0			* オフセットを計算
	move.w	d0,next_pool_offset(a6)	* last free pool の再設定
	move.w	d0,next_free_offset(a6)	*
	moveq.l	#0,d0			* 正常終了
	rts
*
no_more_error:
	moveq.l	#-1,d0
	rts
*
	.end
