[NoReturn]
void cmd_install(string []av) {
	if (av.length == 2)
		print_error("`suprastore install [...]`");	
	install(av[2]);
	Process.exit(0);
}

void build_package(string usr_dir) {
	if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
		print_error(@"$usr_dir is not a dir or doesn't exist");
	var pkg = Package.from_input();
	pkg.create_info_file(@"$usr_dir/info");

	var name_pkg = @"$(pkg.name)-$(pkg.version)";
	string []av = {"tar", "-cf", @"$(name_pkg).suprapack", "-C", usr_dir, "."};
	try {
		var tar = new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE);
		tar.wait();
	} catch(Error e) {
		print_error(e.message);
	}
	print_info(@"$(name_pkg).suprapack is created\n");
}

[NoReturn]
void cmd_build(string []av) {
	if (av.length == 2)
		print_error("`suprastore build [...]`");	
	build_package(av[2]);
	Process.exit(0);
}

[NoReturn]
void cmd_uninstall(string []av) {
	unowned string pkg;
	if (av.length == 2)
		print_error("`suprastore uninstall [...]`");	
	pkg = av[2];
	if (Query.is_exist(pkg) == false)
		print_error(@"the package $pkg doesn't exist");
	var lst = Query.get_from_pkg(pkg).get_installed_files();
	foreach(unowned string i in lst) {
		print_info(@"Suppresion de $(i)");
		FileUtils.unlink(i);
	}
	Query.remove_pkg(pkg);
	Process.exit(0);
}

[NoReturn]
void cmd_list(string []av) {
	var installed = Query.get_all_package();
	foreach (var i in installed) {
		print(@"$(BOLD)$(WHITE)$(i.name) $(GREEN)$(i.version)$(NONE)\n");
		print("\t%s%s %s%s\n", COM, i.author, i.description, NONE);
	}
	Process.exit(0);
}


private void print_search(ref SupraList repo, bool installed) {
	print("%s%s", BOLD, PURPLE);
	print("%s/%s", repo.repo_name, WHITE);
	print("%s %s%s", repo.name, GREEN, repo.version);
	if (installed)
		print(" %s[installed]", CYAN);
	print("%s\n", NONE);
}

[NoReturn]
void cmd_search(string []av) {
	var list = Repository.default().get_list_package();
	var installed = Query.get_all_installed_pkg();
	// search without input
	if (av.length == 2) {
		foreach(var i in list) {
			print_search(ref i, (i.name in installed));
		}
	}
	// search with regex pattern 
	else {
		try {
			var regex = new Regex(av[2], RegexCompileFlags.EXTENDED);
			foreach(var i in list) {
				if (regex.match(i.name) || regex.match(i.version))
					print_search(ref i, (i.name in installed));
			}
		}
		catch (Error e) {
			print_error(e.message);
		}
	}
	Process.exit(0);
}

[NoReturn]
void cmd_update(string []av) {
	// var list = Repository.default().get_list_package();
	//TODO
	Process.exit(0);
}

[NoReturn]
void cmd_help(string []av) {
	print(@"$(BOLD)$(INV)                            Help                            $(NONE)\n");
	print(@"$(BOLD)suprastore$(NONE) help\n");
	print(@"$(BOLD)suprastore$(NONE) install package         Install package from repo\n");
	print(@"$(BOLD)suprastore$(NONE) update package          Update only the package\n");
	print(@"$(BOLD)suprastore$(NONE) update                  Update All\n");
	print(@"$(BOLD)suprastore$(NONE) list                    List all package in repo\n");
	print(@"$(BOLD)suprastore$(NONE) list package            List all files of package\n");
	print(@"\n");
	print(@"$(BOLD)$(COM)[Dev Only]$(NONE)\n");
	print(@"$(BOLD)suprastore$(NONE) build PREFIX  Build a file.suprapack\n");
	print(@"$(BOLD)suprastore$(NONE) your_package.suprapack  Install a file.suprapack\n");
	print(@"$(CYAN)PREFIX is a folder with this directory like: $(NONE)\n");
	print(@"$(CYAN)'bin' 'share' 'lib'$(NONE)\n");
	print(@"$(CYAN)Example: suprapatate/bin/suprapatate `suprastore build suprapatate`$(NONE)\n");
	print(@"$(BOLD)$(INV)                                                            $(NONE)\n");
	Process.exit(0);
}
