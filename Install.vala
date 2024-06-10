const int SIZE_TMP_DIR = 22;

void list_file_dir(string emp_dir, ref List<string> list) {
	try {
		var dir = Dir.open(emp_dir);
		unowned string it;
		while ((it = dir.read_name()) != null) {
			if (emp_dir.length == SIZE_TMP_DIR) {
				if (it == "info" || it == "pre_install.sh" || it == "post_install.sh")
					continue;
			}
			string name = @"$emp_dir/$it";
			if (FileUtils.test(name, FileTest.IS_DIR))
				list_file_dir(name, ref list);
			else 
				list.append(name);
		}
	} catch (Error e) {
		error(e.message);
	}
}

void post_install(List<string> list, int len, ref Package pkg) {
	string packinfo = @"$(config.cache)/$(pkg.name)";
	string info_file = @"$packinfo/info";
	
	DirUtils.create_with_parents(packinfo, 0755);
	pkg.create_info_file(info_file);

	var fs = FileStream.open(info_file, "a");
	if (fs == null)
		error("Cant open %s", info_file);
	fs.printf("[FILES]\n");
	foreach(var i in list) {
		unowned string basename = i.offset(len);
		if (basename != "/info")
			fs.printf("%s%s\n", config.prefix, basename);
	}
}

// copy files to PREFIX ~/.local 
void install_files(List<string> list, int len) {
	uint nb = 0;
	unowned string basename;
	uint list_length = list.length();

	int g_last_size = 0;
	unowned uint8[] blank = CONST_BLANK.data;
	try {
		foreach (unowned var e in list) {
			basename = e.offset(len);
			var fileSrc = File.new_for_path(e);
			var last_dest = config.prefix + basename;
			FileUtils.unlink(last_dest);
			var fileDest = File.new_for_path(last_dest);
			string path = fileDest.get_path();
			path = Path.get_dirname(path);
			DirUtils.create_with_parents(path, 0755);
			fileSrc.move(fileDest, FileCopyFlags.OVERWRITE);
			{
				int file_len = basename.length;
				int calc = g_last_size - file_len;
				
				if (calc <= 0)
					calc = 1;
				blank[calc] = '\0';
				stdout.printf("%s%s[Install]%s [%u/%u] %s%s\r", BOLD, YELLOW, NONE, ++nb, list_length, basename, (string)blank);
				blank[calc] = ' ';
				g_last_size = file_len;
			}
		}
	} catch (Error e) {
		error("FATAL ERROR >>> %s", e.message);
	}
	print("\n");
}

