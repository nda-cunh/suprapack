project('suprapack', ['c', 'vala'], meson_version : '>= 0.56.0', version: '2.35', default_options : ['warning_level=0', 'optimization=2'])

i18n = import('i18n')

add_project_arguments('--enable-experimental', language: 'vala')
add_project_arguments('--target-glib=auto', language: 'vala')

subdir('src')
subdir('po')

subdir('data')

if get_option('tests')
  subdir('tests')
endif
