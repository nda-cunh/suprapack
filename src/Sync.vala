/**
 * Sync is like Query class but for the server
 *
 * it provide SupraList class and RepoInfo
 * it can download a package
 * it can download a list
 * it can check if a package need to be updated
 * it can refresh the list
 * @see Query.vala
 * @see SupraList.vala
 * @see RepoInfo.vala
 **/
class Sync : Object {
	//   SINGLETON
	private static Sync? singleton = null;
	private static unowned Sync default() {
		try {
			if (singleton == null)
				singleton = new Sync();
			return (singleton);
		}
		catch (Error e) {
			error (e.message);
		}
	}
	// Default private Constructor
	private Sync () throws Error {

		repo = null;
		list = null;
		/* init Repo property */
		string contents;
		var regex_repo = /(?P<name>[^\s]+)\s*(?P<url>[^\s]+)/;
		MatchInfo match_info;
		FileUtils.get_contents(config.repo_list, out contents);

		int count = 0;
		foreach (unowned var line in contents.split("\n")) {
			if (line == "")
				continue;
			if (line.has_prefix("#")) {
				// is a comment
			}
			else if (regex_repo.match(line, 0, out match_info)) {
				count++;
				string name = match_info.fetch_named("name");
				string url = match_info.fetch_named("url");
				if (!url.has_suffix ("/")) {
					warning ("Bad Format in %s/repo.list", config.prefix);
					printerr(" \033[33;1m%d\033[0m | %s\033[91m/\033[0m\n", count, line);
					printerr(" %*s | \033[91m%*s %s\033[0m\n\n", count.to_string().length, "", line.length + 1, "^", "~~ need terminate by  '/'");
				}
				if (url.has_prefix ("http"))
					_repo += new RepoInfo(name, url, false);
				else
					_repo += new RepoInfo(name, url, true);
			}
			else
				warning ("Can't read [%s] in %s/repo.list", line, config.prefix);
		}

		/* init List Property package-1.0.suprapack*/
		// var regex = /[a-zA-Z0-9]+[-][a-zA-Z0-9.]+[.]suprapack/;
		foreach (var repo in _repo) {
			FileUtils.get_contents(repo.list, out contents);
			foreach (var pkg in contents.split("\n")) {
				if (SupraList.regex.match(pkg)) {
					var lst = SupraList(repo.name, pkg, repo.local);
					if (Config.is_my_arch(lst.arch))
						_list += (owned)lst;
				}
				else if (pkg != "")
					warning(pkg);
			}
		}
	}



	/**
	 * Get a package from a package name
	 * @param package_name the name of the package
	 * @return SupraList (the package)
	 */
	public static SupraList get_from_pkg (string name_pkg) throws Error{
		var pkg_list = Sync.default()._get_list_package();
		foreach (unowned var pkg in pkg_list) {
			if (pkg.name == name_pkg) {
				return pkg;
			}
		}
		throw new ErrorSP.FAILED(@"Cant found $name_pkg");
	}

	/**
	 * Check if a package exist
	 * @param package_name the name of the package
	 * @return true if the package exist
	 */
	public static bool exist (string package_name) {
		var pkg_list = Sync.default()._get_list_package();
		foreach (unowned var pkg in pkg_list) {
			if (pkg.name == package_name) {
				return true;
			}
		}
		return false;
	}


	/**
	 * Check if a package need to be updated
	 * @param package_name the name of the package
	 * @return bool true if the package need to be updated
	 */
	public static bool check_update (string package_name) throws Error{
		try {
			var Qpkg = Query.get_from_pkg(package_name);
			var Spkg = Sync.get_from_pkg(package_name);

			return Utils.compare_versions (Spkg.version, Qpkg.version);
		}
		catch (Error e) {
			if (e is ErrorSP.FAILED)
				return false;
			throw e;
		}
	}

	/**
	 * Return the url from a repo name
	 * Example: get_url_from_name("cosmos") => "http://gitlab.com/suprastore_repo/cosmos/"...
	 *
	 * @param repo_name the name of the repo
	 * @return string the url of the repo
	 */
	private unowned string? get_url_from_name (string repo_name) {
		for (int i = 0; i < _repo.length; ++i) {
			if (_repo[i].name == repo_name) {
				return _repo[i].url;
			}
		}
		return null;
	}

	/**
	 * Return all package in all repo
	 *
	 * @param repo_name the name of the repo
	 * @return SupraList[] the list of package
	 */
	public static SupraList[] get_list_package(string repo_name = "") {
		return Sync.default()._get_list_package(repo_name);
	}

	private SupraList []_get_list_package (string repo_name = "") {
		SupraList[] result = {};

		if (repo_name == "")
			return list;
		for (int i = 0; i < list.length; ++i) {
			if (list[i].repo_name == repo_name) {
				result += list[i];
			}
		}
		return result;
	}

	/**
	 * Refresh the list of package
	 */
	public static void refresh_list () throws Error {
		if (singleton == null)
			singleton = new Sync();
		foreach (unowned var i in repo) {
			i.refresh_repo();
		}
		singleton = new Sync();
	}


	/**
	 * Download a package and return the location
	 *
	 * @param pkg_name the package to download
	 * @param repo_name the repository name
	 * @return string the location of the package
	 */
	public static string download_package (string pkg_name, string? repo_name = null) {
		var lst = Sync.default ()._get_list_package ();
		foreach (var l in lst) {
			if (repo_name == null || l.repo_name == repo_name)
				if (l.name == pkg_name)
					return Sync.default()._download(l);
		}
		error("can't download the file");
	}


	/**
	 * Download a package from a SupraList and return the location
	 *
	 * @param pkg the package to download
	 * @return string the location of the package
	 */
	public static string download (SupraList pkg) {
		Cancellable cancel = new Cancellable();
		return Sync.default()._download(pkg, cancel);
	}

	private string _download (SupraList pkg, Cancellable? cancel = null) {
		unowned string pkgname = pkg.pkg_name;
		string pkgdir = @"$(config.path_suprapack_cache)/pkg";
		string output = @"$pkgdir/$pkgname";
		DirUtils.create_with_parents(pkgdir, 0755);

		if (FileUtils.test (output, FileTest.EXISTS)) {
			return output;
		}
		string url = this.get_url_from_name(pkg.repo_name) + pkgname;
		try  {
			print(CURSOR);
			Log.debug("Sync", "Download [%s] from [%s] local:(%s)", pkg.name, url, pkg.is_local ? "true" : "false");
			if (pkg.is_local == true) {
				var file_list = GLib.File.new_for_path(url);
				var file_output = GLib.File.new_for_path(output);
				file_list.copy (file_output, FileCopyFlags.OVERWRITE);
				Log.debug("Sync", "Copy from local name: [%s] repo: [%s]", pkg.name, pkg.repo_name);
			}
			else
				Http.download(url, output, false, cancel);
			print(ENDCURSOR);
		} catch (Error e) {
			print(ENDCURSOR);
			FileUtils.remove (output);
			if (e is TlsError) {
				warning ("Try to install glib-networking");
			}
			error ("Can't download %s\n(%s)", url, e.message);
		}
		return output;
	}

	private static SupraList []list {get;set;}
	private static RepoInfo []repo {get;set;}
}
