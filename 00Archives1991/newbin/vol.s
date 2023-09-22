*****************************************************************
*								*
*	volume name command					*
*								*
*	VOL [<drive>:]						*
*       VOL -c [<drive>:]					*
*       VOL -s [<drive>:]<name>					*
*								*
*****************************************************************

.include doscall.h
.include chrcode.h
.include filemode.h

.text

cmd_vol:
		move.b	(a2)+,d2			* A2はパラメータ。D2はその長さ
	**
	**  スイッチの解釈
	**
		clr.b	d3				* D3は -cフラグ。リセットしておく
		clr.b	d4				* D4は -sフラグ。リセットしておく
		bsr	skip_space
		beq	nomore_sw

		cmpi.b	#'-',(a2)
		bne	nomore_sw

		cmp.b	#2,d2
		blo	arg_error			* Bad switch arg.

		move.b	1(a2),d0
		cmp.b	#'s',d0
		beq	sw_set

		cmp.b	#'c',d0
		bne	arg_error			* Unknown switch.
sw_clr:
		moveq	#1,d3				* -cフラグをセットする
		bra	sw_ok
sw_set:
		moveq	#1,d4				* -sフラグをセットする
sw_ok:
		addq.l	#2,a2
		subq.b	#2,d2
		beq	nomore_sw

		movea.l	a2,a0
		bsr	skip_space
		cmpa.l	a0,a2
		beq	arg_error			* Bad switch arg.
nomore_sw:
	**
	**  引数の数のチェック
	**  D1.B には次の語の長さがセットされる
	**
		movea.l	a2,a0				* 語の先頭アドレスを A0 にセーブ
		clr.b	d1				* D1は語の長さ
find_tail:
		movea.l	a2,a3
		bsr	skip_space
		beq	tail_ok

		cmpa.l	a3,a2
		bne	arg_error			* 語の後ろに更に引数がある

		addq.b	#1,d1
		addq.l	#1,a2
		subq.b	#1,d2
		bne	find_tail
tail_ok:
		**	ここまで来れば、もう A2/D2 は要らない。
		**	A0/D1 が 引数である。
	**
	**  <drive>: を調べる
	**  もしあれば、大文字にして D5.W にセットする
	**  なければ D5.W は 0 とする
	**
		clr.w	d5				* D5は指定ドライブ名。0 としておく
		cmp.b	#2,d1
		blo	drivename_skipped

		cmpi.b	#':',1(a0)
		bne	drivename_skipped

		move.b	(a0),d0
		cmp.b	#'a',d0
		bcs	tou_e

		cmp.b	#'z',d0
		bhi	tou_e

		sub.b	#$20,d0
tou_e:
		cmp.b	#'A',d0
		blo	drive_error			* Bad drive name

		move.b	d0,d5				* D5に指定のドライブ名をセット
		addq.l	#2,a0
		subq.b	#2,d1

drivename_skipped:
	**
	**  <name>を調べる
	**
		tst.b	d1
		bne	name_specified

		*
		*  <name>は無い
		*
		tst.b	d4				* -s のときには
		bne	arg_error			* こいつはエラーだ

		bra	arg_ok

name_specified:
		*  <name>がある
		*
		tst.b	d4				* -s でなければ
		beq	arg_error			* こいつはエラーだ

		cmp.b	#21,d1
		bhi	vol_errn			* <name> が長過ぎる
		*
		*  <name> を、正当性をチェックしながら new_volume_label にセットする
		*  19 文字めの前には . を付加する
		*
		lea	new_volume_label+3(pc),a1
		clr.b	d2				* D2は文字数カウンタ
make_volume_name_loop_0:
		clr.b	d7				* D3は漢字カウンタ
make_volume_name_loop:
		tst.b	d1
		beq	make_volume_name_done

		cmp.b	#18,d2
		bne	make_volume_name_1

		move.b	#'.',(a1)+
make_volume_name_1:
		subq.b	#1,d1
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		addq.b	#1,d2
		cmp.b	#':',d0
		beq	vol_errn			* 不正な文字

		cmp.b	#'.',d0
		beq	vol_errn			* 不正な文字

		cmp.b	#'*',d0
		beq	vol_errn			* 不正な文字

		cmp.b	#'?',d0
		beq	vol_errn			* 不正な文字

		cmp.b	#'/',d0
		beq	vol_errn			* 不正な文字

		cmp.b	#'\',d0
		beq	vol_errn			* 不正な文字

		tst.b	d7
		bne	make_volume_name_loop_0

		cmp.b	#$80,d0
		blo	make_volume_name_loop

		cmp.b	#$a0,d0
		blo	make_volume_name_2Bcode

		cmp.b	#$e0,d0
		blo	make_volume_name_loop
