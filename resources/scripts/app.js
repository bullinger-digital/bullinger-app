window.addEventListener('DOMContentLoaded', function() {
    
    pbEvents.subscribe('pb-update', 'transcription', ev => {
        const shadowroot = ev.detail.root;
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

