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

	public errordomain HttpError {
		// Erreurs Génériques
		ERR,
		CANCEL,         // Annulation par l'utilisateur (Cancellable)
		TIMEOUT,        // Le serveur ne répond pas assez vite
		DNS_RESOLVE,    // Impossible de trouver l'hôte (pas d'internet ou mauvaise URL)

		// Erreurs de Statut (Logique HTTP)
		NOT_MODIFIED,   // 304 : Le fichier n'a pas bougé (Super important pour toi !)
		BAD_REQUEST,    // 400 : La requête est mal formée
		FORBIDDEN,      // 403 : Accès refusé (ex: Cloudflare bloque ton User-Agent)
		NOT_FOUND,      // 404 : Le fichier n'existe pas sur le miroir
		SERVER_ERROR,   // 500 : Le serveur du miroir a crashé
		UNAVAILABLE,    // 503 : Le miroir est en maintenance ou surchargé

		// Erreurs de Données
		MALFORMED_URL,  // L'URL passée est invalide
		WRITE_FAILED,   // Impossible d'écrire le fichier sur le disque (disque plein/droits)
		SIZE_MISMATCH   // La taille reçue ne correspond pas au Content-Length
	}

	private const int MAX_REDIRECT = 5;

	/**
	 * Download a file from the internet
	 *
	 * @param url the url of the file
	 * @param output the output file
	 * @param no_print if true, don't print the download progress
	 * @param cancel a cancellable object
	 */
	public void download (string url, string output, bool no_print = false, Cancellable? cancel = null) throws Error {
		Error? err = null;
		var loop = new MainLoop ();

		var s = new Unix.SignalSource(2);
		s.set_callback( () => {
			print("\n");
			warning("Cancel by Ctrl + C (SIGINT) signal");
			cancel?.cancel ();
			return false;
		});

		var output_etag = output + ".etag";
		if (FileUtils.test(output_etag, FileTest.EXISTS) && !FileUtils.test(output, FileTest.EXISTS)) {
			Log.debug("http", "ETag file exists but target file doesn't exist, removing ETag file");
			FileUtils.remove(output_etag);
		}

		if (no_print == false)
			print (HIDECURSOR);
		s.attach(GLib.MainContext.default());

		_download.begin(url, output, no_print, MAX_REDIRECT, cancel, (obj, res) => {
			try {
				if (cancel.is_cancelled ()) {
						FileUtils.remove (output);
						FileUtils.remove (output_etag);
					}
				_download.end (res);
			}
			catch (HttpError.NOT_MODIFIED e) {
				Log.debug("download", "File not modified, using cached version: %s", e.message);
			}
			catch (Error e) {
				err = e;
				FileUtils.remove (output);
				FileUtils.remove (output_etag);
			}
			loop.quit ();
		});
		loop.run ();

		Source.remove (s.get_id ());
		if (no_print == false)
			print (SHOWCURSOR);

		s.destroy ();
		if (err != null)
			throw err;
		if (cancel.is_cancelled ())
			throw new HttpError.CANCEL("the download is cancel (%s)", Log.vala_line ());
	}



	private async void _download (string url, string target, bool no_print = false, int redirect_left = MAX_REDIRECT, Cancellable? cancel = null) throws Error {
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

		/* Open Connection-Files */

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
			output_stream.put_string("User-Agent: SupraPack/1.0\r\n"); // Ajout de l'en-tête "User-Agent"

			string? saved_etag = read_etag_from_disk(target); // Fonction à créer
			if (saved_etag != null) {
				output_stream.put_string(@"If-None-Match: $saved_etag\r\n");
			}

			output_stream.put_string("Cache-Control: no-cache\r\n"); // Ignorer le cache
			output_stream.put_string("Accept-Encoding: identity\r\n"); // Ignorer le cache
			output_stream.put_string("Connection: close\r\n"); // Ignorer le cache
			output_stream.put_string("\r\n");
			output_stream.flush();
		}


		/* ERROR HTTP check 404, 400, 502 ...  */
		int status;
		{
			string error = input_stream.read_line_utf8(null, cancel);
			error = error.offset(error.index_of_char(' '));
			int err =  int.parse(error);
			var err_msg = error.replace("\r", "");
			status = err;

			switch (err) {
				case 304:
					Log.debug("download", "File not modified, use cached version");
					throw new HttpError.NOT_MODIFIED("File hasn't changed (304): %s (%s)", err_msg, Log.vala_line());

				case 400:
					throw new HttpError.BAD_REQUEST("Bad request: %s HTTP (%s)", err_msg, Log.vala_line());

				case 401:
				case 403:
					throw new HttpError.FORBIDDEN("Access denied by the mirror (Auth/Permissions): %s HTTP (%s)", err_msg, Log.vala_line());

				case 404:
					throw new HttpError.NOT_FOUND("File not found on the mirror: %s HTTP (%s)", err_msg, Log.vala_line());

				case 408:
				case 504:
					throw new HttpError.TIMEOUT("Request timeout (Server or Gateway): %s HTTP (%s)", err_msg, Log.vala_line());

				case 429:
					throw new HttpError.UNAVAILABLE("Too many requests (Rate limited): %s HTTP (%s)", err_msg, Log.vala_line());

				case 500:
					throw new HttpError.SERVER_ERROR("Internal server error: %s HTTP (%s)", err_msg, Log.vala_line());

				case 502:
				case 503:
					throw new HttpError.UNAVAILABLE("Mirror temporarily down or overloaded: %s HTTP (%s)", err_msg, Log.vala_line());

				default:
					if (err >= 400 && err < 500) {
						throw new HttpError.ERR("Client error %d: %s (%s)".printf(err, err_msg, Log.vala_line()));
					} else if (err >= 500) {
						throw new HttpError.SERVER_ERROR("Server error %d: %s (%s)".printf(err, err_msg, Log.vala_line()));
					}
					break;
			}
		}

		/* Header Part */
		size_t bytes = 0;
		bool has_length = false;
		bool chunked = false;
		string? location = null;
		string? current_etag = null;
		{
			string? line;
			while ((line = input_stream.read_line_utf8(null, cancel)) != null) {
				if (line == "\r" || line == "")
					break;
				Log.debug("download", "HEADER: [%s]", line);
				int sep = line.index_of_char(':');
				if (sep == -1)
					continue;
				string key = line[0:sep].ascii_down();
				string val = line.offset(sep + 1)._strip();

				switch (key) {
					case "content-length":
						bytes = (size_t)uint64.parse(val);
						has_length = true;
						break;
					case "transfer-encoding":
						chunked = val.ascii_down().contains("chunked");
						break;
					case "location":
						location = val;
						break;
					case "etag":
						current_etag = val;
						break;
				}
			}
		}

		if (status >= 300 && status < 400) {
			if (location == null)
				throw new HttpError.ERR("redirect %d without a Location header for %s (%s)", status, url, Log.vala_line());
			if (redirect_left <= 0)
				throw new HttpError.ERR("too many redirects for %s (%s)", url, Log.vala_line());
			var next = Uri.resolve_relative(url, location, UriFlags.SCHEME_NORMALIZE | UriFlags.ENCODED);
			Log.debug("download", "redirect to %s", next);
			yield _download(next, target, no_print, redirect_left - 1, cancel);
			return ;
		}

		var fs = FileStream.open (target, "w");
		if (fs == null)
			throw new HttpError.WRITE_FAILED("Impossible to create target_file: (%s) file", target);
		string name_file = display_name (target);

		/* Data Part */
		if (chunked == true)
			yield read_chunked (input_stream, fs, name_file, no_print, cancel);
		else
			yield read_identity (input_stream, fs, name_file, no_print, has_length, bytes, target, cancel);

		if (current_etag != null) {
			save_etag_to_disk(target, current_etag);
		}
		return ;
	}

	private string display_name (string target) {
		string name = Uri.unescape_string (target[target.last_index_of_char ('/') + 1:]);
		name = name.to_ascii ();
		if (name.has_suffix (".suprapack")) {
			name = name[0:-10];
			int idx = name.last_index_of_char ('_');
			if (idx != -1)
				name = name[0:idx];
		}
		if (name.length >= 25)
			name = name[0:12] + "..";
		return name;
	}

	private async void read_identity (DataInputStream ins, FileStream fs, string name_file, bool no_print, bool has_length, size_t bytes, string target, Cancellable? cancel) throws Error {
		const size_t SIZE_BUFFER = 262144;
		var buffer = new uint8[SIZE_BUFFER];
		double totalBytes = bytes;
		double actual = 0;
		size_t len = 0;

		do {
			if (no_print == false)
				print_download (name_file, actual, totalBytes);
			if (has_length == true && bytes == 0)
				break;
			try {
				size_t to_read = has_length ? size_t.min (bytes, SIZE_BUFFER) : SIZE_BUFFER;
				len = yield ins.read_async (buffer[0:to_read], Priority.HIGH, cancel);
				if (len > 0) {
					if (has_length == true)
						bytes -= len;
					actual += len;
					fs.write (buffer[0:len], 1);
				}
			}
			catch (Error e) {
				throw new HttpError.ERR ("Error %zu reading data: %s %s", bytes, e.message, Log.vala_line());
			}
		} while (len > 0);

		if (has_length == true && bytes != 0)
			throw new HttpError.SIZE_MISMATCH ("%s: %zu bytes missing out of %.0f (%s)", target, bytes, totalBytes, Log.vala_line());
		if (no_print == false) {
			print_download (name_file, actual, totalBytes);
			stderr.printf ("\n");
		}
	}

	private async void read_chunked (DataInputStream ins, FileStream fs, string name_file, bool no_print, Cancellable? cancel) throws Error {
		var buffer = new uint8[65536];
		double actual = 0;

		for (;;) {
			string? head = ins.read_line_utf8 (null, cancel);
			if (head == null)
				throw new HttpError.SIZE_MISMATCH ("chunked: stream cut before the last chunk (%s)", Log.vala_line ());

			int semi = head.index_of_char (';');
			if (semi != -1)
				head = head[0:semi];

			size_t remain = (size_t)uint64.parse (head._strip (), 16);
			Log.debug ("download", "chunk of %zu bytes", remain);
			if (remain == 0)
				break;

			while (remain > 0) {
				if (no_print == false)
					print_download (name_file, actual, 0);
				size_t len = yield ins.read_async (buffer[0:size_t.min (remain, buffer.length)], Priority.HIGH, cancel);
				if (len == 0)
					throw new HttpError.SIZE_MISMATCH ("chunked: %zu bytes left in the chunk (%s)", remain, Log.vala_line ());
				fs.write (buffer[0:len], 1);
				remain -= len;
				actual += len;
			}
			ins.read_line_utf8 (null, cancel);
		}

		string? trailer;
		while ((trailer = ins.read_line_utf8 (null, cancel)) != null) {
			if (trailer == "\r" || trailer == "")
				break;
			Log.debug ("download", "TRAILER: [%s]", trailer);
		}
		if (no_print == false) {
			print_download (name_file, actual, 0);
			stderr.printf ("\n");
		}
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

		if (max <= 0.0) {
			if (config.simple_print == false)
				stderr.printf("%-50s %8s\r", name_file, "%.2f Mib / ??? Mib     ".printf(actual / MIB));
			return;
		}

		double percent = (100 * actual) / max;

		if (config.simple_print) {
			stdout.printf("download: [%u]\n", (uint)percent);
			return ;
		}
		if (actual > max)
			actual = max;

		uint8[] progress_bar = "[                    ] \0".data;
		modify_percent_bar(progress_bar, percent);
		var part2 = "%.2f Mib / %.2f Mib %s %.1f%%".printf((actual / MIB), (max / MIB), ((string)progress_bar), percent);
		stderr.printf("%-27s %70s\r", name_file, part2);
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

private void save_etag_to_disk(string target_path, string etag_value) {
    string etag_path = target_path + ".etag";
    try {
        FileUtils.set_contents(etag_path, etag_value.strip());
    } catch (Error e) {
        warning("Could not save ETag for %s: %s", target_path, e.message);
    }
}

/**
  Check if the etag exist and target file exist and return the etag value if exist else return null
  the etag file is a simple text file with the same name as the target file but with the extension .etag
*/
private string? read_etag_from_disk(string target_path) {
    string etag_path = target_path + ".etag";
    
    if (!FileUtils.test(etag_path, FileTest.EXISTS)) {
        return null;
    }

    try {
        string etag_content;
        FileUtils.get_contents(etag_path, out etag_content);
        return etag_content.strip(); // .strip() enlève les \n ou espaces
    } catch (Error e) {
        Log.debug("http", "Could not read ETag file: %s", e.message);
        return null;
    }
}

}
