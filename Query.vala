namespace Query{
	public bool is_exist(string name_pkg) {
		return FileUtils.test(@"$(LOCAL)/$name_pkg/info", FileTest.EXISTS);
	}

	public Package get_from_pkg(string name_pkg) {
		var pkg = Package.from_file(@"$(LOCAL)/$name_pkg/info");
		return pkg;
	}
	public void remove_pkg(string name_pkg) {
		var pkg = @"$(LOCAL)/$name_pkg/";
		FileUtils.unlink(pkg + "info");	
		DirUtils.remove(pkg);
	}
}
