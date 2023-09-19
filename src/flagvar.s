* flagvar.s
* Itagaki Fumihiko 28-Feb-91  Create.

.xref strcmp

.xref flag_autolist
.xref flag_ciglob
.xref flag_cifilec
.xref flag_echo
.xref flag_execbit
.xref flag_forceio
.xref flag_ignoreeof
.xref flag_listexec
.xref flag_listlinks
.xref flag_noalias
.xref flag_nobeep
.xref flag_noclobber
.xref flag_noglob
.xref flag_nonullcommandc
.xref flag_printexitvalue
.xref flag_pushdsilent
.xref flag_recexact
.xref flag_reconlyexec
.xref flag_savedirs
.xref flag_symlinks
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
		movem.l	d1/a1-a3,-(a7)
		lea	flagvar_table,a2
		lea	words_top,a3
flagvar_findloop:
		move.w	(a2)+,d0
		bmi	flagvar_nomatch

		move.w	(a2)+,d1
		lea	(a3,d0.w),a1
		bsr	strcmp
		blo	flagvar_nomatch
		bhi	flagvar_findloop

		lea	(a5,d1.w),a1
		move.l	a1,d0
		bra	flagvarptr_return

flagvar_nomatch:
		moveq	#0,d0
flagvarptr_return:
		movem.l	(a7)+,d1/a1-a3
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
		tst.w	(a0)+
		bmi	clear_flagvars_done

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
.xdef word_exact
.xdef word_execbit
.xdef word_listexec
.xdef word_nomatch
.xdef word_nonomatch
.xdef word_symlinks
.xdef word_verbose

.even
flagvar_table:
		dc.w	word_autolist-words_top
		dc.w	flag_autolist

		dc.w	word_cifilec-words_top
		dc.w	flag_cifilec

		dc.w	word_ciglob-words_top
		dc.w	flag_ciglob

		dc.w	word_echo-words_top
		dc.w	flag_echo

		dc.w	word_execbit-words_top
		dc.w	flag_execbit

		dc.w	word_forceio-words_top
		dc.w	flag_forceio

		dc.w	word_ignoreeof-words_top
		dc.w	flag_ignoreeof

		dc.w	word_listexec-words_top
		dc.w	flag_listexec

		dc.w	word_listlinks-words_top
		dc.w	flag_listlinks

		dc.w	word_noalias-words_top
		dc.w	flag_noalias

		dc.w	word_nobeep-words_top
		dc.w	flag_nobeep

		dc.w	word_noclobber-words_top
		dc.w	flag_noclobber

		dc.w	word_noglob-words_top
		dc.w	flag_noglob

		dc.w	word_nonullcommandc-words_top
		dc.w	flag_nonullcommandc

		dc.w	word_printexitvalue-words_top
		dc.w	flag_printexitvalue

		dc.w	word_pushdsilent-words_top
		dc.w	flag_pushdsilent

		dc.w	word_recexact-words_top
		dc.w	flag_recexact

		dc.w	word_reconlyexec-words_top
		dc.w	flag_reconlyexec

		dc.w	word_savedirs-words_top
		dc.w	flag_savedirs

		dc.w	word_symlinks-words_top
		dc.w	flag_symlinks

		dc.w	word_usegets-words_top
		dc.w	flag_usegets

		dc.w	word_verbose-words_top
		dc.w	flag_verbose

		dc.w	-1

words_top:
word_autolist:		dc.b	'autolist',0
word_cifilec:		dc.b	'cifilec',0
word_ciglob:		dc.b	'ciglob',0
word_echo:		dc.b	'echo',0
word_execbit:		dc.b	'execbit',0
word_forceio:		dc.b	'forceio',0
word_ignoreeof:		dc.b	'ignoreeof',0
word_noalias:		dc.b	'noalias',0
word_nobeep:		dc.b	'nobeep',0
word_noclobber:		dc.b	'noclobber',0
word_noglob:		dc.b	'no'
word_glob:		dc.b	'glob',0
word_listexec:		dc.b	'listexec',0
word_listlinks:		dc.b	'listlinks',0
word_nonomatch:		dc.b	'no'
word_nomatch:		dc.b	'nomatch',0
word_nonullcommandc:	dc.b	'nonullcommandc',0
word_printexitvalue:	dc.b	'printexitvalue',0
word_pushdsilent:	dc.b	'pushdsilent',0
word_recexact:		dc.b	'rec'
word_exact:		dc.b	'exact',0
word_reconlyexec:	dc.b	'reconlyexec',0
word_savedirs:		dc.b	'savedirs',0
word_symlinks:		dc.b	'symlinks',0
word_usegets:		dc.b	'usegets',0
word_verbose:		dc.b	'verbose',0
****************************************************************

.end
