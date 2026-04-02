project('suprapack', ['c'], meson_version : '>= 0.56.0', version: '2.29', default_options : ['warning_level=0', 'optimization=2'])

i18n = import('i18n')

need_bootstrap = not (add_languages('vala', required: false, native: false))

if get_option ('bootstrap').enabled()
  need_bootstrap = true  
endif

add_project_arguments('--enable-experimental', language: 'vala')
add_project_arguments('--target-glib=auto', language: 'vala')

subdir('src')
subdir('po')
