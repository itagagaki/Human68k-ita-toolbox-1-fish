#! MAKE -f
#  Makefile for itash.x

#AS	= \bin\AS.X -i $(INCLUDE) # -d
#LK	= \bin\LK.X -p -i # -x
AS	= \usr\pds\HAS.X -i $(INCLUDE) # -d
LK	= \usr\pds\hlk.x -p ${@|basename}.map # -x
LIB	= \bin\LIB.X
BIND	= \bin\BIND.X

VPATH   = ../src
INCLUDE = ../include
EXTLIBS = ../lib/fish/fish.l ../lib/italib/ita.l
DESTDIR = \usr\local\bin
BACKUPDIR = B:\fish


###

LOADER	= cmd.o

FILES	= commando.o misc.l subst.l var.l state.l builtin1.l builtin2.l \
          stdlib.l string.l fctype.l dir_io.l

OBJS_MISC     = chdirx.o chkwild.o echo.o error.o expr.o file.o getline.o \
                goods.o hash.o passwd.o printu.o quote.o skippar.o \
                tmpfile.o wordlist.o

OBJS_SUBST    = enterhis.o expwords.o glob.o modify.o substali.o substcom.o \
                substhis.o substvar.o unpack.o

OBJS_VAR      = evalvar.o findvar.o flagvar.o printvar.o setvar.o setenv.o \
                setsvar.o svartou.o unsetvar.o

OBJS_STATE    = ifthen.o

OBJS_BUILTIN1 = cmdalias.o cmdcopy.o cmdctty.o cmddel.o cmddir.o cmddirs.o \
                cmdecho.o cmdeval.o cmdexit.o cmdglob.o cmdgoto.o cmdhis.o \
                cmdmd.o cmdrd.o cmdren.o cmdrept.o cmdsenv.o

OBJS_BUILTIN2 = cmdset.o cmdshift.o cmdsource.o cmdtime.o cmdtype.o \
                cmdunset.o cmdusenv.o cmdwhich.o

OBJS_STDLIB   = atou.o getenv.o itoa.o irandom.o muldiv.o utoa.o

OBJS_STRING   = _strchr.o findspc.o qstrchr.o scanch2.o skipspc.o \
                skipvnam.o strbot.o strchr.o strcmp.o strcpy.o strechr.o \
                stricmp.o strlen.o strmem.o strpcmp.o

OBJS_FCTYPE   = isalpha.o iscsym.o iscsymf.o isdigit.o islower.o issjis.o \
                isspace.o isupper.o

OBJS_DIR_IO   = chdir.o getcwd.o isatty.o pathname.o tstdrive.o stat.o

###

.PHONY : backup clean cleangarbage

.TERMINAL : *.h *.s

%.o : %.s ; $(AS) $<

###

itash.x : cmd.x commando.x
	$(BIND) -O itash.x cmd.x commando.x /A+SHR

###

cmd.x : $(LOADER)
	$(LK) $(LOADER)

###

commando.x : $(FILES)
	$(LK) $(FILES) $(EXTLIBS)
#
cmdcopy.o cmdctty.o cmddel.o cmddir.o cmddirs.o cmdeval.o cmdren.o cmdsource.o \
cmdtype.o commando.o expr.o getline.o glob.o goods.o hash.o modify.o quote.o \
substcom.o substhis.o substvar.o unpack.o wordlist.o : fish.h

commando.o getline.o cmdgoto.o : source.h

modify.o substhis.o substvar.o : modify.h

commando.o irandom.o : random.h

misc.l     : $(OBJS_MISC)
subst.l    : $(OBJS_SUBST)
var.l      : $(OBJS_VAR)
state.l    : $(OBJS_STATE)
builtin1.l : $(OBJS_BUILTIN1)
builtin2.l : $(OBJS_BUILTIN2)
stdlib.l   : $(OBJS_STDLIB)
string.l   : $(OBJS_STRING)
fctype.l   : $(OBJS_FCTYPE)
dir_io.l   : $(OBJS_DIR_IO)

misc.l subst.l var.l state.l builtin1.l builtin2.l \
stdlib.l string.l fctype.l dir_io.l :
	$(LIB) $@ $?

###

install :
	copy itash.x $(DESTDIR)
	copy commando.x $(DESTDIR)

backup :
	copyall -t Makefile $(BACKUPDIR)\prg
	copyall -t itash.x $(BACKUPDIR)\prg
	copyall -t commando.x $(BACKUPDIR)\prg
	copyall -t ..\src\*.* $(BACKUPDIR)\src
	copyall -t ..\lib\*.* $(BACKUPDIR)\lib
	copyall -t ..\doc\*.* $(BACKUPDIR)\doc

clean :
	-rm -f *.x *.l *.o

cleangarbage :
	-rm -f *.bak
