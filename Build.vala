namespace Build {

	public void create_package(string usr_dir) {
		// check if USR_DIR is a valid directory
		if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
			print_error(@"$usr_dir is not a dir or doesn't exist");

		if (check(usr_dir) == false) {
			print_info("Your usr_dir is not good are you sure ? [y/N]\n");
			var s = stdin.read_line().down();
			if ("n" in s) {
				print_info("Cancel...");
				Process.exit(0);
			}
		}
		// Get a Package from input
		var pkg = Package.from_input();
		// generate info file in USR_DIR
		pkg.create_info_file(@"$usr_dir/info");

		// compress the package
		Build.compress(pkg, usr_dir);
	}
	
	private bool check(string usr_dir) {
		int n = 0;
		if (FileUtils.test(@"$usr_dir/bin", FileTest.EXISTS))
			n++;
		if (FileUtils.test(@"$usr_dir/lib", FileTest.EXISTS))
			n++;
		if (FileUtils.test(@"$usr_dir/share", FileTest.EXISTS))
			n++;
		return (n != 0);
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
