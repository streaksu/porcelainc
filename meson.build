project('porcelainc', 'd', version: '0.0.1', license: 'BSL-1.0')

conf = configuration_data()
conf.set('NAME',    meson.project_name())
conf.set('VERSION', meson.project_version())
conf.set('LICENSE', meson.project_license()[0])

configure_file(
    input:  'source/compiler.d.in',
    output: 'compiler.d',
    configuration: conf
)

include = include_directories('source')
source  = files(
    'source/backend/builtins.d',
    'source/backend/c.d',
    'source/frontend/ast.d',
    'source/frontend/lexer.d',
    'source/frontend/parser.d',
    'source/frontend/token.d',
    'source/utils/files.d',
    'source/utils/messages.d',
    meson.current_build_dir() + '/compiler.d',
    'source/main.d'
)

e = executable(
    meson.project_name(),
    source,
    include_directories: include,
    install: true
)

cc = find_program('cc')

test('Characters',  e, args: ['-c', files('test/characters.pr'), '-o', '1.c'])
test('Empty',       e, args: ['-c', files('test/empty.pr'),      '-o', '2.c'])
test('FizzBuzz',    e, args: ['-c', files('test/fizzbuzz.pr'),   '-o', '3.c'])
test('Hello World', e, args: ['-c', files('test/helloworld.pr'), '-o', '4.c'])
test('Numbers',     e, args: ['-c', files('test/numbers.pr'),    '-o', '5.c'])

test('Characters  + cc', cc, args: '1.c', is_parallel: false)
test('Empty       + cc', cc, args: '2.c', is_parallel: false, should_fail: true)
test('FizzBuzz    + cc', cc, args: '3.c', is_parallel: false)
test('Hello World + cc', cc, args: '4.c', is_parallel: false)
test('Numbers     + cc', cc, args: '5.c', is_parallel: false)
