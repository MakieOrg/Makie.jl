// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

function filterByScore(threshold) {
    const t = parseFloat(threshold) || 0;
    const cards = document.querySelectorAll('.ref-card');
    cards.forEach((card)=>{
        const score = parseFloat(card.dataset.score) || 0;
        card.dataset.hidden = score >= t ? 'false' : 'true';
    });
}
function sortByBackend(grid, backend) {
    const cards = Array.from(grid.children).filter((c)=>c.classList.contains('ref-card'));
    const groups = new Map();
    cards.forEach((card)=>{
        const name = card.dataset.imgname;
        if (!groups.has(name)) groups.set(name, []);
        groups.get(name).push(card);
    });
    const sorted = Array.from(groups.entries()).sort((a, b)=>{
        if (backend === "") {
            const aMax = Math.max(...a[1].map((c)=>parseFloat(c.dataset.score) || 0));
            const bMax = Math.max(...b[1].map((c)=>parseFloat(c.dataset.score) || 0));
            return bMax - aMax;
        } else {
            const aCard = a[1].find((c)=>c.dataset.backend === backend);
            const bCard = b[1].find((c)=>c.dataset.backend === backend);
            const aScore = aCard ? parseFloat(aCard.dataset.score) || 0 : -Infinity;
            const bScore = bCard ? parseFloat(bCard.dataset.score) || 0 : -Infinity;
            return bScore - aScore;
        }
    });
    grid.innerHTML = '';
    sorted.forEach(([_, group])=>group.forEach((card)=>grid.appendChild(card)));
}
function compareToGLMakie(grid, selectedBackend, rootPath) {
    const cards = Array.from(grid.children).filter((c)=>c.classList.contains('ref-card'));
    if (selectedBackend === "" || selectedBackend === "GLMakie") {
        const groups = new Map();
        cards.forEach((card)=>{
            const name = card.dataset.imgname;
            if (!groups.has(name)) groups.set(name, []);
            groups.get(name).push(card);
        });
        const sortedGroups = Array.from(groups.entries()).sort((a, b)=>{
            const aMax = Math.max(...a[1].map((c)=>parseFloat(c.dataset.score) || 0));
            const bMax = Math.max(...b[1].map((c)=>parseFloat(c.dataset.score) || 0));
            return bMax - aMax;
        });
        grid.innerHTML = '';
        sortedGroups.forEach(([imgName, group])=>{
            const backendOrder = {
                'GLMakie': 0,
                'CairoMakie': 1,
                'WGLMakie': 2
            };
            group.sort((a, b)=>{
                const aOrder = backendOrder[a.dataset.backend] ?? 999;
                const bOrder = backendOrder[b.dataset.backend] ?? 999;
                return aOrder - bOrder;
            });
            group.forEach((card)=>{
                card.style.display = '';
                grid.appendChild(card);
            });
        });
        grid.style.gridTemplateColumns = '1fr 1fr 1fr';
        return;
    }
    const groups = new Map();
    cards.forEach((card)=>{
        const name = card.dataset.imgname;
        if (!groups.has(name)) groups.set(name, []);
        groups.get(name).push(card);
    });
    const sortedGroups = Array.from(groups.entries()).sort((a, b)=>{
        const aCard = a[1].find((c)=>c.dataset.backend === selectedBackend);
        const bCard = b[1].find((c)=>c.dataset.backend === selectedBackend);
        const aScore = aCard ? parseFloat(aCard.dataset.score) || 0 : -Infinity;
        const bScore = bCard ? parseFloat(bCard.dataset.score) || 0 : -Infinity;
        return bScore - aScore;
    });
    grid.innerHTML = '';
    sortedGroups.forEach(([imgName, group])=>{
        group.forEach((card)=>{
            if (card.dataset.backend === selectedBackend) {
                card.style.display = '';
            } else {
                card.style.display = 'none';
            }
            grid.appendChild(card);
        });
    });
    grid.style.gridTemplateColumns = '1fr';
}
export { filterByScore as filterByScore };
export { sortByBackend as sortByBackend };
export { compareToGLMakie as compareToGLMakie };

