project('com.fyralabs.Abacus',
        'vala', 'c',
        version: '0.1.0'
)

gnome = import('gnome')
i18n = import('i18n')

if get_option('development')
  app_id = 'com.fyralabs.Abacus.Devel'
  name_suffix = ' (Nightly)'
else
  app_id = 'com.fyralabs.Abacus'
  name_suffix = ''
endif

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('NAME_SUFFIX', name_suffix)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', app_id)
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf.set10('DEVELOPMENT', get_option('development'))
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

add_project_arguments(
  '-include', 'config.h',
  '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
  language: 'c'
)

asresources = gnome.compile_resources(
  'as-resources', 'data/app.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

libgtk_dep = dependency('gtk4', version: '>=4.0.0', required: true)
libhelium_dep = dependency('libhelium-1')

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Evaluation.vala',
    'src/Convertor.vala',
    'src/Token.vala',
    'src/Scanner.vala',
)

executable(
    meson.project_name(),
    asresources,
    sources,
    dependencies: [
        dependency('glib-2.0', version: '>=2.30.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('json-glib-1.0', version: '>=1.4.4'),
        meson.get_compiler('vala').find_library('posix'),
        libgtk_dep,
        libhelium_dep,
    ],
    vala_args: [meson.project_source_root() + '/src/Config.vapi'],
    install: true,
)

subdir('data')
subdir('po')

gnome.post_install(
  gtk_update_icon_cache: true,
  update_desktop_database: true
)