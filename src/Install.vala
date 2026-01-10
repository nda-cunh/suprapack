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

// List all files in a directory (like `ls -R`)
private void list_file_dir(string emp_dir, ref GenericArray<string> list, int depth = 0) {
	const string except_files[] = {"info", "pre_install.sh", "post_install.sh", "uninstall", "pre_install", "post_install", "env"};
	try {
		var dir = Dir.open(emp_dir);
		unowned string it;
		while ((it = dir.read_name()) != null) {
			if (depth == 0) {
				if (it in except_files)
					continue;
			}
			string name = Path.build_filename(emp_dir, it);
			if (FileUtils.test(name, FileTest.IS_DIR) && !FileUtils.test(name, FileTest.IS_SYMLINK))
				list_file_dir(name, ref list, depth + 1);
			else
				list.add(name);
		}
	} catch (Error e) {
		error(e.message);
	}
}

// copy files to PREFIX (~/.local)
private void install_files(GenericArray<string> list, int len) {
	const string install = BOLD + YELLOW + "[Install]" + NONE + " ";
	unowned string basename;
	uint nb = 0;
	uint list_length = list.length;
	int g_last_size = 0;

	try {
		foreach (unowned var e in list.data) {
			basename = e.offset(len);
			var fileSrc = File.new_for_path(e);
			var last_dest = config.prefix + basename;
			FileUtils.unlink(last_dest);
			var fileDest = File.new_for_path(last_dest);
			var path = fileDest.get_path();
			path = Path.get_dirname(path);
			DirUtils.create_with_parents(path, 0755);
			fileSrc.move(fileDest, FileCopyFlags.OVERWRITE);
			{
				int file_len = basename.length;
				int calc = g_last_size - file_len;

				if (calc <= 0)
					calc = 1;
				++nb;
				if (config.simple_print) {
					uint percent = (nb * 100) / list_length;
					stdout.printf("install: [%u] %s\n", percent, basename);
				}
				else
					stdout.printf("%s[%u/%u] %s%*c\r", install, nb, list_length, basename, calc, ' ');
				g_last_size = file_len;
			}
		}
	} catch (Error e) {
		error("FATAL ERROR >>> %s", e.message);
	}
	print("\n");
}


// Create the package information in .suprapack/name_pkg/info
private void post_install(GenericArray<string> list, int len, ref Package pkg) {
	string packinfo = @"$(config.path_suprapack_cache)/$(pkg.name)";
	string info_file = @"$packinfo/info";

	DirUtils.create_with_parents(packinfo, 0755);
	pkg.create_info_file(info_file);
	var fs = FileStream.open(info_file, "a");
	if (fs == null)
		error("Cant open %s", info_file);
	fs.printf("[FILES]\n");
	foreach(unowned var i in list.data) {
		unowned string basename = i.offset(len);
		if (basename != "/info") {
			fs.puts(basename);
			fs.putc('\n');
		}
	}
}

private bool run_post_pre_script (string dir, string filename, string print_name) throws Error {
	FileUtils.chmod(filename, 0777);
	if (FileUtils.test(filename, FileTest.EXISTS | FileTest.IS_EXECUTABLE)) {
		if (config.show_script == true && config.allays_yes == false) {
			string contents;
			FileUtils.get_contents(filename, out contents);
			print("[%s] {\n%s\n}\n", print_name, contents);
			if (Utils.stdin_bool_choose("Continue ? [Y/n]", true) == false)
				throw new ErrorSP.ACCESS("you refused to execute the script.");
		}
		info("%s", print_name);
		var envp = Utils.prepare_envp(dir);
		if (Utils.run({filename}, envp) != 0)
			throw new ErrorSP.FAILED("non zero exit code of pre installation script");
		return true;
	}
	return false;
}

private void script_pre_install(string dir) throws Error {
	if (run_post_pre_script(dir, @"$dir/pre_install", "Pre Install") == false)
		run_post_pre_script(dir, @"$dir/pre_install.sh", "Pre Install");
}

