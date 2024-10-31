[CCode (cname = "struct utsname", cheader_filename = "sys/utsname.h")]
public struct utsname {
	[CCode (cname="uname")]
	public static int uname(out utsname name);
	unowned string sysname;    /* Operating system name (e.g., "Linux") */
	unowned string nodename;   /* Name within "some implementation-defined network" */
	unowned string release;    /* Operating system release */
	unowned string version;    /* Operating system version */
	unowned string machine;    /* Hardware identifier */
	unowned string domainname; /* NIS or YP domain name */
}
