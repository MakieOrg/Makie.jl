window.addEventListener('DOMContentLoaded', () => {

	const observer = new IntersectionObserver(entries => {
		entries.forEach(entry => {
			const id = entry.target.getAttribute('id');
			if (entry.intersectionRatio > 0) {
				document.querySelector(`#contenttable a[href="#${id}"]`).classList.add('active');
			} else {
				document.querySelector(`#contenttable a[href="#${id}"]`).classList.remove('active');
			}
		});
	});

	// Track all sections that have an `id` applied
	document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((section) => {
		observer.observe(section);
	});
	
});