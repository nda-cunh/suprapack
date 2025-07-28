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

namespace Cmd {

	/**
	 * The Command shell of suprapack
	 *
	 * run zsh or bash in a suprapack environment
	 * @param av: argv of command
	 */
	bool shell (string []av) throws Error {
		var env = Environ.get();
		var shell = Environ.get_variable(env, "SHELL") ?? "/bin/bash";
		config.force = true;
		if (av.length == 3) {
			config.change_prefix (av[2]);
		}
		if (shell.has_suffix("bash"))
			Cmd.run({"suprapack", "run", shell, "--noprofile", "--norc"}, true);
		else if (shell.has_suffix("zsh"))
			Cmd.run({"suprapack", "run", shell, "-f"}, true);
		return true;
	}


	/**
	 * The Command download of suprapack
	 *
	 * just download a package from the repository
	 * @param av: argv of command
	 * @return true if the download was successful
	 */
	public bool download (string []av) throws Error {
		if (av.length == 2)
			error("suprapack download <pkg>");

		foreach (var pkg in av[2:av.length]) {
			var supralist = Sync.get_from_pkg(pkg);
			Log.download(@"%s %s", supralist.name, supralist.version);
			var path = Sync.download_package(pkg);
			if (path == null)
				error("Cant download $(av[2])");

			var file = File.new_for_path(path);
			var filed = File.new_for_path(Environment.get_current_dir() + "/" + file.get_basename());
			file.move(filed, FileCopyFlags.OVERWRITE);
			if (config.force == true) {
				var dir_target =  @"./$(supralist.name)-$(supralist.version)";
				DirUtils.create(dir_target, 0755);
				Process.spawn_command_line_sync(@"tar -xf $(filed.get_path()) -C $(dir_target)");
			}
		}

		return true;
	}


	/**
	 * The flag --refresh of suprapack
	 *
	 * refresh the packages list from the repository
	 *
	 * @return true if the refresh was successful
	 */
	public bool refresh () throws Error {
		Log.suprapack("Refreshing packages list");
		Sync.refresh_list();
		Log.suprapack("Packages list Refreshed");
		return true;
	}


	/**
	 * The hide command get_comp of suprapack
	 *
	 * print all installed package
	 *
	 * @param av: argv of command
	 * @return true if the get was successful
	 */
	public bool query_get_comp (string []av) {
		FileUtils.close (2);
		var pkgs = Query.get_all_package();
		for (var i = 0; i != pkgs.length; ++i) {
			if (i == pkgs.length - 1)
				print("%s", pkgs[i].name);
			else
				print("%s ", pkgs[i].name);
		}
		return true;
	}


	bool sync_get_comp (string []av) {
		FileUtils.close (2);
		var pkgs = Sync.get_list_package();
		for (var i = 0; i != pkgs.length; ++i) {
			if (i == pkgs.length - 1)
				print("%s", pkgs[i].name);
			else
				print("%s ", pkgs[i].name);
		}
		return true;
	}

