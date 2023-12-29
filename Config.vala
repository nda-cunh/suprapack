public class Config{
	public Config () throws Error {
		this.change_prefix (@"$HOME/.local");
		this.load_config();
	}
	public void change_prefix (string prefix) throws Error {
		this.prefix = prefix;
		this.cache = prefix + "/.suprapack";
		this.config = this.cache + "/user.conf";
		this.repo_list = this.cache + "/repo.list";
		FileUtils.symlink(@"$HOME/.local/.suprapack", @"$HOME/.config/suprapack");

		DirUtils.create_with_parents(this.prefix, 0755);
		DirUtils.create_with_parents(this.cache, 0755);
		if (FileUtils.test (this.cache, FileTest.EXISTS) == false) {
			DirUtils.create(this.cache, 0755);
		}
		if (FileUtils.test (this.config, FileTest.EXISTS) == false) {
			FileUtils.set_contents (this.config, "is_cached:false");
		}
		if (FileUtils.test (this.repo_list, FileTest.EXISTS) == false) {
			FileUtils.set_contents (this.repo_list, "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/");
		}
	}

	private void load_config() throws Error{
		string contents;
		FileUtils.get_contents (this.config, out contents);

		var lines = contents.split("\n");
		var reg = /^[a-zA-Z0-9_]+[:][a-zA-Z0-9_]+$/;
		foreach (var line in lines) {
			if (!reg.match(line))
				continue;
			if (line.has_prefix ("is_cached")) {
				is_cached = bool.parse(line[line.index_of_char(':') + 1:]);
			}
		}
		
	}
	public void add(string key, string value) throws Error {
		string contents;
		var new_contents = new StringBuilder();
		FileUtils.get_contents (this.config, out contents);

		var lines = contents.split("\n");
		if (value != "")
			new_contents.append_printf("%s:%s\n", key, value);
		foreach (var line in lines) {
			if (!line.has_prefix (key))
				new_contents.append(line);
		}
		print("NewFile:\n%s", new_contents.str);
		FileUtils.set_contents(this.config, new_contents.str);
	}

	public bool force		{get; set; default=false;}
	public string prefix	{get; set; default=@"$HOME/.local";}
	public string cache		{get; private set;}
	public string config	{get; private set;}
	public string repo_list {get; private set;}
	public bool is_cached	{get; private set; default=false;}
}
