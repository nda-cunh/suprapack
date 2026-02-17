sources = []

if need_bootstrap 
  # Bootstrap the project use C sources instead of Vala sources
  warning('[Bootstrap] Vala is not available, using C sources')

  boot_strap = custom_target('tar_gz',
    input: files('../bootstrap.tar.gz'),
    output: [
      'BetterSearch.c',
      'Build.c',
      'Command.c',
      'Config.c',
      'ConfigEnv.c',
      'ConfigUser.c',
      'Http.c',
      'Install.c',
      'Log.c',
      'Makepkg.c',
      'Package.c',
      'Query.c',
      'QueueSet.c',
      'RepoInfo.c',
      'Repository.c',
      'Run.c',
      'SupraList.c',
      'Sync.c',
      'Uninstall.c',
      'Utils.c',
      'main.c',
      ],
    command: [find_program('tar'), '--strip-components=1', '-xf', '@INPUT@', '-C', '@OUTDIR@'],
  )
  sources = boot_strap.to_list()
else
  sources = [
    files(
      'BetterSearch.vala',
      'Build.vala',
      'Command.vala',
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
      'main.vala',
      'uname.vapi',
      )
  ]
endif

executable('suprapack',
  sources,
  c_args: '-w',
  # vala_args: '--enable-experimental',
  dependencies : [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0')
  ],
  install : true)
