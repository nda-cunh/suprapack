vala_srcs = files(
  'Archive.vala',
  'BetterSearch.vala',
  'Build.vala',
  'CommandPackage.vala',
  'CommandRepo.vala',
  'CommandSystem.vala',
  'Config.vala',
  'ConfigEnv.vala',
  'ConfigUser.vala',
  'Http.vala',
  'Install.vala',
  'Log.vala',
  'Makepkg.vala',
  'Package.vala',
  'Query.vala',
  'QueueSet.vala',
  'RepoInfo.vala',
  'Repository.vala',
  'Run.vala',
  'SupraList.vala',
  'Sync.vala',
  'Uninstall.vala',
  'Utils.vala',
  'Version.vala',
  'main.vala',
  'uname.vapi'
  )

zstd_dep = dependency('libzstd', required: true, static: true)

sub_archive = subproject('libarchive', default_options: [
  'default_library=static',
  'progs=[]',
  'zstd=enabled',
  'zlib=disabled',
  'bz2lib=disabled',
  'libb2=disabled',
  'iconv=disabled',
  'lz4=disabled',
  'lzma=disabled',
  'lzo2=disabled',
  'cng=disabled',
  'openssl=disabled',
  'xml2=disabled',
  'expat=disabled',
  'regex=disabled',
  'xattr=disabled',
  'acl=disabled',
  'tests=disabled',
])

dep_archive = sub_archive.get_variable('libarchive_dep')

executable('suprapack',
  vala_srcs,
  c_args: ['-w', '-DGETTEXT_PACKAGE="suprapack"'],
  vala_args: ['--pkg=libarchive'],
  dependencies : [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dep_archive,
  ],
  install : true)
