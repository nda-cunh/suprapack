public const string REPO_URL = "https://gitlab.com/supraproject/suprastore_repository/-/raw/master/";

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
				run_cmd({"curl", "-o", list_file, REPO_URL + "suprastore_list"});
				_list = list_file;
			}
			return _list;
		}
	}
	
	public string name;
	public string url;
}

public struct SupraList {
	public SupraList (string repo_name, string line) {
		this.repo_name = repo_name;
		name = line[0:line.index_of_char ('-')];
		version = line[line.index_of_char ('-') + 1 : line.last_index_of_char ('.')];
	}
	unowned string repo_name;
	string name;
	string version;
}


class Repository {
	//   SINGLETON 
	private static Repository? singleton = null;
	public static unowned Repository default() {
		if (singleton == null)
			singleton = new Repository();
		return (singleton);
	}
	
	// Default Constructor
	private Repository () {
		// set default repo
		_list = {};
		_repo += new RepoInfo("Cosmos", REPO_URL);
	}

	public unowned string? get_url_from_name(string repo_name) {
		foreach (var repo in _repo) {
			if (repo.name == repo_name) {
				return repo.url;
			}
		}
		return null;
	}

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

	private SupraList []_list;
	private RepoInfo []_repo;
}
