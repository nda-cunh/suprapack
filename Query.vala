namespace Query{

	// verify if package is installed in ~/suprastore/name_pkg
	public bool is_exist(string name_pkg) {
		return FileUtils.test(@"$(LOCAL)/$name_pkg/info", FileTest.EXISTS);
	}

	// return the Package struct from a package-name
	public Package get_from_pkg(string name_pkg) {
		var pkg = Package.from_file(@"$(LOCAL)/$name_pkg/info");
		return pkg;
	}
	

	// remove only ~/suprastore/PKG
	public void remove_pkg(string name_pkg) {
		var pkg = @"$(LOCAL)/$name_pkg/";
		FileUtils.unlink(pkg + "info");	
		DirUtils.remove(pkg);
	}

	// return all package ever install
	public Package []get_all_package(){
		try {
			Package []result = {};
			var dir = Dir.open(LOCAL);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg")
					if (Query.is_exist(tmp))
						result += Package.from_file(@"$(LOCAL)/$tmp/info");
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
			var dir = Dir.open(LOCAL);
			unowned string? tmp;

			while ((tmp = dir.read_name()) != null) {
				if (tmp[0] != '.' && tmp != "pkg")
					result += tmp.dup();
			}
			return result;
		}catch(Error e) {
			print_error(e.message);
		}
	}
}
