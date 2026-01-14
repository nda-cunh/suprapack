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
 * Copyright (C) 2026 SupraCorp - Nathan Da Cunha (nda-cunh)
 */

public errordomain ErrorConfigUser {
	INVALID_SYNTAX,
}

[Compact]
public class ConfigUser {
	private static string? _prefix_ = null;
	private static string? _is_cached_ = null;
	private static string? _show_script_ = null;
	private static string? _profile_priority_ = null;
	private static string? is_print = null;
	private static string? shell_print_hidden = null;
	public unowned string config;

	private const OptionEntry[] options = {
		{"shell_print_hidden", '\0', OptionFlags.HIDDEN, OptionArg.NONE, ref shell_print_hidden, "internal option to print hidden options in shell", null },
		{"print", '\0', OptionFlags.NONE, OptionArg.NONE, ref is_print, "print the actual configuration", null },
		{"prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref _prefix_, "Path to the folder", "PATH"},
		{"is_cached", 'c', OptionFlags.NONE, OptionArg.STRING, ref _is_cached_, "Keep the package in the cache", "bool"},
		{"show_script", 's', OptionFlags.NONE, OptionArg.STRING, ref _show_script_, "Show the script before installing", "bool"},
		{"profile_priority", 's', OptionFlags.NONE, OptionArg.STRING, ref _profile_priority_, "Set the profile priority (high or low)", "PROFILE_PRIORITY"},
		{null}
	};


	public ConfigUser (string config) {
		this.config = config;
	}

	/**
	 * Parse the command line arguments (ARGV)
		*
	 * @param argv: the command line arguments
	 **/
	public void parse (ref unowned string []argv) throws Error {
		var opt_context = new OptionContext ("Config");
		opt_context.add_main_entries (options, null);
		opt_context.set_summary ("Set the configuration of the package manager");
		opt_context.set_help_enabled(true);

		if (argv.length == 2) {
			opt_context.parse(ref argv);
			print (opt_context.get_help (true, null));
			return ;
		}

		// Parse the command line
		opt_context.parse(ref argv);

		if (is_print != null) {
			string contents;
			FileUtils.get_contents (this.config, out contents);
			stdout.printf ("[ConfigFile]:\n  %s\n", contents.replace("\n", "\n  "));
			return ;
		}
		if (shell_print_hidden != null) {
			foreach (unowned var option in options) {
				if (option.long_name == null)
					continue;
				if (!(OptionFlags.HIDDEN in option.flags))
					stdout.printf ("--%s= ", option.long_name.strip());
			}
			stdout.printf ("\n");
			return ;
		}

		if (_prefix_ != null)
			this.add ("prefix", _prefix_);
		if (_is_cached_ != null)
			this.add("is_cached", parse_bool (_is_cached_));
		if (_show_script_ != null)
			this.add("show_script", parse_bool (_show_script_));
		if (_profile_priority_ != null) {
			// high = true and low = false
			const string valid_values[] = {"high", "low"};
			if ((_profile_priority_ in valid_values) == false) {
				throw new ErrorConfigUser.INVALID_SYNTAX ("profile_priority must be 'high' or 'low'");
			}
			bool is_high = _profile_priority_ == "high" ? true : false;
			this.add("profile_priority", is_high.to_string ());
		}
		string contents;
		FileUtils.get_contents (this.config, out contents);
		stdout.printf ("[NewFile]:\n  %s\n", contents.replace("\n", "\n  "));
	}

	/**
	 * Add a new config to the config file
	 * @param key: the key to add
	 * @param value: the value to add
	 */


	private void add (string key, string value) throws Error {
		var new_contents = new StringBuilder();
		string contents;
		FileUtils.get_contents (this.config, out contents);

		foreach (unowned var line in contents.split("\n")) {
			if (!line.has_prefix (key)) {
				new_contents.append(line);
				new_contents.append_c ('\n');
			}
		}
		new_contents.append_printf ("%s:%s", key, value);
		FileUtils.set_contents(this.config, new_contents.str);
	}
}

//#############################################
// Helper functions
//#############################################

/**
 * Parse a boolean from a string
 * @param str: the string to parse
 * @return the boolean value
 */
private inline string parse_bool (string str) {
	string tmp;
	bool res;
	tmp = str._strip ().ascii_down ();
	if (bool.try_parse (tmp, out res) == false)
		warning ("Error: %s is not a boolean", str);
	return res.to_string ();
}
