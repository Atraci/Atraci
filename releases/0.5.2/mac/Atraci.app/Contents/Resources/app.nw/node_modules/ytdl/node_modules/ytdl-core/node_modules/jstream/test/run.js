var JStream = require('..');
var assert  = require('assert');
var fs      = require('fs');


/**
 * Tests that a `file` emits `expected` results given a `path`
 *
 * @param (string) description
 * @param (string) file
 * @param (Array.Object) expected
 * @param (Array.Object) path
 */
module.exports = function runTest(description, file, expected, path) {
  describe(description, function() {
    it('JStream emits expected Javascript objects', function(done) {
      var rs = fs.createReadStream(file);
      var jstream = new JStream(path);
      rs.pipe(jstream);

      var dataEmitted = false;
      var n = 0;

      jstream.on('data', function(obj) {
        dataEmitted = true;
        assert.deepEqual(obj, expected[n++]);
      });

      jstream.on('end', function() {
        assert.ok(dataEmitted);
        done();
      });
    });
  });
};
