sources = [
  files('Build.vala'),
  files('Config.vala'),
  files('Log.vala'),
  files('Makepkg.vala'),
  files('Query.vala'),
  files('Run.vala'),
  files('Uninstall.vala'),
  files('Command.vala'),
  files('Install.vala'),
  files('main.vala'),
  files('Package.vala'),
  files('Repository.vala'),
  files('Sync.vala'),
  files('Utils.vala'),
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
