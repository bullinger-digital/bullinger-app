window.addEventListener('DOMContentLoaded', function() {
    // Statistics slider on home
    pbEvents.subscribe('pb-end-update', null, ev => {
        const component = document.getElementById("pb-page-home");
        const slider = component.querySelector('.home-slider');
        const slidesContainer = component.querySelector('.home-slides');

        if(!slider || !slidesContainer) {
            console.error('home.js: Slider or slides container not found');
            return;
        }

        const totalSlides = slidesContainer.children.length;
        let currentIndex = 0;
        
        function goToSlide(index) {
            slidesContainer.style.transform = `translateX(${-index * 100}%)`;
        }

        function nextSlide() {
            currentIndex = (currentIndex + 1) % totalSlides;
            goToSlide(currentIndex);
        }

        goToSlide(0);
        setInterval(nextSlide, 4400);
    })

});