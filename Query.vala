namespace Query{

	/* verify if package is installed in ~/suprastore/name_pkg */
	public bool is_exist(string name_pkg) {
		return FileUtils.test(@"$(config.cache)/$name_pkg/info", FileTest.EXISTS);
	}

	/* remove package with all files installed remove ~/suprastore/name_pkg */
	public void uninstall(string name_pkg) {
		unowned uint8[] blank = CONST_BLANK.data;
		int g_last_size = 0;

		if (Query.is_exist(name_pkg) == false)
			print_error(@"the package $name_pkg doesn't exist");

		int prefix_len = config.prefix.length;
		var lst = Query.get_from_pkg(name_pkg).get_installed_files();
		for (int i = 0; i != lst.length; ++i) {
			{
				int file_len = lst[i].length;
				int calc = g_last_size - file_len;
				
				if (calc <= 0)
					calc = 1;
				blank[calc] = '\0';
				stdout.printf("%s%s[Remove]%s [%u/%u] %s%s\r", BOLD, YELLOW, NONE, i+1, lst.length, lst[i][prefix_len:], (string)blank);
				blank[calc] = ' ';
				g_last_size = file_len;
			}
			FileUtils.unlink(lst[i]);
		}
		Query.remove_pkg(name_pkg);
		print("\n");
	}

	/* return the Package struct from a package-name */
	public Package get_from_pkg(string name_pkg) {
		var pkg = Package.from_file(@"$(config.cache)/$name_pkg/info");
		return pkg;
	}
	

	/* remove only ~/suprastore/PKG */
	private void remove_pkg(string name_pkg) {
		var pkg = @"$(config.cache)/$name_pkg/";
		FileUtils.unlink(pkg + "info");	
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
			print_error(e.message);
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
			print_error(e.message);
		}
	}
}
