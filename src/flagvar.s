* flagvar.s
* Itagaki Fumihiko 28-Feb-91  Create.

.xref strcmp

.xref flag_autolist
.xref flag_ampm
.xref flag_ciglob
.xref flag_cifilec
.xref flag_echo
.xref flag_forceio
.xref flag_ignoreeof
.xref flag_nobeep
.xref flag_noclobber
.xref flag_noglob
.xref flag_nonomatch
.xref flag_recexact
.xref flag_usegets
.xref flag_verbose

.text

****************************************************************
* flagvarptr  フラグ変数名かどうかを調べ、もしそうならばフラグ・データ・アドレスを返す
*
* CALL
*      A0     変数名
*
* RETURN
*      D0.L   フラグ・データ・アドレス
*             フラグ変数名でなければ 0
*
*      CCR    TST.L D0
****************************************************************
.xdef flagvarptr

flagvarptr:
		move.l	a1,-(a7)
		lea	flagvar_table,a1
flagvar_findloop:
		tst.b	(a1)
		beq	flagvar_nomatch

		bsr	strcmp
		beq	flagvar_matched
		blo	flagvar_nomatch

		lea	12(a1),a1
		bra	flagvar_findloop

flagvar_matched:
		moveq	#0,d0
		move.w	10(a1),d0
		add.l	a5,d0
		bra	flagvarptr_return

flagvar_nomatch:
		moveq	#0,d0
flagvarptr_return:
		movea.l	(a7)+,a1
		rts
****************************************************************
* clear_flagvars  フラグ変数で制御されるフラグをすべてクリアする
*
* CALL
*      none
*
* RETURN
*      none
****************************************************************
.xdef clear_flagvars

clear_flagvars:
		move.l	a0,-(a7)
		lea	flagvar_table,a0
clear_flagvars_loop:
		tst.b	(a0)
		beq	clear_flagvars_done

		lea	10(a0),a0
		move.w	(a0)+,d0
		clr.b	(a5,d0.w)
		bra	clear_flagvars_loop

clear_flagvars_done:
		movea.l	(a7)+,a0
		rts
****************************************************************
.data

.xdef word_echo
.xdef word_nomatch
.xdef word_verbose

.even
flagvar_table:
		dc.b	'ampm',0,0,0,0,0,0
		dc.w	flag_ampm

		dc.b	'autolist',0,0
		dc.w	flag_autolist

		dc.b	'ciglob',0,0,0,0
		dc.w	flag_ciglob

		dc.b	'cifilec',0,0,0
		dc.w	flag_cifilec

word_echo:	dc.b	'echo',0,0,0,0,0,0
		dc.w	flag_echo

		dc.b	'forceio',0,0,0
		dc.w	flag_forceio

		dc.b	'ignoreeof',0
		dc.w	flag_ignoreeof

		dc.b	'nobeep',0,0,0,0
		dc.w	flag_nobeep

		dc.b	'noclobber',0
		dc.w	flag_noclobber

		dc.b	'noglob',0,0,0,0
		dc.w	flag_noglob

		dc.b	'no'
word_nomatch:	dc.b	'nomatch',0
		dc.w	flag_nonomatch

		dc.b	'recexact',0,0
		dc.w	flag_recexact

		dc.b	'usegets',0,0,0
		dc.w	flag_usegets

word_verbose:	dc.b	'verbose',0,0,0
		dc.w	flag_verbose

		dc.b	0
****************************************************************

.end
