SRC= main.vala Build.vala Repository.vala Utils.vala Command.vala Query.vala Log.vala Sync.vala Install.vala Package.vala
NAME=suprapack

all:
	valac $(SRC) -X -w -X -fsanitize=address --pkg=gio-2.0 -o $(NAME) 

prod:
	valac $(SRC) -X -w --pkg=gio-2.0 -o $(NAME) 

install: prod
	mkdir -p prefix/bin
	cp $(NAME) prefix/bin/$(NAME)

run: all
	cp $(NAME) ~/.local/bin/$(NAME)
	@#./$(NAME) uninstall nodejs 
	@# ./$(NAME) update suprapatate 
	@# ./$(NAME) list 
