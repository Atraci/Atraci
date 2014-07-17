var Transform = require('readable-stream').Transform;
var util      = require('util');
var clarinet  = require('clarinet');


/**
 * @constructor
 * @extends {Transform}
 */
var JStream = module.exports = function(path) {
  Transform.call(this, { objectMode: true });

  var parser = this.parser = new clarinet.createStream()
    , self = this
    , stack = []
    , currObj = {}
    , currKey = 'root'
    , inArray
    , pathMatch = true
    , parentPathMatch = true
    , comparator
    ;

  if (path) {
    // add some listeners only if path is given
    var onvaluepath = function onvaluepath(value) {
      if (pathMatch && stack.length === path.length &&
          match(currKey, comparator)) {
        self.push(value);
      }
    };

    var onopenpath = function onopenpath() {
      if (stack.length) {
        parentPathMatch = pathMatch = parentPathMatch &&
          comparator !== undefined &&
          match(currKey, comparator);
      }

      comparator = path[stack.length];
    };

    parser.on('value', onvaluepath);
    parser.on('openobject', onopenpath);
    parser.on('openarray', onopenpath);
  }


  parser.on('value', function onvalue(value) {
    currObj[currKey] = value;
    if (inArray) {
      currKey++;
    }
  });

  parser.on('key', function onkey(key) {
    currKey = key;
  });
  
  function onopen(key) {
    var obj, openArray;

    if (key === undefined) {
      // openarray
      obj = currObj[currKey] = [];
      openArray = true;
      key = 0;

    } else {
      // openobject
      obj = currObj[currKey] = {};
      openArray = false;
    }

    stack.push({
      obj: currObj
    , key: currKey + (inArray ? 1 : '')
    , arr: inArray
    , path: pathMatch
    });

    currObj = obj;
    currKey = key;
    inArray = openArray;
  }

  function onclose() {
    var current = stack.pop();
    currObj     = current.obj;
    currKey     = current.key;
    inArray     = current.arr;
    parentPathMatch = stack.length ? stack[stack.length - 1].path : true;
  }

  parser.on('openobject', onopen);
  parser.on('closeobject', onclose);
  parser.on('openarray', onopen);
  parser.on('closearray', onclose);

  parser.on('error', function onerror(err) {
    self.readable = false;
    self.writable = false;
    parser.emit = function() {};
    self.emit('error', err);
  });

  parser.on('end', self.push.bind(self, null));

  if (path) {
    var onclosepath = function onclosepath() {
      if (pathMatch && stack.length === path.length) {
        self.push(currObj[currKey]);
      }
      comparator = path[stack.length - 1];
    };

    parser.on('closeobject', onclosepath);
    parser.on('closearray', onclosepath);

  } else {
    // if `path` is not given, emit `data` event whenever a full
    // objectd on the root is parsed
    parser.on('closeobject', function onobjectavailable() {
      if (!stack.length || stack.length === 1 && inArray) {
        var key = inArray ? currKey - 1 : currKey;
        self.push(currObj[key]);
      }
    });
  }

};
util.inherits(JStream, Transform);


/**
 * Writes to the parser.
 *
 * @param {Buffer|String} chunk
 * @param {String} encoding
 * @param {Function(!Error)} callback
 */
JStream.prototype._transform = function(chunk, encoding, callback) {
  this.parser.write(chunk);
  callback(null);
};


/**
 * Compare a key against a string, number, RegExp, boolean, or function.
 *
 * @param {String} key
 * @param {String|Number|RegExp|Boolean|Function} comparator
 * @return {Boolean}
 */
function match(key, comparator) {
  switch (typeof comparator) {
    case 'string':
    case 'number':
      return key === comparator;

    case 'boolean':
      return comparator;

    case 'function':
      return comparator(key);

    case 'object':
      if (comparator instanceof RegExp) {
        return comparator.test(key);
      }
      break;

  }

  throw new TypeError('Path object not supported.');
}
