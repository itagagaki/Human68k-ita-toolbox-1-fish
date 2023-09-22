.text

		lea	msg_login(pc),a0
		bsr	puts
		lea	logname(pc),a0
		bsr	gets
		lea	msg_password(pc),a0
		bsr	puts
		lea	password(pc),a0
		bsr	getpass


.data

msg_login:	dc.b	'ログイン名: ',0
msg_password:	dc.b	'パスワード: ',0

.bss

logname:	ds.b	256
password:	ds.b	256

.end
