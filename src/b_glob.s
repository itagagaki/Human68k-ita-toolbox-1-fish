* b_glob.s
* This contains built-in command glob.
*
* Itagaki Fumihiko 03-Oct-90  Create.

.include doscall.h

.xref wordlistlen

.text

****************************************************************
*  Name
*       glob - echo arguments
*
*  Synopsis
*       glob words
****************************************************************
.xdef cmd_glob

cmd_glob:
		bsr	wordlistlen
		tst.l	d0
		beq	return_0

		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	#1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
return_0:
		moveq	#0,d0
		rts

.end
