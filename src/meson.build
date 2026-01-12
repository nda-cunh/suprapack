sources = [
  files(
    'BetterSearch.vala',
    'Build.vala',
    'Command.vala',
    'Config.vala',
    'ConfigEnv.vala',
    'Http.vala',
    'Install.vala',
    'Log.vala',
    'main.vala',
    'Makepkg.vala',
    'Package.vala',
    'Query.vala',
    'QueueSet.vala',
    'RepoInfo.vala',
    'Repository.vala',
    'Run.vala',
    'SupraList.vala',
    'Sync.vala',
    'uname.vapi',
    'Uninstall.vala',
    'Utils.vala',
    )
]

executable('suprapack',
  sources,
  c_args: '-w',
  vala_args: '--enable-experimental',
  dependencies : [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0')
  ],
  install : true)
