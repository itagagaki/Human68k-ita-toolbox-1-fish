*****************************************************************
*								*
*	version display command					*
*								*
*	VER							*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h

.text

start:
		pea	msg_dosversion(pc)
		DOS	_PRINT
		addq.l	#4,a7
		DOS	_VERNUM
		move.w	d0,d1
		ext.w	d1
		ext.l	d1
		divu	#10,d1
		move.l	d1,d2
		lsr	#8,d0
		swap	d2
		and.b	#$f,d0
		and.b	#$f,d1
		and.b	#$f,d2
		add.b	#$30,d0
		add.b	#$30,d1
		add.b	#$30,d2
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		move.w	#$2e,(a7)
		DOS	_PUTCHAR
		move.w	d1,(a7)
		DOS	_PUTCHAR
		move.w	d2,(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		pea	msg_crlf(pc)
		DOS	_PRINT
		addq.l	#4,a7
		clr.w	-(a7)
		DOS	_EXIT2

.data

msg_dosversion:	dc.b	CR,LF,'Human68k version ',0
msg_crlf:	dc.b	CR,LF,CR,LF,0

.end start
