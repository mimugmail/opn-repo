document.addEventListener('readystatechange', (event) => {
	document.styleSheets[4].disabled = true;
	document.documentElement.setAttribute('data-theme', getTheme());
});

$(document).ready(function() {

	$('.fa-building-o').addClass('fa-microchip').removeClass('fa-building-o');
	$('.fa-map-signs').addClass('fa-network-wired').removeClass('fa-map-signs');
	$('.fa-map').addClass('fa-chart-network').removeClass('fa-map');
	$('.fa-expand').addClass('fa-network-wired').removeClass('fa-expand');
	$('.fa-lock').addClass('fa-shield-check').removeClass('fa-lock');
	$('.fa-clock-o').addClass('fa-clock').removeClass('fa-clocl-o');
	$('.fa-refresh').addClass('fa-redo').removeClass('fa-refresh');
	$('.glyphicon.glyphicon-fire').addClass('fa fa-route-highway').removeClass('glyphicon glyphicon-fire');
	$('.fa-support').addClass('fa fa-question-circle').removeClass('fa-support');
	$('.fa').addClass('fal fa-lg').removeClass('fa');

	$('ul.nav.navbar-nav.navbar-right').append("<li><span class=\"navbar-theme\" id=\"theme_toggle\"><label class=\"theme-switch\" for=\"checkbox\"><input type=\"checkbox\" id=\"checkbox\" /><div class=\"slider round\"></div></label></span>")
	const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
	toggleSwitch.addEventListener('input', switchTheme);
	if (getTheme() === 'dark') {toggleSwitch.checked = true;}
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

  