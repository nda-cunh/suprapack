SRC= main.vala Log.vala List.vala Install.vala Package.vala
NAME=suprastore

all:
	valac $(SRC) -X -w -X -fsanitize=address --pkg=gio-2.0 -o $(NAME) 

run: all
	./$(NAME) install cppcheck
