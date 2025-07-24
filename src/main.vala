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

	bool all_cmd(string []commands) throws Error {

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

		debug ("prefix: [%s] strap: %s", config.prefix, config.strap);

		if (commands.length < 2) {
			return Cmd.help(opt_context.get_help(false, null));
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

		switch (av1) {
			case "query_get_comp":
				return Cmd.query_get_comp(commands);
			case "sync_get_comp":
				return Cmd.sync_get_comp(commands);
			case "shell":
				return Cmd.shell(commands);
			case "list_files":
			case "-Ql":
				return Cmd.list_files(commands);
			case "loading":
				Cmd.loading(commands);
			case "run":
			case "Qr":
				return Cmd.run(commands);
			case "-Q":
			case "list":
				return Cmd.list(commands);
			case "search":
			case "-Ss":
				return Cmd.search(commands);
			case "-B":
			case "build":
				return Cmd.build(commands);
			case "help":
				return Cmd.help(opt_context.get_help(false, null));
			case "install":
			case "add":
			case "-S":
				return Cmd.install(commands);
			case "uninstall":
			case "remove":
			case "-r":
				return Cmd.uninstall(commands);
			case "have_update":
				return Cmd.have_update(commands);
			case "update":
			case "-Su":
				return Cmd.update(commands);
			case "info":
			case "-Qi":
				return Cmd.info(commands);
			case "prepare":
			case "-P":
				return Cmd.prepare();
			case "search_supravim_plugin":
				return Cmd.search_supravim_plugin(commands);
			case "-G":
			case "download":
				return Cmd.download(commands);
			case "update_list":
			case "refresh":
				return Cmd.refresh();
			case "version":
				return Cmd.version();
		}
		error("La commande \"%s\" n'existe pas.", av1);
	}

	// INIT
	public Main(string []args) {
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
