
document.addEventListener('readystatechange', (event) => {
	document.styleSheets[4].disabled = true;
	document.documentElement.setAttribute('data-theme', getTheme());
});

$(document).ready(function() {

	$('.fa-paper-plane-o').addClass('fa-paper-plane').removeClass('fa-paper-plane-o');
	$('.fa-check-square-o').addClass('fa-check-square').removeClass('fa-check-square-o');
	$('.fa-plus-square-o').addClass('fa-plus-square-o').removeClass('fa-plus-square-o');
	$('.fa-folder-o').addClass('fa-folder-o').removeClass('fa-folder-o');
	$('.fa-square-o').addClass('fa-square').removeClass('fa-square-o');
	$('.fa-building-o').addClass('fa-microchip').removeClass('fa-building-o');
	$('.fa-map-signs').addClass('fa-network-wired').removeClass('fa-map-signs');
	$('.fa-map').addClass('fa-chart-network').removeClass('fa-map');
	$('.fa-expand').addClass('fa-network-wired').removeClass('fa-expand');
	$('.fa-lock').addClass('fa-shield-check').removeClass('fa-lock');
	$('.fa-clock-o').addClass('fa-clock').removeClass('fa-clocl-o');
	$('.fa-refresh').addClass('fa-redo').removeClass('fa-refresh');
	$('.glyphicon.glyphicon-fire').addClass('fa fa-route-highway').removeClass('glyphicon glyphicon-fire');
	$('.fa-support').addClass('fa fa-question-circle').removeClass('fa-support');
	$('.fa-plug').addClass('fa fa-plug')
	$('.fa').addClass('fal fa-lg').removeClass('fa');
});

function getTheme() {
	if (localStorage.getItem('theme')) {theme = localStorage.getItem('theme');}
	else theme = (window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
	return theme;
}

function switchTheme(e) {
	if (e.target.checked) {
		document.documentElement.setAttribute('data-theme', 'dark');
		localStorage.setItem('theme', 'dark');
	}
	else {
		document.documentElement.setAttribute('data-theme', 'light');
		localStorage.setItem('theme', 'light');
	}
  };
  
