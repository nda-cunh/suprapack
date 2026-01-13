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

public unowned string HOME;
public unowned string PWD;
public unowned string USERNAME;
public Config config;
[CCode (has_target = false)]
public delegate bool CommandExecute (string [] commands) throws Error ;

public class Main : Object {
	private const string COLOR = "\033[36;1m";
	public static string? prefix = null;
	public static bool refresh = false;
	public static bool force = false;
	public static bool no_fakeroot = false;
	public static bool yes = false;
	public static bool simple_print = false;
	public static bool supraforce = false;
	public static string? strap = null;
	public static bool build_and_install = false;
	public static string? build_output = null;
	public static bool _debug = false;
	public static bool _recursive = false;


	const OptionEntry[] options = {
		// Special options hidden
		{ "simple-print", '\0', OptionFlags.HIDDEN, OptionArg.NONE, ref simple_print, "simple print used by other program", null },
		{ "supraforce", 's', OptionFlags.HIDDEN, OptionArg.NONE, ref supraforce, "force the operation without update check", null },
		// Normal Options
		{ "prefix", 'p', OptionFlags.NONE, OptionArg.STRING, ref prefix, COLOR + "(All) " + NONE + " the path of the suprapack folder root", "PATH TO THE FOLDER" },
		{ "debug", '\0', OptionFlags.NONE, OptionArg.NONE, ref _debug, COLOR + "(All)" + NONE + " add the debug mode", "DEBUG"},
		{ "refresh", 'r', OptionFlags.NONE, OptionArg.NONE, ref refresh, COLOR + "(All)" + NONE + " refresh the list of packages", null },
		{ "force", 'f', OptionFlags.NONE, OptionArg.NONE, ref force, COLOR + "(Install, Uninstall, Download)" + NONE + " force the operation", null },
		{ "yes", 'y', OptionFlags.NONE, OptionArg.NONE, ref yes, COLOR + "(All)" + NONE + " answer yes to all questions", null },
		{ "no-fakeroot", '\0', OptionFlags.NONE, OptionArg.NONE, ref no_fakeroot, COLOR + "(Build)" + NONE + " don't build package with fakeroot", null },
		{ "strap", '\0', OptionFlags.NONE, OptionArg.STRING, ref strap, COLOR + "(All)" + NONE + " like PacStrap install to another root", "PREFIX"},
		{ "install", '\0', OptionFlags.NONE, OptionArg.NONE, ref build_and_install, COLOR + "(Build)" + NONE + " build and install the package", null },
		{ "build-output", '\0', OptionFlags.NONE, OptionArg.STRING, ref build_output, COLOR + "(Build)" + NONE + " build output", null },
		{ "no-recursive", '\0', OptionFlags.NONE, OptionArg.NONE, ref _recursive, COLOR + "(Uninstall)" + NONE + " remove the recursive", null},
		{ null }
	};

