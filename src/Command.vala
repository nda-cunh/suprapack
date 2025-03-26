namespace Cmd {
	[NoReturn]
	void loading (string []av) {
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


	bool shell (string []av) throws Error {
		var env = Environ.get();
		var shell = Environ.get_variable(env, "SHELL") ?? "/bin/bash";
		config.force = true;
		if (shell.has_suffix("bash"))
			Cmd.run({"suprapack", "run", shell, "--noprofile", "--norc"}, true);
		else if (shell.has_suffix("zsh"))
			Cmd.run({"suprapack", "run", shell, "-f"}, true);
		return true;
	}


	bool download (string []av) throws Error {
		if (av.length == 2)
			error("suprapack download <pkg>");
		foreach (var pkg in av[2:av.length]) {
			var supralist = Sync.get_from_pkg(pkg);
			print_info(@"$(supralist.name) $(supralist.version)", "Download");
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


	bool refresh () throws Error {
		print_info("Refreshing packages list");
		Sync.refresh_list();
		print_info("Packages list Refreshed");
		return true;
	}


	bool query_get_comp (string []av) {
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
		var pkgs = Sync.get_list_package();
		for (var i = 0; i != pkgs.length; ++i) {
			if (i == pkgs.length - 1)
				print("%s", pkgs[i].name);
			else
				print("%s ", pkgs[i].name);
		}
		return true;
	}


	bool install (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack install [...]`");

		var regex = /((?P<repo>[^\s]*)\/)?(?P<package>[^\s]*)/;
		MatchInfo match_info;
		foreach (var i in av[2:av.length]) {
			try {
				if (regex.match(i, 0, out match_info) && !i.has_suffix(".suprapack")) {
					string name_pkg = match_info.fetch_named("package");
					string name_repo = match_info.fetch_named("repo");
					prepare_install(name_pkg, name_repo);
				}
				else if (i.has_suffix(".suprapack")){
					prepare_install(i);
				}
			}catch (Error e) {
				if (e is ErrorSP.FAILED) {
					throw e;
				}
				warning(e.message);
			}
		}
		global::install();
		return true;
	}


	bool build (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack build [...]`");
		foreach (var i in av[2:]) {
			print_info(@"Build $(av[2])");
			Build.create_package(i);
		}
		return true;
	}


	bool info (string []av) {
		if (av.length == 2)
			error("`suprapack info [...]`");
		var info = Query.get_from_pkg(av[2]);
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


	bool have_update (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack have_update [...]`");
		var Qpkg = Query.get_from_pkg(av[2]);
		var Spkg = Sync.get_from_pkg(av[2]);
		if (Utils.compare_versions(Spkg.version, Qpkg.version)) {
			print("Update %s --> %s", Qpkg.version, Spkg.version);
		}
		return true;
	}


	bool uninstall (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack uninstall [...]`");
		config.want_remove = true;

		Uninstall.uninstall(av);
		return true;
	}


	bool list_files (string []av) {
		if (av.length == 2) {
			print_info ("`suprapack list_files <pkg>`");
		}
		foreach (unowned var i in av[2:av.length]) {
			var pkg = Query.get_from_pkg(i);
			print_info(@"$(pkg.name) $(pkg.version)", "List");
			var lst = pkg.get_installed_files();
			foreach (unowned var file in lst) {
				print("%s\n", file);
			}
		}

		return true;
	}


	bool list (string []av) {
		var installed = Query.get_all_package();
		int width = 0;
		int width_version = 0;
		try {
			var regex = new Regex(av[2] ?? "", RegexCompileFlags.EXTENDED);
			foreach (unowned var i in installed) {
				if (regex.match(i.name) || regex.match(i.version) || regex.match(i.description) || regex.match(i.author)) {
					if (i.name.length > width)
						width = i.name.length;
					if (i.version.length > width_version)
						width_version = i.version.length;
				}
			}
			++width_version;
			++width;
			foreach (unowned var i in installed) {
				if (regex.match(i.name) || regex.match(i.version) || regex.match(i.description) || regex.match(i.author)) {
					uint8 buffer[32];
					unowned var size = Utils.convertBytePrint(uint64.parse(i.size_installed), buffer);
					const string format = BOLD + WHITE + "%-*s " + GREEN + " %-*s" + NONE;
					print(format, width, i.name, width_version, i.version, size);
					print("%9s" + COM + " %s" + NONE + "\n", size, i.description);
				}
			}
		} catch (Error e) {
			error(e.message);
		}
		print(NONE);
		return true;
	}


	bool prepare () {
		Repository.prepare();
		return true;
	}


	private void print_supravim_plugin (ref SupraList repo, bool installed) {
		if (installed)
			print("[installed] ");
		print("%s %s [%s]\n", repo.name, repo.version, repo.description);
	}


	bool search_supravim_plugin (string []av) throws Error {
		force_suprapack_update();
		var list = Sync.get_list_package();
		var installed = Query.get_all_installed_pkg();

		foreach(var i in list) {
			if (i.name.has_prefix("plugin-"))
				print_supravim_plugin(ref i, (i.name in installed));
		}
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
					if (regex.match(i.name) || regex.match(i.version) || regex.match(i.description))
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

	bool run (string []av, bool is_shell = false) throws Error {
		if (av.length == 2)
			error("`suprapack run [...]`");
		if (Query.is_exist(av[2]) == false && config.force == false) {
			print_info(@"$(av[2]) doesn't exist install it...");
			Cmd.install({"", "install", av[2]});
		}
		if (Query.is_exist(av[2]) == false && config.force == false) {
			error("(%s) is not installed", av[2]);
		}

		string []av_binary;

		if (config.force == false) {
			var pkg = Query.get_from_pkg(av[2]);
			if (pkg.binary.index_of_char('/') == -1)
				av_binary = {@"$(config.prefix)/bin/$(pkg.binary)"};
			else
				av_binary = {@"$(config.prefix)/$(pkg.binary)"};

			if (av.length >= 3) {
				foreach (var i in av[3: av.length])
					av_binary += i;
			}
		}
		else {
			av_binary = {av[2]};
			foreach (var i in av[3: av.length])
				av_binary += i;
		}
		if (is_shell)
			run_shell(av_binary);
		else
			Utils.run(av_binary);
		return true;
	}

	bool update (string []av) throws Error {
		force_suprapack_update();
		unowned string pkg_name;

		// All Update
		if (av.length == 2) {
			var Qpkg = Query.get_all_installed_pkg();
			foreach (var pkg in Qpkg) {
				if (Sync.check_update(pkg)) {
					prepare_install(pkg, Sync.get_from_pkg(pkg).repo_name);
				}
			}
			global::install();
			return true;
		}
		// update pkg_name
		else {
			pkg_name = av[2];
			if (Query.is_exist(pkg_name) == false) {
				error("%s is not installed", pkg_name);
			}
			return true;
		}
	}

	bool version () {
		print("SupraPack version: %s\n", Query.get_from_pkg ("suprapack").version);
		return true;
	}

	private const string p_suprapack = BOLD + "suprapack" + NONE;
	bool help () {
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
		stdout.printf("\t" + p_suprapack + " --prefix " + CYAN + "(all commands)\n");
		stdout.printf("\t  " + COM + " change the prefix for the install\n"); 
		stdout.printf("\t" + p_suprapack + " --strap " + CYAN + "(all commands)\n");
		stdout.printf("\t  " + COM + " change the strap for the install\n");
		stdout.printf("\t" + p_suprapack + " --force " + CYAN + "(install, uninstall, download)\n");
		stdout.printf("\t  " + COM + " force the install and reinstall all dependencies\n");
		stdout.printf("\t" + p_suprapack + " --yes " + CYAN + "(all commands)\n");
		stdout.printf("\t  " + COM + " say yes to all question\n");
		stdout.printf("\t" + p_suprapack + " --no-fakeroot " + CYAN + "(build)\n");
		stdout.printf("\t  " + COM + " disable fakeroot\n");
		stdout.printf("\t" + p_suprapack + " --build-output " + CYAN + "(build)\n");
		stdout.printf("\t  " + COM + " change the output for the build\n");
		stdout.printf("\t" + p_suprapack + " --install " + CYAN + "(build)\n");
		stdout.printf("\t  " + COM + " build and install a package\n");
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

}
