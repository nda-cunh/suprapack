

namespace Uninstall {

	public void add_queue (string name, ref  GenericSet<string> queue) throws Error {
		if (Query.is_exist (name) == false) {
			warning("%s is not installed", name);
			return ;
		}
		var all_required = Query.get_required_by(name);
		foreach (var deps in all_required) {
			add_queue(deps, ref queue);
		}
		queue.add(name);
	}


	private int calc_padding_max (GenericSet<string?> queue) {
		int size_max = 12;
		foreach (unowned var i in queue) {
			var len = i.length;
			if (len > size_max)
				size_max = len;
		}
		return size_max;
	}

	public bool uninstall (string []av) throws Error {
		var queue = new GenericSet<string?>(str_hash , str_equal);

		foreach (var i in av[2:av.length]) {
			add_queue (i, ref queue);
		}
		if (queue.length <= 0) {
			info("there's nothing to be done");
			return true;
		}
		print("the following packages will be removed\n");
		print("%sPackage (%u)%s\n\n", BOLD,queue.length, NONE);
		double size_max = 0;
		int padding_name = calc_padding_max (queue);
		foreach (var i in queue) {
			var pkg = Query.get_from_pkg(i);
			var size = double.parse(pkg.size_installed) / (1 << 20); 
			size_max += size;
			print("%s  %-*s %s%s %5s %s %5.2f Mib%s\n", PURPLE, padding_name, i, BOLD, GREEN, pkg.version, CYAN, size, NONE);
		}
		
		printf("\nTotal Remove Size:  %s%.2f MiB%s\n", BOLD, size_max, NONE);
		if (config.allays_yes || Utils.stdin_bool_choose_true(":: Proceed with installation [Y/n] ")) {
			foreach (unowned var i in queue) {
				Query.uninstall(i);
			}
		}
		return true;
	}
}
