*************************************************
*						*
*   malloc Ext version Ver 0.14			*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : alloc.s				*
*   author    : T.Kawamoto			*
*   date      : 92/4/15				*
*   functions : allocate_memory_reg_saved	*
*             : allocate_memory			*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	added D2 saving		*
*             : 91/9/22	lake_top(a5)		*
*             : 91/9/23	large size support	*
*   ver 0.12  : 92/4/15	omitted MALLOC		*
*   ver 0.15  : 92/11/2	shrink bug fix		*
*						*
*************************************************
*
	include	defines.inc
*
	.text
*
	.xref	enlarge_lake
	.xref	allocate_lake
	.xref	allocate_large_memory
*
	.xdef	allocate_memory_reg_saved
	.xdef	allocate_memory
*
	dc.b	"Ext malloc library << lake >> Ver 0.16 for fish, ksh, zsh, and dis",0
	.even
*
*
allocate_memory_reg_saved:
*
* input
*  d0	必要なバイトサイズ
*  a5	pointer to local BSS
* output
*  d0	アドレス or -1
*
	movem.l	d1-d5/d7/a0-a2/a4/a6,-(sp)
	bsr	allocate_memory
	movem.l	(sp)+,d1-d5/d7/a0-a2/a4/a6
	rts
*
allocate_memory:
*
* input
*  d0	必要なバイトサイズ
*  a5	pointer to local BSS
* output
*  d0	アドレス or -1
* destroy
*  d1	バイトサイズ
*  d2	ワークレジスタ
*  d7	ワークレジスタ
*  a1	ワークポインタ
*
* 現在サーチ中のもの
*  d0.w	必要なバイトサイズ
*  a4	lake head へのポインタ
*  a6	free pool へのポインタ
*  a2	直前の free pool へのポインタ
*  a1	直後の free pool へのポインタ
*
* free pool の中で必要最小限のサイズをもつもの
*  d5.w	サイズ
*  d3	lake head へのポインタ
*  d4	free pool へのポインタ
*  a0	直前の free head へのポインタ
*
	move.l	d0,d1
	addq.l	#1,d1		* バイトサイズは
	andi.l	#$fffffffe,d1	* 偶数に整合させる
	cmpi.l	#$00004000,d1
	bcc	allocate_large_memory
allocate_memory_retry:
	moveq.l	#-1,d5		* 必要最小限のサイズ
	moveq.l	#0,d4		* 必要最小限へのポインタ
	move.l	lake_top(a5),d7
	bra	lake_entry
lake_loop:
	move.l	next_lake_ptr(a4),d7
lake_entry:
	beq	lake_end	* lake がなくなった
	move.l	d7,a4		* lake head へのポインタ
	tst.w	head_pool+next_pool_offset(a4)
	beq	lake_loop	* large size の場合は、スキップ
	lea	head_pool(a4),a6
pool_loop:
	move.l	a6,a2		* free のポインタをセーブ
	move.w	next_free_offset(a6),d7
	lea	(a6,d7.w),a6
	move.w	next_pool_offset(a6),d7
	beq	lake_loop	* pool がなくなった
	subi.w	#2,d7		* pool のサイズ計算
	cmp.w	d7,d1
	beq	just_fit_found	* 丁度必要サイズと一致なら直ぐに確保へ
	bcc	pool_loop	* 必要サイズに満たない
	subi.w	#2,d7		* pool のサイズ計算
	cmp.w	d7,d1
	beq	just_fit_found	* 丁度必要サイズ＋２でも直ぐに確保へ
	cmp.w	d7,d5
	bcs	pool_loop	* 今までみつかったものより大きい場合はスキップ
	move.w	d7,d5		* 必要最低限が、より小さいものがみつかったので
	move.l	a4,d3		* d5,a0,d3,d4 にセーブ
	move.l	a6,d4
	move.l	a2,a0
	bra	pool_loop
*
lake_end:			* 最後までサーチ終了
	move.l	a0,a2
	move.l	d3,a4
	move.l	d4,a6
	move.l	a6,d7
	bne	larger_found	* 必要最小限があればそれで確保
*
generate_lake_and_retry:
*
* 見つからなかったので、新しく lake を確保
*  あまり頻繁には起こらない部分なので、
*   リトライという無駄によってバグを抑える
*
* まずは、既存の lake の拡張を試みる
*
*  d7	offset work registers,
*  a4	lake head へのポインタ
*  a5	pointer to local BSS
*
	move.l	lake_top(a5),d7
enlarge_loop:
	beq	enlarge_end
	move.l	d7,a4
	bsr	enlarge_lake
	bpl	allocate_memory_retry	* リトライ（あまり起こらない）
	move.l	next_lake_ptr(a4),d7
	bra	enlarge_loop
*
* 拡張が出来なければ新たに lake を確保する
*
enlarge_end:
	bsr	allocate_lake
	bpl	allocate_memory_retry	* リトライ（あまり起こらない）
allocation_error:
	moveq.l	#-1,d0
	rts			* allocation error
*
just_fit_found:
*
* 丁度のサイズが見つかった
*  a6	free pool へのポインタ
*  a2	直前の free pool へのポインタ
*  d7	ワークレジスタ
*
	move.w	next_free_offset(a6),d7
	add.w	d7,next_free_offset(a2)
	lea.l	pool_buffer_head(a6),a6
	move.l	a6,d0
	rts
*
larger_found:
*
* サイズの大きいのが見つかった
*
*  d1.w	必要なバイトサイズ
*  a6	pool head へのポインタ
*  a2	直前の free pool へのポインタ
*  a1	直後の free pool へのポインタ
*  d7	ワークレジスタ
*
	lea.l	pool_buffer_head(a6),a1
	move.l	a1,d0		* 返り値を予め算出
	addi.w	#2,d1		* 確保サイズは、＋２
	move.w	next_free_offset(a6),d7
	lea	(a6,d7.w),a1	* 次の free pool のポインタ
	move.w	next_pool_offset(a6),d7
	move.w	d1,next_pool_offset(a6)
	lea	(a6,d1.w),a6	* 残りの free pool head を作成
	sub.w	d1,d7		* 残りの pool size
	move.w	d7,next_pool_offset(a6)
	move.l	a6,d7		* 直前の free pool と本 free pool
	sub.l	a2,d7		* の差を計算
	move.w	d7,next_free_offset(a2)
	move.l	a1,d7		* 本 free pool と直後の free pool
	sub.l	a6,d7		* の差を計算
	move.w	d7,next_free_offset(a6)
	rts
*
	.end