	/**
	 * The Command install of suprapack
	 *
	 * install a package from a repository or a file
	 *
	 * @param av: argv of command
	 * @return true if the install was successful
	 */
	bool install (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack install [...]`");

		var regex = /((?P<repo>[^\s]*)\/)?(?P<package>[^\s]*)/;
		MatchInfo match_info;
		foreach (unowned var i in av[2:av.length]) {
			try {
				if (regex.match(i, 0, out match_info) && !i.has_suffix(".suprapack")) {
					string name_pkg = match_info.fetch_named("package");
					string name_repo = match_info.fetch_named("repo");
					prepare_install(name_pkg, name_repo, true);
				}
				else if (i.has_suffix(".suprapack")){
					prepare_install(i, null, true);
				}
			}
			catch (Error e) {
				if (e is ErrorSP.FAILED) {
					throw e;
				}
				else if (e is ErrorSP.NOT_FOUND) {
					var? new_name = BetterSearch.search_good_package_from_sync (e.message);
					if (new_name != null) {
						prepare_install(new_name, null, true);
					}
				}
				else
					warning ("Error: %s", e.message);
			}
		}
		global::install();
		return true;
	}


	/**
	 * The command build of suprapack
	 *
	 * build a suprapack package from a PKGBUILD file or a directory
	 * @param av : argv of command
	 */
	bool build (string []av) throws Error {
		if (av.length == 2) {
			if (FileUtils.test ("./PKGBUILD", FileTest.EXISTS)) {
				Build.create_package ("./PKGBUILD");
				return true;
			}
			error("`suprapack build [...]`");
		}

		foreach (var i in av[2:]) {
			Log.suprapack(@"Build %s", av[2]);
			Build.create_package(i);
		}
		return true;
	}


	/**
	 * The Command info of suprapack
	 *
	 * print information about a package
	 *
	 * @param av: argv of command
	 * @return true if the information was printed successfully
	 */
	bool info (string []av) throws Error {
		string tmp;
		if (av.length == 2)
			error("`suprapack info [...]`");
		if (Query.is_exist (av[2]) == false) {
			tmp = BetterSearch.search_good_package_from_query (av[2], true);
			if (tmp == null) {
				warning ("Cancelling ...");
				return false;
			}
		}
		else
			tmp = av[2];
		var info = Query.get_from_pkg(tmp);
		print(BOLD + "Nom                      : " + NONE + "%s\n", info.name);
		print(BOLD + "Version                  : " + NONE + "%s\n", info.version);
		print(BOLD + "Description              : " + NONE + "%s\n", info.description);
		print(BOLD + "Author                   : " + NONE + "%s\n", info.author);
		uint8 buffer[32];
		if (info.size_installed != "") {
			Utils.convertBytePrint(uint64.parse(info.size_installed), buffer);
			print(BOLD + "Installed Size           : " + NONE + "%s\n", buffer);
		}
		var dep_list = info.dependency.split(" ");
		if (dep_list.length >= 1) {
			print(BOLD + "Depends                  : " + NONE);
			foreach (unowned var dep in dep_list)
				print("%s ", dep);
			print("\n");
		}
		if (info.binary != info.name)
			print(BOLD + "Binary                   : " + NONE + "%s\n", info.binary);

		return true;
	}


	/**
	 * The Command have_update of suprapack
	 *
	 * check if a package have an update
	 * @param av: argv of command
	 * @return true if the package have an update
	 */
	public bool have_update (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack have_update [...]`");

		var Qpkg = Query.get_from_pkg(av[2]);
		var Spkg = Sync.get_from_pkg(av[2]);
		if (Utils.compare_versions(Spkg.version, Qpkg.version))
			print("Update %s --> %s", Qpkg.version, Spkg.version);
		return true;
	}


