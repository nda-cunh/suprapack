//TODO read a file 
public const string REPO_URL = "https://gitlab.com/supraproject/suprastore_repository/-/raw/master/";


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
				string []av = {"curl", "-o", list_file, @"$(this.url)/list"};
				Utils.run(av, false);
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
		_repo += new RepoInfo("Cosmos", REPO_URL);
	}

	public static SupraList? get_from_pkg(string name_pkg) {
		var pkg_list = Sync.default().get_list_package();
		foreach (var pkg in pkg_list) {
			if (pkg.name == name_pkg) {
				return pkg;
			}
		}
		return null;
	}

	// return true if need update else return false
	public static bool check_update(string package_name) {
		var Qpkg = Query.get_from_pkg(package_name);
		var Spkg = Sync.get_from_pkg(package_name);
		if (Spkg == null)
			return false;
		
		return (Spkg.version != Qpkg.version);
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

	// return all package in all repo
	public SupraList []get_list_package () {
		if (_list.length == 0) {
			foreach (var repo in _repo) {
				var fs = FileStream.open(repo.list, "r");
				if (fs == null)
					print_error("list introuvable ???");
				string tmp;
				while ((tmp = fs.read_line()) != null)
					_list += SupraList(repo.name, tmp);
			}
		}
		return _list;
	}

	// download a package and return this location
	public string download (SupraList pkg) {
			string pkgdir = @"$(LOCAL)/pkg";
			string pkgname = @"$(pkg.name)-$(pkg.version).suprapack";
			string output = @"$pkgdir/$(pkg.name)-$(pkg.version).suprapack";
			DirUtils.create_with_parents(pkgdir, 0755);
			
			string url = this.get_url_from_name(pkg.repo_name) + pkgname;
			Utils.run_cmd({"curl", "-o", output, url});
			return output;
	}

	private SupraList []_list;
	private RepoInfo []_repo;
}
