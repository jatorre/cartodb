// These bundles are expected to be used together with existing non-browerified code.
// Define step here and add the "dest" value to a bundle defined in ./js_files.js
module.exports = {
  test_specs_for_browserify_modules: {
    src: [
      // Add specs for browserify module code here:
      'lib/assets/test/spec/cartodb/new_dashboard/**/*.js',
      'lib/assets/test/spec/cartodb/new_common/**/*.js'
    ],
    dest: '<%= browserify_modules.tests.dest %>',
    options: {
      transform: ['rewireify'] //Allow mocking of require() dependencies.
    }
  }
};

