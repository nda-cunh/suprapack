SRC= main.vala Run.vala Makepkg.vala Build.vala Repository.vala Utils.vala Command.vala Query.vala Log.vala Sync.vala Install.vala Package.vala Config.vala
NAME=suprapack_dev
LDFLAGS=-X -O2 --pkg=gio-2.0 -X -w --enable-experimental
all: install 

debug:
	valac $(SRC) $(LDFLAGS) --debug -X -fsanitize=address -o suprapack 

build:
	meson build --prefix=$(PWD)/ --bindir=. -Db_sanitize=address

suprapack_dev: build
	ninja install -C build

prod:
	valac $(SRC) $(LDFLAGS) -o suprapack 

install: debug 
	mkdir -p usr/bin
	cp ./suprapack usr/bin/suprapack
	tar -cJf suprapack.suprapack -C usr .
	./suprapack install suprapack.suprapack

run: $(NAME) 
	cp -f suprapack ~/.local/bin/suprapack
	@# ./suprapack add suprapack --force 
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) 
