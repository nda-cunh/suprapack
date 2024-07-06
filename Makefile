SRC= main.vala Uninstall.vala Run.vala Makepkg.vala Build.vala Repository.vala Utils.vala Command.vala Query.vala Log.vala Sync.vala Install.vala Package.vala Config.vala
NAME=suprapack_dev
LDFLAGS=-X -O2 --pkg=gio-2.0 -X -w --enable-experimental

all: install 

make_bootstrap:
	rm -rf bootstrap.tar.gz
	valac $(SRC) $(LDFLAGS) -C 
	tar -cf bootstrap.tar.gz *.c

bootstrap:
	tar -xf bootstrap.tar.gz -C . 
	cc $(SRC:.vala=.c) -O2 `pkg-config --cflags --libs gio-2.0` -w -o suprapack

valac: $(SRC)
	valac $(SRC) $(LDFLAGS) -o suprapack 

build:
	meson build --prefix=$(PWD)/ --bindir=. -Db_sanitize=address

suprapack_dev: build
	ninja install -C build

suprapack:
ifeq ($(shell command -v valac 2> /dev/null),)
	@$(MAKE) --no-print-directory bootstrap;
else
	@$(MAKE) --no-print-directory valac;
endif

install: suprapack 
	mkdir -p usr/bin
	cp ./suprapack usr/bin/suprapack
	tar --zstd -cf suprapack.suprapack -C usr .
	./suprapack install suprapack.suprapack

run: $(NAME) 
	cp -f suprapack ~/.local/bin/suprapack
	@# ./suprapack add suprapack --force 
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) 

.PHONY: bootstrap valac install run make_bootstrap all
