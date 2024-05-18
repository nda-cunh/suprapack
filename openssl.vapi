[CCode(cheader_filename="openssl/ssl.h,openssl/err.h,openssl/bio.h")]
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
	public int SSL_write(void* ssl, char* message, int len);	
	[CCode (cname = "SSL_read")]
	public int SSL_read(void* ssl, char* buff, int len);
	[CCode (cname = "ERR_print_errors_fp")]
	public void ERR_print_errors_fp (GLib.FileStream fp);
	public delegate int Verificator(int ok, void *ctx);

	[CCode (cname = "SSL_VERIFY_NONE")]
	public const int SSL_VERIFY_NONE;
	[CCode (cname = "SSL_CTX_set_verify")]
	public void SSL_CTX_set_verify(void* ctx, int a, void* ptr);
	[CCode (cname = "SSL_CTX_set_cert_verify_callback")]
    public void SSL_CTX_set_cert_verify_callback(void* ctx, Verificator callback);
		

	[CCode (cname = "SSL_CTX_set_options")]
	public void SSL_CTX_set_options(void* ctx, SSL_OPTIONS opts);
	[CCode (cname = "SSL_CTX_set_default_verify_paths")]
	public void SSL_CTX_set_default_verify_paths(void* ctx);

}
