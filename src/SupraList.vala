/**
 * SupraList is a struct that contains information about a package
 *
 * it's like Package struct @see Package.vala but with less information
 * it's used to store information about a package from a repository from a server
 */
public struct SupraList {
	private static Regex? _regex = null;
	public static Regex regex {get {
		if (_regex == null)
			_regex = /^(?P<pkgname>(?P<name>[^_]+)[_](?P<version>.*?)([_](?P<arch>.*?))?[.]suprapack)\s*(?P<desc>(.*))/;
		return _regex;
	}}

	// 42cformatter-v1.0_amd64-Linux.suprapack c formatter for 42 norm
	public SupraList (string repo_name, string line, bool is_local) throws SupraListError {
		this.is_local = is_local;
		MatchInfo info;

		if (regex.match(line, 0, out info)) {
			this.repo_name = repo_name;

			pkg_name = info.fetch_named("pkgname");
			name = info.fetch_named("name");
			version = info.fetch_named("version");
			arch = info.fetch_named("arch");
			description = info.fetch_named("desc");
		}
		else
			throw new SupraListError.FAILED("Can't parse line %s (%s:%d)", line, Log.FILE, Log.LINE);
	}

	unowned string repo_name;
	string pkg_name;
	string name;
	string version;
	string description;
	string arch;
	bool is_local;
}

public errordomain SupraListError {
	FAILED,
}
