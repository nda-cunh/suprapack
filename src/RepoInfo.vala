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
 * Copyright (C) 2025 SupraCorp - Nathan Da Cunha (nda-cunh)
 */


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
 * an url can be [[http://gitlab/../../]] or [[home/user/repo]]
 */
public class RepoInfo : Object {
	public RepoInfo (string name, string url, bool local) throws Error {
		this.local = local;
		this.name = name;
		this.url = url;
		this._list = null;
		init_list();
	}

	/* fetch the 'list' file  LOCAL or HTTP */
	public void fetch_list (string url, string output) throws Error {
		string url_list = url;
		Log.debug("URL %s %s", url_list, output);
		if (url.has_prefix ("http")) {
			url_list += "list";
			Log.debug("Repository", "FETCH HTTP repository %s", url_list);
			try {
				config.set_have_download_mirrorlist ();
				Http.download(url_list, output, false);
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
			Log.debug("Repository", "FETCH local repository %s", url_list);
			this.local = true;
		}
	}

	/* force download the 'list' file */
	public void refresh_repo() throws Error  {
		string list_file = @"/tmp/$(this.name)_$(USERNAME)_list";
		FileUtils.remove(list_file);
		try {
			fetch_list(this.url, list_file);
		} catch (Error e) {
			throw new ErrorSP.FAILED("unable to download file %s", e.message);
		}
		_list = list_file;
	}

	private string? _list;
	public unowned string list {
		get {
			return _list;
		}
	}

	private void init_list () throws Error {
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
			}
			catch (Error e) {
				if (e is TlsError) {
					throw new ErrorSP.TLS_ERROR("%s try to install " + BOLD + PURPLE + "glib-networking" + NONE + " package", e.message );
				}
				throw new ErrorSP.REPOSITORY_NOT_FOUND("unable to download file %s", e.message);
			}
			_list = list_file;
		}
	}

	public string name;
	public string url;
	public bool local;
}
