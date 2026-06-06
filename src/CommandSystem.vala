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

namespace Cmd {

	public bool shell (string []av) throws Error {
		var env = Environ.get();
		var shell = Environ.get_variable(env, "SHELL") ?? "/bin/bash";
		config.force = true;
		if (av.length == 3) {
			config.change_prefix (av[2]);
		}

		config.is_shell = true;
		if (shell.has_suffix("bash"))
			Cmd.run({"suprapack", "run", shell, "--noprofile", "--norc"});
		else if (shell.has_suffix("zsh"))
			Cmd.run({"suprapack", "run", shell, "-f"});
		return true;
	}

	public bool query_get_comp (string []av) throws Error {
		FileUtils.close (2);
		var pkgs = Query.get_all_package();
		for (var i = 0; i != pkgs.length; ++i) {
			if (i == pkgs.length - 1)
				print("%s", pkgs[i].name);
			else
				print("%s ", pkgs[i].name);
		}
		return true;
	}

	public bool sync_get_comp (string []av) throws Error {
		FileUtils.close (2);
		var pkgs = Sync.get_list_package();
		for (var i = 0; i != pkgs.length; ++i) {
			if (i == pkgs.length - 1)
				print("%s", pkgs[i].name);
			else
				print("%s ", pkgs[i].name);
		}
		return true;
	}

	public bool run (string []av) throws Error {
		string []av_binary;
		if (av.length == 2)
			error("`suprapack run [...]`");

		var? name_app = Environment.find_program_in_path (av[2]);
		if (Query.is_exist(av[2]) == false && name_app == null) {
			Log.suprapack("%s doesn't exist install it...", av[2]);
			Cmd.install({"", "install", av[2]});
		}
		name_app = Environment.find_program_in_path (av[2]);
		av_binary = {av[2]};
		if (Query.is_exist (av[2]) && config.force == false) {
			var pkg = Query.get_from_pkg(av[2]);
			av_binary = {pkg.binary};
		}
		else if (name_app == null && av[2].has_suffix(".suprapack"))
			name_app = av[2];
		else if (name_app == null)
			error("(%s) is not installed", av[2]);

		foreach (unowned var i in av[3: av.length])
			av_binary += i;
		if (config.is_shell)
			Shell.run_shell(av_binary);
		else
			Shell.run(av_binary);
	}

	public bool version () throws Error {
		print("SupraPack version: %s\n", Query.get_from_pkg ("suprapack").version);
		return true;
	}

	public bool help (string []av) throws Error {
		const string help1 = BOLD + YELLOW + "[SupraPack] ----- Help -----\n\n" +
		"\t" + p_suprapack + " (add | install) [package name]\n" +
		"\t  " + COM + " install a package from a repository\n" +
		"\t" + p_suprapack + " [(add | install)] [file.suprapack]\n" +
		"\t  " + COM + " install a package from a file (suprapack)\n" +
		"\t" + p_suprapack + " (remove | uninstall) [package name]\n" +
		"\t  " + COM + " remove a package\n" +
		"\t" + p_suprapack + " download [package name]\n" +
		"\t  " + COM + " download the suprapack file, but do not install\n" +
		"\t" + p_suprapack + " update\n" +
		"\t  " + COM + " update all your package\n" +
		"\t" + p_suprapack + " update [package name]\n" +
		"\t  " + COM + " update a package\n" +
		"\t" + p_suprapack + " search <pkg>\n" +
		"\t  " + COM + " search a package in the repo you can use patern for search\n" +
		"\t  " + BOLD + GREY + " Exemple:" + COM + " suprapack search " + CYAN + "'plugin*lsp' \n" +
		"\t" + p_suprapack + " list_files <pkg>\n" +
		"\t  " + COM + " list all file instaled by pkg\n" +
		"\t" + p_suprapack + " list <pkg>\n" +
		"\t  " + COM + " list your installed package\n" +
		"\t" + p_suprapack + " info [package name]\n" +
		"\t  " + COM + " print info of package name\n" +
		"\t" + p_suprapack + " config [config name] [config value]\n" +
		"\t  " + COM + " update a config in your user.conf\n" +
		"\t" + p_suprapack + " <help>\n" +
		"\t  " + COM + " you have RTFM... so you are a real\n" +
		"\n" + BOLD + YELLOW + "[Special argument]\n"
		 + "%s" +
		BOLD + YELLOW + "[Dev Only]\n" + NONE +
		p_suprapack + " build " + CYAN + "[PREFIX]\n" +
		"\t" + COM + " build a suprapack you need a prefix look note part\n" +
		"\t" + COM + " you can add a post_install or pre_install or uninstall file\n" +
		"\t" + COM + " install script can use $$SRCDIR and $$PKGDIR\n" +
		p_suprapack + " prepare\n" +
		"\t" + COM + " prepare your repository\n" +
		"\t" + COM + " to run in your folder full of suprapack files\n" +
		"\t" + COM + " this command generate a list file\n" +
		"\n" +
		BOLD + YELLOW + "[Note]\n" + NONE +
		WHITE + "PREFIX is a folder with this directory like: \n" + NONE +
		CYAN + "'bin' 'share' 'lib'\n" + NONE +
		BOLD + WHITE + "Example: " + CYAN + "suprapatate/bin/suprapatate" + NONE + " `suprapack build suprapatate`\n";

		stdout.printf(help1, Main.opt_context.get_help (true, null));
		return true;
	}

	[NoReturn]
	public bool loading (string []av) throws Error {
		if (av.length == 2)
			error("suprapack loading <command> [<args>]");
		int status = 0;
		var loop = new MainLoop();

		Utils.loading.begin();
		Utils.run_proc.begin(av, (obj, res) => {
			status = Utils.run_proc.end(res);
			loop.quit();
		});
		loop.run();
		Process.exit(status);
	}

	private const string p_suprapack = BOLD + "suprapack" + NONE;
}
