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

/**
 * Provide a simple way to download files from the internet
 *
 * with TLS support and progress bar
 */
namespace Http {

	private errordomain HttpError {
		ERR,
		CANCEL
	}

	/**
	 * Download a file from the internet
	 *
	 * @param url the url of the file
	 * @param output the output file
	 * @param no_print if true, don't print the download progress
	 * @param rec if true, retry the download ( set only by download function d'ont use it )
	 * @param cancel a cancellable object
	 */
	public void download (string url, string? output = null, bool no_print = false, Cancellable? cancel = null, bool rec = false) throws Error {
		Error err = null;
		var loop = new MainLoop ();

		var s = new Unix.SignalSource(2);
		s.set_callback( () => {
			print("\n");
			warning("Cancel by Ctrl + C (SIGINT) signal");
			cancel?.cancel ();
			return false;
		});
		s.attach(GLib.MainContext.default());

		_download.begin(url, output, no_print, rec, cancel, (obj, res) => {
			if (cancel.is_cancelled ())
				FileUtils.remove (output);
			err = _download.end (res);
			loop.quit ();
		});
		loop.run ();
		s.destroy ();
		if (err != null) {
			throw err;
		}
		if (cancel.is_cancelled ())
			throw new HttpError.CANCEL("the download is cancel (%s)", Log.vala_line ());
	}

	private async Error? _download (string url, string? output = null, bool no_print = false, bool rec = false, Cancellable? cancel = null) {
		try {
		const size_t SIZE_BUFFER = 16777216;
		unowned string	host;
		unowned string	query;
		unowned string	path;
		int				port;


		/* Parse Url */
		Uri uri = Uri.parse (url, UriFlags.SCHEME_NORMALIZE | UriFlags.ENCODED);
		host = uri.get_host ();
		query = uri.get_query ();
		path = uri.get_path ();
		port = uri.get_port ();


		string target;
		if (output == null && rec == false)
			target = path[path.last_index_of_char('/') + 1:];
		else
			target = (!)output;

		/* Open Connection-Files */

		var fs = FileStream.open (target, "w");
		if (fs == null)
			throw new HttpError.ERR ("Impossible to create target_file: (%s) file", target);
		var client = new SocketClient(){tls=true};
		var conn = yield client.connect_to_host_async (host, (uint16)port, cancel);

		var output_stream = new DataOutputStream(conn.get_output_stream());
		var input_stream = new DataInputStream(conn.get_input_stream());
		Log.debug("download", "Host [%s] PATH [%s] PORT [%d]", host, path, port);


		/* Send GET request with headers */

		{
			string request = @"$path$(query != null ? "?"+query : "")";
			output_stream.put_string(@"GET $request HTTP/1.1\r\n");
			output_stream.put_string(@"Host: $host\r\n"); // Ajout de l'en-tête "Host"
			output_stream.put_string("Cache-Control: no-cache\r\n"); // Ignorer le cache
			output_stream.put_string("Accept-Encoding: identity\r\n"); // Ignorer le cache
			output_stream.put_string("Connection: close\r\n"); // Ignorer le cache
			output_stream.put_string("\r\n");
			output_stream.flush();
		}


		/* ERROR HTTP check 404, 400, 502 ...  */
		{
			string error = input_stream.read_line_utf8(null, cancel);
			error = error.offset(error.index_of_char(' '));
			int err =  int.parse(error);
			if (err != 200) {
				if (err != 302)
					throw new HttpError.ERR("%s HTTP (%s)", error.replace("\r", ""), Log.vala_line());
			}
		}

		string name_file;
		name_file = Uri.unescape_string(target[target.last_index_of_char ('/') + 1:]);
		name_file = name_file.to_ascii ();
		if (name_file.length >= 25)
			name_file = name_file[0:25] + "..";

		/* Get All bytes Data */
		string line;
		size_t bytes = 0;
		while ((line = input_stream.read_line_utf8(null, cancel)) != null) {
			/* Header Part */
			{
				uint8 buffer [2048];
				Log.debug("download", "HEADER: [%s]", line);
				if (line.has_prefix("Content-Length: "))
					line.scanf("Content-Length: %zu", out bytes);
				else if (line.has_prefix ("Transfer-Encoding:")) {
					line.scanf("Transfer-Encoding: %s", out buffer);
					if (((string)buffer).ascii_down () == "chunked") {
						Log.debug("download", "Retry chunked not supported");
						download(url, output, no_print, null, true);
						return null;
					}
				}
				else if (line.has_prefix("Location: ")) {
					line.scanf("Location: %s", out buffer);
					Log.debug("download", "redirect to %s", (string)buffer);
					download((string)buffer, output, no_print, null, true);
					return null;
				}
			}

			/* Data Part */
			if (line == "\r") {
				var buffer = new uint8[SIZE_BUFFER];
				double totalBytes = bytes;
				double actual = 0;
				size_t len = 0;
				do {
					if (no_print == false)
						print_download (name_file, actual, totalBytes);
					try {
						len = yield input_stream.read_async (buffer[0:SIZE_BUFFER - 1], Priority.HIGH, cancel);

						if (len > 0) {
							buffer[len] = '\0';
							bytes -= len;
							actual += len;
							fs.write (buffer[0:len], 1);
						}
					}
					catch (Error e) {
						if (bytes == 0)
							break;
						throw new HttpError.ERR("Error reading data: %s %s", e.message, Log.vala_line());
					}
				} while (len > 0);

			}
		}
		}
		catch (Error e) {
			return e;
		}
		return null;
	}

	/**
	 * Print the download progress
	 *
	 * @param name_file the name of the file
	 * @param actual the actual size of the file
	 * @param max the max size of the file
	 */
	private void print_download(string name_file, double actual, double max) {
		const double MIB = 1048576.0;
		double percent = (100 * actual) / max;
		if (config.simple_print) {
			print ("download: [%u]\n", (uint)percent);
			return ;
		}
		uint8[] progress_bar = "[                    ] \0".data;

		if (max <= 0.0) {
			stderr.printf("%-50s %8s\r", name_file, "%.2f Mib / ??? Mib     ".printf(actual / MIB));
			return;
		}
		if (actual > max)
			actual = max;

		modify_percent_bar(progress_bar, percent);
		var part2 = "%.2f Mib / %.2f Mib %s %.1f%%".printf((actual / MIB), (max / MIB), ((string)progress_bar), percent);
		stderr.printf("%-27s %70s\r", name_file, part2);
		if (percent == 100.0)
			stderr.printf("\r\n");
	}


	/**
	 * Create a buffer (string) with the progress of the download
	 *
	 * @param buffer the buffer to modify with the progress bar
	 * @param percent the percent of the download (0-100)
	 */
	private void modify_percent_bar (uint8[] buffer, double percent) {
		int calc = (int)(percent * 20 / 100);
		for (int i = 0; i < 20; i++) {
			if (i < calc) {
				buffer[i+1] = '-';
			} else {
				buffer[i+1] = ' ';
			}
		}
		buffer[21] = ']';
		buffer[22] = '\0';
	}
}
