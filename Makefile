#  -----------------------------------------------------------------------
#  Copyright  (c) Joerg Desch <github@jdesch.de>
#  -----------------------------------------------------------------------
#  PROJECT.: ezV24 -- easy RS232/V24 access
#  AUTHOR..: Joerg Desch
#  COMPILER: gcc >2.95.x / Linux
#
#

# the version of the library
VERSION = 0.1
# the release of the library; a change here means, that the API has
# changes. This number is the major number of the above version
SORELEASE = 1
# the patchlevel is the lowest release information. It is incremented
# with each released bugfix.
PATCHLEVEL = 4
# the base name of the library
SOBASE = ezV24

# define the destination OS (currently only linux)
PLATFORM=__LINUX__

# the base path where the file should be installed to.
PREFIX = /usr/local

# an additional prefix for building RPM packages. NOTE: don't forget to add a
# trailing slash!
DESTDIR =


# the tool chain
ifdef CROSS_COMPILE
  CC=$(CROSS_COMPILE)gcc
  CXX=$(CROSS_COMPILE)g++
  LD=$(CROSS_COMPILE)ld
  AR=$(CROSS_COMPILE)ar
  AS=$(CROSS_COMPILE)as
  NM=$(CROSS_COMPILE)nm
  STRIP=$(CROSS_COMPILE)strip
  RANLIB=$(CROSS_COMPILE)ranlib
  NO_LDCONFIG=1
else
  CC=gcc
  CXX=g++
  LD=ld
  AR=ar
  AS=as
  NM=nm
  STRIP=strip
  RANLIB=ranlib
endif


# generate the name of the output file in dependence of the development state.
#
ifeq "${RELEASE}" "DEBUG"
NAME = lib$(SOBASE).so.$(SORELEASE).dbg
else
NAME = lib$(SOBASE).so.$(VERSION)
endif
SONAME = lib$(SOBASE).so.$(SORELEASE)
LIBNAME = lib$(SOBASE)-$(SORELEASE)_s.a
PLAINNAME = lib$(SOBASE).so

# basename of the project
PROJECTNAME = libezV24-$(VERSION).$(PATCHLEVEL)

OBJS = src/ezV24.o src/snprintf.o
LIBS =


INCDIR = -I./ezV24

ifeq "${RELEASE}" "DEBUG"
C_OPT  = -O2
C_FLAG = -c -Wall -fPIC $(C_OPT) -D$(PLATFORM) $(INCDIR)
C_DEFS = -DDEBUG -DBETA
LFLAGS = $(LIBDIR)
else
ifeq "${RELEASE}" "BETA"
C_OPT  = -O2
C_FLAG = -c -Wall -fPIC $(C_OPT) -D$(PLATFORM) $(INCDIR)
C_DEFS = -DBETA
LFLAGS = $(LIBDIR)
else
C_OPT  = -O2
C_FLAG = -c -Wall -fPIC $(C_OPT) -D$(PLATFORM) $(INCDIR)
C_DEFS = -DFINAL
LFLAGS = -s $(LIBDIR)
endif
endif

# flags to build the static library
ARFLAGS = cru

# some distros have a messed up path when in su -
LDCONFIG = /sbin/ldconfig

# concatenate the compile flags
CFLAGS = $(C_FLAG) $(C_DEFS)



# ------------------------------------------------------------------------
# AUTOMATIC COMPILE INSTRUCTIONS
# ------------------------------------------------------------------------

.c.o:
		$(CC) $(CFLAGS) -o "$(<:%.c=%.o)" $<


# --------------------------------------------------------------------------
# DEPENDENCIES
# --------------------------------------------------------------------------

all:		shared static test-v24

shared:		$(NAME)

static:		$(LIBNAME)



$(NAME):	$(OBJS)
		$(CC) -shared -fPIC -Wl,-soname,$(SONAME) -o $(NAME) $(OBJS)

$(LIBNAME):	$(OBJS)
		$(AR) $(ARFLAGS) $(LIBNAME) $(OBJS)
		$(RANLIB) $(LIBNAME)


# source dependencies, but doesn't do anything if the automatism above
# already takes care of this!
#