private void script_pre_install(string dir) throws Error {
	var filename = @"$dir/pre_install.sh";
	if (FileUtils.test(filename, FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		if (config.show_script == true && config.allays_yes == false) {
			string contents;
			FileUtils.get_contents(filename, out contents);
			print("[PreInstall] {\n%s\n}\n", contents);
			if (Utils.stdin_bool_choose_true("Continue ? [Y/n]") == false)
				throw new ErrorSP.ACCESS("you refused to execute the script.");
		}
		print_info(null, "Pre Install");
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", config.prefix, true);
		envp = Environ.set_variable(envp, "PATH", @"$(config.prefix)/bin:" + Environ.get_variable(envp, "PATH"), true);
		if (Utils.run({filename}, envp) != 0)
			throw new ErrorSP.FAILED("non zero exit code of pre installation script");
	}
}

private void script_post_install(string dir) throws Error {
	var filename = @"$dir/post_install.sh";
	if (FileUtils.test(filename, FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		if (config.show_script == true && config.allays_yes == false) {
			string contents;
			FileUtils.get_contents(filename, out contents);
			print("[PostInstall] {\n%s\n}\n", contents);
			if (Utils.stdin_bool_choose_true("Continue ? [Y/n]") == false)
				throw new ErrorSP.ACCESS("you refused to execute the script.");
		}
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", config.prefix, true);
		envp = Environ.set_variable(envp, "PATH", @"$(config.prefix)/bin:" + Environ.get_variable(envp, "PATH"), true);
		print_info(null, "Post Install");
		if (Utils.run({filename}, envp) != 0)
			throw new ErrorSP.FAILED("non zero exit code of pre installation script");
	}
}

// install package suprapack
public void install_suprapackage(string suprapack) throws Error {
	force_suprapack_update();

	if (FileUtils.test(suprapack, FileTest.EXISTS)) {
		if (!(suprapack.has_suffix(".suprapack")))
			throw new ErrorSP.BADFILE("ce fichier n'est pas un suprapack");
	}
	else 
		throw new ErrorSP.ACCESS(@"$suprapack n'existe pas");
	var tmp_dir = DirUtils.make_tmp("suprastore_XXXXXX");
	print_info(@"Extraction de $(CYAN)$(suprapack)$(NONE)");
	if (Utils.run_silent({"tar", "-xf", suprapack, "-C", tmp_dir}) != 0) 
		throw new ErrorSP.FAILED(@"unable to decompress package\npackage => $(suprapack)");

	var pkg = Package.from_file(@"$tmp_dir/info");

	/* Pre Install script launch */
	script_pre_install(tmp_dir);
	if (Query.is_exist(pkg.name)) {
		Query.uninstall(pkg.name);
	}

	print_info(@"Installation de $(CYAN)$(pkg.name) $(pkg.version)$(NONE) par $(pkg.author)");

	var list = new List<string>();
	list_file_dir(tmp_dir, ref list);	
	install_files(list, tmp_dir.length);

	script_post_install(tmp_dir);

	post_install(list, tmp_dir.length, ref pkg);
	if(Utils.run_silent({"rm", "-rf", tmp_dir}) != 0)
		new OptionError.FAILED(@"unable to remove directory\ndirectory => $(tmp_dir)");
}


private void force_suprapack_update () throws Error {
	if (!Query.is_exist("suprapack"))
		return ;
	if (config.supraforce == false && Sync.check_update("suprapack")) {
		print_info(null, "Canceling... An update of suprapack is here", "\033[35;1m");
		Process.spawn_command_line_sync(@"$(config.prefix)/bin/suprapack --force --supraforce add suprapack");
		var cmd_str = "";
		foreach (var i in config.cmd) {
			cmd_str += @"$i ";
		}
		Process.spawn_command_line_sync(@"$cmd_str");
		Process.exit(0);
	}
}

public void install() throws Error {
	force_suprapack_update();

	print("\nresolving dependencies...\n");

	if (config.queue_pkg.length() == 0){
		print_info("there's nothing to be done");
		return;
	}

	print("looking for conflicting packages...\n");

	int name_max = 0;
	int version_max = 0;
    foreach (var i in config.queue_pkg) {

		foreach (var exclude in i.exclude_package.split(" ")) {
			exclude = exclude.strip();
			if (Query.is_exist(exclude)) {
				print_info(@"Impossible to install '$(i.name)' because '$(exclude)' is in conflict with him", "Conflict", "\033[31;1m");
				print_info(@"please choose if you want to uninstall '$(exclude)' [y/N]", "Conflict", "\033[31;1m");
				if (Utils.stdin_bool_choose(": ") == true) {
					Query.uninstall(exclude);
				}
				else {
					throw new ErrorSP.CANCEL("Cancelling...");
				}
			}
		}

		/* Calc the len for padding*/
        var len = (i.name.length + i.repo.length + 2);
        if (len > name_max)
            name_max = len;
        len = (i.version.length);
        if (len > version_max)
            version_max = len;
    }

	int64 size_installed = 0;
	print("Package (%u)\n\n", config.queue_pkg.length());

	foreach (var i in config.queue_pkg) {
		string version = i.version;
		if (Query.is_exist(i.name)) {
			version = Query.get_from_pkg(i.name).version; 
		}
		int n = 0;
		n += printf("  %s%s%s%s/%-*s %s%s", BOLD, PURPLE, i.repo, NONE, name_max - i.repo.length, i.name, BOLD, GREEN);
		n += printf("%-*s%s", version_max, version, NONE);
		if (version != i.version)
			n += printf(" --> %s%s%s", BOLD, YELLOW, i.version);
		n+= printf("%s\n", NONE);
		size_installed += int64.parse(i.size_installed);
	}

	print(@"\nTotal Installed Size:  $(BOLD)%.2f MiB$(NONE)\n", (double)size_installed / (1 << 20));


	unowned var first_package = config.queue_pkg.nth_data(0).name;
	config.queue_pkg.reverse();
	if (config.allays_yes || Utils.stdin_bool_choose_true(":: Proceed with installation [Y/n] ")) {
		print("\n");
		foreach (var i in config.queue_pkg) {
			if (config.force == true || i.name == first_package) {
				install_suprapackage(i.output);
			}
			else {
				if (Query.is_exist(i.name) == true) {
					if (Sync.check_update(i.name)) {
						install_suprapackage(i.output);
					}
					else
						print_info(@"$(i.name) is already installed", "Info", "\033[37m");
				}
				else
					install_suprapackage(i.output);
			}
			if (!config.is_cached && i.repo != "Local") {
				FileUtils.unlink(i.output);
			}
		}
		/* add dependency in  .required_by file */
		foreach (var i in config.queue_pkg) {
			//i == sfml
			foreach (var deps in i.dependency.split(" ")) {
				Query.add_package_to_required_by(i.name, deps);
			}
		}


	}
	else {
		throw new ErrorSP.CANCEL("Cancelling...");
	}
}

//* Add a package in Config.queue *//
void prepare_install(string name_search, string name_repo = "") throws Error{
	if (name_search == "")
		return;
	force_suprapack_update();
	
	if (name_search.has_suffix(".suprapack")) {
		if (!FileUtils.test(name_search, FileTest.EXISTS))
			throw new ErrorSP.ACCESS (@"$name_search not found");
		SupraList pkg = SupraList("Local", name_search, true); 
		add_queue_list(pkg, name_search);
		return;
	}


	SupraList[] queue = {};
	var list = Sync.get_list_package (name_repo);
	// Search in $(name_repo)_list
	foreach (var pkg in list) {
		if (pkg.name == name_search) {
			queue += pkg;
		}
	}

	// Search in Groups if package exist
	unowned var group = Sync.group_get_from_name(name_search);
	if (group.length() >= 1) {
		foreach (unowned var gp in group) {
			// Add Simple Package
			if (gp.length() == 1) {
				foreach (var pkg in list) {
					if (pkg.name == gp.nth_data(0)) {
						queue += pkg;
					}
				}
			}
			// Add Package with multi choose like (ccls or clangd)
			else {
				bool need_choose = true;
				foreach (unowned var pkg in gp) {
					if (Query.is_exist(pkg)) {
						need_choose = false;
						break;
					}
				}
				// if no dependency in the choose is installed
				if (need_choose) {
					print("please choose one: ");
					var nb = int.parse(stdin.read_line());
					if (nb < 0 || nb > queue.length - 1) {
						print_info("Cancelling...");
						return ;
					}
				}
			}
		}
	}

	SupraList pkg;
	if (queue.length == 0) {
		if (Query.is_exist(name_search) == true) {
			throw new ErrorSP.ACCESS(@"Can't found $name_search but exist in local");
		}
		throw new ErrorSP.ACCESS(@"$(name_search) not found");
	}
	else if (queue.length == 1){
		pkg = queue[0];
	}
	else {
		// if Force search auto best package
		if (config.force == true) {
			var lst = Utils.sort_supralist_version(queue);
			pkg = lst[lst.length - 1];
		}else {
			print_info("Similar package are found", "Conflict", "\033[31;1m");
			for (int i = 0; i < queue.length; i++) {
			print("%s", BOLD);
				print(@"%4d) $(PURPLE)%s/$(WHITE)%s [%s]$(NONE)\n", i, queue[i].repo_name, queue[i].name, queue[i].version);
			}
			print("please choose one: ");
			var nb = int.parse(stdin.read_line());
			if (nb < 0 || nb > queue.length - 1) {
				print_info("Cancelling...");
				return ;
			}
			pkg = queue[nb];
		}
	}

	var output = Sync.download(pkg);
	add_queue_list(pkg, output);
}

void add_queue_list(SupraList pkg, string output) throws Error {

	Process.spawn_command_line_sync(@"tar -xf $(output) ./info");
	Package pkgtmp = Package.from_file("./info");
	FileUtils.unlink("./info");
	pkgtmp.output = output;
	pkgtmp.repo = pkg.repo_name;

	config.queue_pkg.append(pkgtmp);
	try {
		foreach (var i in pkgtmp.dependency.split(" ")) {
			if (config.check_if_in_queue(i)) {
				continue;
			}
			if (Query.is_exist(i) && config.force == false) {
				print("AVAntle crshhh\n");
				if (Sync.check_update(i))
					prepare_install(i);
				continue;
			}
			else
				prepare_install(i);
		}
	} catch (Error e) {
		throw new ErrorSP.FAILED("Dependency of %s -> %s", pkg.name, e.message);
	}
}
