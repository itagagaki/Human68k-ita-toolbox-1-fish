* b_source.s
* This contains built-in command source.
*
* Itagaki Fumihiko 16-Aug-90  Create.

.include ../src/fish.h
.include ../src/source.h

.xref strcmp
.xref strfor1
.xref OpenLoadRun_source
.xref usage
.xref too_few_args

.text

****************************************************************
*  Name
*       source - run shell script on current shell
*
*  Synopsis
*       source [-h] file
****************************************************************
.xdef cmd_source

cmd_source:
		moveq	#0,d7			*  D7.B : source flag
		sf	d6			*  D6.B := 0 ... openできなければエラー
		move.w	d0,d1
		beq	cmd_source_1

		lea	str_h,a1
		bsr	strcmp
		bne	cmd_source_1

		moveq	#(1<<SOURCE_FLAGBIT_JUSTREAD),d7
		st	d6
		bsr	strfor1
		subq.w	#1,d1
cmd_source_1:
		subq.w	#1,d1
		bcs	cmd_source_too_few_args

		movea.l	a0,a1
		bsr	strfor1
		exg	a0,a1
		jsr	OpenLoadRun_source		***!! 再帰 !!***
		moveq	#0,d0
		rts

cmd_source_too_few_args:
		bsr	too_few_args
		lea	msg_usage,a0
		bra	usage
****************************************************************
.data

str_h:		dc.b	'-h',0
msg_usage:	dc.b	'[ -h ] { - | <ファイル名> }',0

.end
