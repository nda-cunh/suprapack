install_data('_suprapack', install_dir: 'share/zsh/site-functions')
install_data('suprapack-installer.desktop', install_dir: 'share/applications')

# Generate info file 
if get_option('suprapack')
  description = 'package-manager without root'

  conf_data = configuration_data()
  conf_data.set('description', description)
  conf_data.set('name', meson.project_name())
  conf_data.set('version', meson.project_version())
  info_file = configure_file(input : 'info.in', output : 'info', configuration : conf_data)
  install_data('env', install_dir: '.')
  install_data('post_install', install_dir: '.')
  install_data('pre_install', install_dir: '.')
  install_data('uninstall', install_dir: '.')

  install_data(info_file, install_dir: '.')
endif
