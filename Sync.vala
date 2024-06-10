// Contains Informations or package from the repo
// repo_name (Cosmos)
// name (suprabear)
// version (1.2)
public struct SupraList {
	public SupraList (string repo_name, string line, bool is_local) {
		this.is_local = is_local;
		//42cformatter-v1.0.suprapack c formatter for 42 norm
		MatchInfo match_info;
		var regex = /(?P<pkgname>.*?)[.]suprapack/;

		if (regex.match(line, 0, out match_info)) {
			this.repo_name = repo_name;
			pkg_name = match_info.fetch_named("pkgname") + ".suprapack";

			name = pkg_name[0:pkg_name.last_index_of_char ('-')];
			version = pkg_name[pkg_name.last_index_of_char ('-') + 1 : pkg_name.last_index_of_char ('.')];
			description = line.offset(pkg_name.length).strip();
		}
	}
	unowned string repo_name;
	string pkg_name;
	string name;
	string version;
	string description;
	bool is_local; 
}


// RepoInfo contains information of a repo like Cosmos 
// name  (Cosmos)
// url (http://gitlab/../../)
public class RepoInfo : Object{
	public RepoInfo(string name, string url) {
		this.local = false;
		this.name = name;
		this.url = url;
		this._list = null;
	}

	/* fetch the 'list' file  LOCAL or HTTP */
	public void fetch_list (string url, string output) throws Error {
		string url_list = url;
		// message("URL %s", url_list);
		if (url.has_prefix ("http")) {
			url_list += "list";
			debug("Repository", "FETCH HTTP repository %s", url_list);
			try {
				Utils.download(url_list, output, true); 
			}
			catch (Error e) {
				FileUtils.remove (output);
				throw e;
			}
		}
		else {
			url_list += "/list";
			var file_list = GLib.File.new_for_path(url_list);
			var file_output = GLib.File.new_for_path(output);
			file_list.copy (file_output, FileCopyFlags.OVERWRITE);
			debug("Repository", "FETCH local repository %s", url_list);
			this.local = true;
		}
	}

	/* force download the 'list' file */
	public void refresh_repo() {
		string list_file = @"/tmp/$(this.name)_$(USERNAME)_list";
		FileUtils.remove(list_file);
		try {
			fetch_list(this.url, list_file);
		} catch (Error e) {
			error("unable to download file %s", e.message);
		}
		_list = list_file;
	}

	private string? _list;
	public string list {
		get {
			if (_list == null) {
				string list_file = @"/tmp/$(this.name)_$(USERNAME)_list";
				bool should_download = true;
				if (FileUtils.test (list_file, FileTest.EXISTS)) {
					var stat = Stat.l(list_file);
					var now = time_t();
					if (stat.st_mtime + 700 > now)
						should_download = false;
				}
				try {
					if (should_download == true) {
						fetch_list(this.url, list_file);
					}
				} catch (Error e) {
					error("unable to download file %s", e.message);
				}
				_list = list_file;
			}
			return _list;
		}
	}

	public string name;
	public string url;
	public bool local;
}


// Sync class is connected to all Repository
// he can download list
// he can download package
// have to the management of all repository online
class Sync {
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

		groups = new Groups();
		repo = null;
		list = null;
		/* init Repo property */
		string contents;
		var regex_repo = /(?P<name>[^\s]+)\s*(?P<url>[^\s]+)/;
		MatchInfo match_info;
		FileUtils.get_contents(config.repo_list, out contents);

		int count = 0;
		foreach (var line in contents.split("\n")) {
			if (line == "")
				continue;
			if (regex_repo.match(line, 0, out match_info)) {
				count++;
				string name = match_info.fetch_named("name");
				string url = match_info.fetch_named("url");
				if (url.has_suffix ("/"))
					_repo += new RepoInfo(name, url);
				else {
					warning ("Bad Format in %s/repo.list", config.prefix);
					printerr(" \033[33;1m%d\033[0m | %s\033[91m/\033[0m\n", count, line);
					printerr(" %*s | \033[91m%*s %s\033[0m\n\n", count.to_string().length, "", line.length + 1, "^", "~~ need terminate by  '/'");
				}
			}
			else
				warning ("Can't read [%s] in %s/repo.list", line, config.prefix);
		}

