// ---------------------------------------------------
// Loads Shoelace for ShoelaceWidgets.jl. Every sl-* element
// the package creates carries this script as a Bonito asset,
// so Bonito puts it in the head once per page and users never
// have to add anything themselves.
//
// It is a classic script (not a module) on purpose: it runs
// synchronously while the head is parsed, so the theme links
// land in the head before the body paints, the same as static
// <link> tags would.
// ---------------------------------------------------
(function () {
    if (window.ShoelaceWidgets) {
        return;
    }

    const CDN = "https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn";
    const root = document.documentElement;

    function theme_link(name) {
        const id = "shoelace-widgets-theme-" + name;
        let link = document.getElementById(id);
        if (!link) {
            link = document.createElement("link");
            link.id = id;
            link.rel = "stylesheet";
            link.href = CDN + "/themes/" + name + ".css";
            document.head.appendChild(link);
        }
        return link;
    }

    // `auto` loads both themes and lets prefers-color-scheme pick, so
    // switching the system theme reskins a running page.  A forced theme
    // turns the other stylesheet off with `not all`.  The dark theme
    // tokens are scoped to `.sl-theme-dark`, so that class is present
    // unless the page is forced light.
    function setTheme(theme) {
        for (const name of ["light", "dark"]) {
            theme_link(name).media = theme === "auto"
                ? "(prefers-color-scheme: " + name + ")"
                : (name === theme ? "all" : "not all");
        }
        root.classList.toggle("sl-theme-dark", theme !== "light");
        root.dataset.slTheme = theme;
    }

    window.ShoelaceWidgets = { setTheme };

    // `get_shoelace(theme=...)` sets the attribute before this script runs.
    setTheme(root.dataset.slTheme || "auto");

    // A real script tag rather than `import()`: the autoloader finds the
    // base path for each component by looking for a script whose src ends
    // in shoelace-autoloader.js, without one it requests them from the page.
    const autoloader = document.createElement("script");
    autoloader.type = "module";
    autoloader.src = CDN + "/shoelace-autoloader.js";
    document.head.appendChild(autoloader);
})();
