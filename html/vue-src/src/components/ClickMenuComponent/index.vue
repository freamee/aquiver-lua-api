<script setup lang="ts">
import { hoverSound, selectSound } from '@/plugins/audioPlugin';
import { useClickMenuStore } from './clickmenu.store';

const { store, executeClick } = useClickMenuStore();

</script>

<template>
    <transition enter-active-class="animate__animated animate__zoomIn animate__faster"
        leave-active-class="animate__animated animate__zoomOut animate__faster">
        <div v-if="store.opened" id="clickmenuID" class="click-menu-parent">
            <transition-group enter-active-class="animate__animated animate__fadeIn animate__faster"
                leave-active-class="animate__animated animate__fadeOut animate__faster">

                <div :key="store.menuHeader" class="click-menu-header">
                    {{ store.menuHeader }}
                </div>
                <div @mouseenter="hoverSound()" class="click-menu-entry" :key="a.name"
                    v-for="(a,index) in store.menuData" @click="executeClick(a), selectSound()">
                    <i :class=a.icon></i> {{ a.name }}
                </div>
            </transition-group>
        </div>
    </transition>
</template>



<style lang="scss" scoped>
$textstroke: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;

$background-gradient: linear-gradient(90deg, rgba(20, 20, 20, 0.55) 0%, transparent 100%);
$background-gradient-hover: linear-gradient(90deg, rgba(230, 150, 3, 0.25) 0%, transparent 100%);

.click-menu-parent {
    position: absolute;
    left: 55%;
    z-index: 99999;
    border-radius: .25vw;
    transform: skewY(-2deg);
    text-shadow: $textstroke;

    .click-menu-header {
        position: relative;
        font-size: 1.2vw;
        color: rgb(220, 220, 220);
        font-variant: small-caps;
        width: 100%;
        text-align: center;
        animation: rollIn .5s ease;
    }

    .click-menu-entry {
        position: relative;
        color: rgb(200, 200, 200);
        font-size: .8vw;
        padding: .45vw 1vw;
        padding-left: .4vw;
        background: $background-gradient;
        transition: ease();
        transition-duration: .1s;
        border-left: .15vw solid transparent;
        margin: .25vw 0;
        animation: rollIn .35s ease;

        &:hover {
            border-left: .15vw solid orange;
            background: $background-gradient-hover;
        }

        i {
            margin-right: .35vw;
        }
    }
}
</style>