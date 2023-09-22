.include doscall.h
.include chrcode.h

.text

start:
		clr.w	d1
		move.b	(a2)+,d1
		beq	done

		subq.w	#1,d1
		subq.l	#2,a7
loop:
		clr.w	d0
		move.b	(a2)+,d0
		move.w	d0,(a7)
		DOS	_PUTCHAR
		dbra	d1,loop

		move.w	#CR,(a7)
		DOS	_PUTCHAR
		move.w	#LF,(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
done:
		DOS	_EXIT

.end start
