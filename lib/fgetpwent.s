* fgetpwent.s
* Itagaki Fumihiko 17-Aug-91  Create.

.include chrcode.h
.include limits.h
.include pwd.h

.xref fgetc

.text

*****************************************************************
* fgetpwent - パスワード・ファイルから1エントリを得る
*
* CALL
*      D0.W   パスワード・ファイルのファイル・ハンドル
*             （行の先頭を指していること）
*
*      A0     格納バッファ（PW_SIZEバイト）
*
* RETURN
*      D0.L   負: OSのエラー・コードまたはEOF
*              1: 書式が誤っている
*              0: 成功
*      CCR    TST.L D0
*****************************************************************
.xdef fgetpwent

fgetpwent:
		movem.l	d1-d5/a0-a1,-(a7)
		move.w	d0,d2

		moveq	#';',d3
		lea	PW_NAME(a0),a1
		move.w	#PW_NAME_SIZE,d1
		bsr	getpwfield
		bne	getpwent_return

		lea	PW_PASSWD(a0),a1
		move.w	#PW_PASSWD_SIZE,d1
		bsr	getpwfield
		bne	getpwent_return

		lea	PW_UID(a0),a1
		bsr	getpwid
		bne	getpwent_return

		lea	PW_GID(a0),a1
		bsr	getpwid
		bne	getpwent_return

		lea	PW_GECOS(a0),a1
		move.w	#PW_GECOS_SIZE,d1
		bsr	getpwfield
		bne	getpwent_return

		lea	PW_DIR(a0),a1
		move.w	#PW_DIR_SIZE,d1
		bsr	getpwfield
		bne	getpwent_return

		moveq	#LF,d3
		lea	PW_SHELL(a0),a1
		move.w	#PW_SHELL_SIZE,d1
		bsr	getpwfield
getpwent_return:
		movem.l	(a7)+,d1-d5/a0-a1
		rts


getpwfield:
		sf	d4
getpwfield_loop:
		move.w	d2,d0
		jsr	fgetc
		bmi	getpwfield_return

		cmp.b	#';',d0
		beq	getpwfield_colon

		cmp.b	#CR,d0
		beq	getpwfield_cr

		cmp.b	#LF,d0
		beq	getpwfield_lf

		bsr	getpwfield_flush_cr
		bne	getpwfield_return

		bsr	getpwfield_insert
		bne	getpwfield_return

		bra	getpwfield_loop

getpwfield_cr:
		bsr	getpwfield_flush_cr
		bne	getpwfield_return

		st	d4
		bra	getpwfield_loop

getpwfield_colon:
		cmp.b	d0,d3
		bne	getpwfield_error

		bsr	getpwfield_flush_cr
		bne	getpwfield_return

		bra	getpwfield_done

getpwfield_lf:
		cmp.b	d0,d3
		bne	getpwfield_error
getpwfield_done:
		clr.b	(a1)
getpwfield_success:
		moveq	#0,d0
getpwfield_return:
		rts

getpwfield_error:
		moveq	#1,d0
		rts

getpwfield_flush_cr:
		tst.b	d4
		beq	getpwfield_flush_cr_done

		subq.w	#1,d1
		bcs	getpwfield_error

		move.b	#CR,(a1)+
getpwfield_flush_cr_done:
		moveq	#0,d4
		rts

getpwfield_insert:
		subq.w	#1,d1
		bcs	getpwfield_error

		move.b	d0,(a1)+
getpwfield_insert_done:
		moveq	#0,d0
		rts


getpwid:
		moveq	#0,d4
		moveq	#0,d1
getpwid_loop:
		move.w	d2,d0
		jsr	fgetc
		bmi	getpwfield_return

		cmp.b	d3,d0
		beq	getpwid_done

		sub.b	#'0',d0
		blo	getpwfield_error

		cmp.b	#9,d0
		bhi	getpwfield_error

		moveq	#0,d5
		move.b	d0,d5
		mulu	#10,d4
		add.l	d5,d4
		cmp.l	#32767,d4
		bhi	getpwfield_error

		addq.w	#1,d1
		bra	getpwid_loop

getpwid_done:
		tst.w	d1
		beq	getpwfield_error

		move.w	d4,(a1)
		bra	getpwfield_success

.end