	/**
	 * The Command uninstall of suprapack
	 *
	 * uninstall a package
	 *
	 * @param av: argv of command
	 * @return true if the uninstall was successful
	 */
	bool uninstall (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack uninstall [...]`");

		config.want_remove = true;

		Uninstall.uninstall(av);
		return true;
	}


	/**
	 * The Command list_files of suprapack
	 *
	 * list all files installed by a package
	 *
	 * @param av: argv of command
	 * @return true if the list was successful
	 */
	bool list_files (string []av) {
		if (av.length == 2)
			error ("`suprapack list_files <pkg..>`");

		foreach (unowned var i in av[2:av.length]) {
			string tmp;

			if (Query.is_exist (i) == false) {
				tmp = BetterSearch.search_good_package_from_query (i, true);
				if (tmp == null) {
					warning ("Cancelling ...");
					continue;
				}
			}
			else
				tmp = av[2];
			try {
				var pkg = Query.get_from_pkg(tmp);
				Log.suprapack("%s %s", pkg.name, pkg.version);
				var lst = pkg.get_installed_files();
				foreach (unowned var file in lst) {
					print("%s\n", file);
				}
			}
			catch (Error e) {
				warning("Error: %s", e.message);
			}
		}

		return true;
	}


	/**
	 * The Command list of suprapack
	 *
	 * list all installed packages
	 *
	 * @param av: argv of command
	 * @return true if the list was successful
	 */
	bool list (string []av) {
		var installed = Query.get_all_package();
		int width = 0;
		int width_version = 0;
		try {
			var str_regex = av[2]?.replace("*", ".*") ?? "";
			var regex = new Regex(str_regex, RegexCompileFlags.EXTENDED);
			Package [] good = {};
			foreach (unowned var i in installed) {
				if ((regex.match(i.name) || regex.match(i.version) || regex.match(i.description) || regex.match(i.author))) {
					good += i;
				}
			}
			foreach (unowned var i in good) {
				if (i.name.length > width)
					width = i.name.length;
				if (i.version.length > width_version)
					width_version = i.version.length;
			}
			++width_version;
			++width;
			foreach (unowned var i in good) {
				uint8 buffer[32];
				unowned var size = Utils.convertBytePrint(uint64.parse(i.size_installed), buffer);
				const string format = BOLD + WHITE + "%-*s " + GREEN + " %-*s" + NONE;
				print(format, width, i.name, width_version, i.version, size);
				print("%9s" + COM + " %s" + NONE + "\n", size, i.description);
			}
		} catch (Error e) {
			error(e.message);
		}
		print(NONE);
		return true;
	}


	/**
	 * The Command prepare of suprapack
	 *
	 * prepare the repository (for dev)
	 */
	public bool prepare () {
		Repository.prepare();
		return true;
	}


	/**
	 * The Command search_supravim_plugin of suprapack
	 *
	 * print all suprapack plugin
	 *
	 * @param av: argv of command
	 */
	public void print_supravim_plugin (ref SupraList repo, bool installed) {
		if (installed)
			print("[installed] ");
		print("%s %s [%s]\n", repo.name, repo.version, repo.description);
	}


	public bool search_supravim_plugin (string []av) throws Error {
		force_suprapack_update();
		var list = Sync.get_list_package();
		var installed = Query.get_all_installed_pkg();

		foreach(var i in list) {
			if (i.name.has_prefix("plugin-"))
				print_supravim_plugin(ref i, (i.name in installed));
		}
		return true;
	}


	/**
	 * The Command search of suprapack
	 *
	 * search a package in the repository by regex pattern
	 * or print all package if no pattern is given
	 *
	 * @param av: argv of command
	 * @return true if the search was successful
	 */
	bool search (string []av) throws Error {
		force_suprapack_update();
		var list = Sync.get_list_package();
		var installed = Query.get_all_installed_pkg();
		// search without input
		if (av.length == 2) {
			for (var i = 0; i != list.length; ++i) {
				print_search(ref list[i], (list[i].name in installed));
			}
		}
		// search with regex pattern
		else {
			try {
				string regex_str = av[2].replace("*", ".*");
				var regex = new Regex(regex_str, RegexCompileFlags.OPTIMIZE);
				foreach(var i in list) {
					if ((regex.match(i.name) || regex.match(i.version) || regex.match(i.description)))
						print_search(ref i, (i.name in installed));
				}
			}
			catch (Error e) {
				error(e.message);
			}
		}
		print(NONE);
		return true;
	}

	private void print_search (ref SupraList repo, bool installed) {
		print(BOLD + PURPLE + " %s/" + WHITE, repo.repo_name);
		print("%s " + GREEN + "%s", repo.name, repo.version);
		if (installed)
			print(CYAN + " [installed]");
		print(NONE);
		if (repo.description != "")
			print("\n\t" + COM + "%s\n", repo.description);
	}

	/**
	 * The Command run of suprapack
	 * run the package.binary_name or the shell command with profile or suprapack
	 *
	 * it can accept --yes, --force argument
	 * if force is true it will run a shell command
	 *
	 * @param av: argv of command
	 * @param is_shell: if true run the command in a shell like bash or zsh
	 */
	bool run (string []av, bool is_shell = false) throws Error {
		string []av_binary;
		if (av.length == 2)
			error("`suprapack run [...]`");

		var? name_app = Environment.find_program_in_path (av[2]);
		if (Query.is_exist(av[2]) == false && name_app == null) {
			Log.suprapack("%s doesn't exist install it...", av[2]);
			Cmd.install({"", "install", av[2]});
		}
		name_app = Environment.find_program_in_path (av[2]);
		av_binary = {av[2]};
		if (Query.is_exist (av[2]) && config.force == false) {
			var pkg = Query.get_from_pkg(av[2]);
			av_binary = {pkg.binary};
		}
		else if (name_app == null && av[2].has_suffix(".suprapack"))
			name_app = av[2];
		else if (name_app == null)
			error("(%s) is not installed", av[2]);


		foreach (var i in av[3: av.length])
			av_binary += i;
		if (is_shell)
			Shell.run_shell(av_binary);
		else
			Shell.run(av_binary);
	}


	/**
	 * The Command update of suprapack
	 *
	 * update all packages or a specific package
	 *
	 * @param av: argv of command
	 * @return true if the update was successful
	 */
	bool update (string []av) throws Error {
		force_suprapack_update();
		unowned string pkg_name;

		// All Update
		if (av.length == 2) {
			var Qpkg = Query.get_all_installed_pkg();
			foreach (unowned var pkg in Qpkg) {
				try {
					if (Sync.check_update(pkg)) {
						prepare_install(pkg, Sync.get_from_pkg(pkg).repo_name);
					}
				}
				catch (Error e) {
					warning("Error: %s", e.message);
				}
			}
			global::install();
			return true;
		}
		// update pkg_name
		else {
			string tmp;
			foreach (unowned var i in av[2:av.length]) {
				if (Query.is_exist(i) == false) {
					tmp = BetterSearch.search_good_package_from_query(i, true);
					if (tmp == null) {
						warning ("Cancelling ...");
						return false;
					}
				}
				else
					tmp = i;
				pkg_name = tmp;
			}
			return true;
		}
	}


	/**
	 * The Command version of suprapack
	 *
	 * print the version of suprapack
	 *
	 * @return true if the version was printed successfully
	 */
	bool version () throws Error {
		print("SupraPack version: %s\n", Query.get_from_pkg ("suprapack").version);
		return true;
	}


	/**
	 * The Command help of suprapack
	 *
	 * print the help of suprapack
	 *
	 * @param help_command: the command to print the help for
	 * @return true if the help was printed successfully
	 */
	bool help (string help_command) {
		stdout.printf(BOLD + YELLOW + "[SupraPack] ----- Help -----\n\n");
		stdout.printf("\t" + p_suprapack + " (add | install) [package name]\n");
		stdout.printf("\t  " + COM + " install a package from a repository\n");
		stdout.printf("\t" + p_suprapack + " [(add | install)] [file.suprapack]\n");
		stdout.printf("\t  " + COM + " install a package from a file (suprapack)\n");
		stdout.printf("\t" + p_suprapack + " (remove | uninstall) [package name]\n");
		stdout.printf("\t  " + COM + " remove a package\n");
		stdout.printf("\t" + p_suprapack + " download [package name]\n");
		stdout.printf("\t  " + COM + " download the suprapack file, but do not install\n");
		stdout.printf("\t" + p_suprapack + " update\n");
		stdout.printf("\t  " + COM + " update all your package\n");
		stdout.printf("\t" + p_suprapack + " update [package name]\n");
		stdout.printf("\t  " + COM + " update a package\n");
		stdout.printf("\t" + p_suprapack + " search <pkg>\n");
		stdout.printf("\t  " + COM + " search a package in the repo you can use patern for search\n");
		stdout.printf("\t  " + BOLD + GREY + " Exemple:" + COM + " suprapack search " + CYAN + "'plugin*lsp' \n");
		stdout.printf("\t" + p_suprapack + " list_files <pkg>\n");
		stdout.printf("\t  " + COM + " list all file instaled by pkg\n");
		stdout.printf("\t" + p_suprapack + " list <pkg>\n");
		stdout.printf("\t  " + COM + " list your installed package\n");
		stdout.printf("\t" + p_suprapack + " info [package name]\n");
		stdout.printf("\t  " + COM + " print info of package name\n");
		stdout.printf("\t" + p_suprapack + " config [config name] [config value]\n");
		stdout.printf("\t  " + COM + " update a config in your user.conf\n");
		stdout.printf("\t" + p_suprapack + " <help>\n");
		stdout.printf("\t  " + COM + " you have RTFM... so you are a real\n");
		stdout.printf("\n");
		stdout.printf(BOLD + YELLOW + "[Special argument]\n" + NONE);
		unowned string help_text = help_command.offset(help_command.index_of("Options:") + 8);
		stdout.printf ("%s", help_text);
		stdout.printf("\n");
		stdout.printf(BOLD + YELLOW + "[Dev Only]\n" + NONE);
		stdout.printf(p_suprapack + " build " + CYAN + "[PREFIX]\n");
		stdout.printf("\t" + COM + " build a suprapack you need a prefix look note part\n");
		stdout.printf("\t" + COM + " you can add a post_install.sh or pre_install.sh\n");
		stdout.printf("\t" + COM + " install script can use $$SRCDIR and $$PKGDIR\n");
		stdout.printf(p_suprapack + " prepare\n");
		stdout.printf("\t" + COM + " prepare your repository\n");
		stdout.printf("\t" + COM + " to run in your folder full of suprapack files\n");
		stdout.printf("\t" + COM + " this command generate a list file\n");
		stdout.printf("\n");
		stdout.printf(BOLD + YELLOW + "[Note]\n" + NONE);
		stdout.printf(WHITE + "PREFIX is a folder with this directory like: \n" + NONE);
		stdout.printf(CYAN + "'bin' 'share' 'lib'\n" + NONE);
		stdout.printf(BOLD + WHITE + "Example: " + CYAN + "suprapatate/bin/suprapatate" + NONE + " `suprapack build suprapatate`\n");
		return true;
	}

	[NoReturn]
		private void loading (string []av) {
			if (av.length == 2)
				error("suprapack loading <command> [<args>]");
			int status = 0;
			var loop = new MainLoop();

			Utils.loading.begin();
			Utils.run_proc.begin(av, (obj, res) => {
					status = Utils.run_proc.end(res);
					loop.quit();
					});
			loop.run();
			Process.exit(status);
		}

	private const string p_suprapack = BOLD + "suprapack" + NONE;
}
