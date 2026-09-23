	namespace Suprapack.ZSTD {
	public errordomain Error {
		CANT_OPEN_ARCHIVE,
			INFO_NOT_FOUND,
			WRITE
	}

	public void extract (string archive_path, string dest_path) throws ZSTD.Error {
		var reader = new Archive.Read ();
		reader.support_filter_all ();
		reader.support_format_all ();

		if (reader.open_filename (archive_path, 10240) != Archive.Result.OK) {
			throw new ZSTD.Error.CANT_OPEN_ARCHIVE ("Failed to open archive: [%s] (%s)", archive_path, reader.error_string ());
		}

		DirUtils.create_with_parents (dest_path, 0755);
		string old_cwd = Environment.get_current_dir ();
		Environment.set_current_dir (dest_path);

		unowned Archive.Entry entry;
		int flags = Archive.ExtractFlags.TIME | Archive.ExtractFlags.PERM;

		while (reader.next_header (out entry) == Archive.Result.OK) {
			if (reader.extract (entry, flags) != Archive.Result.OK) {
				printerr ("Erreur extraction : %s\n", reader.error_string ());
			}
		}

		reader.close ();
		Environment.set_current_dir (old_cwd);
	}

	public string get_info (string archive_path) throws ZSTD.Error {
		var reader = new Archive.Read();
		reader.support_filter_all();
		reader.support_format_all();

		if (reader.open_filename(archive_path, 10240) != Archive.Result.OK) {
			throw new ZSTD.Error.CANT_OPEN_ARCHIVE ("Failed to open archive: [%s] (%s)", archive_path, reader.error_string());
		}

		unowned Archive.Entry entry;

		while (reader.next_header(out entry) == Archive.Result.OK) {

			string path = entry.pathname ();

			while (path.has_prefix ("./")) {
				path = path.substring (2);
			}
			if (path.has_prefix ("/")) {
				path = path.substring (1);
			}

			if (path == "info" || Path.get_basename (path) == "info" && !("/" in path)) {
				uint8[] content;
				var size = entry.size();
				content = new uint8[size];

				var bytes_read = reader.read_data(content);
				if (bytes_read < 0) {
					throw new ZSTD.Error.CANT_OPEN_ARCHIVE ("Failed to read 'info' entry from archive: [%s] (%s)", archive_path, reader.error_string());
				}
				return ((string)content).dup ();
			} else {
				reader.read_data_skip();
			}
		}
		throw new ZSTD.Error.INFO_NOT_FOUND ("'info' entry not found in archive: [%s]", archive_path);
	}

	public static void create_package (string package_dest, string usr_dir) throws Error {
		var writer = new Archive.Write ();
		writer.set_format_pax_restricted ();
		writer.add_filter_zstd ();

		string abs_dest = File.new_for_path (package_dest).get_path ();

		if (writer.open_filename (abs_dest) != Archive.Result.OK) {
			throw new Error.WRITE ("unable to open archive for writing: %s", writer.error_string ());
		}

		var disk_reader = new Archive.ReadDisk ();
		disk_reader.set_standard_lookup ();

		string old_cwd = Environment.get_current_dir ();
		Environment.set_current_dir (usr_dir);

		try {
			uint8 buffer[8192];
			if (FileUtils.test ("info", FileTest.EXISTS)) {
				Posix.Stat st;
				Posix.lstat ("info", out st);

				var entry = new Archive.Entry ();
				entry.set_pathname ("./info");
				disk_reader.entry_from_file (entry, -1, st);
				entry.set_uid (0);
				entry.set_gid (0);
				entry.set_uname ("root");
				entry.set_gname ("root");

				writer.write_header (entry);

				var file = File.new_for_path ("info");
				var stream = file.read ();
				ssize_t bytes_read;
				while ((bytes_read = stream.read (buffer)) > 0) {
					writer.write_data (buffer[0:bytes_read]);
				}
			}
			add_dir_recursive (writer, disk_reader, ".");
		} 
		catch (Error e) {
			throw new Error.WRITE ("error while creating package: %s", e.message);
		}
		Environment.set_current_dir (old_cwd);
		writer.close ();
	}

	private static void add_dir_recursive (Archive.Write writer, Archive.ReadDisk disk_reader, string rel_path) throws Error {
		try {
			var dir = Dir.open (rel_path);
			string? name = null;

			while ((name = dir.read_name ()) != null) {
				string child_path = (rel_path == ".") ? name : Path.build_filename (rel_path, name);

				if (child_path == "info" || child_path == "./info") {
					continue;
				}
				var entry = new Archive.Entry ();
				entry.set_pathname (child_path);

				Posix.Stat st = {};
				if (Posix.lstat (child_path, out st) < 0) {
					printerr ("Warning: cannot stat %s\n", child_path);
					continue;
				}
				disk_reader.entry_from_file (entry, -1, st);

				entry.set_uid (0);
				entry.set_gid (0);
				entry.set_uname ("root");
				entry.set_gname ("root");

				if (writer.write_header (entry) != Archive.Result.OK) {
					throw new Error.WRITE ("unable to write header for %s: %s", child_path, writer.error_string ());
				}

				if (FileUtils.test (child_path, FileTest.IS_REGULAR)) {
					var file = File.new_for_path (child_path);
					var stream = file.read ();
					uint8 buffer[16384];
					ssize_t bytes_read;

					while ((bytes_read = stream.read (buffer)) > 0) {
						writer.write_data (buffer[0:bytes_read]);
					}
				}

				if (FileUtils.test (child_path, FileTest.IS_DIR) && !FileUtils.test (child_path, FileTest.IS_SYMLINK)) {
					add_dir_recursive (writer, disk_reader, child_path);
				}
			}
		} catch (GLib.Error e) {
			throw new Error.WRITE ("error while adding directory %s: %s", rel_path, e.message);
		}
	}

}
