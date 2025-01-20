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
		this.strap = this.prefix;
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


	inline string parse_bool (string str) {
		string tmp;
		bool res;
		tmp = str._strip ().ascii_down ();
		if (bool.try_parse (tmp, out res) == false)
			warning ("Error: %s is not a boolean", str);
		return res.to_string ();
	}

	public void parse (ref unowned string []argv) throws Error {
		string? _prefix_ = null;
		string? _show_script_ = null;
		string? _is_cached_ = null;

		OptionEntry options[4];
		options[0] = { "prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref _prefix_, "Path to the folder", "PATH"};
		options[1] = { "is_cached", 'c', OptionFlags.NONE, OptionArg.STRING, ref _is_cached_, "Keep the package in the cache", "bool"};
		options[2] = { "show_script", 's', OptionFlags.NONE, OptionArg.STRING, ref _show_script_, "Show the script before installing", "bool"};
		options[3] = {null};

		var opt_context = new OptionContext ("Config");
		opt_context.add_main_entries (options, null);
		opt_context.set_summary ("Set the configuration of the package manager");
		opt_context.set_help_enabled(true);

		if (argv.length == 2)  {
			opt_context.parse(ref argv);
			print (opt_context.get_help (true, null));
			return ;
		}

		// Parse the command line
		opt_context.parse(ref argv);

		if (_prefix_ != null)
			this.add ("prefix", _prefix_);
		if (_is_cached_ != null)
			this.add("is_cached", parse_bool (_is_cached_));
		if (_show_script_ != null)
			this.add("show_script", parse_bool (_show_script_));
		string contents;
		FileUtils.get_contents (this.config, out contents);
		print ("[NewFile]:\n  %s\n", contents.replace("\n", "\n  "));
	}

	private void add(string key, string value) throws Error {
		var new_contents = new StringBuilder();
		string contents;
		FileUtils.get_contents (this.config, out contents);

		foreach (var line in contents.split("\n")) {
			if (!line.has_prefix (key)) {
				new_contents.append(line);
				new_contents.append_c ('\n');
			}
		}
		new_contents.append_printf ("%s:%s", key, value);
		FileUtils.set_contents(this.config, new_contents.str);
	}

	public bool check_if_in_queue(string name) {
		foreach (var i in queue_pkg)
			if (i.name == name)
				return true;
		return false;
	}

	public static bool is_my_arch (string arch) throws Error {
		unowned string arch_actual = Utils.get_arch ();
		if ("any" in arch)
			return true;
		if (arch == arch_actual)
			return true;
		return false;
	}


	public List<Package?>	queue_pkg;
	public unowned string[] cmd;

	public bool allays_yes		{get;set;default=false;}
	public bool force			{get; set; default=false;}
	public bool supraforce		{get; set; default=false;}
	public bool use_fakeroot	{get; set; default=true;}
	public string prefix		{get; private set; default=@"$HOME/.local";}
	public string cache			{get; private set;}
	public string config		{get; private set;}
	public string repo_list 	{get; private set;}
	public string strap			{get; private set;}
	public bool is_cached		{get; private set; default=false;}
	public bool show_script 	{get; private set; default=false;}
	public bool want_remove 	{get; set; default=false;}
}
