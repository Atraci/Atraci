var	tty	= require('tty');

/**
 * Creates a ProgressBar.
 *
 * @constructor
 * @this {ProgressBar}
 * @param {stdout} output The output interface for the progress bar. Use process.stdout.
 * @param {number} width The width of the progress bar in characters, borders excluded.
*/
function ProgressBar(output, width){
	if (width){
		this.width	= width;
	}
	this._output	= output;
}

ProgressBar.prototype = {
	/**
	 * The output interface of the progress bar.
	 *
	 * @private
	*/
	_output: null,
	/**
	 * {Object} Object containing the symbol instructions for the progress bar.
	*/
	symbols: {
		leftBorder:	'[',
		rightBorder:	']',
		loaded:		'#',
		notLoaded:	'-'
	},
	/**
	 * {number} Width of the progress bar in characters, borders excluded.
	*/
	width:		10,
	/**
	 * {Boolean} Boolean determining whether the bar progresses from left to right.
	*/
	leftToRight:	true,
	/**
	 * {String} The format to write on the stdout.
	*/
	format:		'$bar; $percentage;% loaded.',
	/**
	 * {number} Progress value (0.0 - 1.0) of the progress bar.
	*/
	progress:	0,
	/**
	 * {RegExp} The RegExp the bar uses to interpret the format string.
	*/
	interpreter:	/\$([a-z]+)(\s?,\s?([0-9]+)(\s?:\s?(.))?)?;/ig,
	/**
	 * Updates the progress bar graphical representation.
	 *
	 * @param {number} value The new value for progress. (Optional)
	*/
	update:	function(value){
		if (typeof value !== 'undefined'){
			value = +value;
			if (value < 0 || value > 1){
				throw new RangeError('Value out of bounds.');
			} else if (isNaN(value)) {
				throw new TypeError('Value not a number.');
			} else {
				this.progress	= value;
			}
		}
		value	= this.progress;
		var	percentage	= Math.floor(value * 100),
			done		= Math.floor(value * this.width),
			notDone		= this.width - done,
			graphStart	= Array(done + 1).join(this.symbols.loaded),
			graphEnd	= Array(notDone + 1).join(this.symbols.notLoaded),
			graph		= this.leftToRight ? graphStart + graphEnd : graphEnd + graphStart;

		graph	=	this.symbols.leftBorder	+ 
				graph			+
				this.symbols.rightBorder;

		this.clear();

		var line = this.format.replace(this.interpreter, function(str, valueName, padding, pad){
			padding	= arguments[3] || 0;
			pad	= arguments[5] || ' ';
			var val;
			switch (valueName.toLowerCase()){
				case 'percentage':
					val = percentage;
					break;
				case 'progress':
					val = value;
					break;
				case 'bar':
					val = graph;
					break;
				default:
					return str;
			}
			val	= String(val);
			if (padding){
				var	paddingNeeded = Number(padding) - val.length + 1;
				val	= Array(paddingNeeded > 0 ? paddingNeeded : 1).join(pad) + val;
			}
			return val;
		});
		this._output.write(line);
	},
	/**
	 * Clears the progress bar off the screen.
	*/
	clear: function(){
		this._output.cursorTo(0);
		this._output.clearLine(1);
	}
}

exports.ProgressBar	= ProgressBar;
/**
 * A shorthand function to create a new ProgressBar instance.
*/
exports.create		= function(a,b,c){
	return new ProgressBar(a,b,c);
}
