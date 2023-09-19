IRANDOM_MAX	equ	32767

	.offset 0

irandom_index:		ds.b	1
irandom_position:	ds.b	1
irandom_poolsize:	ds.b	1		*  POOLSIZE
irandom_pad:		ds.b	1
irandom_table:		ds.w	55
irandom_pool:		*			ds.w	POOLSIZE

IRANDOM_STRUCT_HEADER_SIZE	equ	irandom_pool-irandom_index
