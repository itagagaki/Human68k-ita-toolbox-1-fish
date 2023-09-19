#! A:/bin/MAKE.X -f
#  Makefile for italib.l

AS	= \usr\pds\HAS.X -l -i $(INCLUDE)
LIB	= \bin\LIB.X
RM      = -\usr\local\bin\rm -f

INCLUDE = ../include

OBJS = \
	DecHUPAIR.o EncHUPAIR.o atou.o bsltosl.o catpath.o chdir.o \
	contwild.o cryptch.o decpass.o divul.o drvchk.o encpass.o \
	fclose.o fgetc.o fgetpwent.o fgetpwnam.o getcwd.o getenv.o \
	getpass.o headtail.o irandom.o isalnum.o isalpha.o isatty.o \
	iscntrl.o iscsym.o isdigit.o isfullpath.o islower.o isspace.o \
	issjis.o isupper.o itoa.o memmovd.o memmovi.o memset.o \
	minmaxul.o muldivsl.o mulul.o printfi.o printfs.o remove.o \
	reverse.o rotate.o setenv.o skipspc.o sltobsl.o stpcpy.o \
	strazbot.o strazcpy.o strbot.o strchr.o strcmp.o strcpy.o \
	strfor1.o strforn.o strlen.o strmove.o strspc.o tfopen.o \
	tolower.o toupper.o

define newline

endef

###

.PHONY : all install backup clean clobber

%.o : %.s
	$(AS) $<

###

all:: ita.l

clobber::
	$(RM) *.l *.o *.bak

###

ita.l: $(OBJS)
	@echo $@>@files
	$(foreach i,$?,@echo $i>>@files$(newline))
	$(LIB) -i @files
	@$(RM) @files

clean::
	$(RM) ita.l

###
