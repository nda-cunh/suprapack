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
 * Copyright (C) 2026 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

namespace Cmd {

	public bool download (string []av) throws Error {
		if (av.length == 2)
			error("suprapack download <pkg>");

		foreach (unowned var pkg in av[2:av.length]) {
			var supralist = Sync.get_from_pkg(pkg);
			Log.download(@"%s %s", supralist.name, supralist.version);
			var path = Sync.download_package(pkg);
			if (path == null)
				error("Cant download $(av[2])");

			var file = File.new_for_path(path);
			var filed = File.new_for_path(Environment.get_current_dir() + "/" + file.get_basename());
			file.copy(filed, FileCopyFlags.OVERWRITE);
			if (config.force == true) {
				var dir_target =  @"./$(supralist.name)-$(supralist.version)";
				DirUtils.create(dir_target, 0755);
				Process.spawn_command_line_sync(@"tar -xf $(filed.get_path()) -C $(dir_target)");
			}
		}

		return true;
	}

	public void force_suprapack_update () throws Error {
		if (!Query.is_exist("suprapack"))
			return ;
		if (config.supraforce == false && Sync.check_update("suprapack")) {
			Log.info("Canceling... An update of suprapack is here");
			Process.spawn_command_line_sync(@"$(config.prefix)/bin/suprapack --force --supraforce add suprapack");
			var cmd_str = string.joinv(" ", config.cmd);
			Process.spawn_command_line_sync(cmd_str);
			Process.exit(0);
		}
	}

	/**
	 * The Command install of suprapack
	 *
	 * install a package from a repository or a file
	 *
	 * @param av: argv of command
	 * @return true if the install was successful
	 */
	public bool install (string []av) throws Error {
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

	public bool build (string []av) throws Error {
		if (av.length == 2) {
			if (FileUtils.test ("./PKGBUILD", FileTest.EXISTS)) {
				Build.create_package_from_dir ("./PKGBUILD");
				return true;
			}
			error("`suprapack build [...]`");
		}

		foreach (unowned var i in av[2:]) {
			Log.suprapack(@"Build %s", av[2]);
			if (FileUtils.test(@"$i/PKGBUILD", FileTest.EXISTS))
				Build.create_package_from_pkgbuild(i);
			else
				Build.create_package_from_dir(i);
		}
		return true;
	}

	public bool extract (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack extract [...]`");
		unowned string name = av[2];

		string dest;
		if (av.length == 4)
			dest = Path.build_filename ("./", av[3]);
		else {
			var sp = name.split("_");
			var pkgname = sp[0];
			var pkgver =  sp[1];
			dest = Path.build_filename("./", pkgname + "-" + pkgver);
		}
		Log.suprapack(@"Extract %s to %s", name, dest);
		Build.extract_package(name, dest);
		return true;
	}

	public bool info (string []av) throws Error {
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

	public bool have_update (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack have_update [...]`");

		var Qpkg = Query.get_from_pkg(av[2]);
		var Spkg = Sync.get_from_pkg(av[2]);
		if (Utils.compare_versions(Spkg.version, Qpkg.version))
			print("Update %s --> %s", Qpkg.version, Spkg.version);
		return true;
	}

	public bool uninstall (string []av) throws Error {
		if (av.length == 2)
			error("`suprapack uninstall [...]`");

		config.want_remove = true;
		Uninstall.uninstall(av);
		return true;
	}

	public bool list_files (string []av) throws Error {
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

	public bool list (string []av) throws Error {
		var installed = Query.get_all_package();
		int width = 0;
		int width_version = 0;
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
		print(NONE);
		return true;
	}

	public bool update (string []av) throws Error {
		force_suprapack_update();
		unowned string pkg_name;

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
		else {
			string? tmp;
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
}
