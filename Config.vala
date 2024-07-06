public class Config : Object{
	public Config () throws Error {
		var env = Environ.get();
		this.change_prefix (@"$HOME/.local");
		this.load_config();
		var prefix_tmp = Environ.get_variable(env, "PREFIX");
		if (prefix_tmp != null)
			this.change_prefix(prefix_tmp);
		queue_pkg = new List<Package?>();
		create_source_profile();
	}

	void create_source_profile () throws Error {
		var profile = @"$HOME/.suprapack_profile";
		if (FileUtils.test(profile, FileTest.EXISTS) == false) {
var str = """# Prefix:%1$s
export PATH=$PATH:%1$s/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:%1$s/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:%1$s/share/pkgconfig:%1$s/lib/pkgconfig
export XDG_DATA_DIRS=$XDG_DATA_DIRS:%1$s/share
export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:%1$s/etc
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:%1$s/lib"
export LIBRARY_PATH="$LIBRARY_PATH:%1$s/lib"
export C_INCLUDE_PATH="$C_INCLUDE_PATH:%1$s/include"
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:%1$s/include"
export GSETTINGS_SCHEMA_DIR=%1$s/share/glib-2.0/schemas/
export PYTHONPATH="$PYTHONPATH:%1$s/lib/python3/dist-packages"
export fpath=(%1$s/bin $fpath)
""".printf(this.prefix);
			FileUtils.set_contents(profile, str);
		}

	}
	
	public void change_strap (string prefix_strap) {
		this.strap = prefix_strap;
	}

	public void change_prefix (string prefix) throws Error {
		string contents;
		var new_prefix = prefix;
		var new_cache = prefix + "/.suprapack";
		var new_config = new_cache + "/user.conf";
		var new_repo_list = new_cache + "/repo.list";
		FileUtils.symlink(@"$HOME/.local/.suprapack", @"$HOME/.config/suprapack");
		
		DirUtils.create_with_parents(new_prefix, 0755);
		DirUtils.create_with_parents(new_cache, 0755);
		if (FileUtils.test (new_cache, FileTest.EXISTS) == false) {
			DirUtils.create(new_cache, 0755);
		}
		if (FileUtils.test (new_config, FileTest.EXISTS) == false) {
			FileUtils.set_contents (new_config, "is_cached:false");
		}
		if (FileUtils.test (new_repo_list, FileTest.EXISTS) == false) {
			if (FileUtils.test(this.repo_list, FileTest.EXISTS)) {
				info("[Repo] Copy all %s content in new prefix", this.prefix); 
				FileUtils.get_contents (this.repo_list, out contents);
				FileUtils.set_contents (new_repo_list, contents);
			}
			else
				FileUtils.set_contents (new_repo_list, "");
		}
		
		this.prefix = (owned)new_prefix;
		this.cache = (owned)new_cache;
		this.config = (owned)new_config; 
		this.repo_list = (owned)new_repo_list;
	}

	private void load_config() throws Error{
		string contents;
		FileUtils.get_contents (this.config, out contents);

		var lines = contents.split("\n");
		var reg = /^([^:]+)[:]([^\s]+)$/;
		foreach (var line in lines) {
			if (!reg.match(line))
				continue;
			if (line.has_prefix ("is_cached")) {
				is_cached = bool.parse(line[line.index_of_char(':') + 1:]);
			}
			else if (line.has_prefix ("show_script")) {
				show_script = bool.parse(line[line.index_of_char(':') + 1:]);
			}
			else if (line.has_prefix ("prefix")) {
				this.change_prefix(line[line.index_of_char(':') + 1:].replace("~", HOME));
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

	public bool check_if_in_queue(string name) {
		foreach (var i in queue_pkg)
			if (i.name == name)
				return true;
		return false;
	}

	public List<Package?>	queue_pkg;
	public unowned string[] cmd;
	public bool allays_yes {get;set;default=false;} 
	public bool force		{get; set; default=false;}
	public bool supraforce	{get; set; default=false;}
	public string prefix	{get; private set; default=@"$HOME/.local";}
	public string cache		{get; private set;}
	public string config	{get; private set;}
	public string repo_list {get; private set;}
	public string strap {get; private set;}
	public bool is_cached	{get; private set; default=false;}
	public bool show_script {get; private set; default=false;}

}
