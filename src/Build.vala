/*
 * This file is part of SupraPack.
 *
 * SupraPack is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SupraPack is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2025 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

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
		if (FileUtils.test(@"$usr_dir/PKGBUILD", FileTest.EXISTS)) {
			// move to usr_dir
			var last_dir = Environment.get_current_dir();
			if (config.build_output == ".") {
				config.build_output = last_dir;
			}
			print ("Using PKGBUILD in %s\n", @"$last_dir$usr_dir/PKGBUILD");
			var new_pwd = @"$last_dir/$usr_dir";
			Environment.set_variable("PWD", new_pwd, true);
			PWD = new_pwd;
			Environment.set_current_dir(new_pwd);
			new Makepkg (@"$new_pwd/PKGBUILD");
			Environment.set_current_dir(last_dir);
			return ;
		}

		// check if USR_DIR is a valid directory
		if (!(FileUtils.test(usr_dir, FileTest.EXISTS)) || !(FileUtils.test(usr_dir, FileTest.IS_DIR)))
			error("%s is not a dir or doesn't exist", usr_dir);

		if (check(usr_dir) == false) {
			Log.suprapack("Your usr_dir is not good are you sure ? [Y/n]\n");
			if (Utils.stdin_bool_choose ("Your usr_dir is not good are you sure ? [Y/n]", true) == false){
				Log.suprapack("Cancel...");
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
				Log.suprapack("Change lib/x86_64-linux-gnu");
				Process.spawn_command_line_sync(@"find $path/ -mindepth 1 -exec mv {} $usr_dir/lib/ \\;", null, out stderr);
				DirUtils.remove(path);
			}
			path = @"$usr_dir/include/x86_64-linux-gnu";
			if (FileUtils.test(@"$path/", FileTest.EXISTS)) {
				Log.suprapack("Change include/x86_64-linux-gnu");
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


		var usrdir_preinstall = @"$usr_dir/pre_install.sh";
		if (FileUtils.test(usrdir_preinstall, FileTest.EXISTS))
			FileUtils.chmod(usrdir_preinstall, 0777);
		var usrdir_uninstall = @"$usr_dir/uninstall";
		if (FileUtils.test(usrdir_uninstall, FileTest.EXISTS))
			FileUtils.chmod(usrdir_uninstall, 0777);
		var usrdir_postinstall = @"$usr_dir/post_install.sh";
		if (FileUtils.test(usrdir_postinstall, FileTest.EXISTS))
			FileUtils.chmod(usrdir_postinstall, 0777);
		string arch_normalize;
		if (config.build_target != null) {
			arch_normalize = Utils.get_arch_magik(config.build_target);
		}
		else {
			arch_normalize = Utils.get_arch_magik(pkg.arch);
		}

		var name_pkg = @"$(pkg.name)_$(pkg.version)_$(arch_normalize)";
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
		Log.suprapack("%s is created", package_dest);
		if (config.build_and_install == true) {
			prepare_install(package_dest, "", true);
			install();
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
	 * in the pre_install.sh script
	 *
	 * @param pkgdir the directory of the package
	 */
	private void autoconfig(string pkgdir) throws Error {
		var directory = File.new_for_path(pkgdir);
		process_directory(directory);
	}

	private void process_directory(File directory) throws Error {
		var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
		FileInfo info;

		while ((info = enumerator.next_file()) != null) {
			var child = directory.get_child(info.get_name());

			if (info.get_file_type() == FileType.DIRECTORY) {
				process_directory(child);
			} else if (info.get_name().has_suffix(".pc")) {
				patch_pc_file(child);
			}
		}
	}

	private void patch_pc_file(File file) throws Error {
		try {
			uint8[] content;
			file.load_contents(null, out content, null);
			var regex = new Regex("^prefix=.*", RegexCompileFlags.MULTILINE);
			string new_content = regex.replace((string)content, -1, 0, "prefix=${pcfiledir}/../..");
			file.replace_contents(new_content.data, null, false, FileCreateFlags.NONE, null);
		}
		catch (RegexError e) {
			warning("Erreur Regex sur %s: %s", file.get_path(), e.message);
		}
	}
}