private void script_post_install(string dir) throws Error {
	if (run_post_pre_script(dir, @"$dir/post_install", "Post Install") == false)
		run_post_pre_script(dir, @"$dir/post_install.sh", "Post Install");
}

// install package suprapack
public void install_suprapackage(Package suprapack) throws Error {
	force_suprapack_update();

	unowned string output = suprapack.output;

	if (FileUtils.test(output, FileTest.EXISTS)) {
		if (!(output.has_suffix(".suprapack")))
			throw new ErrorSP.BADFILE("ce fichier n'est pas un suprapack");
	}
	else
		throw new ErrorSP.ACCESS("%s n'existe pas", output);
	var tmp_dir = DirUtils.make_tmp("suprastore_XXXXXX");
	Log.suprapack("Extraction de " + CYAN + "%s" + NONE, output);
	if (Utils.run({"tar", "-xf", output, "-C", tmp_dir}, {}, true) != 0)
		throw new ErrorSP.FAILED("unable to decompress package\npackage => %s", output);

	debug ("Extracted in %s/info (%s)", tmp_dir, output);
	var pkg = Package.from_file(@"$tmp_dir/info");
	pkg.is_wanted = suprapack.is_wanted;

	/* Pre Install script launch */
	script_pre_install(tmp_dir);
	if (Query.is_exist(pkg.name)) {
		Query.uninstall(pkg.name);
	}

	Log.suprapack("Installation de" + CYAN + " %s %s" + NONE + " par %s", pkg.name, pkg.version, pkg.author);

	var list = new GenericArray<string>(512);
	list_file_dir(tmp_dir, ref list);
	install_files(list, tmp_dir.length);

	/* Post Install script launch */
	script_post_install(tmp_dir);

	// create info file
	post_install(list, tmp_dir.length, ref pkg);


	// Uninstall script
	if (FileUtils.test(@"$tmp_dir/uninstall", FileTest.EXISTS)) {
		var fileSrc = File.new_for_path(@"$tmp_dir/uninstall");
		var fileDest = File.new_for_path(@"$(config.path_suprapack_cache)/$(pkg.name)/uninstall");
		fileSrc.move(fileDest, FileCopyFlags.OVERWRITE);
	}

	// remove useless tmp dir
	if (Utils.run({"rm", "-rf", tmp_dir}, {}, true) != 0)
		new OptionError.FAILED("unable to remove directory\ndirectory => %s", tmp_dir);
}


private void force_suprapack_update () throws Error {
	if (!Query.is_exist("suprapack"))
		return ;
	if (config.supraforce == false && Sync.check_update("suprapack")) {
		info("Canceling... An update of suprapack is here");
		Process.spawn_command_line_sync(@"$(config.prefix)/bin/suprapack --force --supraforce add suprapack");
		var cmd_str = string.joinv(" ", config.cmd);
		Process.spawn_command_line_sync(cmd_str);
		Process.exit(0);
	}
}



