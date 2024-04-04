SRC= main.vala Run.vala Makepkg.vala Build.vala Repository.vala Utils.vala Command.vala Query.vala Log.vala Sync.vala Install.vala Package.vala Config.vala
NAME=suprapack_dev

all: install 

debug:
	valac $(SRC) --debug -X -O2 -X -w -X -fsanitize=address --pkg=gio-2.0 -o suprapack 

build:
	meson build --prefix=$(PWD)/ --bindir=. -Db_sanitize=address

suprapack_dev: build
	ninja install -C build

prod:
	valac $(SRC) --enable-experimental -X -flto -X -O2 -X -w --pkg=gio-2.0 -o suprapack 

install: debug 
	mkdir -p usr/bin
	cp ./suprapack usr/bin/suprapack
	tar -cJf suprapack.suprapack -C usr .
	./suprapack install suprapack.suprapack

run: prod 
	./suprapack build PKGBUILD
	@# cp suprapack ~/.local/bin/suprapack
	@# ./suprapack add suprapack --force 
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) 
