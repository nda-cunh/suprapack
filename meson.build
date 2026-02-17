project('suprapack', ['c'], version: '2.27', default_options : ['warning_level=0', 'optimization=2'])

need_bootstrap = not (add_languages('vala', required: false, native: false))

if get_option ('bootstrap').enabled()
  need_bootstrap = true  
endif

add_project_arguments('--enable-experimental', language: 'vala')
add_project_arguments('--target-glib=auto', language: 'vala')

subdir('src')
