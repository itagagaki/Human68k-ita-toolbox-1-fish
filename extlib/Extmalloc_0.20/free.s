*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : free.s				*
*   author    : T.Kawamoto			*
*   date      : 92/4/15				*
*   functions : free_memory_reg_saved		*
*             : free_memory			*
*             : free_all_memory_reg_saved	*
*             : free_all_memory			*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*             : 91/9/23	large size support	*
*   ver 0.02  : 91/9/28	shrink support		*
*   ver 0.03  : 91/10/2	add free_all_memory	*
*   ver 0.12  : 92/4/15	omitted MALLOC		*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	is_previous_free
	.xref	free_lake
	.xref	shrink_lake
*
	.xdef	free_memory_reg_saved
	.xdef	free_memory
	.xdef	MFREEALL
	.xdef	free_all_memory_reg_saved
	.xdef	free_all_memory
*
free_memory_reg_saved:
*
* input
*  d0	アドレス
*  a5	pointer to local BSS
* output
*  d0	エラーコード
*
	movem.l	d7/a1/a2/a4/a6,-(sp)
	bsr	free_memory
	movem.l	(sp)+,d7/a1/a2/a4/a6
	rts
*
free_memory:
*
* input
*  d0	アドレス
*  a5	pointer to local BSS
* output
*  d0	エラーコード
* destroy
*  d7	ワークレジスタ
*  a1	ワークポインタ
*  a2	ワークポインタ
*  a4	lake head へのポインタ
*  a6	pool head へのポインタ
*
	subq.l	#2,d0
	move.l	lake_top(a5),d7
	bra	lake_entry
lake_loop:
	move.l	next_lake_ptr(a4),d7
lake_entry:
	beq	no_pool			* lake がなくなった
	move.l	d7,a4			* lake head へのポインタ
	add.l	#head_pool,d7
	cmp.l	d0,d7
	beq	free_lake		* large size の開放
	tst.w	head_pool+next_pool_offset(a4)
	beq	lake_loop		* large size の場合は、スキップ
	cmp.l	d0,a4			* d0 pointer が lake の範囲内にあるかどうか？
	bcc	lake_loop		* ない（その１）
	move.l	lake_size(a4),d7
	add.l	a4,d7
	cmp.l	d7,d0
	bcc	lake_loop		* ない（その２）
	lea	head_pool(a4),a6	* 範囲内なので詳しく pool をサーチ
pool_loop:
	move.w	next_pool_offset(a6),d7
	beq	no_pool			* pool がなくなった
	lea	(a6,d7.w),a6
	cmp.l	a6,d0
	bne	pool_loop		* この pool かどうか？
*
* 開放したい pool の位置が見つかった
*
*  a6	開放したい pool へのポインタ
*
* 直前が free pool かどうかをチェック
*
	bsr	is_previous_free
	beq	together_previous
*
* 直前が free pool でない場合
*
*  a6	開放したい pool へのポインタ
*  a2	直前の free pool へのポインタ
*
	move.l	a6,d0
	sub.l	a2,d0			* ふたつの間隔
	move.w	next_free_offset(a2),d7	* next_free_offset を二分して
	move.w	d0,next_free_offset(a2)	* 直前のほうと
	sub.w	d0,d7
	move.w	d7,next_free_offset(a6)	* 開放したいほうに代入
	bra	together_if_following_is_free
*
* 直前が free pool の場合
*
*  a6	開放したい pool へのポインタ
*  a2	直前の free pool へのポインタ
*
together_previous:
	move.w	next_pool_offset(a6),d7	* ふたつを
	add.w	d7,next_pool_offset(a2)	* まとめて
	move.l	a2,a6			* しまう
*
together_if_following_is_free:
*
* 今度は、直後が free pool かどうかをチェック
*
	move.w	next_pool_offset(a6),d7
	cmp.w	next_free_offset(a6),d7
	bne	together_following_skip
*
* 直後が free pool の場合
*
*  a6	開放したい pool へのポインタ
*  a2	直後の free pool へのポインタ
*
	lea	(a6,d7.w),a2
	move.w	next_pool_offset(a2),d7	* ふたつを
	beq	together_following_skip
	add.w	d7,next_pool_offset(a6)	* まとめて
	move.w	next_free_offset(a2),d7	* しまって
	add.w	d7,next_free_offset(a6)	* ひとつに
together_following_skip:
	bra	shrink_lake
	moveq.l	#0,d0
	rts
*
no_pool:
*
* 最後までサーチ終了
*
*   なかったのでエラー終了
*
	moveq.l	#-1,d0
	rts
*
MFREEALL:
free_all_memory_reg_saved:
*
* input
*  a5	pointer to local BSS
* output
*  d0	エラーコード
*
	movem.l	d7/a1/a4/a6,-(sp)
	bsr	free_all_memory
	movem.l	(sp)+,d7/a1/a4/a6
	rts
*
free_all_memory:
*
* input
*  a5	pointer to local BSS
* output
*  d0	エラーコード
* destroy
*  d7	ワークレジスタ
*  a1	ワークポインタ
*  a4	lake head へのポインタ
*  a6	ワークポインタ
*
	subq.l	#2,d0
	move.l	lake_top(a5),d7
	bra	lake_all_entry
lake_all_loop:
	move.l	next_lake_ptr(a6),d7
lake_all_entry:
	beq	no_all_pool		* lake がなくなった
	move.l	d7,a6			* lake head へのポインタ
	move.l	a6,a4
	bsr	free_lake
	bra	lake_all_loop
*
no_all_pool:
*
* 最後まで free 完了
*
	moveq.l	#0,d0
	rts
*
	.end