	bool all_cmd (string []commands) throws Error {

		var opt_context = new OptionContext ();
		opt_context.add_main_entries (options, null);
		opt_context.set_help_enabled(false);
		opt_context.set_ignore_unknown_options(true);
		opt_context.parse(ref commands);

		if (_debug == true)
			Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
		if (refresh)
			Sync.refresh_list();
		if (prefix != null)
			config.change_prefix(prefix);
		if (strap != null)
			config.change_strap(strap);
		config.force = force;
		config.allays_yes = yes;
		config.supraforce = supraforce;
		config.simple_print = simple_print;
		config.use_fakeroot = !no_fakeroot;
		config.build_and_install = build_and_install;
		config.build_output = build_output ?? ".";
		config.is_recursive_uninstall = !_recursive;

		// Create source profile if not exist
		if (FileUtils.test(@"$HOME/.suprapack_profile", FileTest.EXISTS) == false) {
			config.create_source_profile();
		}

		debug ("prefix: [%s] strap: %s", config.prefix, config.strap);

		if (commands.length < 2) {
			return Cmd.help(commands);
		}

		if (commands[1] == "config") {
			config.parse(ref commands);
			return true;
		}

		unowned string av1 = commands[1];
		config.cmd = commands;

		if (av1.has_suffix(".suprapack")) {
			prepare_install(commands[1]);
			install();
			return true;
		}

		var cmd_table = new HashTable<string, CommandExecute>(str_hash, str_equal);
		// special
		cmd_table["loading"] = Cmd.loading;
		cmd_table["query_get_comp"] = Cmd.query_get_comp;
		cmd_table["sync_get_comp"] = Cmd.sync_get_comp;
		// pacman
		cmd_table["-B"] = Cmd.build;
		cmd_table["-P"] = Cmd.prepare;
		cmd_table["-Q"] = Cmd.list;
		cmd_table["-Qi"] = Cmd.info;
		cmd_table["-Ql"] = Cmd.list_files;
		cmd_table["-Qr"] = Cmd.run;
		cmd_table["-G"] = Cmd.download;
		cmd_table["-R"] = Cmd.uninstall;
		cmd_table["-S"] = Cmd.install;
		cmd_table["-Ss"] = Cmd.search;
		cmd_table["-Su"] = Cmd.update;
		cmd_table["-Syyu"] = Cmd.update;
		cmd_table["add"] = Cmd.install;
		cmd_table["build"] = Cmd.build;
		cmd_table["download"] = Cmd.download;
		cmd_table["have_update"] = Cmd.have_update;
		cmd_table["help"] = Cmd.help;
		cmd_table["info"] = Cmd.info;
		cmd_table["install"] = Cmd.install;
		cmd_table["list"] = Cmd.list;
		cmd_table["list_files"] = Cmd.list_files;
		cmd_table["prepare"] = Cmd.prepare;
		cmd_table["refresh"] = Cmd.refresh;
		cmd_table["remove"] = Cmd.uninstall;
		cmd_table["run"] = Cmd.run;
		cmd_table["search"] = Cmd.search;
		cmd_table["search_supravim_plugin"] = Cmd.search_supravim_plugin;
		cmd_table["shell"] = Cmd.shell;
		cmd_table["uninstall"] = Cmd.uninstall;
		cmd_table["update"] = Cmd.update;
		cmd_table["version"] = Cmd.version;


		if (av1 in cmd_table) {
			CommandExecute cmd_execute = cmd_table[av1];
			return cmd_execute(commands);
		}
		else {
			int max = 0;
			unowned string? best_match = null;
			foreach (unowned var key in cmd_table.get_keys ()) {
				int score = BetterSearch.get_score_sync(av1, key);
				if (score > max) {
					best_match = key;
					max = score;
				}
			}
			if (best_match != null && max >= 20) {
				var value = Utils.stdin_bool_choose(YELLOW +  BOLD + "[Suprapack] Did you mean " + PURPLE + best_match + NONE + " [y/N] ?", false);
				if (value == true) {
					CommandExecute cmd_execute = cmd_table[best_match];
					return cmd_execute(commands);
				}
			}
		}

		error("La commande \"%s\" n'existe pas.", av1);
	}

	// INIT
	public Main (string []args) {
		if (Environment.get_variable("GIO_MODULE_DIR") == null) {
			if (FileUtils.test("/usr/lib/gio/modules", FileTest.IS_DIR | FileTest.EXISTS))
				Environment.set_variable ("GIO_MODULE_DIR", "/usr/lib/gio/modules", true);
			else if (FileUtils.test("/usr/lib/x86_64-linux-gnu/gio/modules", FileTest.IS_DIR | FileTest.EXISTS))
				Environment.set_variable ("GIO_MODULE_DIR", "/usr/lib/x86_64-linux-gnu/gio/modules", true);
			else {
				if (Environment.get_variable("GIO_MODULE_DIR") == null) {
					warning ("gio module not found");
					warning ("try install glib-networking");
					warning ("set GIO_MODULE_DIR to modules directory");
				}
			}
		}
		// set locale for utf8 support
		Intl.setlocale();
		// warning, error, message function
		init_message();
		// load environment variables
		HOME = Environment.get_variable("HOME");
		PWD = Environment.get_variable("PWD");
		USERNAME = Environment.get_user_name();

		try {
			config = new Config();
			if (all_cmd(args) == true)
				Process.exit(0);
		} catch (Error e) {
			warning(e.message);
		}
		Process.exit(1);
	}

	public static void main(string []args) {
		new Main(args);
	}
}
