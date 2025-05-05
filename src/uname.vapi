/**
 * This is a simple binding for the uname system call.
 * It is based on the C header file sys/utsname.h.
 */
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

namespace SupraUnix {
	[IntegerType ( rank = 9 )]
	[CCode ( cname="uid_t", has_type_id = false )]
	[SimpleType]
	public struct uid : int {
	}

	[CCode (cname = "getuid", cheader_filename = "unistd.h")]
	public uid getuid ();
	[CCode (cname = "geteuid", cheader_filename = "unistd.h")]
	public uid geteuid ();

	public bool is_root () {
		uid uid = getuid();
		uid euid = geteuid();

		if (uid == 0 && euid == 0)
			return true;
		else
			return false;
	}
}
