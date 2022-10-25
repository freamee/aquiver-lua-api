<script setup lang="ts">
import { useProgressStore } from './progress.store';

const { store } = useProgressStore();

</script>

<template>
    <transition @after-leave="store.percent = 0" enter-active-class="animate__animated animate__fadeIn animate__faster"
        leave-active-class="animate__animated animate__fadeOut animate__faster">
        <div v-show="store.opened" class="kozeprehuz">
            <div class="circle-progress-parent">
                <circle-progress :percent="store.percent" />
                <div class="progress-text">{{ store.text }}</div>
            </div>
        </div>
    </transition>
</template>



<style lang="scss" scoped>
$greywhite: rgb(220, 220, 220);
$textstroke: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;

.circle-progress-parent {
    position: absolute;
    bottom: 20%;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 6.5vw;
    width: 6.5vw;
    flex-wrap: wrap;

    .progress-text {
        position: absolute;
        white-space: nowrap;
        overflow: hidden;
        color: $greywhite;
        bottom: -2vw;
        font-size: 1.1vw;
        text-shadow: $textstroke;
    }
}
</style>