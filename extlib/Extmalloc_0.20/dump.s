*************************************************
*						*
*   malloc Ext version Ver 0.10			*
*   Copyright 1991 by Ｅｘｔ(T.Kawamoto)	*
*						*
*************************************************
*						*
*   file name : dump.s				*
*   author    : T.Kawamoto			*
*   date      : 91/9/23				*
*   functions : dumpout_memory_reg_saved	*
*             : dumpout_memory			*
*   history   : 91/9/16	now coding		*
*             : 91/9/21	debugging has finished	*
*   ver 0.01  : 91/9/22	lake_top(a5)		*
*             : 91/9/23	large size support	*
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
dumpout_memory_reg_saved:
*
* input
*  a5	pointer to local BSS
* output
*  無し
*
	movem.l	d0-d2/d6/a0-a2/a4/a6,-(sp)
	bsr	dumpout_memory
	movem.l	(sp)+,d0-d2/d6/a0-a2/a4/a6
	rts
*
dumpout_memory:
*
* input
*  a5	pointer to local BSS
* output
*  無し
* destroy
*  a0	ワークポインタ
*  a1	ワークポインタ
*  d0	ワークレジスタ
*  d1	ワークレジスタ
*  d2	ワークレジスタ
*  d6	ワークレジスタ
*  a4	lake head へのポインタ
*  a6	normal pool へのポインタ
*  a2	free pool へのポインタ
*
	move.l	lake_top(a5),d6
	bra	lake_entry
*
pool_end:
	lea	pool_end_string,a0
	bsr	print_string
	cmp.l	a6,a2
	beq	lake_loop
	lea	illegal_free_pointer_string,a0
	bsr	print_string
lake_loop:
	move.l	next_lake_ptr(a4),d6
lake_entry:
	beq	lake_end	* lake がなくなった
	move.l	d6,a4		* lake head へのポインタ
	move.l	a4,d0
	bsr	print_long
	lea	length_string,a0
	bsr	print_string
	move.l	lake_size(a4),d0
	bsr	print_long
	tst.w	head_pool+next_pool_offset(a4)
	beq	large_pool		* large size の場合
	lea	lake_string,a0
	bsr	print_string
	lea	head_pool(a4),a6
	move.l	a6,a2
pool_loop:
	cmp.l	a6,a2
	bne	free_skip
	move.w	next_free_offset(a2),d2
	lea	(a2,d2.w),a2
free_skip:
	move.w	next_pool_offset(a6),d6
	lea	(a6,d6.w),a6
	bsr	print_head
	tst.w	next_pool_offset(a6)
	beq	pool_end	* pool がなくなった
	cmp.l	a6,a2
	beq	is_free_pool
is_used_pool:
	lea	used_string,a0
	bsr	print_string
	bsr	print_contents
	bra	pool_loop
*
is_free_pool:
	lea	free_string,a0
	bsr	print_string
	bra	pool_loop
*
large_pool:
	lea	large_pool_string,a0
	bsr	print_string
	bra	lake_loop	* large pool は一つだけ
*
lake_end:			* 最後までサーチ終了
	rts
*
print_head:
*
* input
*  a5	pointer to local BSS
*  a6	pool head
* destroy
*  d0	ワークレジスタ
*  a0	ワークポインタ
*
	move.l	#9,d0
	bsr	putchar
	move.l	a6,d0
	bsr	print_long
	lea	length_string,a0
	bsr	print_string
	moveq.l	#0,d0
	move.w	next_pool_offset(a6),d0
	bsr	print_word
	rts
*
print_contents:
*
* input
*  a5	pointer to local BSS
*  a6	pool head
* destroy
*  d0	ワークレジスタ
*  d1	ワークレジスタ
*  a0	ワークポインタ
*  a1	ワークポインタ
*
	move.w	next_pool_offset(a6),d1
	subq.l	#pool_buffer_head,d1
	cmp.l	#17,d1
	bcc	print_contents_end
	lea	pool_buffer_head(a6),a1
	bra	print_contents_next
*
print_contents_loop:
	move.l	#' ',d0
	bsr	putchar
	move.b	(a1)+,d0
	bsr	print_byte
print_contents_next:
	dbra	d1,print_contents_loop
print_contents_end:
	lea	CRLF_string,a0
*
print_string:
	move.l	a0,-(sp)
	dc.w	$ff09		* PRINT
	addq.l	#4,sp
	rts
*
print_long:
	move.l	d0,-(sp)
	swap	d0
	bsr	print_word
	move.l	(sp)+,d0
print_word:
	move.w	d0,-(sp)
	asr.w	#8,d0
	bsr	print_byte
	move.w	(sp)+,d0
print_byte:
	move.w	d0,-(sp)
	asr.b	#4,d0
	bsr	print_nible
	move.w	(sp)+,d0
print_nible:
	move.w	d0,-(sp)
	andi.w	#15,d0
	move.b	print_table(pc,d0.w),d0
	bsr	putchar
	move.w	(sp)+,d0
	rts
*
print_table:
	dc.b	'0123456789ABCDEF'
*
putchar:
	move.w	d0,-(sp)
	dc.w	$ff02		* PUTCHAR
	addq.l	#2,sp
	rts
*
length_string:
	dc.b	' (',0
lake_string:
	dc.b	') LAKE',$0d,$0a,0
large_pool_string:
	dc.b	') LARGE POOL',$0d,$0a,0
used_string:
	dc.b	') USED POOL ',0
free_string:
	dc.b	') FREE POOL'
CRLF_string:
	dc.b	$0d,$0a,0
pool_end_string:
	dc.b	') END',$0d,$0a,0
illegal_free_pointer_string:
	dc.b	'free pointer is destroyed',$0d,$0a,0
*
	.even
*
	.end
