.include doscall.h

.text

pause:
		move.w	#$08,-(a7)
		DOS	_KFLUSH
		addq.l	#2,a7
		clr.w	-(a7)
		DOS	_EXIT2

.end pause
