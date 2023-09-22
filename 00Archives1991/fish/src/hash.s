* hash.s
* Itagaki Fumihiko 19-Nov-90  Create.

.include doscall.h
.include ../src/fish.h

.xref toupper
.xref mulul
.xref hash_table
.xref word_path
.xref find_shellvar
.xref for1str
.xref is_builtin_dir
.xref isabsolute
.xref dos_allfile
.xref cat_pathname
.xref test_drive_path
.xref command_table
.xref too_many_args
.xref hash_flag
.xref puts
.xref hash_hits
.xref printu
.xref hash_misses
.xref divul
.xref nputs

.text

****************************************************************
* hash - filename hash function
*
* CALL
*      A0     filename
*
* RETURN
*      D0.L   key
****************************************************************
.xdef hash

hash:
		movem.l	d1-d4/a0,-(a7)
		moveq	#0,d2			* D2 : hashval
		move.l	#4999,d3		* D3 : base
		move.w	#7,d4			* 8文字まで
hash_loop:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq	hash_done

		cmp.b	#'.',d0
		beq	hash_done

		*  hashval += ch * base;

		move.l	d3,d1
		bsr	toupper
		bsr	mulul
		add.l	d0,d2

		*  base = base * 2017 + 1;

		move.l	d3,d0
		move.l	#2017,d1
		bsr	mulul
		move.l	d0,d3

		dbra	d4,hash_loop
hash_done:
		move.l	d2,d0
		and.l	#$3ff,d0
		movem.l	(a7)+,d1-d4/a0
		rts
****************************************************************
* rehash
*
* CALL
*      none
*
* RETURN
*      none
****************************************************************
.xdef rehash

searchnamebuf = -(((MAXWORDLEN+4+1)+1)>>1<<1)
files_buf = searchnamebuf-(((53)+1)>>1<<1)

rehash:
		link	a6,#files_buf
		movem.l	d0-d2/a0-a4,-(a7)
	*
	*  ハッシュ表をクリアする
	*
		lea	hash_table,a4
		move.w	#1023,d0
rehash_clear_loop:
		clr.b	(a4,d0.w)
		dbra	d0,rehash_clear_loop
	*
	*  シェル変数 path の各要素が示すディレクトリの内容をハッシュする
	*
		lea	word_path,a0
		bsr	find_shellvar
		beq	rehash_done

		addq.l	#2,a0
		move.w	(a0)+,d1			* D1.W : $#path
		bsr	for1str
		movea.l	a0,a1				* A1 : $path ポインタ
		moveq	#0,d2				* D2.B : インデックス
		bra	rehash_start

rehash_loop:
		movea.l	a1,a0
		bsr	is_builtin_dir
		beq	rehash_builtin

		bsr	isabsolute
		bne	rehash_next
****************
rehash_real_directory:
		lea	searchnamebuf(a6),a0
		lea	dos_allfile,a2
		bsr	cat_pathname
		bmi	rehash_continue

		bsr	test_drive_path
		bne	rehash_continue

		movea.l	a1,a3

		move.w	#$37,-(a7)		* ボリューム・ラベル以外
		move.l	a0,-(a7)
		pea	files_buf(a6)
		DOS	_FILES
		lea	10(a7),a7
rehash_real_directory_loop:
		tst.l	d0
		bmi	rehash_real_directory_done

		lea	files_buf+30(a6),a0
		bsr	hash
		bset.b	d2,(a4,d0.l)
		pea	files_buf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		bra	rehash_real_directory_loop

rehash_real_directory_done:
		movea.l	a3,a1
		bra	rehash_continue
****************
rehash_builtin:
		lea	command_table,a0
rehash_builtin_loop:
		tst.b	(a0)
		beq	rehash_next

		bsr	hash
		bset.b	d2,(a4,d0.l)
		lea	14(a0),a0
		bra	rehash_builtin_loop
****************
rehash_next:
		movea.l	a1,a0
		bsr	for1str
		movea.l	a0,a1
rehash_continue:
		addq.w	#1,d2
rehash_start:
		dbra	d1,rehash_loop
rehash_done:
		movem.l	(a7)+,d0-d2/a0-a4
		unlk	a6
		move.b	#1,hash_flag
		rts
****************************************************************
.xdef cmd_rehash

cmd_rehash:
		tst.w	d0
		bne	too_many_args

		bsr	rehash
		moveq	#0,d0
		rts
****************************************************************
.xdef cmd_unhash

cmd_unhash:
		tst.w	d0
		bne	too_many_args

		clr.b	hash_flag
		moveq	#0,d0
		rts
****************************************************************
.xdef cmd_hashstat

cmd_hashstat:
		tst.w	d0
		bne	too_many_args

		moveq	#1,d2
		lea	puts(pc),a1
		lea	msg_hits,a0
		bsr	puts
		move.l	hash_hits,d0
		bsr	printu
		lea	msg_misses,a0
		bsr	puts
		move.l	hash_misses,d0
		bsr	printu
		lea	msg_ratio,a0
		bsr	puts

		move.l	hash_hits,d0
		beq	cmd_hashstat_2

		move.l	#100,d1
		bsr	mulul
		move.l	hash_hits,d1
		add.l	hash_misses,d1
		bsr	divul
cmd_hashstat_2:
		bsr	printu
		lea	msg_percent,a0
		bsr	nputs
cmd_hashstat_done:
		moveq	#0,d0
		rts
****************************************************************
.data

msg_hits:	dc.b	'ヒット ',0
msg_misses:	dc.b	'回, ミス ',0
msg_ratio:	dc.b	'回, ヒット率 ',0
msg_percent:	dc.b	'%',0

.end
