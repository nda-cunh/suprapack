public void build_package(string usr_dir) {
	if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
		print_error(@"$usr_dir is not a dir or doesn't exist");
	var pkg = Package.from_input();
	pkg.create_info_file(@"$usr_dir/info");

	var name_pkg = @"$(pkg.name)-$(pkg.version)";
	string []av = {"tar", "-cJf", @"$(name_pkg).suprapack", "-C", usr_dir, "."};
	try {
		var tar = new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE);
		tar.wait();
	} catch(Error e) {
		print_error(e.message);
	}
	print_info(@"$(name_pkg).suprapack is created\n");
}
