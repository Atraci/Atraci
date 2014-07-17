var	ProgressBar	= require('progress-bar'),
	bar		= ProgressBar.create(process.stdout),
	progress	= -1;

function advance(){
	if (++progress > 100){
		console.log('\nDone.');
		return;
	}
	bar.update(progress / 100);
	setTimeout(advance, 100);
}

advance();