		/* init List Property */
		var regex = /[a-zA-Z0-9]+[-][a-zA-Z0-9.]+[.]suprapack/;
		foreach (var repo in _repo) {
			FileUtils.get_contents(repo.list, out contents);
			var lines = contents.split("\n");
			int i = 0;
			// foreach (unowned var pkg in lines) {
			for(; i != lines.length; ++i) {
				if (lines[i] == "[Groups]")
					break;
				else if (regex.match(lines[i])) {
					_list += SupraList(repo.name, lines[i], repo.local);
				}
				else if (lines[i] != "")
					warning(lines[i]);
			}
			if (lines[i] != "[Groups]")
				break;
			for (++i; i != lines.length; ++i) {
				groups.add_line (lines[i]);
			}
		}
	}


	/////////////////////////////////////////////////////////////////
	//							Groups 
	/////////////////////////////////////////////////////////////////


	public static unowned List<List<string>> group_get_from_name(string name) {
		return groups[name];
	}


	public static SupraList get_from_pkg(string name_pkg) throws Error{
		var pkg_list = Sync.default()._get_list_package();
		foreach (var pkg in pkg_list) {
			if (pkg.name == name_pkg) {
				return pkg;
			}
		}
		throw new ErrorSP.FAILED(@"Cant found $name_pkg");
	}

	// return true if need update else return false
	public static bool check_update(string package_name) throws Error{
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

	// return url from a repo_name (comsos)  -> gitlab
	private unowned string? get_url_from_name(string repo_name) {
		foreach (var repo in _repo) {
			if (repo.name == repo_name) {
				return repo.url;
			}
		}
		return null;
	}

	/* Return supralist from a repo or all supralist */
	public static SupraList[] get_list_package(string repo_name = "") {
		return Sync.default()._get_list_package(repo_name);
	}

	// return all package in all repo
	SupraList []_get_list_package (string repo_name = "") {
		SupraList[] result = {};

		if (repo_name == "")
			return list;
		foreach (var i in list) {
			if (i.repo_name == repo_name)
				result += i;
		}
		return result;
	}

	public static bool refresh_list () throws Error {
		if (singleton == null)
			singleton = new Sync();
		foreach (var i in repo) {
			i.refresh_repo();
		}
		singleton = new Sync();
		return true;
	}

	public static string download_package (string pkg_name, string? repo_name = null) {
		var lst = Sync.default ()._get_list_package ();
		foreach (var l in lst) {
			if (repo_name == null || l.repo_name == repo_name)
				if (l.name == pkg_name)
					return Sync.default()._download(l);
		}
		error("can't download the file");
	}


	public static string download (SupraList pkg) {
		Cancellable cancel = new Cancellable();
		return Sync.default()._download(pkg, cancel);
	}

	// download a package and return this location
	string _download (SupraList pkg, Cancellable? cancel = null) {
		string pkgdir = @"$(config.cache)/pkg";
		string pkgname = @"$(pkg.name)-$(pkg.version).suprapack";
		string output = @"$pkgdir/$pkgname";
		DirUtils.create_with_parents(pkgdir, 0755);

		if (FileUtils.test (output, FileTest.EXISTS)) {
			return output;
		}
		string url = this.get_url_from_name(pkg.repo_name) + pkgname;
		try  {
			print(CURSOR);
			debug("Sync", "Download [%s] from [%s] local:(%s)", pkg.name, url, pkg.is_local ? "true" : "false");
			if (pkg.is_local == true) {
				var file_list = GLib.File.new_for_path(url);
				var file_output = GLib.File.new_for_path(output);
				file_list.copy (file_output, FileCopyFlags.OVERWRITE);
				debug("Sync", "Copy from local name: [%s] repo: [%s]", pkg.name, pkg.repo_name);
			}
			else
				Utils.download(url, output, false, false, cancel); 
			print(ENDCURSOR);
		} catch (Error e) {
			print(ENDCURSOR);
			FileUtils.remove (output);
			error ("Can't download %s (%s)", url, e.message);
		}
		return output;
	}

	private static Groups groups; 
	private static SupraList []list {get;set;}
	private static RepoInfo []repo {get;set;}
}
