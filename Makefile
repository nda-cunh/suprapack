# VERSION = sed -s "s/version:.*$/version: $VERSION/" usr/info -i
NAME =	suprapack_dev
LDFLAGS=-X -O2 --pkg=gio-2.0 -X -w --enable-experimental

VAPI =	src/uname.vapi
SRC =	src/main.vala \
		src/Uninstall.vala \
		src/Run.vala \
		src/Makepkg.vala \
		src/Build.vala \
		src/Repository.vala \
		src/Utils.vala \
		src/Command.vala \
		src/Query.vala \
		src/Log.vala \
		src/Sync.vala \
		src/Install.vala \
		src/Package.vala \
		src/Config.vala \

all: install 

make_bootstrap: src/uname.vapi
	rm -rf bootstrap.tar.gz
	valac $(SRC) $(VAPI) $(LDFLAGS) -C 
	tar -cf bootstrap.tar.gz src/*.c

bootstrap:
	tar -xf bootstrap.tar.gz -C . 
	cc $(SRC:.vala=.c) -O2 `pkg-config --cflags --libs gio-2.0` -w -o suprapack

build:
	meson build --prefix=$(PWD)/ --bindir=. -Db_sanitize=address

suprapack_dev: build
	ninja install -C build

suprapack: $(SRC)
ifeq ($(shell command -v valac 2> /dev/null),)
	@$(MAKE) --no-print-directory bootstrap;
else
	valac $(SRC) src/uname.vapi $(LDFLAGS) -o suprapack 
endif

install: suprapack 
	@rm -rf *.suprapack
	@mkdir -p usr/bin
	@cp ./suprapack usr/bin/suprapack
	@./suprapack build usr --no_fakeroot
	@./suprapack install suprapack*.suprapack

run: $(NAME) 
	cp -f suprapack ~/.local/bin/suprapack
	suprapack search 

.PHONY: bootstrap valac install run make_bootstrap all
