bool cmd_install(string []av) {
	if (av.length == 2)
		print_error("`suprapack install [...]`");	

	if (FileUtils.test(av[2], FileTest.EXISTS)) {
		install_suprapackage(av[2]);
		return true;
	}
	install(av[2]);
	return true;
}

bool cmd_build(string []av) {
	if (av.length == 2)
		print_error("`suprapack build [...]`");	
	print_info(@"Build $(av[2])");
	Build.create_package(av[2]);
	return true;
}

bool cmd_info(string []av) {
	if (av.length == 2)
		print_error("`suprapack info [...]`");	
	var info = Query.get_from_pkg(av[2]);
	print(@"$(BOLD)Nom                      : $(NONE)%s\n", info.name);
	print(@"$(BOLD)Version                  : $(NONE)%s\n", info.version);
	print(@"$(BOLD)Description              : $(NONE)%s\n", info.description);
	print(@"$(BOLD)Author                   : $(NONE)%s\n", info.author);
	var dep_list = info.dependency.split(" ");
	if (dep_list.length >= 1) {
		print(@"$(BOLD)Depends                  : $(NONE)");
		foreach (var dep in dep_list)
			print("%s ", dep);
		print("\n");
	}
	if (info.binary != info.name)
		print(@"$(BOLD)Binary                   : $(NONE)%s\n", info.binary);

	return true;
}

bool cmd_have_update(string []av) {
	if (av.length == 2)
		print_error("`suprapack have_update [...]`");	
	var Qpkg = Query.get_from_pkg(av[2]);
	var Spkg = Sync.get_from_pkg(av[2]);
	if (Spkg.version != Qpkg.version) {
		print("Update %s --> %s", Qpkg.version, Spkg.version);
	}
	return true;
}

bool cmd_uninstall(string []av) {
	if (av.length == 2)
		print_error("`suprapack uninstall [...]`");	
	Query.uninstall(av[2]);
	return true;
}

bool cmd_list(string []av) {
	var installed = Query.get_all_package();
	foreach (var i in installed) {
		print(@"$(BOLD)$(WHITE)$(i.name) $(GREEN)$(i.version)$(NONE)");
		print("\t%s%s%s\n", COM, i.description, NONE);
	}
	return true;
}

bool cmd_prepare() {
	Repository.prepare();
	return true;
}


private void print_search(ref SupraList repo, bool installed) {
	print("%s%s", BOLD, PURPLE);
	print("%s/%s", repo.repo_name, WHITE);
	print("%s %s%s", repo.name, GREEN, repo.version);
	if (installed)
		print(" %s[installed]", CYAN);
	print("%s\n", NONE);
}

bool cmd_search(string []av) {
	var list = Sync.default().get_list_package();
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
	return true;
}

bool cmd_run(string []av) {
	if (av.length == 2)
		print_error("`suprapack run [...]`");	
	if (Query.is_exist(av[2]) == false) {
		print_info(@"$(av[2]) doesn't exist install it...");
		cmd_install({"", "install", av[2]});
	}
	if (Query.is_exist(av[2]) == false) {
		print_error(@"$(av[2]) is not installed");
	}
	var pkg = Query.get_from_pkg(av[2]);

	string []av_binary;
	if (pkg.binary.index_of_char('/') == -1)
		av_binary = {@"$(PREFIX)/bin/$(pkg.binary)"};
	else
		av_binary = {@"$(PREFIX)/$(pkg.binary)"};

	if (av.length >= 3) {
		foreach (var i in av[3: av.length])
			av_binary += i;	
	}
	var status = Utils.run(av_binary);
	if(status != 0)
		print_error(@"non zero exit code of package binary\npackage => $(pkg.name)");
	return true;
}


bool update_package(string pkg_name, bool force = true) {
	var list = Sync.default().get_list_package();
	var pkg = Query.get_from_pkg(pkg_name);
	string Qversion = pkg.version;
	string Sversion;

	foreach (var i in list) {
		if (i.name == pkg_name) {
			Sversion = i.version;
			if (Sversion != Qversion) {
				print_info(@"Update avaiable for $(pkg_name) $(CYAN)$(pkg.version) --> $(i.version)");
				if (force == false) {
					print_info(@"Do you want update it ? [yes/No]");
					var input = stdin.read_line().strip().down();
					if (input == "" || "y" in input)
						install(pkg_name);
					else
						print_info("Cancel ...");
				}
				else {
					install(pkg_name);
				}
			}else {
				print_info(@"No update avaiable for $(pkg_name) $(i.version)");
			}
			return true;
		}
	}
	return false;
}

bool cmd_update(string []av) {
	unowned string pkg_name;

	// All Update
	if (av.length == 2) {
		var Qpkg = Query.get_all_installed_pkg();
		foreach (var pkg in Qpkg) {
			update_package(pkg, false);
		}
		return true;
	}
	// update pkg_name
	else {
		pkg_name = av[2];
		if (Query.is_exist(pkg_name) == false) {
			print_error(@"$pkg_name is not installed");
		}
		if (update_package(pkg_name) == false)
			print_error(@"target not found: $pkg_name");
		return true;
	}
}

bool cmd_help() {
	string suprapack = @"$(BOLD)suprapack$(NONE)";
	print(@"$(BOLD)$(YELLOW)[SupraStore] ----- Help -----\n\n");
	print(@"	$(suprapack) install [package name]\n");
	print(@"	  $(COM) install a package from a repository\n");
	print(@"	$(suprapack) install [file.suprapack]\n");
	print(@"	  $(COM) install a package from a file (suprapack)\n");
	print(@"	$(suprapack) uninstall [package name]\n");
	print(@"	  $(COM) remove a package\n");
	print(@"	$(suprapack) your_file.suprapack\n");
	print(@"	  $(COM) install a package from a file (suprapack)\n");
	print(@"	$(suprapack) update\n");
	print(@"	  $(COM) update all your package\n");
	print(@"	$(suprapack) update [package name]\n");
	print(@"	  $(COM) update a package\n");
	print(@"	$(suprapack) search <pkg>\n");
	print(@"	  $(COM) search a package in the repo you can use patern for search\n");
	print(@"	  $(BOLD)$(GREY) Exemple:$(COM) suprapack search $(CYAN)'^supra.*' \n");
	print(@"	$(suprapack) list <pkg>\n");
	print(@"	  $(COM) list your installed package\n");
	print(@"	$(suprapack) info [package name]\n");
	print(@"	  $(COM) print info of package name\n");
	print(@"	$(suprapack) <help>\n");
	print(@"	  $(COM) you have RTFM... so you are a real\n");
	print(@"\n");
	print(@"$(BOLD)$(YELLOW)[Dev Only]$(NONE)\n");
	print(@"	$(suprapack) build $(CYAN)[PREFIX]\n");
	print(@"	  $(COM) build a suprapack you need a prefix look note part\n");
	print(@"\n");
	print(@"$(BOLD)$(YELLOW)[Note]$(NONE)\n");
	print(@"	$(WHITE)PREFIX is a folder with this directory like: $(NONE)\n");
	print(@"	$(CYAN)'bin' 'share' 'lib'$(NONE)\n");
	print(@"	$(BOLD)$(WHITE)Example: $(CYAN)suprapatate/bin/suprapatate$(NONE) `suprapack build suprapatate`$(NONE)\n");
	return true;
}
