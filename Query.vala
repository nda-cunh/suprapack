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
}
