project('suprapack', ['c', 'vala'])

add_project_arguments('-w', language: 'c')
add_project_arguments('--enable-experimental', language: 'vala')

executable('suprapack',
           'Log.vala',
           'Uninstall.vala',
           'Utils.vala',
           'Repository.vala',
           'Command.vala',
           'main.vala',
           'Query.vala',
           'Package.vala',
           'Install.vala',
           'Build.vala',
           'Config.vala',
           'Sync.vala',
           'Run.vala',
           'Makepkg.vala',
           c_args: '-O3',#todo
           dependencies : [
              dependency('glib-2.0'),
              dependency('gobject-2.0'),
              dependency('gio-2.0')],
           install : true)
