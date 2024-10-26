NAME =	suprapack_dev
LDFLAGS=-X -O2 --pkg=gio-2.0 -X -w --enable-experimental

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
		src/Config.vala

all: install 

make_bootstrap:
	rm -rf bootstrap.tar.gz
	valac $(SRC) $(LDFLAGS) -C 
	mv src/*.c .
	tar -cf bootstrap.tar.gz *.c

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
	valac $(SRC) $(LDFLAGS) -o suprapack 
endif

install: suprapack 
	@rm -rf *.suprapack
	@mkdir -p usr/bin
	@cp ./suprapack usr/bin/suprapack
	@./suprapack build usr
	@./suprapack install suprapack*.suprapack

run: $(NAME) 
	cp -f suprapack ~/.local/bin/suprapack
	suprapack search 
	@# ./suprapack add suprapack --force 
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) 

.PHONY: bootstrap valac install run make_bootstrap all
