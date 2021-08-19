window.addEventListener('DOMContentLoaded', () => {

	let headings = [...document.querySelector(".franklin-content").querySelectorAll('h1, h2, h3, h4, h5, h6')];
	let toc_entries = headings.map(head => {
		let id = head.getAttribute('id');
		return document.querySelector(`.page-content a[href="#${id}"]`)
	});

	headings = headings.filter((h, i) => toc_entries[i] !== null);
	toc_entries = toc_entries.filter((h, i) => toc_entries[i] !== null);

	const observer = new IntersectionObserver(entries => {
		
		rects = headings.map(h => h.getBoundingClientRect());

		let was_visible = false;
		for (let i = 0; i<headings.length; i++){
			rect = rects[i];

			visible = (
				rect.top >= 0 &&
				rect.left >= 0 &&
				rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && /* or $(window).height() */
				rect.right <= (window.innerWidth || document.documentElement.clientWidth) /* or $(window).width() */
			);
			was_visible = was_visible || visible;

			toc_entries[i].classList.toggle('active', visible);
		}

		if (!was_visible){
			let minimum_topdiff = Infinity;
			let min_i = -1;
			for (let i = 0; i<headings.length; i++){
				td = Math.abs(rects[i].top);
				if (td < minimum_topdiff){
					minimum_topdiff = td;
					min_i = i;
				}
			}
			for (let i = 0; i<headings.length; i++){
				toc_entries[i].classList.toggle('active', i == min_i);
			}
		}
	});

	// Track all sections that have an `id` applied
	headings.forEach((section) => {
		observer.observe(section);
	});



    // navbar button

    document.querySelector("button.greedy-nav__toggle").addEventListener("click", function(){
        document.querySelector("#navbar-container").classList.add('visible');
        document.querySelector("#overlay").classList.add('visible');
    });

	document.querySelector("#overlay").addEventListener("click", function(){
        document.querySelector("#navbar-container").classList.remove('visible');
        document.querySelector("#overlay").classList.remove('visible');
    });

	document.querySelectorAll("#navbar .page-content a").forEach(x => {
		x.addEventListener("click", function(){
			document.querySelector("#navbar-container").classList.remove('visible', true);
			document.querySelector("#overlay").classList.remove('visible', true);
		});
	})
	
});