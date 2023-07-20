function maybeAddWarning () {
    // DOCUMENTER_NEWEST is defined in versions.js, DOCUMENTER_CURRENT_VERSION and DOCUMENTER_STABLE
    // in siteinfo.js.
    // If either of these are undefined something went horribly wrong, so we abort.
    if (
            window.DOCUMENTER_NEWEST === undefined ||
            window.DOCUMENTER_CURRENT_VERSION === undefined ||
            window.DOCUMENTER_STABLE === undefined
       ) {
        return
    };

    // Current version is not a version number, so we can't tell if it's the newest version. Abort.
    if (!/v(\d+\.)*\d+/.test(window.DOCUMENTER_CURRENT_VERSION)) {
        return
    };

    // Current version is newest version, so no need to add a warning.
    if (window.DOCUMENTER_NEWEST === window.DOCUMENTER_CURRENT_VERSION) {
        return
    };

    // Add a noindex meta tag (unless one exists) so that search engines don't index this version of the docs.
    if (document.body.querySelector('meta[name="robots"]') === null) {
        const meta = document.createElement('meta');
        meta.name = 'robots';
        meta.content = 'noindex';

        document.getElementsByTagName('head')[0].appendChild(meta);
    };

    const div = document.createElement('div');
    div.classList.add('outdated-warning-overlay');
    const href = '/' + window.DOCUMENTER_STABLE + '/';
    div.innerHTML = `This documentation is for the version ${window.DOCUMENTER_CURRENT_VERSION}.<br>The latest version is ${window.DOCUMENTER_NEWEST}. <br> <a href="${href}">Go to the latest documentation</a>.`;
    const masthead = document.querySelector(".masthead");
    masthead.prepend(div);
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', maybeAddWarning);
} else {
    maybeAddWarning();
};
