bool cmd_run(string []av) {
	if (av.length == 2)
		print_error("`suprapack run [...]`");	
	if (Query.is_exist(av[2]) == false) {
		print_info(@"$(av[2]) doesn't exist install it...");
	}
	if (Query.is_exist(av[2]) == false) {
		print_error(@"$(av[2]) is not installed");
	}
	var pkg = Query.get_from_pkg(av[2]);

	string []av_binary;
	av_binary = {@"~/.local/$(pkg.binary)"};
	if (av.length >= 3) {
		foreach (var i in av[3: av.length])
			av_binary += i;	
	}
	Utils.run(av_binary);
	return true;
}

public void main(string []args) {
	cmd_run(args);
}
