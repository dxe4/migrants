module.exports = (grunt) ->
    grunt.initConfig(
        pkg: grunt.file.readJSON('package.json')
        coffee:
            files:
                src: ['../migrants/**/*.coffee']
                dest: '../migrants/base/js/script.js'
    )
    
    grunt.loadNpmTasks('grunt-contrib-coffee')
    grunt.registerTask('default', ['coffee'])
