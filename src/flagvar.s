* flagvar.s
* Itagaki Fumihiko 28-Feb-91  Create.

.xref strcmp

.xref flag_ciglob
.xref flag_cifilec
.xref flag_echo
.xref flag_forceio
.xref flag_ignoreeof
.xref flag_nobeep
.xref flag_noclobber
.xref flag_noglob
.xref flag_nonomatch
*.xref flag_notify
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
loop:
		tst.b	(a1)
		beq	no_match

		bsr	strcmp
		beq	matched

		lea	12(a1),a1
		bra	loop

matched:
		moveq	#0,d0
		move.w	10(a1),d0
		add.l	a5,d0
		bra	flagvarptr_return

no_match:
		moveq	#0,d0
flagvarptr_return:
		movea.l	(a7)+,a1
		rts
****************************************************************
.data

.xdef word_echo
.xdef word_verbose

.even
flagvar_table:
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

		dc.b	'nonomatch',0
		dc.w	flag_nonomatch

*		dc.b	'notify',0,0,0,0
*		dc.w	flag_notify

		dc.b	'usegets',0,0,0
		dc.w	flag_usegets

word_verbose:	dc.b	'verbose',0,0,0
		dc.w	flag_verbose

		dc.b	0
****************************************************************

.end
