window.addEventListener('DOMContentLoaded', () => {

	// const headings = [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')];

	// const observer = new IntersectionObserver(entries => {
		
	// 	let prev_active = null;

	// 	if (entries.length == 1 && !entries[0].isIntersecting){
	// 		let e = entries[0];
	// 		if (e.boundingClientRect.top < 0){
	// 			// moved out to the top, keep active
	// 			prev_active = e.target;
	// 		} else {
	// 			// moved out to the bottom, deactivate and activate previous
	// 			let id = e.target.getAttribute('id');
	// 			document.querySelector(`.page-content a[href="#${id}"]`).classList.remove('active');

	// 			let i = headings.indexOf(e.target);
	// 			if (i >= 1){
	// 				let id = headings[i-1].getAttribute('id');
	// 				document.querySelector(`.page-content a[href="#${id}"]`).classList.add('active');
	// 				prev_active = headings[i-1];
	// 			}
	// 		}
	// 	} else {
	// 		if (prev_active !== null){
	// 			prev_active.classList.remove('active');
	// 			prev_active = null;
	// 		}

	// 		entries.forEach(e => {
	// 			let id = e.target.getAttribute('id');
	// 			if (e.isIntersecting){
	// 				document.querySelector(`.page-content a[href="#${id}"]`).classList.add('active');
	// 			}
	// 		});
	// 	}

	// 	// intersectings = entries.filter(e => e.isIntersecting);

	// 	// for (let i = 0; i < entries.length; i++){
	// 	// 	let entry = entries[i];
	// 	// 	let id = entry.target.getAttribute('id');
	// 	// 	if (entry.isIntersecting) {
	// 	// 		document.querySelector(`.page-content a[href="#${id}"]`).classList.add('active');
	// 	// 	} else {
	// 	// 		document.querySelector(`.page-content a[href="#${id}"]`).classList.remove('active');
	// 	// 	}
	// 	// }
	// 	// if (best_id !== null){
	// 	// 	document.querySelector(`.page-content a[href="#${best_id}"]`).classList.add('active');
	// 	// } else if(best_before_id !== null) {
	// 	// 	document.querySelector(`.page-content a[href="#${best_before_id}"]`).classList.add('active');
	// 	// }
	// 	// best_before_id = best_id;
	// 	// entries.forEach(entry => {

	// 	// 	const id = entry.target.getAttribute('id');
	// 	// 	if (entry.intersectionRatio > 0) {
	// 	// 		document.querySelector(`.page-content a[href="#${id}"]`).classList.add('active');
	// 	// 	} else {
	// 	// 		document.querySelector(`.page-content a[href="#${id}"]`).classList.remove('active');
	// 	// 	}
	// 	// });
	// });

	// // Track all sections that have an `id` applied
	// headings.forEach((section) => {
	// 	observer.observe(section);
	// });





    // navbar button

    document.querySelector("button.greedy-nav__toggle").addEventListener("click", function(){
        document.querySelector("#navbar-container").classList.toggle('visible');
        document.querySelector("#overlay").classList.toggle('visible');
    });

	document.querySelector("#overlay").addEventListener("click", function(){
        document.querySelector("#navbar-container").classList.toggle('visible');
        document.querySelector("#overlay").classList.toggle('visible');
    });
	
});