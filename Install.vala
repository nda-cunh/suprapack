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
	} catch(Error e) {
		print_error(e.message);
	}
}

void post_install(List<string> list, int len, ref Package pkg) {
	string packinfo = @"$(LOCAL)/$(pkg.name)";
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
			fs.printf("%s%s\n", PREFIX, basename);
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
			var fileDest = File.new_for_path(PREFIX + basename);
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

private void script_pre_install(string dir) {
	if (FileUtils.test(@"$dir/pre_install.sh", FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		print_info(null, "Preparation");
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", PREFIX, true);
		var status = Utils.run({@"$dir/pre_install.sh"}, envp);
		if(status != 0)
			print_error("non zero exit code of pre installation script");
	}
}

private void script_post_install(string dir) {
	if (FileUtils.test(@"$dir/post_install.sh", FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		var envp = Environ.get();
		envp = Environ.set_variable(envp, "SRCDIR", dir, true);
		envp = Environ.set_variable(envp, "PKGDIR", PREFIX, true);
		print_info(null, "Finition");
		var status = Utils.run({@"$dir/post_install.sh"}, envp);
		if(status != 0)
			print_error("non zero exit code of pre installation script");
	}
}

// install package suprapack
public void install_suprapackage(string suprapack) {
	Utils.create_pixmaps_link();
	if (FileUtils.test(suprapack, FileTest.EXISTS)) {
		if (!(suprapack.has_suffix(".suprapack")))
			print_error("ce fichier n'est pas un suprapack");
	}
	else 
		print_error(@"$suprapack n'existe pas.");
	try {
		var tmp_dir = DirUtils.make_tmp("suprastore_XXXXXX");
		print_info(@"Extraction de $(CYAN)$(suprapack)$(NONE)");
		var status = Utils.run_silent({"tar", "-xf", suprapack, "-C", tmp_dir});
		if(status != 0) 
			print_error(@"unable to decompress package\npackage => $(suprapack)");
		var pkg = Package.from_file(@"$tmp_dir/info");
		if (Query.is_exist(pkg.name)) {
			Query.uninstall(pkg.name);
		}
		if (pkg.dependency != "") {
			print_info("search dependency...", "Dependency");
			var dep_list = pkg.dependency.split(" ");
			foreach(var dep in dep_list) {
				install(dep, false);
			}
			print_info("All dependencies have been installed !", "Dependency");
		}
		script_pre_install(tmp_dir);
		print_info(@"Installation de $(CYAN)$(pkg.name) $(pkg.version)$(NONE) par $(pkg.author)");
		var list = new List<string>();
		list_file_dir(tmp_dir, ref list);	
		install_files(list, tmp_dir.length);
		script_post_install(tmp_dir);
		post_install(list, tmp_dir.length, ref pkg);
		var status = Utils.run_silent({"rm", "-rf", tmp_dir});
		if(status != 0)
			print_error(@"unable to remove directory\ndirectory => $(tmp_dir)")
	} catch (Error e) {
		print_error(e.message);
	}
}


public void install(string name_search, bool force = true) {
	var sync = Sync.default();
	string output;
	
	var list = sync.get_list_package();
	foreach (var pkg in list) {
		if (pkg.name == name_search) {
			if (force == false) {
				if (Query.is_exist(pkg.name) == true) {
					if (Sync.check_update(pkg.name)) {
						update_package(pkg.name, true);
					}
					return;
				}
			}
			print_info(@"$(pkg.name):$(pkg.version) found in $(pkg.repo_name)");
			output = sync.download(pkg);
			install_suprapackage(output);
			return ;
		}
	}
	if (Query.is_exist(name_search) == true) {
		print_info(@"Can't install $name_search but exist in local");
	}
	else
		print_error(@"$name_search doesn't exist");
}
