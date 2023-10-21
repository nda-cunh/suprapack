SRC= main.vala Query.vala Log.vala Repository.vala Install.vala Package.vala
NAME=suprastore

all:
	valac $(SRC) -X -w -X -fsanitize=address --pkg=gio-2.0 -o $(NAME) 

run: all
	./$(NAME) uninstall suprapatate 
	# ./$(NAME) list 
