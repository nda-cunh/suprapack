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
		print_error(e.message);
	}
}

void post_install(List<string> list, int len, ref Package pkg) {
	string packinfo = @"$(config.cache)/$(pkg.name)";
	string info_file = @"$packinfo/info";
	
	DirUtils.create_with_parents(packinfo, 0755);
	pkg.create_info_file(info_file);

	var fs = FileStream.open(info_file, "a");
	if (fs == null)
		print_error(@"Cant open $info_file");
	fs.printf("[FILES]\n");
	foreach(var i in list) {
		unowned string basename = i.offset(len);
		if (basename != "/info")
			fs.printf("%s%s\n", config.prefix, basename);
	}
}

void draw_install_file(uint min, uint max, string file) {
	stdout.printf("%s%s[Install]%s [%u/%u] %s\n", BOLD, YELLOW, NONE, min, max, file);
}

// copy files to PREFIX ~/.local 
void install_files(List<string> list, int len) {
	uint nb = 0;
	unowned string basename;
	uint list_length = list.length();
	try {
		foreach (var e in list) {
			basename = e.offset(len);
			var fileSrc = File.new_for_path(e);
			var last_dest = config.prefix + basename;
			FileUtils.unlink(last_dest);
			var fileDest = File.new_for_path(last_dest);
			string path = fileDest.get_path();
			path = path[0: path.last_index_of_char('/')];
			DirUtils.create_with_parents(path, 0755);
			fileSrc.move(fileDest, FileCopyFlags.OVERWRITE);
			draw_install_file(++nb, list_length, basename);
		}
	} catch (Error e) {
		print_error(@"FATAL ERROR >>> $(e.message)");
	}
}

private void script_pre_install(string dir) throws Error {
	if (FileUtils.test(@"$dir/pre_install.sh", FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		print_info(null, "Preparation");
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", config.prefix, true);
		if (Utils.run({@"$dir/pre_install.sh"}, envp) != 0)
			throw new ErrorSP.FAILED("non zero exit code of pre installation script");
	}
}

private void script_post_install(string dir) {
	if (FileUtils.test(@"$dir/post_install.sh", FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", config.prefix, true);
		print_info(null, "Finition");
		if (Utils.run({@"$dir/post_install.sh"}, envp) != 0)
			print_error("non zero exit code of pre installation script");
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

public void install_local (string path) throws Error {
	if (path.has_suffix(".suprapack")) {
		SupraList pkg = SupraList("Local", path);//TODO mettre le path dans les '/'
		add_queue_list(pkg, path);
		install("");
	}
}

public void install(string name_search = "", string name_repo = "") throws Error{
	force_suprapack_update();

	prepare_install(name_search, name_repo);

	if (config.queue_pkg.length() == 0)
		print_error("there's nothing to be done");
	print("resolving dependencies...\n");
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
					print_info("Cancelling...");
					return ;
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
		if (version == i.version)
			print(" %s/%-*s %s\n", i.repo, name_max - i.repo.length , i.name, i.version);
		else
			print(" %s/%-*s %-*s --> %s\n", i.repo, name_max - i.repo.length , i.name, version_max, version, i.version);
		size_installed += int64.parse(i.size_installed);
	}

	print("\nTotal Installed Size:  %.2f MiB\n", (double)size_installed / (1 << 20));

	config.queue_pkg.reverse();
	if (config.allays_yes || Utils.stdin_bool_choose_true(":: Proceed with installation [Y/n] ")) {
		foreach (var i in config.queue_pkg) {
			if (config.force == true || i.name == name_search)
				install_suprapackage(i.output);
			else {
				if (Query.is_exist(i.name) == true) {
					if (Sync.check_update(i.name)) {
						install_suprapackage(i.output);
					}
					else
						print_info("The package is already installed, use --force if you want to replace it", "Info");
				}

			}
			if (!config.is_cached) {
				FileUtils.unlink(i.output);
			}
		}
	}
}

void prepare_install(string name_search, string name_repo = "") throws Error{
	if (name_search == "")
		return;
	force_suprapack_update();
	
	SupraList[] queue = {};
	var list = Sync.get_list_package (name_repo);
	foreach (var pkg in list) {
		if (pkg.name == name_search) {
			queue += pkg;
		}
	}

	SupraList pkg;
	if (queue.length == 0) {
		if (Query.is_exist(name_search) == true) {
			throw new ErrorSP.ACCESS(@"Can't found $name_search but exist in local");
		}
		throw new ErrorSP.FAILED(@"$(name_search) not found");
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
	pkgtmp.output = output;
	pkgtmp.repo = pkg.repo_name;

	config.queue_pkg.append(pkgtmp);
	foreach (var i in pkgtmp.dependency.split(" ")) {
		if (config.check_if_in_queue(i)) {
			continue;
		}
		prepare_install(i);
	}
}
