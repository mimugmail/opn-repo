$( document ).ready(function() {
	$('ul.nav.navbar-nav.navbar-right').append("<li><span class=\"navbar-theme\" id=\"theme_toggle\"><label class=\"theme-switch\" for=\"checkbox\"><input type=\"checkbox\" id=\"checkbox\" /><div class=\"slider round\"></div></label></span>")

const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
toggleSwitch.addEventListener('input', switchTheme);
const currentTheme = localStorage.getItem('theme') ? localStorage.getItem('theme') : null;
if (currentTheme) {
	document.documentElement.setAttribute('data-theme', currentTheme);
	if (currentTheme === 'dark') {
		toggleSwitch.checked = true;
	}
}

$('#debug').text("storage: "+currentTheme);
});

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


  /*
              <li><span class="navbar-text" id="theme_toggle"><label class="theme-switch" for="checkbox"><input type="checkbox" id="checkbox" /></label></span>
            </li>
  */