make_volume_name_2Bcode:
		cmp.b	#18,d2
		beq	vol_errn			* 漢字が主部と拡張子に跨っている

		cmp.b	#21,d2
		beq	vol_errn			* 漢字が末尾をはみでている

		move.b	#1,d7
		bra	make_volume_name_loop

make_volume_name_done:
		clr.b	(a1)				* コピー完了

arg_ok:
	**
	**  対象ドライブを決める
	**
		DOS	_CURDRV
		tst.w	d5
		beq	for_current_drive

		move.w	d0,d1		* 上の _CURDRV の値
		move.w	d5,d2
		sub.b	#'A',d2
		move.w	d2,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		cmp.w	d2,d0
		bls	drive_error			* Bad specified drivename.

		move.w	d1,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		bra	drive_ok

for_current_drive:
		add.b	#'A',d0
		move.b	d0,d5
drive_ok:
		lea	findbuf(pc),a0				* どの場合にも使われる
		bsr	set_drive_name
		move.b	#'*',(a0)+
		move.b	#'.',(a0)+
		move.b	#'*',(a0)+
		clr.b	(a0)

		lea	delete_name_buf(pc),a0			* erase と change で使われる
		bsr	set_drive_name

		tst.b	d4					* -s
		bne	change_volume

		tst.b	d3					* -c
		bne	erase_volume
********************************
show_volume:
		pea	msg_volume1(pc)
		DOS	_PRINT
		move.w	d5,-(a7)
		DOS	_PUTCHAR
		pea	msg_volume2(pc)
		DOS	_PRINT
		lea	10(a7),a7

		bsr	find_volume
		bmi	show_volume_none

		bsr	put_a_space
		lea	filebuf_packedname(pc),a0
		move.w	#22,d1
		subq.l	#2,a7
		moveq	#0,d0
vol_prlp:
		tst.w	d1
		beq	vol_p2

		move.b	(a0)+,d0
		beq	vol_pr1

		cmp.b	#'.',d0
		beq	vol_prx

		move.w	d0,(a7)
		DOS	_PUTCHAR
vol_prx:
		dbra	d1,vol_prlp

vol_pr0:
		bsr	put_a_space
vol_pr1:
		dbra	d1,vol_pr0
vol_p2:
		addq.l	#2,a7
		pea	msg_datetime3(pc)
		bra	show_volume_done

show_volume_none:
		pea	msg_novolume(pc)
show_volume_done:
		DOS	_PRINT
		addq.l	#4,a7
		bra	vol_exit
********************************
erase_volume:
		bsr	vol_clr_sub
		beq	vol_errf
		bmi	vol_errd1
		bra	vol_exit
********************************
change_volume:
		lea	new_volume_label(pc),a0
		bsr	set_drive_name
		*
		*  現ボリューム・ラベルを探してタイム・スタンプをD1に得る
		*
		clr.l	d1
		bsr	find_volume
		bmi	find_current_volume_done

		lea	filebuf_datime(pc),a0
		move.l	(a0),d1
		swap	d1
find_current_volume_done:
		*
		*  新ボリューム・ラベル名と同じ名前の
		*  ディレクトリ・エントリ（ボリューム・ラベルを除く）が
		*  無いことをチェックする
		*
		move.w	#$3f,-(a7)
		pea	new_volume_label(pc)
		pea	filebuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
find_same_name_entry:
		bmi	vol_change_2			* 無い

		btst.b	#FILEMODE_VOLUME,filebuf_atr(pc)
		beq	vol_errm			* ある！

		bsr	findnext
		bra	find_same_name_entry
vol_change_2:
		*
		*  新ボリュームラベル名と同じ名前の
		*  デバイスが無いことをチェックする
		*
		move.w	#2,-(a7)
		pea	new_volume_label(pc)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bpl	vol_errcm
		*
		*  現ボリューム・ラベルを削除する
		*
		bsr	vol_clr_sub
		bmi	vol_errd
		*
		*  新しいボリュームラベルを新規作成する
		*
		move.w	#8,-(a7)
		pea	new_volume_label(pc)
		DOS	_CREATE
		addq.l	#6,a7
		tst.l	d0
		bmi	vol_errm
		*
		*  新しいボリュームラベルのタイムスタンプを
		*  旧ボリュームラベル（もしあれば）に合わせる
		*
		move.l	d1,-(a7)	* D1 が 0 のときも、取得となるだけだから大丈夫
		move.w	d0,-(a7)
		DOS	_FILEDATE
		move.l	d0,d1
		move.w	(a7)+,d0
		addq.l	#4,a7
		swap	d1
		cmp.w	#$ffff,d1
		beq	vol_errcm

		move.w	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
		tst.l	d0
		bmi	vol_errm
vol_exit:
		clr.w	-(a7)
		DOS	_EXIT2
****************
vol_errcm:
		move.l	d0,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
