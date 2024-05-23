project('suprapack', ['c', 'vala'], default_options : ['warning_level=3', 'optimization=2'])

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
           c_args: '-w',
           dependencies : [
              dependency('glib-2.0'),
              dependency('gobject-2.0'),
              dependency('gio-2.0')],
           install : true)
