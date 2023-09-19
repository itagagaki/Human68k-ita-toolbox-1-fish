LDLIBES = Extmalloc.a

OBJECTS = alloc.o large.o free.o enlarge.o shrink.o previous.o dump.o c.o

all : Extmalloc.a

$(OBJECTS) : %.o : %.s defines.inc
	has $*

$(LDLIBES) : $(OBJECTS)
	har $@ $?
