SRC= main.vala Build.vala Repository.vala Utils.vala Command.vala Query.vala Log.vala Sync.vala Install.vala Package.vala Config.vala
NAME=suprapack

all: $(NAME)

suprapack:
	valac $(SRC) -X -O2 -X -w -X -fsanitize=address --pkg=gio-2.0 -o suprapack 

build:
	meson build --prefix=$(PWD)/ --bindir=. -Db_sanitize=address

suprapack_dev: build
	ninja install -C build

prod:
	valac $(SRC) -X -O2 -X -w --pkg=gio-2.0 -o suprapack 

install: prod
	mkdir -p usr/bin
	cp ./suprapack usr/bin/suprapack
	tar -cJf suprapack.suprapack -C usr .
	./suprapack install suprapack.suprapack
	
install_vim: install
	./suprapack install supravim

run: all
	# cp suprapack ~/.local/bin/suprapacl
	./suprapack add suprapack 
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) 
