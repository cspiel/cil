# Debugging. Set ECHO= to debug this Makefile 
ECHO = @

# USECCGR = 1
USEFRONTC = 1

# First stuff that makes the executable 
# Define the ARCHOS in your environemt : [x86_LINUX, x86_WIN32, SUNOS]

SOURCEDIRS  = src
OBJDIR      = obj
MLLS        = 
MLYS        = 
# ast clex cparse
MODULES     = pretty errormsg stats cil box
EXECUTABLE  = $(OBJDIR)/spec
CAMLUSEUNIX = 1
ifdef RELEASE
UNSAFE      = 1
endif
CAMLLIBS    = 

ifdef USECCGR
MLLS      += mllex.mll
MLYS      += cilparse.mly
MODULES   += mllex cilparse
PARSELIBS += ../parsgen/libccgr.a ../smbase/libsmbase.a \
             libstdc++-3-libc6.1-2-2.10.0.a
endif

ifdef USEFRONTC
SOURCEDIRS += src/frontc
MLLS       += clexer.mll
MLYS       += cparser.mly
MODULES    += cabs clexer cparser cprint cabs2cil frontc
endif

# Add main late
MODULES    += main
    # Include now the common set of rules for OCAML
include Makefile.ocaml



##### Settings that depend on the computer we are on
##### Make sure the COMPUTERNAME environment variable is set
ifeq ($(COMPUTERNAME), RAW)   # George's workstation
SAFECCDIR=C:/Necula/SafeC
PCCDIR=../../Source/Touchstone/PCC
endif
ifeq ($(COMPUTERNAME), FETA) # George's home machine
SAFECCDIR=D:/Necula/SafeC
PCCDIR=../../Source/Touchstone/PCC
endif



#####################3
.PHONY : spec
spec : $(EXECUTABLE)$(EXE)

export EXTRAARGS
export BOX
ifndef _GNUCC
_MSVC = 1			# Use the MSVC compiler by default
endif

ifdef BOX
SRCEXT=box
else
SRCEXT=cil
endif

ifdef _GNUCC
CCL=gcc -x c -O3 -Wall
DOOPT=-O3
CC=$(CC) -c
CONLY=-c
OUT=-o
EXEOUT=-o
DEF=-D
ASMONLY=-S -o 
CPPSTART=gcc -E %i -Dx86_WIN32 -D_GNUCC
CPPOUT=-o %o
CPP=$(CPPSTART) $(CPPOUT)
INC=-I
endif


ifdef _MSVC
CCL=cl /TC /O2 /Zi /MLd /I./lib /DEBUG
DOOPT=/O2
CC=$(CCL) /c
CONLY=/c
OUT=/Fo
EXEOUT=/Fe
DEF=/D
ASMONLY=/Fa
INC=/I
CPPSTART=cl /Dx86_WIN32 /D_MSVC /E /TC /I./lib /FI fixup.h /DBEFOREBOX
CPPOUT= %i >%o
CPP=$(CPPSTART) $(CPPOUT)
EXTRAARGS += -msvc
endif

ifdef BOX
CPPSTART += /FI safec.h
CCL += /FI safec.h
endif


SAFECC=perl $(SAFECCDIR)/cil/lib/safecc.pl --cabs --cil
ifdef BOX
SAFECC+= --box
endif
ifdef RELEASE
SAFECC+= --release
endif



####### Test with PCC sources
PCCTEST=test/PCC
ifdef RELEASE
PCCTYPE=RELEASE
SPJARG=
else
PCCTYPE=_DEBUG
SPJARG=--gory --save-temps=pccout
endif
ifdef _GNUCC
PCCCOMP=_GNUCC
else
PCCCOMP=_MSVC
endif

testpcc/% : $(PCCDIR)/src/%.c $(EXECUTABLE)$(EXE) 
	$(SAFECC) --keep=$(PCCTEST) $(DEF)x86_WIN32 $(DEF)$(PCCTYPE) $(CONLY) \
                  $(PCCDIR)/src/$*.c \
                  $(OUT)$(PCCTEST)/$(notdir $*).o

HASHTESTMAIN=test/small1/hashtest.c
hashtest: $(HASHTESTMAIN) $(EXECUTABLE)$(EXE)
	rm -f $(PCCTEST)/hashtest.exe
	$(SAFECC) --keep=$(PCCTEST) $(DEF)x86_WIN32 $(DEF)$(PCCTYPE) \
                 $(INC)$(PCCDIR)/src \
                 $(PCCDIR)/src/hash.c \
                 $(HASHTESTMAIN) \
                 $(EXEOUT)$(PCCTEST)/hashtest.exe
	$(PCCTEST)/hashtest.exe

RBTESTMAIN=test/small1/rbtest.c
rbtest: $(RBTESTMAIN) $(EXECUTABLE)$(EXE)
	rm -f $(PCCTEST)/hashtest.exe
	$(SAFECC) --keep=$(PCCTEST) $(DEF)x86_WIN32 $(DEF)$(PCCTYPE) \
                 $(INC)$(PCCDIR)/src \
                 $(PCCDIR)/src/redblack.c \
                 $(RBTESTMAIN) \
                 $(EXEOUT)$(PCCTEST)/rbtest.exe
	$(PCCTEST)/rbtest.exe

testallpcc: $(EXECUTABLE)$(EXE)
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.o
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.exe
	make -C $(PCCDIR) \
             CC="$(SAFECC) --keep=$(SAFECCDIR)/cil/test/PCC $(CONLY)" \
             USE_JAVA=1 USE_JUMPTABLE=1 TYPE=$(PCCTYPE) \
             COMPILER=$(PCCCOMP) \
	     defaulttarget

runpcc:
	cd $(PCCDIR)/../test; pwd; spj --gory $(SPJARG) arith/Fact.java

############ Small tests
SMALL1=test/small1
test/% : $(SMALL1)/%.c $(EXECUTABLE)$(EXE)
	$(SAFECC) $(SMALL1)/$*.c $(CONLY) $(DOOPT) $(ASMONLY)$(SMALL1)/$*.s


### Generic test
testfile/% : $(EXECUTABLE)$(EXE) %
	$(SAFECC) /TC $*

testdir/% : $(EXECUTABLE)$(EXE)
	make -C CC="perl safecc.pl" $*


################## Linux device drivers
testlinux/% : $(EXECUTABLE)$(EXE) test/linux/%.cpp
	$(SAFECC) -o test/linux/$*.o \
                  test/linux/$*.cpp 

testqp : testlinux/qpmouse
testserial: testlinux/generic_serial
