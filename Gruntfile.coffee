module.exports = (grunt) ->
  buildPlatforms = parseBuildPlatforms(grunt.option('platforms'))
  packageJson = grunt.file.readJSON('package.json')

  ataciVersion = packageJson.version
  grunt.log.writeln 'Building ' + packageJson.version

  grunt.initConfig
    clean: ['build/releases/**']

    coffee:
      compileBare:
        options:
          bare: true
        files:
          'js/app.js': ['coffee/-*.coffee', 'coffee/app.coffee', 'coffee/_*.coffee']

    compass:
      dist:
        options:
          cssDir: 'css'
        files:
          'css/app.css': 'sass/app.sass'

    uglify:
      target:
        files:
          'js/app.js': 'js/app.js'

    cssmin:
      minify:
        files:
          'css/app.css': 'css/app.css'

    shell:
      runnw:
        options:
          stdout: true
        command: [
          '.\\cache\\0\.10\.1\\win\\nw.exe . --debug',
          './cache/0.10.1/osx/node-webkit.app/Contents/MacOS/node-webkit . --debug',
          './cache/0.10.1/linux32/nw . --debug',
          './cache/0.10.1/linux64/nw . --debug'
        ].join('&')

    'regex-replace':
      windows_installer:
        src: ['dist/win/windows-installer.iss']
        actions:
          name: 'version'
          search: '#define AppVersion "[\.0-9]+"'
          replace: '#define AppVersion "' + ataciVersion + '"'

    nodewebkit:
      options:
        version: '0.10.1'
        build_dir: './build'
        mac_icns: './images/icon.icns'
        mac: buildPlatforms.mac
        win: buildPlatforms.win
        linux32: buildPlatforms.linux32
        linux64: buildPlatforms.linux64
      src: ['./css/**', './fonts/**', './images/**', './js/**', './l10n/**', './node_modules/**', './featured-music/**', '!./node_modules/grunt*/**', './index.html', './package.json']

    copy:
      main:
        files: [
          src: 'libraries/win/ffmpegsumo.dll'
          dest: 'build/releases/Atraci/win/Atraci/ffmpegsumo.dll'
          flatten: true
        ,
          src: 'libraries/win/ffmpegsumo.dll'
          dest: 'build/cache/win/<%= nodewebkit.options.version %>/ffmpegsumo.dll'
          flatten: true
        ,
          src: 'libraries/mac/ffmpegsumo.so'
          dest: 'build/releases/Atraci/mac/Atraci.app/Contents/Frameworks/node-webkit Framework.framework/Libraries/ffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/mac/ffmpegsumo.so'
          dest: 'build/cache/mac/<%= nodewebkit.options.version %>/node-webkit.app/Contents/Frameworks/node-webkit Framework.framework/Libraries/ffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/linux64/libffmpegsumo.so'
          dest: 'build/releases/Atraci/linux64/Atraci/libffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/linux64/libffmpegsumo.so'
          dest: 'build/cache/linux64/<%= nodewebkit.options.version %>/libffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/linux64/icudtl.dat'
          dest: 'build/releases/Atraci/linux64/Atraci/icudtl.dat'
          flatten: true
        ,
          src: 'libraries/linux32/libffmpegsumo.so'
          dest: 'build/releases/Atraci/linux32/Atraci/libffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/linux32/libffmpegsumo.so'
          dest: 'build/cache/linux32/<%= nodewebkit.options.version %>/libffmpegsumo.so'
          flatten: true
        ,
          src: 'libraries/linux32/icudtl.dat'
          dest: 'build/releases/Atraci/linux32/Atraci/icudtl.dat'
          flatten: true
        ]

    compress:
      linux32:
        options:
          mode: 'tgz'
          archive: 'build/releases/Atraci/linux32/Atraci-' + ataciVersion + '.tgz'
        expand: true
        cwd: 'build/releases/Atraci/linux32/'
        src: '**'
      linux64:
        options:
          mode: 'tgz'
          archive: 'build/releases/Atraci/linux64/Atraci-' + ataciVersion + '.tgz'
        expand: true
        cwd: 'build/releases/Atraci/linux64/'
        src: '**'

    coffeelint:
      app: ['coffee/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-compass'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-regex-replace'
  grunt.loadNpmTasks 'grunt-node-webkit-builder'
  grunt.loadNpmTasks 'grunt-contrib-compress'
  grunt.loadNpmTasks 'grunt-coffeelint'

  grunt.registerTask 'default', ['compass', 'coffeelint', 'coffee']
  grunt.registerTask 'obfuscate', ['uglify', 'cssmin']
  grunt.registerTask 'nodewkbuild', ['nodewebkit', 'copy']
  grunt.registerTask 'run', ['default', 'shell:runnw']
  grunt.registerTask 'build', ['default', 'obfuscate', 'clean', 'regex-replace', 'nodewkbuild', 'compress']

parseBuildPlatforms = (argumentPlatform) ->

  # this will make it build no platform when the platform option is specified
  # without a value which makes argumentPlatform into a boolean
  inputPlatforms = argumentPlatform or process.platform + ';' + process.arch

  # Do some scrubbing to make it easier to match in the regexes bellow
  inputPlatforms = inputPlatforms.replace('darwin', 'mac')
  inputPlatforms = inputPlatforms.replace(/;ia|;x|;arm/, '')
  buildAll = /^all$/.test(inputPlatforms)
  buildPlatforms =
    mac: /mac/.test(inputPlatforms) or buildAll
    win: /win/.test(inputPlatforms) or buildAll
    linux32: /linux32/.test(inputPlatforms) or buildAll
    linux64: /linux64/.test(inputPlatforms) or buildAll

  buildPlatforms
