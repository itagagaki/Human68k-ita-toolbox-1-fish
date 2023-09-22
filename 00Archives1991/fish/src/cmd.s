.include doscall.h
.include chrcode.h
.include limits.h
.include ../src/fish.h

OSVER_1_50	equ	$100*1+50

CHECKLEN	equ	10

CurrentMCB	equ	top-$100

MCB_allocater	equ	$004
MCB_program	equ	$100+(prog_ptr-top)
MCB_name	equ	$100+(check_name-top)

.text
*****************************************************************
top:
data_ptr:	dc.l	0
prog_ptr:	dc.l	0
stack_ptr:	dc.l	0
check_name:	dc.b	'ItaShell1.0xx',0
*****************************************************************
.even
start:
	**
	**  OSバージョンをチェックする
	**
		DOS	_VERNUM
		cmp.w	#OSVER_1_50,d0
		lea	msg_dos_error(pc),a4
		bcs	error
	**
	**  ルート・シェルを探す
	**
		lea	own_stack(pc),a7	* スタックを自分の下に設定する
		clr.l	-(a7)
		DOS	_SUPER			* スーパーバイザー・モードに切り換える
		move.l	d0,(a7)			* 前のSSPの値をセーブ
		lea	CurrentMCB(pc),a0	* 現プロセスのMCBポインター
search_real_shell:
		move.l	MCB_allocater(a0),d0	* このブロックを確保したプロセスのMCBポインター
		beq	no_real_shell		* 親はいない

		move.l	d0,d1
		rol.l	#8,d1
		tst.b	d1
		bne	no_real_shell		* 親はいない

		movea.l	d0,a0
		lea	MCB_name(a0),a2
		lea	check_name(pc),a3
		move.w	#CHECKLEN-1,d0
idcheck_loop:
		cmpm.b	(a2)+,(a3)+
		dbne	d0,idcheck_loop
		bne	search_real_shell	* シェルではない

		move.l	MCB_program(a0),d0
		beq	search_real_shell	* ？？コードを指していない

		bra	search_real_shell_done	* ルート・シェルが見つかった
						* D0.L : プログラム・コードのアドレス

no_real_shell:
		moveq	#0,d0			* ルート・シェルは見つからなかった
						* D0.L : 0
search_real_shell_done:
		move.l	(a7),d1			* D1.L = 前のSSPの値
		move.l	d0,(a7)			* D0.L をセーブ
****************
* 正しくはこうする
*		movea.l	usp,a0
*		addq.l	#4,a0
*		movea.l	a0,usp
****************
		move.l	d1,-(a7)
		DOS	_SUPER			* ユーザー・モードに戻す
****************
*上でやっていないからしない
*		addq.l	#4,sp
****************
	**
	**  スタック・ポインターを設定して
	**  現プロセスのメモリーをスタックの大きさに切り詰める
	**
		movea.l	(a7)+,a2		* A2 : ルート・シェルのコード・アドレス
		lea	top+STACKSIZE,a7	* これはあまり良くないな
		move.l	a7,stack_ptr
		movea.l	a7,a1
		lea	top-240(pc),a0
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
		*  最大メモリーを確保
		*
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		sub.l	#$81000000,d0
		move.l	d0,d1			* D1.L : 確保量
		move.l	d1,(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	mem_error

		movea.l	d0,a2
		add.l	d1,d0			* D0.L : 確保したブロックの次のアドレス
		*
		*  現コマンドのパス名をpathnameにセット
		*
		lea	pathname(pc),a0
		lea	top-$80(pc),a1		* ディレクトリ部
		bsr	stpcpy
		lea	top-$3c(pc),a1		* ファイル名
		bsr	stpcpy
		*
		*  コードをロード
		*
		move.l	d0,-(a7)		* bottom address
		move.l	a2,-(a7)		* load address
		pea	pathname(pc)		* load file name pointer
		or.b	#3,(a7)			* load .X type file
		move.w	#$0103,-(a7)		* function : load
		DOS	_EXEC
		lea	14(a7),a7
		tst.l	d0
		lea	msg_load_error(pc),a4
		bmi	error
		*
		*  メモリーを切り詰める
		*
		move.l	a2,d0
		add.l	4(a2),d0
		addq.l	#1,d0
		bclr	#0,d0
		sub.l	a2,d0
		move.l	d0,-(a7)
		move.l	a2,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7

		move.l	(a2),d0
		bra	run

no_load_go:
	**
	**  ルート・シェルがいる .. データ退避領域のみを確保する
	**
		move.l	12(a2),-(a7)		* ルート・シェルのデータの大きさだけ
		DOS	_MALLOC			* メモリーを確保
		addq.l	#4,a7
		tst.l	d0
		bmi	mem_error

		move.l	d0,(a2)
run:
	**
	**  実行開始
	**
		move.l	d0,data_ptr
		move.l	a2,prog_ptr
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
msg_dos_error:	dc.b	43,'バージョン 2.0 以降の Human68k が必要です',CR,LF
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