namespace Query{

	/* verify if package is installed in ~/suprastore/name_pkg */
	public bool is_exist(string name_pkg) {
		return FileUtils.test(@"$(config.cache)/$name_pkg/info", FileTest.EXISTS);
	}

	/* remove package with all files installed remove ~/suprastore/name_pkg */
	public void uninstall(string name_pkg) {
		int g_last_size = 0;

		if (Query.is_exist(name_pkg) == false)
			error("the package %s doesn't exist", name_pkg);

		const string remove = BOLD + YELLOW + "[Remove]" + NONE + " ";
		int prefix_len = config.prefix.length;
		var lst = Query.get_from_pkg(name_pkg).get_installed_files();
		for (int i = 0; i != lst.length; ++i) {
			{
				int file_len = lst[i].length;
				int calc = g_last_size - file_len;

				if (calc <= 0)
					calc = 1;
				stdout.printf("%s[%u/%u] %s%*c\r", remove, i+1, lst.length, lst[i][prefix_len:], calc, ' ');
				g_last_size = file_len;
			}
			FileUtils.unlink(lst[i]);
		}
		Query.remove_pkg(name_pkg);
		print("\n");
	}

	/**
	* return the Package struct from a package-name
	*/
	public Package get_from_pkg(string name_pkg) {
		var pkg = Package.from_file(@"$(config.cache)/$name_pkg/info");
		return pkg;
	}

	/**
	* Add package in required_by ex:  sfml -> openal
	*/
	public void add_package_to_required_by(string name_pkg, string package_add) throws Error {
		var dest = @"$(config.cache)/$package_add/required_by";
		var line = name_pkg + "\n";
		string contents;
		if (FileUtils.test(dest, FileTest.EXISTS)) {
			FileUtils.get_contents(dest, out contents);
		}
		else
			contents = "";
		if ((line in contents) == false) {
			FileUtils.set_contents(dest, contents + line);
		}
	}


	/* return all package required by name_pkg */
	public string[] get_required_by(string name_pkg) throws Error {
		string []res = {};
		string contents;
		var required_by = @"$(config.cache)/$name_pkg/required_by";
		if (FileUtils.test(required_by, FileTest.EXISTS) == false) {
			return res;
		}
		else {
			FileUtils.get_contents(required_by, out contents);
			foreach (var deps in contents.split("\n")) {
				if (deps.strip() == "")
					continue;
				res += deps;
			}
		}
		return res;
	}


	/* remove only ~/suprastore/PKG */
	private void remove_pkg(string name_pkg) {
		var pkg = @"$(config.cache)/$name_pkg/";
		FileUtils.unlink(pkg + "info");
		FileUtils.unlink(pkg + "required_by");
		DirUtils.remove(pkg);
	}

	// return all package ever install
	public Package []get_all_package(){
		try {
			Package []result = {};
			var dir = Dir.open(config.cache);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg" && FileUtils.test(@"$(config.cache)/$tmp", FileTest.IS_DIR))
					if (Query.is_exist(tmp))
						result += Package.from_file(@"$(config.cache)/$tmp/info");
			}
			return result;
		}catch(Error e) {
			error(e.message);
		}
	}

	// return all package ever install
	public string []get_all_installed_pkg() {
		try {
			string []result = {};
			var dir = Dir.open(config.cache);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg" && FileUtils.test(@"$(config.cache)/$tmp", FileTest.IS_DIR))
					result += tmp.dup();
			}
			return result;
		}catch(Error e) {
			error(e.message);
		}
	}
}
