# Values defined here are accessible from within Vala.
# This can be useful for setting build-time constants, such as the version or app id.
# See the Config.vapi file for more information.

config = configuration_data()
config.set_quoted('APP_ID', meson.project_name())
config.set_quoted('APP_PATH', path_identifier)
config.set_quoted(
  'NAME_SUFFIX',
  get_option('development') ? ' (Development)' : '',
)
config.set_quoted('VERSION', meson.project_version())
config.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config.set_quoted(
  'LOCALEDIR',
  join_paths(get_option('prefix'), get_option('localedir')),
)
config.set10('DEVELOPMENT', get_option('development'))

configure_file(
  output: 'config.h',
  configuration: config,
)

add_project_arguments(
  '-include', 'config.h',
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w',
  language: 'c',
)

# Define sources and dependencies for your application below.

sources = [
  gresources,
  'Application.vala',
  'MainWindow.vala',
  'Evaluation.vala',
  'Convertor.vala',
  'Token.vala',
  'Scanner.vala',
  'History.vala',
]

dependencies = [
  dependency('gtk4'),
  dependency('gee-0.8'),
  dependency('gio-2.0'),
  dependency('libhelium-1'),
  dependency('json-glib-1.0'),
  meson.get_compiler('c').find_library('m', required: true),
  meson.get_compiler('vala').find_library('posix'),
]

executable(
  meson.project_name(),
  [blueprints_workaround, sources],
  dependencies: dependencies,
  vala_args: [meson.project_source_root() + '/src/Config.vapi'],
  install: true,
)
