using openssl; 


using Posix;

public class Http {
	string url;
	string domain;
	string uri;
	bool tls = false;
	int socket;
	SSL_CTX *ctx;
	SSL *ssl;

	~Http(){
		SSL_shutdown(ssl);
		SSL_free(ssl);
		SSL_CTX_free(ctx);
		close(socket);
		EVP_cleanup();
	}

	public Http (string url) {
		this.url = url;
		AddrInfo *si, p;
		AddrInfo hints = {};
		hints.ai_family = AF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;

		/*  Parse URL  */
		MatchInfo match_info;
		if (!/((?P<type>(https?)):\/\/)?(?P<name>[^\/]*)(?P<uri>.*)/.match (url, 0, out match_info))
			error("Regex Error");

		var type   = match_info.fetch_named("type");
		domain = match_info.fetch_named("name");
		uri    = match_info.fetch_named("uri");


		SSL_library_init ();
		OpenSSL_add_all_algorithms();
		SSL_load_error_strings();
		ctx = SSL_CTX_new(TLS_client_method());
		if (ctx == null) {
			perror("SSL_CTX_new");
			return;
		}
		SSL_CTX_set_default_verify_paths(ctx);
		SSL_CTX_set_options(ctx, SSL_OPTIONS.NO_SSLv3 | NO_SSLv2 | NO_COMPRESSION);
		



		ssl = SSL_new(ctx);
		if (ssl == null) {
			perror("SSL_new");
			exit(1);
		}


		/*  DNS  Resolver  */
		getaddrinfo(domain, type, hints, out si);
		for (p = si; p != null; p = p->ai_next) {
			if ((socket = Posix.socket(p->ai_family, p->ai_socktype, p->ai_protocol)) < 0)
				continue;
			if (connect(socket, p->ai_addr, p->ai_addrlen) < 0) {
				error("Erreur lors de la connexion au serveur");
			}
			break;
		}

		int err = 0;
		SSL_set_fd(ssl, socket);
		if (SSL_connect(ssl) <= 0) {
			err = SSL_get_error(ssl, err);
			perror("SSL_connect");
		}


		print("Socket:	%d\n", socket);
		print("Domain:	%s\n", domain);
		print("Type:	%s\n", type);
		print("uri:	%s\n", uri);
		
		if (type == "https"){
			tls = true;
		}
	}

	public void send_message (string request) {
		message("request [%s] uri [%s] domain [%s]", request, uri, domain);

		if (SSL_write(ssl, request, request.length) < 0) {
			ERR_print_errors_fp (GLib.stdout);
			error("Erreur lors de l'envoi de la requête HTTP");
		}
	}

	private void _send_download() {
		send_message (@"GET $uri HTTP/1.1\r
Host: $domain\r
Cache-Control: no-cache\r
Accept-Encoding: identity\r
Connection: close\r
\r\n\r\n");
	}

	public async Bytes async_download () {
	 	_send_download ();
		var bytes = yield async_receive_message ();
		return bytes;
	}
	public Bytes download () {
	 	_send_download ();
		return receive_message ();
	}
	
	

	public Bytes receive_message (uint64 size_buffer = 8192) {
		var builder = new StringBuilder();
    	var buffer = new uint8[size_buffer];
		
		ssize_t n;
		while ((n = SSL_read(ssl, buffer, (int)size_buffer)) > 0) {
			builder.append_len ((string)buffer, n);
		}
		return StringBuilder.free_to_bytes ((owned)builder);
	}

	public async Bytes async_receive_message (uint64 size_buffer = 8192) {
		var thread = new Thread<Bytes>(null, ()=> {
			var bytes = receive_message (size_buffer);
			Idle.add(async_receive_message.callback);
			return (owned)bytes;
		});
		yield;
		var bytes = thread.join();
		return bytes;
	}

}

int main(string[] args) {

	// var http = new Http("https://raw.githubusercontent.com/PalsFreniers/CLiMb_index/master/list");
	var http = new Http("https://gitlab.com/supraproject/suprastore_repository/-/raw/master/list");

	// Timeout.add (100, ()=>{
		// print("hello\n");
		// return true;
	// });

	var bytes = http.download ();
	print("[%s]\n", (string)bytes.get_data());
	return 0;
}
