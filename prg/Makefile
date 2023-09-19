#! A:/bin/MAKE.X -f
#  Makefile for fish.x

#AS	= \bin\AS.X -i $(INCLUDE)
AS	= \usr\pds\HAS.X -l -i $(INCLUDE)
#LK	= \bin\LK.X -p -i
LK	= \usr\pds\hlk.x -p ${@|basename}.map
LIB	= \bin\LIB.X
BIND	= \bin\BIND.X
INSTALL = copy
STRIP   = A:\usr\pds\strip.x
TOUCH   = A:\bin\TOUCH.X
CP      = copy
RM      = -\usr\local\bin\rm -f

LKFLAG_STRIP = -x

VPATH   = ../src
INCLUDE = ../include
EXTLIBS = ../lib/ita.l ../extlib/Extmalloc.a

###

FILES	= main.o state.l builtin1.l builtin2.l subst.l var.l misc.l string.l dir_io.l

OBJS_BUILTIN1 = b_alias.o b_alloc.o b_bind.o b_dirs.o b_echo.o b_eval.o \
                b_exit.o b_glob.o b_goto.o b_history.o b_logout.o \
                b_printf.o b_repeat.o b_return.o b_setenv.o

OBJS_BUILTIN2 = b_set.o b_shift.o b_source.o b_srand.o b_time.o b_unset.o \
                b_unsetenv.o b_which.o

OBJS_MISC     = chkwild.o echo.o error.o expr.o file.o f_getenv.o \
                getcwdx.o getline.o malloc.o misc.o hash.o passwd.o quote.o \
                skippar.o tmpfile.o wordlist.o

OBJS_SUBST    = enterhis.o expwords.o glob.o modify.o substali.o substcom.o \
                substhis.o substvar.o unpack.o

OBJS_VAR      = var.o f_setenv.o flagvar.o setsvar.o svartou.o

OBJS_STATE    = ifthen.o switchcase.o foreach.o function.o

OBJS_STRING   = qstrchr.o scanch2.o skipvnam.o jstrchr.o strpcmp.o

OBJS_DIR_IO   = pathname.o stat.o

###

.PHONY : all install backup clean clobber

.TERMINAL : *.h *.s

%.o : %.s ; $(AS) $<

###

all:: fish.x

install::

backup::

clean::

clobber::
	$(RM) *.x *.l *.o *.map *.bak

###

fish.x: fishing.x fishbody.x
	$(BIND) -O $@ fishing.x fishbody.x /A+SHR

install::
	$(INSTALL) fish.x $(DESTDIR)

clean::
	$(RM) fish.x
###

fishing.x: fish_loader.o
	$(LK) $(LKFLAG_STRIP) -o $@ $<

clean::
	$(RM) fishing.x fishing.map

###

fishbody.x: fishg.x
	$(CP) fishg.x $@
	$(TOUCH) $@
	$(STRIP) $@

clean::
	$(RM) fishbody.x

###

fishg.x: $(FILES) $(EXTLIBS)
	$(LK) -o $@ $(FILES) $(EXTLIBS)
	grep bsssize fishg.map

clean::
	$(RM) fishg.x fishg.map

#
fish_loader.o main.o b_ctty.o b_dirs.o b_eval.o b_source.o b_srand.o \
expr.o getline.o glob.o ifthen.o malloc.o modify.o substcom.o substhis.o \
substvar.o switchcase.o unpack.o wordlist.o : fish.h

main.o b_set.o b_unset.o b_setenv.o b_unsetenv.o f_getenv.o f_setenv.o var.o : var.h

main.o foreach.o getline.o b_goto.o substvar.o : source.h

main.o function.o : function.h

main.o function.o enterhis.o substhis.o b_history.o getline.o : history.h

main.o foreach.o b_goto.o : loop.h

modify.o substhis.o substvar.o : modify.h

b_alloc.o : extmalloc.h

clean::
	$(RM) *.o
#

misc.l     : $(OBJS_MISC)
subst.l    : $(OBJS_SUBST)
var.l      : $(OBJS_VAR)
state.l    : $(OBJS_STATE)
builtin1.l : $(OBJS_BUILTIN1)
builtin2.l : $(OBJS_BUILTIN2)
string.l   : $(OBJS_STRING)
dir_io.l   : $(OBJS_DIR_IO)

misc.l subst.l var.l state.l builtin1.l builtin2.l string.l dir_io.l :
	$(LIB) $@ $?

clean::
	$(RM) *.l

###
