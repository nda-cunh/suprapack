/**
 * RepoInfo is a struct that contains information about a repository
 * it's used to store information about a repository from a server
 *
 * it contains :
 * the name of the repository
 * the url of the repository
 * and if the repository is local or not (http or local (folder))
 *
 * a name can be (Cosmos)
 * an url can be (http://gitlab/../../) or (/home/user/repo)
 */
public class RepoInfo : Object {
	public RepoInfo (string name, string url, bool local) {
		this.local = local;
		this.name = name;
		this.url = url;
		this._list = null;
	}

	/* fetch the 'list' file  LOCAL or HTTP */
	public void fetch_list (string url, string output) throws Error {
		string url_list = url;
		debug("URL %s %s", url_list, output);
		if (url.has_prefix ("http")) {
			url_list += "list";
			debug("Repository", "FETCH HTTP repository %s", url_list);
			try {
				Http.download(url_list, output, true);
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
	public void refresh_repo () {
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