src/ezV24.o:	src/ezV24.c ezV24/ezV24.h ezV24/ezV24_config.h ezV24/snprintf.h

src/snprintf.o:	src/snprintf.c ezV24/snprintf.h



# This install / uninstall the library into the given directories.
#

install:
		install -d -m 755 $(DESTDIR)$(PREFIX)/include/$(SOBASE)/
		install -d -m 755 $(DESTDIR)$(PREFIX)/lib/
		install -m 644 ezV24/ezV24.h $(DESTDIR)$(PREFIX)/include/$(SOBASE)/
		install -m 644 $(LIBNAME) $(DESTDIR)$(PREFIX)/lib/$(LIBNAME)
		install -m 755 $(NAME) $(DESTDIR)$(PREFIX)/lib/$(NAME)
		$(STRIP) $(DESTDIR)$(PREFIX)/lib/$(LIBNAME)
		$(STRIP) $(DESTDIR)$(PREFIX)/lib/$(NAME)
		rm -f $(DESTDIR)$(PREFIX)/lib/$(SONAME) $(DESTDIR)$(PREFIX)/lib/$(PLAINNAME)
		ln -s $(PREFIX)/lib/$(NAME) $(DESTDIR)$(PREFIX)/lib/$(SONAME)
		ln -s $(PREFIX)/lib/$(SONAME) $(DESTDIR)$(PREFIX)/lib/$(PLAINNAME)
ifndef CROSS_COMPILE
		if [ -z $$NO_LDCONFIG ]; then \
		  $(LDCONFIG); \
		fi
endif

uninstall:
		rm -f $(PREFIX)/include/ezV24/*
		rmdir $(PREFIX)/include/ezV24
		rm -f $(PREFIX)/lib/$(LIBNAME)
		rm -f $(PREFIX)/lib/$(NAME)
		rm -f $(PREFIX)/lib/$(SONAME) $(PREFIX)/lib/$(PLAINNAME)
ifndef CROSS_COMPILE
		if [ -z $$NO_LDCONFIG ]; then \
		  $(LDCONFIG); \
		fi
endif

# This entry is for packing a distribution tarball
#
tarball:	api-ref
		if test -d $(PROJECTNAME); then\
		  rm -fR $(PROJECTNAME)/*;\
		  rmdir $(PROJECTNAME);\
		fi
		mkdir $(PROJECTNAME)
		cp ezV24.h ezV24_config.h ezV24.c $(PROJECTNAME)/
		cp snprintf.h snprintf.c test-v24.c $(PROJECTNAME)/
		cp Makefile Makefile.cygwin README $(PROJECTNAME)/
		cp AUTHORS HISTORY COPY* BUGS ChangeLog $(PROJECTNAME)/
		cp doc++.conf manual.dxx $(PROJECTNAME)/
		cp -r --parents api-html $(PROJECTNAME)/
		cp -r --parents debian $(PROJECTNAME)/
		tar cfz $(PROJECTNAME).tar.gz $(PROJECTNAME)
		rm -fR $(PROJECTNAME)/*
		rmdir $(PROJECTNAME)

# build the api reference
#
api-ref:	doc/doxygen.conf doc/manual.dxx ezV24/ezV24.h
		doxygen doc/doxygen.conf

# The ezV24-Test program. To compile the dynamic link version, the
# library must be installed first! To avoid this, i use the static lib!
#	gcc -o test-v24 -Wall test-v24.c -l$(SOBASE)
#
test-v24:	samples/test-v24.c ezV24/ezV24.h $(LIBNAME)
		$(CC) -o test-v24 -Wall -DUNINSTALLED samples/test-v24.c -L./ $(INCDIR) $(LIBNAME)


# --------------------------------------------------------------------------
# OTHER TASKS
# --------------------------------------------------------------------------

clean:
		rm -f src/*.o core

clean-all:
		rm -f src/*.o core test-v24 $(NAME) $(LIBNAME)
		rm -f $(PROJECTNAME).tar.gz
		rm -f doc/api-html/*
		rmdir doc/api-html


# --[end of file]-----------------------------------------------------------
