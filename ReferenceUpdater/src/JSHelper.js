/**
 * JSHelper.js - ES6 module for ReferenceUpdater UI interactions
 */

/**
 * Filter reference cards by score threshold
 * @param {number} threshold - Minimum score to show
 */
export function filterByScore(threshold) {
    const t = parseFloat(threshold) || 0;
    const cards = document.querySelectorAll('.ref-card');
    cards.forEach(card => {
        const score = parseFloat(card.dataset.score) || 0;
        card.dataset.hidden = score >= t ? 'false' : 'true';
    });
}

/**
 * Setup image cycling button for a card
 * Cycles through: recorded -> reference -> glmakie -> recorded
 * @param {HTMLElement} buttonContainer - Container with the button and images
 * @param {HTMLElement} mediaRecorded - Recorded image element
 * @param {HTMLElement} mediaReference - Reference image element
 * @param {HTMLElement} mediaGlmakie - GLMakie reference image element
 */
export function setupImageCycleButton(buttonContainer, mediaRecorded, mediaReference, mediaGlmakie) {
    const button = buttonContainer.querySelector('button');
    if (!button) return;

    button.addEventListener('click', () => {
        // Get current z-index to determine state
        const getZ = (el) => parseInt(el.style.zIndex || window.getComputedStyle(el).zIndex || '0');

        // Cycle: recorded -> reference -> glmakie -> recorded
        if (getZ(mediaRecorded) > getZ(mediaReference) && getZ(mediaRecorded) > getZ(mediaGlmakie)) {
            // Currently showing recorded, switch to reference
            mediaRecorded.style.zIndex = '1';
            mediaReference.style.zIndex = '3';
            mediaGlmakie.style.zIndex = '2';
            button.textContent = 'Showing: reference';
        } else if (getZ(mediaReference) > getZ(mediaRecorded) && getZ(mediaReference) > getZ(mediaGlmakie)) {
            // Currently showing reference, switch to glmakie
            mediaRecorded.style.zIndex = '2';
            mediaReference.style.zIndex = '1';
            mediaGlmakie.style.zIndex = '3';
            button.textContent = 'Showing: glmakie';
        } else {
            // Currently showing glmakie, switch to recorded
            mediaRecorded.style.zIndex = '3';
            mediaReference.style.zIndex = '2';
            mediaGlmakie.style.zIndex = '1';
            button.textContent = 'Showing: recorded';
        }
    });
}

/**
 * Sort reference cards by backend score
 * @param {HTMLElement} grid - The grid container
 * @param {string} backend - Backend name ("GLMakie", "CairoMakie", "WGLMakie", or "" for reset)
 */
export function sortByBackend(grid, backend) {
    const cards = Array.from(grid.children).filter(c => c.classList.contains('ref-card'));
    const groups = new Map();

    // Group cards by image name
    cards.forEach(card => {
        const name = card.dataset.imgname;
        if (!groups.has(name)) groups.set(name, []);
        groups.get(name).push(card);
    });

    // Sort groups
    const sorted = Array.from(groups.entries()).sort((a, b) => {
        if (backend === "") {
            // Reset: sort by max score across all backends
            const aMax = Math.max(...a[1].map(c => parseFloat(c.dataset.score) || 0));
            const bMax = Math.max(...b[1].map(c => parseFloat(c.dataset.score) || 0));
            return bMax - aMax;
        } else {
            // Sort by specific backend
            const aCard = a[1].find(c => c.dataset.backend === backend);
            const bCard = b[1].find(c => c.dataset.backend === backend);
            const aScore = aCard ? parseFloat(aCard.dataset.score) || 0 : -Infinity;
            const bScore = bCard ? parseFloat(bCard.dataset.score) || 0 : -Infinity;
            return bScore - aScore;
        }
    });

    // Re-append cards in sorted order
    grid.innerHTML = '';
    sorted.forEach(([_, group]) => group.forEach(card => grid.appendChild(card)));
}

/**
 * Compare selected backend to GLMakie by filtering cards to single column
 * @param {HTMLElement} grid - The grid container
 * @param {string} selectedBackend - Backend to compare ("CairoMakie" or "WGLMakie")
 */
