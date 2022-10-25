import './global.scss';
import 'animate.css';
import 'vue-slider-component/theme/default.css';
import 'vue3-circle-progress/dist/circle-progress.css';

import { createApp } from 'vue';
import VueSlider from 'vue-slider-component';
import CircleProgress from 'vue3-circle-progress';

import App from './views/App.vue';
import piniaApp from './plugins/piniaPlugin';

createApp(App)
    .use(piniaApp)
    .component('VueSlider', VueSlider)
    .component("CircleProgress", CircleProgress)
    .mount('#app');