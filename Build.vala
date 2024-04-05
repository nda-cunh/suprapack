namespace Build {

	public void create_package(string usr_dir) throws Error {
		if (!FileUtils.test(usr_dir, FileTest.IS_DIR)) {
			new Makepkg (usr_dir);
			return ;
		}

		// check if USR_DIR is a valid directory
		if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
			print_error(@"$usr_dir is not a dir or doesn't exist");

		if (check(usr_dir) == false) {
			print_info("Your usr_dir is not good are you sure ? [Y/n]\n");
			var s = stdin.read_line()?.down();
			if ("n" in (s ?? "")) {
				print_info("Cancel...");
				Process.exit(0);
			}
		}
		// Modify the build_package

		string stderr;
		try {
			// modify /etc 
			if (FileUtils.test(@"$usr_dir/../etc", FileTest.EXISTS)) {
				Process.spawn_command_line_sync(@"mv $usr_dir/../etc $usr_dir/etc");
			}

			// modify x86_64-linux
			string path = @"$usr_dir/lib/x86_64-linux-gnu";
			if (FileUtils.test(@"$path/", FileTest.EXISTS)) {
				print_info("Change lib/x86_64-linux-gnu");
				Process.spawn_command_line_sync(@"find $path/ -mindepth 1 -exec mv {} $usr_dir/lib/ \\;", null, out stderr);
				DirUtils.remove(@"$path");
			}
			path = @"$usr_dir/include/x86_64-linux-gnu";
			if (FileUtils.test(@"$path/", FileTest.EXISTS)) {
				print_info("Change include/x86_64-linux-gnu");
				Process.spawn_command_line_sync(@"find $path/ -mindepth 1 -exec mv {} $usr_dir/include/ \\;", null, out stderr);
				DirUtils.remove(@"$path");
			}
		}catch(Error e) {
			print_error(e.message);
		}


		// Create the info_file or use it
		Package pkg;

		if (FileUtils.test(@"$usr_dir/info", FileTest.EXISTS)) {
			pkg = Package.from_file(@"$usr_dir/info");
		}
		else {
			pkg = Package.from_input();
		}
		pkg.size_installed = Utils.size_folder(usr_dir).to_string();
		pkg.create_info_file(@"$usr_dir/info");


		if (FileUtils.test(@"$usr_dir/pre_install.sh", FileTest.EXISTS))
			FileUtils.chmod(@"$usr_dir/pre_install.sh", 0777);
		if (FileUtils.test(@"$usr_dir/post_install.sh", FileTest.EXISTS))
			FileUtils.chmod(@"$usr_dir/post_install.sh", 0777);
		// compress the package
		var name_pkg = @"$(pkg.name)-$(pkg.version)";
		if (Utils.run_silent({"tar", "--zstd", "-cf", @"$(name_pkg).suprapack", "-C", usr_dir, "."}) != 0)
			print_error(@"unable to create package\npackage => $(name_pkg)");
		print_info(@"$(name_pkg).suprapack is created\n");
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
}
