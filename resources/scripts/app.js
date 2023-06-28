window.addEventListener('DOMContentLoaded', function() {
    const toggle = document.querySelector('[name=lang-toggle]')

    function applyLangColors () {
        const view = document.getElementById('view1')
        if (toggle.checked) {
            // console.log('lang-toggle', 'checked')
            view.style.setProperty("--lang-de-color", 'var(--bb-lang-de-color)');
            view.style.setProperty("--lang-el-color", 'var(--bb-lang-el-color)');
            view.style.setProperty("--lang-la-color", 'var(--bb-lang-la-color)');
        } else {
            // console.log('lang-toggle', 'unchecked')
            view.style.setProperty("--lang-la-color", 'transparent');
            view.style.setProperty("--lang-el-color", 'transparent');
            view.style.setProperty("--lang-de-color", 'transparent');
        }
    }

    toggle.addEventListener('change', applyLangColors)

    pbEvents.subscribe('pb-update', 'transcription', ev => {
        const shadowroot = ev.detail.root;
        // set initial value
        applyLangColors()

        if(!(ev.target.id === "facsimile-links")) return;
        const pblinks = document.getElementById("facsimile-links")
        const empty = pblinks.shadowRoot.querySelector('.content');
        if(empty.textContent=== "") {
            const viewer = document.querySelector('pb-facsimile').style.display = "none";
            document.getElementById("facsimile-status").style.display ="block";
        }
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
    });

});

