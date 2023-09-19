.include doscall.h
.include chrcode.h
.include limits.h
.include ../src/fish.h

ID_CHECK_LEN	equ	48

MCB_allocater	equ	$004
MCB_dirname	equ	$080
MCB_filename	equ	$0C4

CurrentMCB	equ	header_top-$100
CurrentPDB	equ	header_top-$0f0

Header_CodeP	equ	$100+(header_codeP-header_top)
Header_ID	equ	$100+(header_id-header_top)

.text
*****************************************************************
header_top:
header_dataP:	dc.l	0		* $f0(PDB) : 自分のデータのアドレス
header_codeP:	dc.l	0		* $f4(PDB) : 自分のコードのアドレス
header_stackP:	dc.l	0		* $f8(PDB) : 自分のスタックのアドレス
header_id:	dc.b	"FISH - Fumihiko Itagaki's shell - Version  0.7 ",0
*****************************************************************
		dc.b	'Copyright(C)1991-92 by Itagaki Fumihiko',0

.even
start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
	**
	**  OSバージョンをチェックする
	**
		DOS	_VERNUM
		cmp.w	#REQUIRED_OSVER,d0
		lea	msg_dos_error(pc),a4
		bcs	error
	**
	**  ルート・シェルを探す
	**
		lea	own_stack(pc),a7		*  スタックを自分の下に設定する
		clr.l	-(a7)
		DOS	_SUPER				*  スーパーバイザ・モードに切り換える
		move.l	d0,(a7)				*  前のSSPの値をセーブ
		lea	CurrentMCB(pc),a0		*  現プロセスのMCBポインタ
search_real_shell:
		move.l	MCB_allocater(a0),d0		*  このブロックを確保したプロセスのMCBポインタ
		beq	no_real_shell			*  親はいない

		move.l	d0,d1
		rol.l	#8,d1
		tst.b	d1
		bne	no_real_shell			*  親はいない

		movea.l	d0,a0
		lea	Header_ID(a0),a2
		lea	header_id(pc),a3
		move.w	#ID_CHECK_LEN-1,d0
idcheck_loop:
		cmpm.b	(a2)+,(a3)+
		dbne	d0,idcheck_loop
		bne	search_real_shell		*  シェルではない

		move.l	Header_CodeP(a0),d0
		beq	search_real_shell		*  ？？コードを指していない

		bra	search_real_shell_done		*  ルート・シェルが見つかった
							*  D0.L : プログラム・コードのアドレス

no_real_shell:
		moveq	#0,d0				*  ルート・シェルは見つからなかった
							*  D0.L : 0
search_real_shell_done:
		move.l	(a7),d1				*  D1.L = 前のSSPの値
		move.l	d0,(a7)				*  D0.L をセーブ
****************
* 正しくはこうする
*		movea.l	usp,a0
*		addq.l	#4,a0
*		movea.l	a0,usp
****************
		move.l	d1,-(a7)
		DOS	_SUPER				*  ユーザ・モードに戻す
****************
*上でやっていないからしない
*		addq.l	#4,sp
****************
	**
	**  スタック・ポインタを設定して
	**  現プロセスのメモリをスタックの大きさに切り詰める
	**
		movea.l	(a7)+,a2			*  A2 : ルート・シェルのコード・アドレス
		lea	header_id+STACKSIZE,a7		*  自分のスタックを設定する
		move.l	a7,header_stackP		*  $f8(PDB) に自分のスタックのアドレスをセット
		movea.l	a7,a1
		lea	CurrentPDB(pc),a0
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7

		cmpa.l	#0,a2
		bne	no_load_go
	**
	**  ルート・シェルはいない .. 自分がルート・シェルになる
	**
		*
		*  最大メモリを確保
		*
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		sub.l	#$81000000,d0
		move.l	d0,d1				*  D1.L : 確保量
		move.l	d1,(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	mem_error

		movea.l	d0,a2
		add.l	d1,d0				*  D0.L : 確保したブロックの次のアドレス
		*
		*  現コマンドのパス名をpathnameにセット
		*
		lea	pathname(pc),a0
		lea	CurrentMCB+MCB_dirname(pc),a1
		bsr	stpcpy
		lea	CurrentMCB+MCB_filename(pc),a1
		bsr	stpcpy
		*
		*  コードをロード
		*
		move.l	d0,-(a7)			*  bottom address
		move.l	a2,-(a7)			*  load address
		pea	pathname(pc)			*  load file name pointer
		or.b	#3,(a7)				*  load .X type file
		move.w	#$0103,-(a7)			*  function : load
		DOS	_EXEC
		lea	14(a7),a7
		tst.l	d0
		lea	msg_load_error(pc),a4
		bmi	error
		*
		*  メモリを切り詰める
		*
		move.l	4(a2),d0			*  4(texttop) : 切り詰める大きさ
		addq.l	#1,d0
		bclr	#0,d0
		move.l	d0,-(a7)
		move.l	a2,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7

		move.l	(a2),d0				*  0(texttop) : 子シェル毎のデータのアドレス
		bra	run

no_load_go:
	**
	**  ルート・シェルがいる .. データ退避領域のみを確保する
	**
		move.l	12(a2),-(a7)			*  12(texttop) : 子シェル毎のデータの大きさだけ
		DOS	_MALLOC				*  メモリを確保
		addq.l	#4,a7
		tst.l	d0
		bmi	mem_error
run:
	**
	**  実行開始
	**
		move.l	d0,header_dataP			*  $f0(PDB) に自分のデータのアドレスをセット
		move.l	a2,header_codeP			*  $f4(PDB) に自分のコードのアドレスをセット
		jmp	16(a2)
*****************************************************************
mem_error:
		lea	msg_mem_error(pc),a4
error:
		moveq	#0,d0
		move.b	(a4)+,d0
		move.l	d0,-(a7)
		move.l	a4,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.w	#1,-(a7)
		DOS	_EXIT2
for:
		bra	for
*****************************************************************
stpcpy:
		move.b	(a1)+,(a0)+
		bne	stpcpy

		subq.l	#1,a0
		rts

*****************************************************************
msg_mem_error:	dc.b	20,'メモリが足りません',CR,LF
msg_dos_error:	dc.b	40,'バージョン2.00以降のHuman68kが必要です',CR,LF
msg_load_error:	dc.b	38,'シェルの本体をロードできませんでした',CR,LF
*****************************************************************

*****************************************************************
.bss

.even
pathname:
		ds.b	MAXPATH+1
.even
		ds.b	40
own_stack:
*****************************************************************

.end start