vol_errm:
		lea	msg_volnomake(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
drive_error:
		lea	msg_drive_err(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
arg_error:
		lea	msg_bad_arg(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
vol_errd:
		lea	msg_volnodel(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
vol_errd1:
		lea	msg_volnodel1(pc),a0
		move.w	#$502,-(a7)
		bra	error_exit
vol_errn:
		lea	msg_volume_err(pc),a0
		move.w	#$500,-(a7)
		bra	error_exit
vol_errf:
		lea	msg_volnofound(pc),a0
		move.w	#$503,-(a7)
error_exit:
		movea.l	a0,a1
strlen_loop:
		tst.b	(a1)+
		bne	strlen_loop

		move.l	a1,d0
		subq.l	#1,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		DOS	_EXIT2
****************************************************************
set_drive_name:
		move.b	d5,(a0)+
		move.b	#':',(a0)+
		move.b	#'\',(a0)+
		rts
****************************************************************
vol_clr_sub:
		bsr	find_volume
		bmi	vol_clr_none
vol_clr_sub_1:
		btst.b	#FILEMODE_READONLY,filebuf_atr(pc)
		bne	vol_clr_rerr

		lea	delete_name_buf+3(pc),a0
		lea	filebuf_packedname(pc),a1
		move.w	#18+1+3+1-1,d0
set_delete_name:
		move.b	(a1)+,(a0)+
		dbra	d0,set_delete_name

		clr.w	-(a7)
		pea	delete_name_buf(pc)
		DOS	_CHMOD
		addq.l	#6,a7
		tst.l	d0
		bmi	vol_clr_err

		pea	delete_name_buf(pc)
		DOS	_DELETE
		addq.l	#4,a7
		tst.l	d0
		bmi	vol_clr_err

		bsr	findnext
		bpl	vol_clr_sub_1

		moveq	#1,d0
		rts

vol_clr_none:
		clr.l	d0
		rts

vol_clr_rerr:
		moveq	#-1,d0
vol_clr_err:
		rts
****************************************************************
find_volume:
		move.w	#$08,-(a7)
		pea	findbuf(pc)
		pea	filebuf(pc)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		rts
****************************************************************
findnext:
		pea	filebuf(pc)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		rts
****************************************************************
put_a_space:
		move.w	#' ',-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
****************************************************************
skip_space:
		tst.b	d2
		beq	skip_space_return

		cmpi.b	#' ',(a2)
		beq	skip_space_continue

		cmp.b	#HT,(a2)
		beq	skip_space_continue

		cmpi.b	#CR,(a2)
		beq	skip_space_continue

		cmpi.b	#LF,(a2)
		beq	skip_space_continue

		cmpi.b	#VT,(a2)
		bne	skip_space_return
skip_space_continue:
		addq.l	#1,a2
		subq.w	#1,d2
		bne	skip_space
skip_space_return:
		rts
****************************************************************
.data

msg_volume1:	dc.b	'ドライブ ',NUL
msg_volume2:	dc.b	': のボリュ－ムラベルは',NUL
msg_datetime3:	dc.b	' です',CR,LF,NUL
msg_novolume:	dc.b	'ありません',CR,LF,NUL
msg_volume_err:	dc.b	'ボリュ－ムラベルが無効です',CR,LF,NUL
msg_volnomake:	dc.b	'ボリュ－ムラベルが作れません',CR,LF,NUL
msg_drive_err:	dc.b	'ドライブ名が無効です',CR,LF,NUL
msg_bad_arg:	dc.b	'パラメ－タが無効です',CR,LF,NUL
msg_volnodel:	dc.b	'旧'
msg_volnodel1:	dc.b	'ボリュ－ムラベルが消去できません',CR,LF,NUL
msg_volnofound:	dc.b	'ボリュ－ムラベルが見つかりません',CR,LF,NUL

****************************************************************
.bss

filebuf:
filebuf_sys_atr:	ds.b	1		* 0
filebuf_sys_driveno:	ds.b	1		* 1
filebuf_sys_dircls:	ds.w	1		* 2
filebuf_sys_dirfat:	ds.w	1		* 4
filebuf_sys_dirsec:	ds.w	1		* 6
filebuf_sys_dirpos:	ds.w	1		* 8
filebuf_sys_filename:	ds.b	8		* 10
filebuf_sys_ext:	ds.b	3		* 18
filebuf_atr:		ds.b	1		* 21
filebuf_datime:
filebuf_time:		ds.w	1		* 22
filebuf_date:		ds.w	1		* 24
filebuf_filelen:	ds.l	1		* 26
filebuf_packedname:	ds.b	18+1+3+1	* 30

new_volume_label:	ds.b	26		* '?:\(18).(3)',0
findbuf:		ds.b	7		* '?:\*.*',0
delete_name_buf:	ds.b	26

.end cmd_vol
