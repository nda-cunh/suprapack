source_names = [
  'BetterSearch',
  'Build',
  'CommandPackage',
  'CommandRepo',
  'CommandSystem',
  'Config',
  'ConfigEnv',
  'ConfigUser',
  'Http',
  'Install',
  'Log',
  'Makepkg',
  'Package',
  'Query',
  'QueueSet',
  'RepoInfo',
  'Repository',
  'Run',
  'SupraList',
  'Sync',
  'Uninstall',
  'Utils',
  'main',
]

vala_sources = []
bootstrap_outputs = []
foreach source_name : source_names
  vala_sources += files(source_name + '.vala')
  bootstrap_outputs += source_name + '.c'
endforeach
vala_sources += files('uname.vapi')

sources = []

if need_bootstrap 
  # Bootstrap the project use C sources instead of Vala sources
  warning('[Bootstrap] Vala is not available, using C sources')

  boot_strap = custom_target('tar_gz',
    input: files('../bootstrap.tar.gz'),
    output: bootstrap_outputs,
    command: [find_program('tar'), '--strip-components=1', '-xf', '@INPUT@', '-C', '@OUTDIR@'],
  )
  sources = boot_strap.to_list()
else
  sources = vala_sources
endif

executable('suprapack',
  sources,
  c_args: ['-w', '-DGETTEXT_PACKAGE="suprapack"'],
  # vala_args: '--enable-experimental',
  dependencies : [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0')
  ],
  install : true)
