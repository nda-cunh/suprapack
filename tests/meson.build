test_version = executable('test-version',
  files('test_version.vala'),
  c_args: ['-w'],
  dependencies : [
    version_dep,
    dependency('glib-2.0'),
    dependency('gobject-2.0')
  ],
  install : false)

test('version', test_version)
