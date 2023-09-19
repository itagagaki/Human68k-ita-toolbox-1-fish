.include doscall.h
.include chrcode.h

.xref DecodeHUPAIR

.text

start:
		bra	start1
		dc.b	'#HUPAIR',0
start1:
		lea	1(a2),a0
		bsr	DecodeHUPAIR
		move.w	d0,d1
		subq.l	#2,a7
		bra	print_start

loop1:
		move.w	#'>',(a7)
		DOS	_PUTCHAR
loop2:
		clr.w	d0
		move.b	(a0)+,d0
		beq	continue

		move.w	d0,(a7)
		DOS	_PUTCHAR
		bra	loop2

continue:
		move.w	#'<',(a7)
		DOS	_PUTCHAR
		move.w	#CR,(a7)
		DOS	_PUTCHAR
		move.w	#LF,(a7)
		DOS	_PUTCHAR
print_start:
		dbra	d1,loop1

		addq.l	#2,a7
		DOS	_EXIT

.end start
