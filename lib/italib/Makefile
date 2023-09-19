#! A:/bin/MAKE.X -f
#  Makefile for italib.l

AS	= \usr\pds\HAS.X -l -i $(INCLUDE)
LIB	= \bin\LIB.X
RM      = -\usr\local\bin\rm -f

INCLUDE = ../../include

OBJS = DecHUPAIR.o EncHUPAIR.o atou.o divul.o drvchk.o fgetc.o getpass.o \
       headtail.o irandom.o isalnum.o isalpha.o isatty.o iscntrl.o iscsym.o \
       isdigit.o islower.o isspace.o issjis.o isupper.o itoa.o memmovd.o \
       memmovi.o memset.o minmaxul.o muldivsl.o mulul.o printfi.o printfs.o \
       remove.o reverse.o rotate.o skipspc.o strbot.o strcmp.o strlen.o \
       strspc.o tfopen.o tolower.o toupper.o

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