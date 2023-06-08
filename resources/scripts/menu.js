window.addEventListener('DOMContentLoaded', () => {

    /*
    resets combobox menues in header to close when the user clicks outside the dropdown.
     */
    document.body.addEventListener('click', (e) => {
        if (e.target.nodeName !== 'INPUT') {
            const menues = document.querySelectorAll('.dropdown-menu input');
            Array.from(menues).forEach(cx => {
                cx.checked = false;
            });
        }

        const target = e.target;
        if (!target.closest('.mobile-menu')) {
            document.querySelector('.mobile-menu').removeAttribute('open');
        }
    });

});