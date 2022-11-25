<script setup lang="ts">
import { hoverSound, selectSound } from '@/plugins/audioPlugin';
import eventhandler from '@/plugins/eventhandler';
import { useModalStore } from './modal.store';

const { store } = useModalStore();

</script>

<template>
    <transition enter-active-class="animate__animated animate__zoomIn animate__faster"
        leave-active-class="animate__animated animate__zoomOut animate__faster">

        <div v-if="store.opened" class='modal-parent'>
            <i @click="store.opened = false" class="fa-solid fa-xmark modal-exit-icon"></i>

            <i v-if="store.modalData.icon" :class="`${store.modalData.icon} modal-icon`"></i>
            <div class="modal-question">{{ store.modalData.question }}</div>

            <input v-for="a in store.modalData.inputs" class="modal-input-entry" v-model="a.value"
                :placeholder="a.placeholder" type="text">

            <div v-if="store.modalData.buttons.length > 0" class="modal-buttons-child">
                <div @mouseenter="hoverSound()" @click="() => {
                    eventhandler.TriggerServer(a.event, a.args);
                    selectSound();
                    store.opened = false;
                }" v-for="a in store.modalData.buttons" class="modal-button-entry">
                    {{ a.name }}
                </div>
            </div>
        </div>

    </transition>
</template>



<style lang="scss" scoped>
$textstroke: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;

$modal-background: rgb(35, 35, 35);
$modal-button-bg: rgb(25, 25, 25);
$modal-border: 0.25vw;

.modal-parent {
    position: absolute;
    z-index: 99999;
    background-color: $modal-background;
    width: 25vw;
    max-height: 25vw;
    border-radius: $modal-border;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;

    .modal-exit-icon {
        position: absolute;
        color: rgb(150, 150, 150);
        font-size: 0.9vw;
        right: 0;
        top: 0;
        padding: 0.25vw 0.45vw;
        transition: ease();
        transition-duration: 0.1s;
        font-weight: bold;

        &:hover {
            color: red;
        }
    }

    .modal-icon {
        position: relative;
        width: 100%;
        display: flex;
        justify-content: center;
        align-items: center;
        margin-top: 1vw;
        font-size: 4vw;
        color: lightgreen;
    }

    .modal-question {
        position: relative;
        width: 100%;
        font-size: 0.9vw;
        color: white;
        margin: 1.3vw 0;
        text-align: center;
        white-space: pre-line;
    }

    .modal-input-entry {
        position: relative;
        width: 75%;
        background-color: $modal-button-bg;
        outline: 0;
        border: 0;
        color: rgb(210, 210, 210);
        font-size: 0.85vw;
        padding: 0.4vw 0;
        margin-bottom: 0.5vw;
        text-align: center;
    }

    .modal-buttons-child {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
        width: 100%;

        .modal-button-entry {
            position: relative;
            width: 100%;
            background-color: $modal-button-bg;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 0.9vw;
            padding: 0.75vw 0;
            transition: ease();
            transition-duration: 0.1s;
            color: rgb(220, 220, 220);

            &:first-child {
                border-bottom-left-radius: $modal-border;
            }

            &:last-child {
                border-bottom-right-radius: $modal-border;
            }

            &:hover {
                background-color: lightgreen;
                color: black;
                font-weight: bold;
            }
        }
    }
}
</style>