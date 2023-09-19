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
.xref flag_noalias
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
		movem.l	d1/a1-a2,-(a7)
		lea	flagvar_table,a2
		moveq	#0,d1
flagvar_findloop:
		move.l	(a2)+,d0
		beq	flagvar_nomatch

		move.w	(a2)+,d1
		movea.l	d0,a1
		bsr	strcmp
		blo	flagvar_nomatch
		bhi	flagvar_findloop

		add.l	a5,d1
		move.l	d1,d0
		bra	flagvarptr_return

flagvar_nomatch:
		moveq	#0,d0
flagvarptr_return:
		movem.l	(a7)+,d1/a1-a2
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
		tst.l	(a0)
		beq	clear_flagvars_done

		addq.l	#4,a0
		move.w	(a0)+,d0
		clr.b	(a5,d0.w)
		bra	clear_flagvars_loop

clear_flagvars_done:
		movea.l	(a7)+,a0
		rts
****************************************************************
.data

.xdef word_glob
.xdef word_echo
.xdef word_nomatch
.xdef word_exact
.xdef word_verbose

.even
flagvar_table:
		dc.l	word_ampm
		dc.w	flag_ampm

		dc.l	word_autolist
		dc.w	flag_autolist

		dc.l	word_cifilec
		dc.w	flag_cifilec

		dc.l	word_ciglob
		dc.w	flag_ciglob

		dc.l	word_echo
		dc.w	flag_echo

		dc.l	word_forceio
		dc.w	flag_forceio

		dc.l	word_ignoreeof
		dc.w	flag_ignoreeof

		dc.l	word_noalias
		dc.w	flag_noalias

		dc.l	word_nobeep
		dc.w	flag_nobeep

		dc.l	word_noclobber
		dc.w	flag_noclobber

		dc.l	word_noglob
		dc.w	flag_noglob

		dc.l	word_nonomatch
		dc.w	flag_nonomatch

		dc.l	word_recexact
		dc.w	flag_recexact

		dc.l	word_usegets
		dc.w	flag_usegets

		dc.l	word_verbose
		dc.w	flag_verbose

		dc.l	0

word_ampm:		dc.b	'ampm',0
word_autolist:		dc.b	'autolist',0
word_ciglob:		dc.b	'ciglob',0
word_cifilec:		dc.b	'cifilec',0
word_echo:		dc.b	'echo',0
word_forceio:		dc.b	'forceio',0
word_ignoreeof:		dc.b	'ignoreeof',0
word_noalias:		dc.b	'noalias',0
word_nobeep:		dc.b	'nobeep',0
word_noclobber:		dc.b	'noclobber',0
word_noglob:		dc.b	'no'
word_glob:		dc.b	'glob',0
word_nonomatch:		dc.b	'no'
word_nomatch:		dc.b	'nomatch',0
word_recexact:		dc.b	'rec'
word_exact:		dc.b	'exact',0
word_usegets:		dc.b	'usegets',0
word_verbose:		dc.b	'verbose',0
****************************************************************

.end
