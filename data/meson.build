
########### Simple Variables
description = 'package-manager without root'
#######################################################


######## Info file
conf_data = configuration_data()
conf_data.set('description', description)
conf_data.set('name', meson.project_name())
conf_data.set('version', meson.project_version())
info_file = configure_file(input : 'info.in', output : 'info', configuration : conf_data)
install_data(info_file, install_dir: '.')
################################################ Install script


datadir = get_option('datadir')

install_subdir('applications', install_dir: datadir)
install_subdir('mime', install_dir: datadir)
install_subdir('zsh', install_dir: datadir)

files = files(
  'env',
  'info.in',
  'post_install',
  'pre_install',
  'uninstall'
)

prefix = get_option('prefix')

install_data(files, install_dir: prefix)
meson.add_install_script(exe_suprapack, 'build', prefix, '--yes', '--no-fakeroot', '--build-output', meson.project_source_root())
