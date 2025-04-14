
namespace Uninstall {

	public bool uninstall (string []av) throws Error {
		var queue = new QueueSet();

		foreach (unowned var i in av[2:av.length]) {
			add_queue (i, queue);
		}

		if (queue.length <= 0) {
			info("there's nothing to be done");
			return true;
		}

		print("the following packages will be removed\n");
		print(BOLD + "Package (%u)\n\n" + NONE, queue.length);
		uint8 buffer[24];
		uint64 size_max = 0;
		int padding_name = calc_padding_max (queue);

		foreach (unowned var i in queue) {
			var pkg = Query.get_from_pkg(i);
			uint64 size = uint64.parse(pkg.size_installed);
			size_max += size;
			Utils.convertBytePrint (size, buffer);
			print((PURPLE + "  %-*s " + BOLD + GREEN + " %5s " + CYAN + " %s\n" + NONE),
				padding_name, i, pkg.version, buffer);
		}

		Utils.convertBytePrint (size_max, buffer);
		printf("\nTotal Remove Size:  " + BOLD + "%s\n" + NONE, buffer);
		if (config.allays_yes || Utils.stdin_bool_choose(":: Proceed with installation [Y/n] ", true)) {
			foreach (unowned var i in queue) {
				Query.uninstall(i);
			}
		}
		return true;
	}

	private void add_queue (string name, QueueSet queue) throws Error {
		if (name in queue) {
			return ;
		}

		if (Query.is_exist (name) == false) {
			warning("%s is not installed", name);
			return ;
		}

		queue.add(name);

		var all_required = Query.get_required_by(name);
		foreach (unowned var deps in all_required) {
			add_queue(deps, queue);
		}
	}


	private int calc_padding_max (QueueSet queue) {
		int size_max = 12;
		foreach (unowned var i in queue) {
			var len = i.length;
			if (len > size_max)
				size_max = len;
		}
		return size_max;
	}
}
