window.addEventListener('DOMContentLoaded', function() {
    const toggle = document.querySelector('[name=lang-toggle]')

    function applyLangColors () {
        const view = document.getElementById('view1')
        const usage = view.shadowRoot.querySelector('.lang-usage')
        // hide toggle if there is nothing to display
        if (!usage) {
            toggle.parentElement.style.display = 'none';
            return;
        }
        toggle.parentElement.style.display = 'inline-block';
        if (toggle.checked) {
            usage.style.display = 'block';
            view.style.setProperty("--lang-de-color", 'var(--bb-lang-de-color)');
            view.style.setProperty("--lang-el-color", 'var(--bb-lang-el-color)');
            view.style.setProperty("--lang-la-color", 'var(--bb-lang-la-color)');
            view.style.setProperty("--lang-he-color", 'var(--bb-lang-he-color)');
            view.style.setProperty("--lang-fr-color", 'var(--bb-lang-fr-color)');
            view.style.setProperty("--lang-it-color", 'var(--bb-lang-it-color)');
            view.style.setProperty("--lang-en-color", 'var(--bb-lang-en-color)');
        } else {
            usage.style.display = 'none';
            view.style.setProperty("--lang-la-color", 'transparent');
            view.style.setProperty("--lang-el-color", 'transparent');
            view.style.setProperty("--lang-de-color", 'transparent');
            view.style.setProperty("--lang-he-color", 'transparent');
            view.style.setProperty("--lang-fr-color", 'transparent');
            view.style.setProperty("--lang-it-color", 'transparent');
            view.style.setProperty("--lang-en-color", 'transparent');
        }
    }

    toggle.addEventListener('change', applyLangColors)

    pbEvents.subscribe('pb-update', 'transcription', ev => {
        applyLangColors()
    });

    pbEvents.subscribe('pb-update', 'facsimile', ev => {
        document.getElementById("facsimile-status").style.display ="none";
    });

    pbEvents.subscribe('pb-update', 'metadata', ev => {
        const shadowroot = ev.detail.root;
        const metaView = ev.target;
        if(!metaView) return;
        const expander = metaView.shadowRoot.querySelector('.overlength .expander');
        if(!expander) return;
        expander.addEventListener('click', ev =>  {
            const regest = shadowroot.querySelector('.regesttext');
            const icon = ev.target.nodeName === 'IRON-ICON' ? ev.target : ev.target.firstElementChild;
            if(regest.classList.contains('overlength')){
                regest.classList.remove('overlength');
                icon.setAttribute('icon','arrow-drop-up');
                expander.style.display="block";
            }else{
                regest.classList.add('overlength');
                icon.setAttribute('icon','arrow-drop-down');
                regest.scrollIntoView({behavior: "smooth", block: "end", inline: "nearest"});
            }
        });

        // Link regest divisions to letter text
         const links = shadowroot.querySelectorAll('a.link-regest');
         links.forEach(element => {
            element.addEventListener('click', ev => {
                ev.preventDefault();

                const textView = document.getElementById("view1");
                const allTargets = textView.shadowRoot.querySelectorAll('div.link-regest')
                allTargets.forEach(e => e.classList.remove("active"));
                const id = element.getAttribute("href").replace("#", "");
                const targetElement = textView.shadowRoot.getElementById(id);
                if(targetElement) {
                    targetElement.scrollIntoView({ behavior: "smooth" });
                    targetElement.classList.add("active");
                }
            })
         });
    });

});

