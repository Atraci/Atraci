var	ProgressBar	= require('progress-bar'),
	bar		= ProgressBar.create(process.stdout),
	progress	= -1;

// Dye the bar green :) and pad percentage to a length of 3 with zeroes.
bar.format = '\033[32m$bar;\033[m $percentage,3:0;% loaded.'; 

bar.symbols.loaded	= '\u2605';	// Black star
bar.symbols.notLoaded	= '\u2606';	// White star
bar.leftToRight		= false;	// Reverse progress.

function advance(){
	if (++progress > 100){
		console.log('\nDone.');
		return;
	}
	bar.update(progress / 100);
	setTimeout(advance, 100);
}

advance();
