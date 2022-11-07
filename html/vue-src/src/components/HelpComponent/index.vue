<script setup lang="ts">
import { getImage } from '@/plugins/imagePlugin';
import { useHelpStore } from './help.store';

const { store } = useHelpStore();
</script>

<template>
    <div class="help-notification-parent">
        <transition-group enter-active-class="animate__animated animate__fadeInLeft animate__faster"
            leave-active-class="animate__animated animate__fadeOutLeft animate__faster">

            <div class="help-notification-entry" :key="a.uid" v-for="a in store.helps">
                <div class="indicator">
                    <div v-if="a.key">{{ a.key }}</div>
                    <div class="img" :style="{ 'background-image': `url(${getImage(a.image).img})` }" v-if="a.image"></div>
                    <i v-if="a.icon" :class="a.icon"></i>
                </div>
                <div class="text">{{ a.msg }}</div>
            </div>

        </transition-group>
    </div>
</template>



<style lang="scss" scoped>
$greywhite: rgb(220, 220, 220);
$textstroke: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;

.help-notification-parent {
    position: absolute;
    bottom: 40%;
    left: 2%;
    pointer-events: none;
    text-shadow: $textstroke;

    .help-notification-entry {
        position: relative;
        max-width: 15vw;
        margin: 0.1vw 0;
        font-size: 0.8vw;
        color: white;
        white-space: pre-line;
        display: flex;
        align-items: center;
        padding: .25vw;
        background: linear-gradient(90deg, rgba(0, 0, 0, 0.25) 0%, transparent 100%);
        border-left: .15vw solid rgb(155, 155, 155);

        .indicator {
            position: relative;
            height: 1.5vw;
            width: 1.5vw;
            display: flex;
            justify-content: center;
            align-items: center;
            border: .125vw solid rgb(175, 175, 175);
            border-radius: 100%;
            margin-right: .5vw;
        }

        .text {
            flex: 1;
        }

        .img {
            position: relative;
            width: 75%;
            height: 75%;
            background-position: center;
            background-size: contain;
            background-repeat: no-repeat;
        }
    }
}
</style>