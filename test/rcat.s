.include doscall.h
.text
start:
	move.w	#'.',-(a7)
	DOS	_PUTCHAR
	addq.l	#2,a7
	bra	start

done:
	DOS	_EXIT

.end start
