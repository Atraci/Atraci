var run  = require('./run');
var path = require('path');


/*jshint quotmark:false */
var file1 = path.join(__dirname, 'assets', 'data.json');
var expected1 = [
  { "hello": "world" }
, { "0": "a", "1": "b", "2": "c" }
, { "list": ["mr", "plow"] }
, { "foo": [
      "bar"
    , "baz"
    , 2
    , { "one": "two" }
    , ["a", "b", "c"]
    ]
  , "yes": "no"
  }
];

var file2 = path.join(__dirname, 'assets', 'array.json');
var expected2 = [
  { "id": "one" }
, { "id": "two" }
, { "id": "three" }
, { "id": "four" }
];

run('Read a file with JSON strings', file1, expected1);
run('Read a file with JSON objects in an array', file2, expected2);
