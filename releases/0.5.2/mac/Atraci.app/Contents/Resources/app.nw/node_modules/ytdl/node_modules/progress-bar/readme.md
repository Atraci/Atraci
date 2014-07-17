progress-bar
============

A simple STDOUT progress bar for NodeJS.

Installation
------------

```shell

$ npm install progress-bar

```

Usage
-----

```javascript

// Create an instance:
var	bar	= require('progress-bar').create(process.stdout);

// Update progress and draw to screen:
bar.update(0.5);

```

![[★★★★★★★★★★★★★★★★★★★★★★★★★] 100% loaded.](https://github.com/jussi-kalliokoski/node-progress-bar/raw/master/screenshot.png)

Documentation
-------------

JSDocs can be found at http://niiden.com/node-progress-bar/jsdoc/ .

MIT License
