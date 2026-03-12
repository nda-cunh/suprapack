project('suprapack', ['c'], meson_version : '>= 0.56.0', version: '2.28', default_options : ['warning_level=0', 'optimization=2'])

need_bootstrap = not (add_languages('vala', required: false, native: false))

if get_option ('bootstrap').enabled()
  need_bootstrap = true  
endif

subdir('src')
subdir('po')
subdir('data')
