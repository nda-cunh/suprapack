[CCode(cheader_filename="openssl/ssl.h")]
namespace openssl {

	[Flags]
	[CCode (cprefix="SSL_OP_")]
	public enum SSL_OPTIONS {
        NO_SSLv2,
        NO_SSLv3,
        NO_COMPRESSION,
		NO_TLSv1,
		NO_TLSv1_1
    }	

	[CCode (cname="X509")]
    public struct X509{}
	
	[CCode (cname="SSL")]
    public struct SSL{}
	[CCode (cname="SSL_CTX")]
    public struct SSL_CTX{}


	[CCode (cname = "X509_verify_cert")]
	public void* X509_verify_cert(X509 *ctx);
	[CCode (cname = "X509_STORE_set_default_paths")]
	public void X509_STORE_set_default_paths();
	[CCode (cname = "X509_STORE_new")]
	public void* X509_STORE_new();
	[CCode (cname = "X509_STORE_free")]
	public void X509_STORE_free (void* store);
	[CCode (cname = "X509_STORE_init")]
	public void X509_STORE_init ();

	[CCode (cname = "SSL_library_init")]
	public void SSL_library_init();
	[CCode (cname = "OpenSSL_add_all_algorithms")]
	public void OpenSSL_add_all_algorithms();
	[CCode (cname = "SSL_load_error_strings")]
	public void SSL_load_error_strings();
	[CCode (cname = "SSL_CTX_new")]
	public void* SSL_CTX_new(void* method);
	[CCode (cname = "TLS_client_method")]
	public void* TLS_client_method();
	[CCode (cname = "SSL_new")]
	public void* SSL_new(void* ctx);
	[CCode (cname = "SSL_set_fd")]
	public void SSL_set_fd(void* ssl, int fd);
	[CCode (cname = "SSL_connect")]
	public int SSL_connect(void* ssl);
	[CCode (cname = "SSL_get_error")]
	public int SSL_get_error(void* ssl, int err);
	[CCode (cname = "SSL_shutdown")]
	public void SSL_shutdown(void* ssl);
	[CCode (cname = "SSL_free")]
	public void SSL_free(void* ssl);
	[CCode (cname = "SSL_CTX_free")]
	public void SSL_CTX_free(void* ctx);
	[CCode (cname = "EVP_cleanup")]
	public void EVP_cleanup();
	[CCode (cname = "SSL_write")]
	int SSL_write(void* ssl, char* message, int len);	
	[CCode (cname = "SSL_read")]
	int SSL_read(void* ssl, char* buff, int len);
}
