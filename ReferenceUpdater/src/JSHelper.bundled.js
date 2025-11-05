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
function setupImageCycleButton(buttonContainer, mediaRecorded, mediaReference, mediaGlmakie) {
    const button = buttonContainer.querySelector('button');
    if (!button) return;
    button.addEventListener('click', ()=>{
        const getZ = (el)=>parseInt(el.style.zIndex || window.getComputedStyle(el).zIndex || '0');
        if (getZ(mediaRecorded) > getZ(mediaReference) && getZ(mediaRecorded) > getZ(mediaGlmakie)) {
            mediaRecorded.style.zIndex = '1';
            mediaReference.style.zIndex = '3';
            mediaGlmakie.style.zIndex = '2';
            button.textContent = 'Showing: reference';
        } else if (getZ(mediaReference) > getZ(mediaRecorded) && getZ(mediaReference) > getZ(mediaGlmakie)) {
            mediaRecorded.style.zIndex = '2';
            mediaReference.style.zIndex = '1';
            mediaGlmakie.style.zIndex = '3';
            button.textContent = 'Showing: glmakie';
        } else {
            mediaRecorded.style.zIndex = '3';
            mediaReference.style.zIndex = '2';
            mediaGlmakie.style.zIndex = '1';
            button.textContent = 'Showing: recorded';
        }
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
function compareToGLMakie(grid, selectedBackend) {
    const cards = Array.from(grid.children).filter((c)=>c.classList.contains('ref-card'));
    if (selectedBackend === "") {
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
        sortedGroups.forEach(([_, group])=>{
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
    sortedGroups.forEach(([_, group])=>{
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
function collectCheckedFiles() {
    const allCards = document.querySelectorAll('.ref-card');
    const uploadFiles = [];
    const deleteFiles = [];
    allCards.forEach((card)=>{
        const checkbox = card.querySelector('.checkbox-input');
        if (checkbox && checkbox.checked) {
            const filepath = card.dataset.filepath;
            if (filepath) {
                const isMissingSection = card.closest('.section')?.querySelector('h2')?.textContent?.includes('Missing');
                if (isMissingSection) {
                    deleteFiles.push(filepath);
                } else {
                    uploadFiles.push(filepath);
                }
            }
        }
    });
    return {
        uploadFiles,
        deleteFiles
    };
}
function updateSelectionCounts() {
    const { uploadFiles , deleteFiles  } = collectCheckedFiles();
    const uploadCountHeader = document.getElementById('upload-count-header');
    const deleteCountHeader = document.getElementById('delete-count-header');
    const uploadFileList = document.getElementById('upload-file-list');
    const deleteFileList = document.getElementById('delete-file-list');
    if (uploadCountHeader) {
        uploadCountHeader.textContent = uploadFiles.length + ' images selected for updating:';
    }
    if (deleteCountHeader) {
        deleteCountHeader.textContent = deleteFiles.length + ' images selected for removal:';
    }
    if (uploadFileList) {
        uploadFileList.innerHTML = '';
        uploadFiles.forEach((file)=>{
            const li = document.createElement('li');
            li.className = 'upload-list-item';
            li.textContent = file;
            uploadFileList.appendChild(li);
        });
    }
    if (deleteFileList) {
        deleteFileList.innerHTML = '';
        deleteFiles.forEach((file)=>{
            const li = document.createElement('li');
            li.className = 'upload-list-item';
            li.textContent = file;
            deleteFileList.appendChild(li);
        });
    }
}
function setupSelectionCountUpdates() {
    document.addEventListener('change', (event)=>{
        if (event.target.classList.contains('checkbox-input')) {
            updateSelectionCounts();
        }
    });
    updateSelectionCounts();
}
export { filterByScore as filterByScore };
export { setupImageCycleButton as setupImageCycleButton };
export { sortByBackend as sortByBackend };
export { compareToGLMakie as compareToGLMakie };
export { collectCheckedFiles as collectCheckedFiles };
export { updateSelectionCounts as updateSelectionCounts };
export { setupSelectionCountUpdates as setupSelectionCountUpdates };

