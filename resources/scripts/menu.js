window.addEventListener('DOMContentLoaded', () => {
    /*
    resets mobile menu when user clicks outside of it
     */
    document.body.addEventListener('click', (e) => {
        const target = e.target;
        if (!target.closest('.mobile-menu')) {
            document.querySelector('.mobile-menu').removeAttribute('open');
        }
    });

});