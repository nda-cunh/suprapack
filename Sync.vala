// Contains Informations or package from the repo
// repo_name (Cosmos)
// name (suprabear)
// version (1.2)
public struct SupraList {
	public SupraList (string repo_name, string line) {
		this.repo_name = repo_name;
		name = line[0:line.last_index_of_char ('-')];
		version = line[line.last_index_of_char ('-') + 1 : line.last_index_of_char ('.')];
	}
	unowned string repo_name;
	string name;
	string version;
}


// RepoInfo contains information of a repo like Cosmos 
// name  (Cosmos)
// url (http://gitlab/../../)
public class RepoInfo {
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
				if(Utils.run_silent({"curl", "-o", list_file, this.url + "list"}) != 0) 
					print_error(@"unable to download file\nfile => {$(list_file) located at $(this.url)}");
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
	public static unowned Sync default() {
		if (singleton == null)
			singleton = new Sync();
		return (singleton);
	}
	// Default private Constructor
	private Sync () {
		_list = {};
        var fs = FileStream.open(config.repo_list, "r");
		if (fs == null)
			print_error(@"unable to retreive repository list\nfile => $(config.repo_list)");
		var line = 1;
        string tmp;
		while((tmp = fs.read_line()) != null) {
			if (tmp != "") {
				var repoSplit = / +/.split(tmp);
				if(repoSplit.length != 2)
					print_error(@"unable to parse repository\nline $(line) => $(tmp)");
				_repo += new RepoInfo(repoSplit[0], repoSplit[1]);
			}
			line++;
		}
	}

	public static SupraList get_from_pkg(string name_pkg) throws Error{
		var pkg_list = Sync.default().get_list_package();
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
			if(e is ErrorSP.FAILED)
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

	public static SupraList []get_all_package() {
		var pkgs = Sync.default().get_list_package();
		return pkgs;
	}
	// return all package in all repo
	public SupraList []get_list_package () {
		if (_list.length == 0) {
			foreach (var repo in _repo) {
				var fs = FileStream.open(repo.list, "r");
				if (fs == null)
					print_error(@"unable to retreive repository $(repo.name)\nfile =>$(repo.list)");
				string tmp;
				var regex = /[a-zA-Z0-9]+[-][a-zA-Z0-9.]+[.]suprapack/;
				while ((tmp = fs.read_line()) != null) {
					if (regex.match(tmp))
						_list += SupraList(repo.name, tmp);
					else
						warning(tmp);
				}
			}
		}
		return _list;
	}
	
	public static string download_package (string pkg_name, string? repo_name = null) {
		var lst = Sync.default ().get_list_package ();
		foreach (var l in lst) {
			if (repo_name == null || l.repo_name == repo_name)
				if (l.name == pkg_name)
					return Sync.default().download(l);
		}
		print_error("cant download the file");
	}

	// download a package and return this location
	public string download (SupraList pkg) {
			string pkgdir = @"$(config.cache)/pkg";
			string pkgname = @"$(pkg.name)-$(pkg.version).suprapack";
			string output = @"$pkgdir/$(pkg.name)-$(pkg.version).suprapack";
			DirUtils.create_with_parents(pkgdir, 0755);
			
			string url = this.get_url_from_name(pkg.repo_name) + pkgname;
			if(Utils.run_silent({"curl", "-o", output, url}) != 0) 
				print_error(@"unable to download package\npackage => $(pkgname)");
			return output;
	}

	private SupraList []_list;
	private RepoInfo []_repo;
}
