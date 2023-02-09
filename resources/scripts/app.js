window.addEventListener('load', () => {
    const viewer = document.querySelector('pb-facsimile');
    const status = document.getElementById('status');
    window.pbEvents.subscribe('pb-facsimile-status', null, (ev) => {
        if (ev.detail.status === 'fail') {
            viewer.style.visibility = 'hidden';
        } else {
            viewer.style.visibility = 'visible';
            status.innerHTML = ev.detail.status;
        }
    });
});

window.addEventListener('DOMContentLoaded', function() {
    pbEvents.subscribe('pb-update', 'metadata', ev => {
        const shadowroot = ev.detail.root;
        const metaView = ev.target;
        if(!metaView) return;
        const expander = metaView.shadowRoot.querySelector('.overlength ~ div');
        expander.addEventListener('click', ev =>  {
            const regest = shadowroot.querySelector('#regest');
            const icon = ev.target.nodeName === 'IRON-ICON' ? ev.target : ev.target.firstElementChild;
            if(regest.classList.contains('overlength')){
                regest.classList.remove('overlength');
                icon.setAttribute('icon','arrow-drop-up');
            }else{
                regest.classList.add('overlength');
                icon.setAttribute('icon','arrow-drop-down');
                regest.scrollIntoView({behavior: "smooth", block: "end", inline: "nearest"});
            }
        });
    });

});

