public struct SupraList {
	public SupraList (string repo_name, string line) {
		this.repo_name = repo_name;
		name = "";
		version = "";
	}
	unowned string repo_name;
	string name;
	string version;
}

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
