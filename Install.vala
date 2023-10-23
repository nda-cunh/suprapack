void list_file_dir(string emp_dir, ref List<string> list) {
	try {
		var dir = Dir.open(emp_dir);
		unowned string it;
		while ((it = dir.read_name()) != null) {
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
	stdout.printf("[Install] [%u/%u] %s\n", min, max, file);
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

// install package suprapack
public void install_suprapackage(string suprapack) {
	if (FileUtils.test(suprapack, FileTest.EXISTS)) {
		if (!(suprapack.has_suffix(".suprapack")))
			print_error("ce fichier n'est pas un suprapack");
	}
	else 
		print_error(@"$suprapack n'existe pas.");
	try {
		var tmp_dir = DirUtils.make_tmp("suprastore_XXXXXX");
		print_info(@"Extraction de $(CYAN)$(suprapack)$(NONE)");
		run_cmd({"tar", "-xf", suprapack, "-C", tmp_dir});
		var pkg = Package.from_file(@"$tmp_dir/info");
		print_info(@"Installation de $(YELLOW)$(pkg.name) $(pkg.version)$(NONE) par $(pkg.author)");
		var list = new List<string>();
		list_file_dir(tmp_dir, ref list);	

		install_files(list, tmp_dir.length);
		post_install(list, tmp_dir.length, ref pkg);
		
		run_cmd({"rm", "-rf", tmp_dir});
	} catch (Error e) {
		print_error(e.message);
	}
}


public void install(string name_search) {
	var sync = Sync.default();
	string output;
	
	var list = sync.get_list_package();
	foreach (var pkg in list) {
		if (pkg.name == name_search) {
			print_info(@"$(pkg.name):$(pkg.version) found in sync $(pkg.repo_name)");
			output = sync.download(pkg);
			install_suprapackage(output);
			return ;
		}
	}
	print_error(@"$name_search doesn't exist");
}
