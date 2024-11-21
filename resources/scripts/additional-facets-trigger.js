/* Trigger for additional facets (see also bullinger-theme.css) */
window.addEventListener("DOMContentLoaded", () => {
    const facets = document.querySelector('.facets');
    if (facets) {
        facets.addEventListener('pb-custom-form-loaded', function(ev) {
            // Expand additional facets if a facet filter is active
            const initialState = facets.querySelectorAll(".additional-facets-trigger ~ .facet-dimension select option[selected]").length !== 0
            const trigger = facets.querySelector(".additional-facets-trigger")
            trigger.classList.toggle('additional-facets-trigger-active', initialState)
            trigger.addEventListener('click', (e) => {
                e.currentTarget.classList.toggle('additional-facets-trigger-active')
            })
        });
    }
});
