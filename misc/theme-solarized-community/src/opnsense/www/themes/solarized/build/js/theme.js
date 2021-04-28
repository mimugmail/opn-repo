document.addEventListener('readystatechange', (event) => {
    //const theme = localStorage.getItem('theme') ? localStorage.getItem('theme') : 'light';
	document.documentElement.setAttribute('data-theme', getTheme());
});

$(document).ready(function() {
	$('ul.nav.navbar-nav.navbar-right').append("<li><span class=\"navbar-theme\" id=\"theme_toggle\"><label class=\"theme-switch\" for=\"checkbox\"><input type=\"checkbox\" id=\"checkbox\" /><div class=\"slider round\"></div></label></span>")

	const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
	toggleSwitch.addEventListener('input', switchTheme);

	if (getTheme() === 'dark') {toggleSwitch.checked = true;}
});

function getTheme() {
	var theme = 'light';
	if (localStorage.getItem('theme')) {
		if (localStorage.getItem('theme') === 'dark') {theme = 'dark';}
	} else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {theme = 'dark';}
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
