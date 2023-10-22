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

// copy files to PREFIX ~/.local 
void install_files(List<string> list, int len) {
	uint nb = 0;
	foreach(var i in list) {
		unowned string basename = i.offset(len);
		run_cmd({"install", i, PREFIX + basename});
		print("[Install] [%u/%u] %s\n", ++nb, list.length(), basename);
	}
}

// install package suprapack
public void install_package(string suprapack) {
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
	Repository repo = Repository.default();
	string pkgdir = @"$(LOCAL)/pkg";
	string pkgname;
	string output;
	
	var list = repo.get_list_package();
	foreach (var pkg in list) {
		if (pkg.name == name_search) {
			DirUtils.create_with_parents(pkgdir, 0755);
			print_info(@"$(pkg.name):$(pkg.version) found in repo $(pkg.repo_name)");
			pkgname = @"$(pkg.name)-$(pkg.version).suprapack";
			output = @"$pkgdir/$(pkg.name)-$(pkg.version).suprapack";
			
			string url = repo.get_url_from_name(pkg.repo_name) + pkgname;
			download(url, output);
			install_package(output);
			return ;
		}
	}
	print_error(@"$name_search doesn't exist");
}

public void download(string url, string output) {
	run_cmd({"curl", "-o", output, url});
}
