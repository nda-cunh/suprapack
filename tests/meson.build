version_lib = static_library('supraversion',
  files('../src/Version.vala'),
  c_args: ['-w'],
  vala_header: 'supraversion.h',
  vala_vapi: 'supraversion.vapi',
  dependencies : [
    dependency('glib-2.0'),
    dependency('gobject-2.0')
  ],
  install : false)

version_dep = declare_dependency(
  link_with: version_lib,
  include_directories: include_directories('.'))


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
