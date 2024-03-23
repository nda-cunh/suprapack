// Contains Informations or package from the repo
// repo_name (Cosmos)
// name (suprabear)
// version (1.2)
public struct SupraList {
	public SupraList (string repo_name, string line) {
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
}


// RepoInfo contains information of a repo like Cosmos 
// name  (Cosmos)
// url (http://gitlab/../../)
public class RepoInfo : Object{
	public RepoInfo(string name, string url) {
		this.name = name;
		this.url = url;
		this._list = null;
	}

	private string? _list;
	public string list {
    get {
        if (_list == null) {
            string list_file = @"/tmp/$(this.name)_$(USERNAME)_list";
            // print_info(@"Download list from $(this.name) repo");
            bool should_download = true;
            if (FileUtils.test (list_file, FileTest.EXISTS)) {
				var stat = Stat.l(list_file);
				var now = time_t();
				if (stat.st_mtime + 700 > now)
					should_download = false;
            }
            if (should_download && Utils.run_silent({"curl", "-o", list_file, this.url + "list"}) !=  0) {
                print_error(@"unable to download file\nfile => {$(list_file) located at $(this.url)}");
            }
            _list = list_file;
        }
        return _list;
    }
}

	public string name;
	public string url;
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
			print_error (e.message);
		}
	}
	// Default private Constructor
	private Sync () throws Error {

		/* init Repo property */
		string contents;
		var regex_repo = /(?P<name>[^\s]+)\s*(?P<url>[^\s]+)/;
		MatchInfo match_info;
		FileUtils.get_contents(config.repo_list, out contents);

		foreach (var line in contents.split("\n")) {
			if (regex_repo.match(line, 0, out match_info)) {
				string name = match_info.fetch_named("name");
				string url = match_info.fetch_named("url");
				_repo += new RepoInfo(name, url);
			}
		}

		/* init List Property */
		var regex = /[a-zA-Z0-9]+[-][a-zA-Z0-9.]+[.]suprapack/;
		foreach (var repo in _repo) {
			FileUtils.get_contents(repo.list, out contents);
			foreach (var pkg in contents.split("\n")) {
				if (regex.match(pkg))
					_list += SupraList(repo.name, pkg);
				else if (pkg != "")
					warning(pkg);
			}
		}
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
			return (Spkg.version != Qpkg.version);
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

	public static void refresh_list () {
		foreach (var i in _repo) {
            FileUtils.remove(@"/tmp/$(i.name)_$(USERNAME)_list");
		}
	}

	public static string download_package (string pkg_name, string? repo_name = null) {
		var lst = Sync.default ()._get_list_package ();
		foreach (var l in lst) {
			if (repo_name == null || l.repo_name == repo_name)
				if (l.name == pkg_name)
					return Sync.default()._download(l);
		}
		print_error("cant download the file");
	}
	

	public static string download (SupraList pkg) {
		return Sync.default()._download(pkg);
	}

	// download a package and return this location
	string _download (SupraList pkg) {
		string pkgdir = @"$(config.cache)/pkg";
		string pkgname = @"$(pkg.name)-$(pkg.version).suprapack";
		string output = @"$pkgdir/$pkgname";
		DirUtils.create_with_parents(pkgdir, 0755);

		if (FileUtils.test (output, FileTest.EXISTS)) {
			print_info(output, "Cache");
			return output;
		}
		string url = this.get_url_from_name(pkg.repo_name) + pkgname;
		if (Utils.run_silent({"curl", "-o", output, url}) != 0) 
			print_error(@"unable to download package\npackage => $(pkgname)");
		return output;
	}

	private static SupraList []list {get;set;}
	private static RepoInfo []repo {get;set;}
}
