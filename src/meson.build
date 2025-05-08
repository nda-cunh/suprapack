sources = [
  files('Build.vala',
    'QueueSet.vala',
    'Config.vala',
    'Log.vala',
    'Makepkg.vala',
    'Query.vala',
    'Run.vala',
    'Uninstall.vala',
    'Command.vala',
    'Install.vala',
    'main.vala',
    'Package.vala',
    'Repository.vala',
    'Sync.vala',
    'Utils.vala',
    'Http.vala',
    'SupraList.vala',
    'RepoInfo.vala',
    'BetterSearch.vala',
    'uname.vapi')
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