public void install () throws Error {
	force_suprapack_update();

	print("\nresolving dependencies...\n");

	if (config.queue_pkg.size == 0){
		info("there's nothing to be done");
		return;
	}

	print("looking for conflicting packages...\n");

	int name_max = 0;
	int version_max = 0;
	foreach (unowned var i in config.queue_pkg) {

		foreach (unowned var exclude in i.exclude_package.split(" ")) {
			exclude = exclude._strip();
			if (Query.is_exist(exclude)) {
				if (Query.is_exist(i.name)) {
					var pkg = Query.get_from_pkg(i.name);	
					if (exclude in pkg.get_all_dependency()) {
						warning ("Uninstalling %s because it is an old dependency of %s\n", exclude, i.name);
						var pkg_exclude = Query.get_from_pkg(exclude);
						config.queue_pkg_uninstall.add(pkg_exclude);
						continue ;
					}
				}
				Log.conflict("Impossible to install '%s' because '%s' is in conflict with him", i.name, exclude);
				Log.conflict("please choose if you want to uninstall '%s' [y/N]", exclude);
				if (Utils.stdin_bool_choose(": ", false)) {
					var pkg_exclude = Query.get_from_pkg(exclude);
					config.queue_pkg_uninstall.add(pkg_exclude);
				}
				else {
					throw new ErrorSP.CANCEL("Cancelling...");
				}
			}
		}

		/* Calc the len for padding*/
		var len = (i.name.length + i.repo.length + 2);
		if (len > name_max)
			name_max = len;
		len = (i.version.length);
		if (len > version_max)
			version_max = len;
	}

	int64 size_installed = 0;
	int64 size_uninstalled = 0;
	print("Package (%u)\n\n", config.queue_pkg.size);

	foreach (unowned var? i in config.queue_pkg) {
		string version = i.version;
		if (Query.is_exist(i.name)) {
			version = Query.get_from_pkg(i.name).version;
		}
		printf("  " + BOLD + PURPLE +"%s" + NONE + "/%-*s " + BOLD + GREEN, i.repo, name_max - i.repo.length, i.name);
		printf("%-*s" + NONE, version_max, version);
		if (version != i.version)
			printf(" --> " + BOLD + YELLOW + "%s", i.version);
		printf(NONE + "\n");
		size_installed += int64.parse(i.size_installed);
	}

	if (config.queue_pkg_uninstall.size > 0) {
		print(BOLD + COM + "\nUninstalling (%u)\n\n", config.queue_pkg_uninstall.size);
		foreach (unowned var? i in config.queue_pkg_uninstall) {
			string version = i.version;
			if (Query.is_exist(i.name)) {
				version = Query.get_from_pkg(i.name).version;
			}
			uint8 buffer[32];
			Utils.convertBytePrint (int64.parse(i.size_installed), buffer);
			printf (BOLD + PURPLE + "  " + RED + "%s " + COM + " %-20s\n" + NONE, i.name, buffer);
			size_uninstalled += int64.parse(i.size_installed);
		}
	}

	uint8 buffer[32];
	if (size_uninstalled > 0) {
		Utils.convertBytePrint (size_uninstalled, buffer);
		print(COM + "\nTotal Uninstalled Size: " + BOLD + RED + "%s" + NONE + "", (string)buffer);
	}
	Utils.convertBytePrint   (size_installed, buffer);
	print("\nTotal Installed Size:  " + BOLD + "%s" + NONE + "\n", (string)buffer);

	config.queue_pkg.reverse();

	if (config.allays_yes || Utils.stdin_bool_choose(":: Proceed with installation [Y/n] ", true)) {
		print("\n");
		// Remove all suprapackages in the queue
		foreach (unowned var i in config.queue_pkg_uninstall) {
			Query.uninstall(i.name);
		}
		// Installation of suprapackages
		foreach (unowned var i in config.queue_pkg) {
			if (config.force == true || i.is_wanted == true) {
				install_suprapackage(i);
			}
			else {
				if (Query.is_exist(i.name) == true) {
					if (Sync.check_update(i.name)) {
						install_suprapackage(i);
					}
					else
						info("%s is already installed", i.name);
				}
				else
					install_suprapackage(i);
			}
			if (!config.is_cached && i.repo != "Local") {
				FileUtils.unlink(i.output);
			}
		}
		/* add dependency in  .required_by file */
		foreach (unowned var i in config.queue_pkg) {
			// Dependency of the package
			foreach (unowned var deps in i.dependency.split(" ")) {
				Query.add_package_to_required_by(i.name, deps);
			}
		}
	}
	else {
		throw new ErrorSP.CANCEL("Cancelling...");
	}
}

