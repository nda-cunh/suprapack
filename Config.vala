public struct ConfigInfo {
	public ConfigInfo(string name, string val) {
		this.name = name;
		this.data = val;
	}

	string name;
	string data;
}

class Config {
	private static Config? singleton = null;
	public static unowned Config default() {
		if(singleton == null)
			singleton = new Config();
		return (singleton);
	}

	private Config () {
        var fs = FileStream.open(CONFIG, "r");
		if (fs == null)
			print_error(@"unable to retreive config file\nfile => $(CONFIG)");
		var line = 1;
        string tmp;
		while((tmp = fs.read_line()) != null) {
			if (tmp != "") {
				var repoSplit = tmp.split(":");
				if(repoSplit.length != 2)
					print_error(@"unable to parse config\nline $(line) => $(tmp)");
				_config += ConfigInfo(repoSplit[0], repoSplit[1]);
			}
			line++;
		}
	}

	public string? get_from_name(string name) {
		foreach (var config in _config) {
			if (config.name == name)
				return config.data;
		}
		return null;
	}

	public void update_config(ConfigInfo cfg) {
		var founded = false;
		var i = 0;
		while (i < _config.length) {
			if (_config[i].name == cfg.name) {
				founded = true;
				var conf_data_old = _config[i].data;
				_config[i].data = cfg.data;
				print_info(@"$(_config[i].name) config has been updated from $(conf_data_old) to $(_config[i].data)", "Config");
			}
			i++;
		}
		if (founded == false)
			_config += cfg;
		redraw_config();
	}

	public void redraw_config() {
        var fs = FileStream.open(CONFIG, "w");
		if (fs == null)
			print_error(@"unable to retreive config file\nfile => $(CONFIG)");
		foreach (var config in _config) {
			fs.printf("%s:%s", config.name, config.data);
		}
		print_info("Finished to override configs", "Config");
	}

	private ConfigInfo []_config;
}
