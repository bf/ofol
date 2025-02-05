project(
  'SDL3_ttf',
  'c',
  version: '3.1.0',
  license: 'zlib',
  default_options: [
    meson.version().version_compare('>=1.3.0') ? 'c_std=gnu99,c99' : 'c_std=gnu99',
  ],
)

cc = meson.get_compiler('c')

c_args = ['-I../subprojects/SDL3_ttf-3.1.0/include/']
if get_option('default_library') != 'static' and host_machine.system() == 'windows'
  c_args += '-DDLL_EXPORT'
endif

m_dep = cc.find_library('m', required : false)
freetype_dep = dependency('freetype2', required: true)
sdl3_dep = dependency('sdl3')

sdl3_ttf = library(
  'SDL3_ttf',
  'src/SDL_ttf.c',
  # 'DL3_ttf/SDL_ttf.c',
  c_args: c_args,
  dependencies: [freetype_dep, m_dep, sdl3_dep],
  install: true
)

depinc = include_directories(
  '.', 
  # '/usr/include/freetype2/', 
  './include/')
sdl3_ttf_dep = declare_dependency(
  link_with: sdl3_ttf,
  version: meson.project_version(),
  include_directories: depinc,
)