//* Add one package in Config.queue *//
private void prepare_install (string name_search, string? name_repo = null, bool is_wanted = false) throws Error{
	if (name_search == "")
		return;
	// Check and update if 'Suprapack' have the last version
	force_suprapack_update();

	// Check if the package is a local file (file.suprapack)
	if (name_search.has_suffix(".suprapack")) {
		if (!FileUtils.test(name_search, FileTest.EXISTS))
			throw new ErrorSP.NOT_FOUND(name_search);
		SupraList pkg = SupraList("Local", name_search, true);
		pkg.is_wanted = is_wanted;
		add_queue_list(pkg, name_search);
		return;
	}


	// get all package with the same name in all repo or in a specific repo
	SupraList[] queue = {};
	var list = Sync.get_list_package (name_repo ?? "");
	foreach (unowned var pkg in list) {
		if (pkg.name == name_search) {
			queue += pkg;
		}
	}

	SupraList pkg;

	// if no package found
	if (queue.length == 0) {
		if (Query.is_exist(name_search) == true) {
			throw new ErrorSP.ACCESS("Can't found %s but exist in local", name_search);
		}
		throw new ErrorSP.NOT_FOUND(name_search);
	}
	// if only one package found
	else if (queue.length == 1){
		pkg = queue[0];
	}
	// if multiple package found
	else {
		// if Force search auto best package
		if (config.force == true) {
			var lst = Utils.sort_supralist_version(queue);
			pkg = lst[lst.length - 1];
		}
		else {
			Log.conflict("Similar package are found");
			for (int i = 0; i < queue.length; i++) {
				print("%s", BOLD);
				print("%4d) " + PURPLE + "%s/" + WHITE + "%s [%s]" + NONE + "\n", i, queue[i].repo_name, queue[i].name, queue[i].version);
			}
			print("please choose one: ");
			var nb = int.parse(stdin.read_line());
			if (nb < 0 || nb > queue.length - 1) {
				info("Cancelling...");
				return ;
			}
			pkg = queue[nb];
		}
	}

	// Download the package
	var output = Sync.download(pkg);
	// Add the package in the queue	
	pkg.is_wanted = is_wanted;
	add_queue_list(pkg, output);
}

// Add package in the queue
// output is the path of the file package (/tmp/lua_5.4.7_amd64-Linux.suprapack)
// pkg is the package object with all the info of the package
private void add_queue_list(SupraList pkg, string output) throws Error {
	Log.debug ("Add in queue: %s", pkg.name);
	// get the info file of the package
	Process.spawn_command_line_sync(@"tar -xf $(output) ./info");
	// Create the package object with the info file
	Package pkgtmp = Package.from_file("./info");
	FileUtils.unlink("./info");
	pkgtmp.output = output;
	pkgtmp.repo = pkg.repo_name;
	pkgtmp.is_wanted = pkg.is_wanted;

	// Add the package in the queue
	config.queue_pkg.add(pkgtmp);

	// Add alls dependencies of the package in the queue
	try {
		// Add Dependency in QUEUE
		foreach (unowned var i in pkgtmp.get_dependency()) {
			// skip if the package is already in the queue
			if (config.queue_pkg.contains_name(i)) {
				continue;
			}
			
			// if the package is ever installed don't add it in the queue
			// if the force option is not set, add only if the package have an update 
			if (Query.is_exist(i) && config.force == false) {
				if (Sync.check_update(i))
					prepare_install(i);
				continue;
			}
			// if `force` option is set, add it
			else
				prepare_install(i);
		}
		// Add Optional Dependency in QUEUE
		foreach (unowned var i in pkgtmp.optional_dependency.split(" ")) {
			// skip if the package is already in the queue
			if (config.queue_pkg.contains_name(i)) {
				continue;
			}
			// if the package is not found in repository skip it because it's optional
			if (Sync.exist(i) == false) {
				Log.skip("\033[95m Optional Dependency %s not found" + NONE, i);
				continue;
			}
			// if the package is ever installed don't add it in the queue
			// if the force option is not set, add only if the package have an update
			if (Query.is_exist(i) && config.force == false) {
				if (Sync.check_update(i))
					prepare_install(i);
				continue;
			}
			// if `force` option is set, add it
			else
				prepare_install(i);
		}
	}
	catch (Error e)
	{
		throw new ErrorSP.FAILED("Dependency of %s -> %s", pkg.name, e.message);
	}
}
