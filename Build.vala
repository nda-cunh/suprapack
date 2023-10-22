namespace Build {

	public void create_package(string usr_dir) {
		// check if USR_DIR is a valid directory
		if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
			print_error(@"$usr_dir is not a dir or doesn't exist");

		// Get a Package from input
		var pkg = Package.from_input();
		// generate info file in USR_DIR
		pkg.create_info_file(@"$usr_dir/info");

		// compress the package
		Build.compress(pkg, usr_dir);
	}

	private void compress(Package pkg, string usr_dir) {
		var name_pkg = @"$(pkg.name)-$(pkg.version)";
		string []av = {"tar", "-cJf", @"$(name_pkg).suprapack", "-C", usr_dir, "."};

		try {
			new Subprocess.newv(av, SubprocessFlags.STDERR_SILENCE).wait();
		} 
		catch(Error e) {
			print_error(e.message);
		}
		print_info(@"$(name_pkg).suprapack is created\n");
	}
}
