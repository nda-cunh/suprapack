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

namespace Shell {
	private void env_change (ref string []env, string variable, string value) {
		unowned string? last_variable = Environ.get_variable (env, variable);
		if (last_variable != null) {
			env = Environ.set_variable(env, variable, @"$value:$last_variable", true);
		}
		else {
			env = Environ.set_variable(env, variable, value, true);
		}
	}


	private string[] load_env () {
		var env = Environ.get();
		var content = ConfigEnv.get_all_options_parsed ();
		for (uint i = 0; i < content.length; i += 2) {
			unowned string name = content[i];
			unowned string value = content[i + 1];
			env_change (ref env, name, value);
		}

		env = Environ.set_variable (env, "PREFIX", config.prefix, true);
		return (owned)env;
	}

	[NoReturn]
		public void run_shell (string []args) throws Error {
			string ps1_contents;
			var env = load_env();

			var shell = Environ.get_variable(env, "SHELL") ?? "/bin/bash";
			if (shell == "/bin/zsh")
				ps1_contents = "%(?:%{\033[01;32m%}%1{➜%} :%{\033[01;31m%}%1{➜%} ) %{\033[36m%}%c%{\033[00m%} ";
			else
				ps1_contents = "\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ ";
			env = Environ.set_variable(env, "PS1", "\033[35m(suprapack) \033[0m" + ps1_contents, true);
			Process.exit(simple_run(args, env));
		}


	[NoReturn]
		public void run (string []args) throws Error {
			var env = load_env();
			Process.exit(simple_run(args, env));
		}

	inline int simple_run (string []args, string []env) throws Error
	{
		int status;
		Process.spawn_sync(null, args, env, SpawnFlags.SEARCH_PATH | SpawnFlags.CHILD_INHERITS_STDIN, null, null, null, out status);
		return Process.exit_status(status);
	}
}