export function compareToGLMakie(grid, selectedBackend) {
    const cards = Array.from(grid.children).filter(c => c.classList.contains('ref-card'));

    if (selectedBackend === "") {
        // Reset: restore original order and show all cards in 3-column layout

        // Group by image name
        const groups = new Map();
        cards.forEach(card => {
            const name = card.dataset.imgname;
            if (!groups.has(name)) groups.set(name, []);
            groups.get(name).push(card);
        });

        // Sort groups by max score
        const sortedGroups = Array.from(groups.entries()).sort((a, b) => {
            const aMax = Math.max(...a[1].map(c => parseFloat(c.dataset.score) || 0));
            const bMax = Math.max(...b[1].map(c => parseFloat(c.dataset.score) || 0));
            return bMax - aMax;
        });

        // Clear and re-add all cards in original order (grouped by image, all backends per image)
        grid.innerHTML = '';
        sortedGroups.forEach(([_, group]) => {
            // Sort cards within group by backend order: GLMakie, CairoMakie, WGLMakie
            const backendOrder = { 'GLMakie': 0, 'CairoMakie': 1, 'WGLMakie': 2 };
            group.sort((a, b) => {
                const aOrder = backendOrder[a.dataset.backend] ?? 999;
                const bOrder = backendOrder[b.dataset.backend] ?? 999;
                return aOrder - bOrder;
            });

            // Add all cards for this image
            group.forEach(card => {
                card.style.display = '';
                grid.appendChild(card);
            });
        });

        grid.style.gridTemplateColumns = '1fr 1fr 1fr';
        return;
    }

    // Comparison mode: show only selected backend in single column

    // Group cards by image name
    const groups = new Map();
    cards.forEach(card => {
        const name = card.dataset.imgname;
        if (!groups.has(name)) groups.set(name, []);
        groups.get(name).push(card);
    });

    // Sort by selected backend's score
    const sortedGroups = Array.from(groups.entries()).sort((a, b) => {
        const aCard = a[1].find(c => c.dataset.backend === selectedBackend);
        const bCard = b[1].find(c => c.dataset.backend === selectedBackend);
        const aScore = aCard ? parseFloat(aCard.dataset.score) || 0 : -Infinity;
        const bScore = bCard ? parseFloat(bCard.dataset.score) || 0 : -Infinity;
        return bScore - aScore;
    });

    // Clear grid and re-add cards in comparison order
    grid.innerHTML = '';
    sortedGroups.forEach(([_, group]) => {
        // Add all cards from this group (hidden except selected)
        group.forEach(card => {
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

/**
 * Collect all checked items for upload
 * Separates files into upload (new/updated) and delete (missing) categories
 * @returns {Object} Object with uploadFiles and deleteFiles arrays
 */
export function collectCheckedFiles() {
    const allCards = document.querySelectorAll('.ref-card');
    const uploadFiles = [];
    const deleteFiles = [];

    allCards.forEach(card => {
        const checkbox = card.querySelector('.checkbox-input');
        if (checkbox && checkbox.checked) {
            const filepath = card.dataset.filepath;
            if (filepath) {
                // Check if this is from the missing files section (for deletion)
                const isMissingSection = card.closest('.section')?.querySelector('h2')?.textContent?.includes('Missing');
                if (isMissingSection) {
                    deleteFiles.push(filepath);
                } else {
                    uploadFiles.push(filepath);
                }
            }
        }
    });

    return { uploadFiles, deleteFiles };
}

/**
 * Update selection counts in the UI
 * Updates the count headers and file lists based on checked items
 */
export function updateSelectionCounts() {
    const { uploadFiles, deleteFiles } = collectCheckedFiles();

    // Update counts
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

    // Update lists
    if (uploadFileList) {
        uploadFileList.innerHTML = '';
        uploadFiles.forEach(file => {
            const li = document.createElement('li');
            li.className = 'upload-list-item';
            li.textContent = file;
            uploadFileList.appendChild(li);
        });
    }
    if (deleteFileList) {
        deleteFileList.innerHTML = '';
        deleteFiles.forEach(file => {
            const li = document.createElement('li');
            li.className = 'upload-list-item';
            li.textContent = file;
            deleteFileList.appendChild(li);
        });
    }
}

/**
 * Setup selection count updates
 * Adds event listeners to update counts when checkboxes change
 */
export function setupSelectionCountUpdates() {
    // Add event listeners to all checkboxes
    document.addEventListener('change', (event) => {
        if (event.target.classList.contains('checkbox-input')) {
            updateSelectionCounts();
        }
    });

    // Initial update
    updateSelectionCounts();
}
