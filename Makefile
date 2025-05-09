# VERSION = sed -s "s/version:.*$/version: $VERSION/" usr/info -i
NAME =	suprapack_dev
LDFLAGS=-X -O2 --disable-warnings --pkg=gio-2.0 -X -w -X -flto --enable-experimental --target-glib=auto

VAPI =	src/uname.vapi
SRC =	src/main.vala \
		src/Uninstall.vala \
		src/QueueSet.vala \
		src/Run.vala \
		src/Makepkg.vala \
		src/Build.vala \
		src/Repository.vala \
		src/Utils.vala \
		src/Command.vala \
		src/Query.vala \
		src/Log.vala \
		src/BetterSearch.vala \
		src/Sync.vala \
		src/Install.vala \
		src/Package.vala \
		src/Config.vala \
		src/Http.vala \
		src/SupraList.vala \
		src/RepoInfo.vala \

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
ifeq ($(shell id -u), 0)
	@./suprapack build usr --no-fakeroot --install --supraforce --prefix=/usr
else 
	@./suprapack build usr --no-fakeroot --install --supraforce
endif

run: $(NAME) 
	cp -f suprapack ~/.local/bin/suprapack
	# suprapack remove supravim 
	suprapack add sfmlll

.PHONY: bootstrap valac install run make_bootstrap all
