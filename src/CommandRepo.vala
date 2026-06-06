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

	public bool refresh () throws Error {
		Log.suprapack("Refreshing packages list");
		Sync.refresh_list();
		Log.suprapack("Packages list Refreshed");
		return true;
	}

	public bool prepare (string []av) throws Error {
		Repository.prepare(av);
		return true;
	}

	public void print_supravim_plugin (ref SupraList repo, bool installed) {
		if (installed)
			print("[installed] ");
		print("%s %s [%s]\n", repo.name, repo.version, repo.description);
	}

	public bool search_supravim_plugin (string []av) throws Error {
		force_suprapack_update();
		var list = Sync.get_list_package();
		var installed = Query.get_all_installed_pkg();

		foreach (var i in list) {
			if (i.name.has_prefix("plugin-"))
				print_supravim_plugin(ref i, (i.name in installed));
		}
		return true;
	}

	private void print_search (ref SupraList repo, bool installed) {
		print(BOLD + PURPLE + " %s/" + WHITE, repo.repo_name);
		print("%s " + GREEN + "%s", repo.name, repo.version);
		if (installed)
			print(CYAN + " [installed]");
		print(NONE);
		if (repo.description != "")
			print("\n\t" + COM + "%s\n", repo.description);
	}

	public bool search (string []av) throws Error {
		force_suprapack_update();
		var list = Sync.get_list_package();
		var installed = Query.get_all_installed_pkg();
		if (av.length == 2) {
			for (var i = 0; i != list.length; ++i) {
				print_search(ref list[i], (list[i].name in installed));
			}
		}
		else {
			try {
				string regex_str = av[2].replace("*", ".*");
				var regex = new Regex(regex_str, RegexCompileFlags.OPTIMIZE);
				foreach (var i in list) {
					var desc = i.description.down ();
					if ((regex.match(i.name) || regex.match(i.version) || regex.match(desc)))
						print_search(ref i, (i.name in installed));
				}
			}
			catch (Error e) {
				error(e.message);
			}
		}
		print(NONE);
		return true;
	}
}
