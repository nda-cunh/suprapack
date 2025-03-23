/**
 * Used by `suprapack build`
 * to create a package from a directory
 * or from a MAKEPKG file (like ArchLinux ([pacman]))
 */
namespace Build {

	/**
	 * Create a package from a directory and create the info file
	 * a good directory is a directory with bin, lib, share, etc
	 * if the directory is not good the user can cancel the operation
	 * and the package will not be created
	 *
	 * @param usr_dir the directory to create the package
	 */
	public void create_package(string usr_dir) throws Error {
		if (!FileUtils.test(usr_dir, FileTest.IS_DIR)) {
			new Makepkg (usr_dir);
			return ;
		}

		// check if USR_DIR is a valid directory
		if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
			error("%s is not a dir or doesn't exist", usr_dir);

		if (check(usr_dir) == false) {
			print_info("Your usr_dir is not good are you sure ? [Y/n]\n");
			if (Utils.stdin_bool_choose ("Your usr_dir is not good are you sure ? [Y/n]", true) == false){
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
				DirUtils.remove(path);
			}
			path = @"$usr_dir/include/x86_64-linux-gnu";
			if (FileUtils.test(@"$path/", FileTest.EXISTS)) {
				print_info("Change include/x86_64-linux-gnu");
				Process.spawn_command_line_sync(@"find $path/ -mindepth 1 -exec mv {} $usr_dir/include/ \\;", null, out stderr);
				DirUtils.remove(path);
			}
		}
		catch(Error e) {
			error(e.message);
		}


		// Create the info_file or use it
		Package pkg;

		var usrdir_info = @"$usr_dir/info";
		if (FileUtils.test(usrdir_info, FileTest.EXISTS)) {
			pkg = Package.from_file(usrdir_info);
		}
		else {
			pkg = Package.from_input();
		}
		pkg.size_installed = Utils.size_folder(usr_dir).to_string();
		pkg.create_info_file(usrdir_info);
		autoconfig (usr_dir);


		if (FileUtils.test(@"$usr_dir/pre_install.sh", FileTest.EXISTS))
			FileUtils.chmod(@"$usr_dir/pre_install.sh", 0777);
		if (FileUtils.test(@"$usr_dir/uninstall", FileTest.EXISTS))
			FileUtils.chmod(@"$usr_dir/uninstall", 0777);
		if (FileUtils.test(@"$usr_dir/post_install.sh", FileTest.EXISTS))
			FileUtils.chmod(@"$usr_dir/post_install.sh", 0777);
		var name_pkg = @"$(pkg.name)_$(pkg.version)_$(pkg.arch)";
		var package_dest = @"$(config.build_output)/$(name_pkg).suprapack";
		DirUtils.create_with_parents (config.build_output, 0755);
		var loop = new MainLoop();
		var thread = new Thread<void> (null, () => {
			// compress the package with fakeroot or not
				if (config.use_fakeroot == true) {

				if (Utils.run({"fakeroot", "tar", "--zstd", "-cf", package_dest, "-C", usr_dir, "."}, {}, true) != 0)
					error("unable to create package\npackage => %s", name_pkg);
			}
			else {

			if (Utils.run({"tar", "--zstd", "-cf", package_dest, "-C", usr_dir, "."}, {}, true) != 0)
					error("unable to create package\npackage =>  %s", name_pkg);
			}
			loop.quit();
		});
		Utils.loading.begin();
		loop.run ();
		thread.join ();
		print_info(@"$(package_dest) is created");
		if (config.build_and_install == true) {
			install_suprapackage (package_dest);
		}
	}

	/**
	 * check if the directory is a good directory
	 * a good directory is a directory with bin, lib, share, etc
	 *
	 * @param usr_dir the directory to check
	 * @return true if the directory is good
	 */
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


	/**
	 * autoconfig the package
	 * autoconfig is a script that will be executed before the installation
	 * it will replace the $PREFIX in the pkg-config files
	 * and add the sed command to replace the $PREFIX in the pkg-config files
	 * in the pre_install.sh script
	 *
	 * @param pkgdir the directory of the package
	 */
	private void autoconfig (string pkgdir) throws Error {
		var result = new StringBuilder();
		string contents;
		autoconfig_iter_dir (result, @"$pkgdir/lib/pkgconfig/");
		autoconfig_iter_dir (result, @"$pkgdir/share/pkgconfig/");
		autoconfig_iter_dir (result, @"$pkgdir/include/pkgconfig/");
		if (result.str != "") {
			if (FileUtils.test (@"$pkgdir/pre_install.sh", FileTest.EXISTS)) {
				FileUtils.get_contents (@"$pkgdir/pre_install.sh", out contents);
				FileUtils.set_contents (@"$pkgdir/pre_install.sh", contents + result.str);
			}
			else {
				FileUtils.set_contents (@"$pkgdir/pre_install.sh", "#!/bin/bash\n" + result.str);
			}
		}
	}

	private void autoconfig_iter_dir (StringBuilder result, string file_directory) throws Error {
		Dir dir;
		try {
			dir = Dir.open(file_directory);
		} catch (Error e) {
			return ;
		}
		string filename;
		string contents;

		while ((filename = dir.read_name ()) != null) {
			var output = @"$file_directory/$filename";
			debug("pkg-config %s", output);
			FileUtils.get_contents (output, out contents);
			var regex = new Regex("""^prefix.*?$""", RegexCompileFlags.MULTILINE);
			contents = regex.replace (contents, contents.length, 0, "prefix=$PREFIX");
			FileUtils.set_contents (output, contents);
			result.append ("sed -i \"s|\\$PREFIX|$(echo $prefix)|g\" ${SRCDIR}/");
			var index = 0;
			index = file_directory.last_index_of ("include/");
			if (index == -1)
				index = file_directory.last_index_of ("share/");
			if (index == -1)
				index = file_directory.last_index_of ("lib/");
			if (index == -1)
				warning ("index == -1 error in pkg-config transform");
			result.append (file_directory.offset(index) + filename);
			result.append_c ('\n');
		}
	}
}
