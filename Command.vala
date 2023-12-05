
async void loading() {
	const string animation[] = {
	"⠋ Loading .  ",
	"⠙ Loading .. ",
	"⠹ Loading ...",
	"⠸ Loading .. ",
	"⠼ Loading ...",
	"⠴ Loading .. ",
	"⠦ Loading .  ",
	"⠧ Loading .. ",
	"⠇ Loading .  ",
	"⠏ Loading .. "
	};
	int i = 0;
	while (true) {
		yield Utils.sleep(300);
		print("%s\r", animation[i]);
		++i;
		if (i == animation.length)
			i = 0;
	}
}

async int cmd_loading(string []av) {
	try {
		var loop = new MainLoop();
		int status = 0;
		Pid child_pid;
		Process.spawn_async   (null, av[2:av.length], null, STDOUT_TO_DEV_NULL | STDERR_TO_DEV_NULL |CHILD_INHERITS_STDIN | SEARCH_PATH , null, out child_pid);
		
		Log.set_default_handler(()=> {});
		ChildWatch.add (child_pid, (pid, _status) => {
			status = _status;
			print("\n");
			loop.quit ();
		});

		Idle.add(()=> {
			loading.begin();
			return false;
		});
		loop.run();
		return status;
	} catch (Error e) {
		print_error(e.message);
	}
}

bool cmd_download(string []av) throws Error {
	if (av.length == 2)
		print_error("suprapack download <pkg>");
	foreach (var pkg in av[2:av.length]) {
		var supralist = Sync.get_from_pkg(pkg);
		print_info(@"$(supralist.name) $(supralist.version)", "Download");
		var path = Sync.download_package(pkg);
		if (path == null)
			print_error("Cant download $(av[2])");

		var file = File.new_for_path(path);
		var filed = File.new_for_path(Environment.get_current_dir() + "/" + file.get_basename());
		file.move(filed, FileCopyFlags.OVERWRITE);
	}

	return true;
}

bool cmd_query_get_comp(string []av) {
	var pkgs = Query.get_all_package();
	for (var i = 0; i != pkgs.length; ++i) {
		if (i == pkgs.length - 1)
			print("%s", pkgs[i].name);
		else
			print("%s ", pkgs[i].name);
	}
	return true;
}

bool cmd_sync_get_comp(string []av) {
	var pkgs = Sync.get_all_package();
	for (var i = 0; i != pkgs.length; ++i) {
		if (i == pkgs.length - 1)
			print("%s", pkgs[i].name);
		else
			print("%s ", pkgs[i].name);
	}
	return true;
}

bool cmd_install(string []av) throws Error {
	if (av.length == 2)
		print_error("`suprapack install [...]`");	

	if (FileUtils.test(av[2], FileTest.EXISTS)) {
		install_suprapackage(av[2]);
		return true;
	}
	foreach (var i in av[2:av.length]) {
		try {
			print_info(i, "Installing");
			install(i);
		}catch (Error e) {
			printerror(e.message);
		}
	}
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

bool cmd_config(string []av) {
	if(av.length <= 3)
		print_error("`suprapack config [...]`");
	var conf = Config.default();
	var cfg = ConfigInfo(av[2], av[3]);
	conf.update_config(cfg);
	return true;
}

bool cmd_have_update(string []av) throws Error{
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
	foreach (var i in av[2:av.length]) {
		print_info(i, "Removing");
		Query.uninstall(i);
	}
	return true;
}

bool cmd_list_files(string []av) {
	foreach (var i in av[2:av.length]) {
		var pkg = Query.get_from_pkg(i);
		print_info(@"$(pkg.name) $(pkg.version)", "List");
		var lst = pkg.get_installed_files();
		foreach (var file in lst) {
			print("%s\n", file);
		}
	}
	
	return true;
}

bool cmd_list(string []av) {
	var installed = Query.get_all_package();
	int width = 0;
	int width_version = 0;
	try {
		var regex = new Regex(av[2] ?? "", RegexCompileFlags.EXTENDED);
		foreach (var i in installed) {
			if (regex.match(i.name) || regex.match(i.version) || regex.match(i.description) || regex.match(i.author)) {
				if (i.name.length > width)
					width = i.name.length;
				if (i.version.length > width_version)
					width_version = i.version.length;
			}
		}
		++width_version;
		++width;
		foreach (var i in installed) {
			if (regex.match(i.name) || regex.match(i.version) || regex.match(i.description) || regex.match(i.author)) {
				print(@"%s%s%-*s %s%-*s%s", BOLD, WHITE, width, i.name, GREEN, width_version, i.version, NONE);
				print("%s%s%s\n", COM, i.description, NONE);
			}
		}
	} catch (Error e) {
		print_error(e.message);
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

bool cmd_run(string []av) throws Error {
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
	Process.exit(Process.exit_status(Utils.run(av_binary)));
}


bool update_package(string pkg_name, bool force = true) throws Error{
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

bool cmd_update(string []av) throws Error {
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
	print(@"	$(suprapack) add [package name]\n");
	print(@"	$(suprapack) install [package name]\n");
	print(@"	  $(COM) install a package from a repository\n");
	print(@"	$(suprapack) install [file.suprapack]\n");
	print(@"	  $(COM) install a package from a file (suprapack)\n");
	print(@"	$(suprapack) remove [package name]\n");
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
	print(@"	$(suprapack) list_files <pkg>\n");
	print(@"	  $(COM) list all file instaled by pkg\n");
	print(@"	$(suprapack) list <pkg>\n");
	print(@"	  $(COM) list your installed package\n");
	print(@"	$(suprapack) info [package name]\n");
	print(@"	  $(COM) print info of package name\n");
	print(@"	$(suprapack) config [config name] [config value]\n");
	print(@"	  $(COM) update a config in your user.conf\n");
	print(@"	$(suprapack) <help>\n");
	print(@"	  $(COM) you have RTFM... so you are a real\n");
	print(@"\n");
	print(@"$(BOLD)$(YELLOW)[Dev Only]$(NONE)\n");
	print(@"	$(suprapack) build $(CYAN)[PREFIX]\n");
	print(@"	  $(COM) build a suprapack you need a prefix look note part\n");
	print(@"	  $(COM) you can add a post_install.sh or pre_install.sh\n");
	print(@"	  $(COM) install script can use $$SRCDIR and $$PKGDIR\n");
	print(@"\n");
	print(@"$(BOLD)$(YELLOW)[Note]$(NONE)\n");
	print(@"	$(WHITE)PREFIX is a folder with this directory like: $(NONE)\n");
	print(@"	$(CYAN)'bin' 'share' 'lib'$(NONE)\n");
	print(@"	$(BOLD)$(WHITE)Example: $(CYAN)suprapatate/bin/suprapatate$(NONE) `suprapack build suprapatate`$(NONE)\n");
	return true;
}
