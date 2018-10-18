# export LD_LIBRARY_PATH=

PHONY : all

TARGET_NAME ?= bin/MultiTaskApp

AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
CC	= $(CROSS_COMPILE)gcc
CPP	= $(CC) -E
AR	= $(CROSS_COMPILE)ar
NM	= $(CROSS_COMPILE)nm
STRIP	= $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB	= $(CROSS_COMPILE)RANLIB

CFLAGS =
CFLAGS += -rdynamic -pipe -O2 -Wall
CFLAGS += -I 3th
CFLAGS += -I bsp
CFLAGS += -I include
CFLAGS += -I kernel
CFLAGS += -I module
CFLAGS += -I service
CFLAGS += -I util


LDFLAGS = 
LDFLAGS += -fPIC -rdynamic -shared 

LINK_STATIC := -Wl,-Bstatic
LINK_SHARED := -Wl,-Bdynamic

export AS LD CC CPP AR NM STRIP OBJCOPY OBJDUMP RANLIB CFLAGS LDFLAGS LINK_STATIC LINK_SHARED

LD_SCRIPT ?= script/x86.lds
export LD_SCRIPT

ifeq ($(CROSS_COMPILE),arm-hisiv400-linux-)
	LD_SCRIPT := script/arm.lds
else
	LD_SCRIPT := script/x86.lds
endif

TEST_CFLAGS ?= ${CFLAGS}
LINK_PATH := -L libs
LD_LIBS := 
LD_LIBS += -lbsp
LD_LIBS += -lkernel
LD_LIBS += -lmodule
LD_LIBS += -lservice
LD_LIBS += -lutil

export TEST_CFLAGS LINK_PATH LD_LIBS

MAKEFILE_BUILD := script/Makefile.build
MAKEFILE_TEST_BUILD := script/Makefile.test.build
export MAKEFILE_BUILD MAKEFILE_TEST_BUILD

dirs := 
dirs += bsp/
dirs += init/
dirs += kernel/
dirs += module/
dirs += service/
dirs += util/

dirs := ${patsubst %/,%,$(filter %/, $(dirs))}
PHONY += $(dirs)
$(dirs): FORCE
	@make -f ${MAKEFILE_BUILD}  obj=$@

objs := init/main.o

all: $(dirs) ${objs}
	@mkdir -p bin
	$(CC) ${CFLAGS} ${LINK_PATH} -T ${LD_SCRIPT} -o ${TARGET_NAME} ${objs} ${LINK_STATIC} ${LD_LIBS} ${LINK_SHARED}

test_dirs := tests/
test_dirs := ${patsubst %/,%,$(filter %/, $(test_dirs))}
$(test_dirs): FORCE
	@make -f ${MAKEFILE_TEST_BUILD}  obj=$@
	
test: $(test_dirs) FORCE
	
clean:	FORCE
	@echo  ">>> clean target"
	@rm -f *.bak *.so *.a
	@rm -f ${TARGET_NAME}
	@${shell for dir in `find -maxdepth 3 -type d | grep -v git| grep -v include | grep -v \.si4project`;\
	do rm -f $${dir}/*.o $${dir}/*.bak $${dir}/*.so $${dir}/*.a $${dir}/*.dep;done}
	@${shell cd tests && for i in `find *.c`;do rm -f `echo $$i|sed 's/\.c//g' `;done }
	@rm -f bin/*

distclean: clean
	@echo  ">>> distclean"
	@rm -fr libs
	@rm -fr bin

help: 
	@echo  'Cleaning targets:'
	@echo  '  clean		  - Remove most generated files but keep the config and'
	@echo  '                    enough build support to build external modules'
	@echo  '  mrproper	  - Remove all generated files + config + various backup files'
	@echo  '  distclean	  - mrproper + remove editor backup and patch files'
	@echo  ''
	@exit 0


PHONY += FORCE
FORCE: