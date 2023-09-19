*************************************************
*						*
*   malloc Ext version				*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : alloc.s				*
*   author    : T.Kawamoto			*
*   date      : 92/4/15				*
*   functions : realloc_memory_reg_saved	*
*             : realloc_memory			*
*   history   : 92/5/17	now coding		*
*   ver 0.14  : 92/5/17	add _realloc		*
*   ver 0.16  : 93/5/1	fixed error when	*
*             :		copying 1-2 bytes area	*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	allocate_memory
	.xref	free_memory
*
	.xdef	realloc_memory_reg_saved
	.xdef	realloc_memory
*
realloc_memory_reg_saved:
*
* input
*  d0	アドレス
*  d1	リアロックサイズ
*  a5	pointer to local BSS
* output
*  d0	アドレス or -1
*
	movem.l	d1-d7/a1-a4/a6,-(sp)
	bsr	realloc_memory
	movem.l	(sp)+,d1-d7/a1-a4/a6
	rts
*
realloc_memory:
*
* input
*  d0	アドレス
*  d1	リアロックサイズ
*  a5	pointer to local BSS
* output
*  d0	アドレス or -1
* destroy
*  d2	ワークレジスタ
*  d3	ワークレジスタ
*  d4	ワークレジスタ
*  d5	ワークレジスタ
*  d6	オリジナルサイズ
*  d7	ワークレジスタ
*  a1	ワークポインタ
*  a2	ワークポインタ
*  a3	オリジナルアドレス
*  a4	lake head へのポインタ
*  a6	pool head へのポインタ
*
	subq.l	#2,d0			* ここから free したい size の計算
	move.l	lake_top(a5),d7
	bra	lake_entry
lake_loop:
	move.l	next_lake_ptr(a4),d7
lake_entry:
	beq	no_pool			* lake がなくなった
	move.l	d7,a4			* lake head へのポインタ
	add.l	#head_pool,d7
	cmp.l	d0,d7
	beq	realloc_lake		* large size のリアロック
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
* リアロックしたい pool の位置が見つかった
*
*  a6	オリジナルの pool へのポインタ
*  d1	リアロックしたい size
*
	clr.l	d6
	move.w	next_pool_offset(a6),d6
	subq.l	#2,d6
	lea	2(a6),a3
	bra	realloc_memory_body
*
* リアロックしたい lake の位置が見つかった
*
*  a4	オリジナルの lake へのポインタ
*  d1	リアロックしたい size
*
realloc_lake:
	move.l	lake_size(a4),d6
	sub.l	#head_pool+pool_buffer_head,d6
	lea	head_pool+pool_buffer_head(a4),a3
realloc_memory_body:
*
* リアロックの実体
*
*  a3	オリジナルの領域へのポインタ
*  d6	オリジナル size
*  d1	リアロックしたい size
*
	move.l	d1,d0
	cmp.l	d6,d1
	bcc	min_size_skip
	move.l	d1,d6
min_size_skip:
	bsr	allocate_memory
	tst.l	d0
	bmi	no_pool
*
*  a3	オリジナルの領域へのポインタ
*  d6	オリジナル size とリアロックしたい size のうち小さい方
*  d0	リアロックしたい領域へのポインタ
*
	move.l	a3,a1
	move.l	d0,a2
	move.l	a2,a3
	move.l	a1,d0
	btst.l	#1,d6			* ハーフワード単位のサ
	beq	half_skip		* イズで奇数であるなら
	move.w	(a1)+,(a2)+		* 偶数に調整しておく
half_skip:
	asr.l	#2,d6			* ロングワード単位サイズ
	tst.l	d6			* 0 バイトなら
	beq	move_skip		* スキップ    93/5/1
	subq.l	#1,d6
move_loop:
	move.l	(a1)+,(a2)+
	dbra	d6,move_loop
	clr.w	d6
	subq.l	#1,d6
	bcc	move_loop
move_skip:
	bsr	free_memory
	tst.l	d0
	bmi	no_pool
	move.l	a3,d0
	rts
*
no_pool:
*
* 最後までサーチ終了
*
*   なかったのでエラー終了
*
no_memory:
*
* メモリが足りないのでエラー終了
*
	moveq.l	#-1,d0
	rts
*
	.end
