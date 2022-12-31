<script setup lang="ts">
import { hoverSound } from '@/plugins/audioPlugin';
import { useDialogueStore } from './dialogue.store';


const { store, PlayerSelectAnswer } = useDialogueStore();

</script>

<template>
    <transition enter-active-class="animate__animated animate__fadeIn animate__faster"
        leave-active-class="animate__animated animate__fadeOut animate__faster">

        <div v-if="store.opened && store.dialoguesData.Entries" class="dialog-parent">
            <div class="dialogue-header">
                <div>Dialogue</div>
                <div>{{ store.dialoguesData.Header }}</div>
            </div>

            <div class="dialogue-main">
                <div class="ped-talk">
                    <div>
                        {{ store.dialoguesData.Entries.PedSays }}
                    </div>
                </div>
                <div class="talk-br"></div>

                <div style="display:flex; justify-content:center; align-items: center; flex-wrap: wrap;">
                    <div @mouseenter="hoverSound()" v-for="answer in store.dialoguesData.Entries.PlayerSays"
                        @click="PlayerSelectAnswer(answer)" class="answer-entry">
                        {{ answer.Text }}
                    </div>
                </div>
            </div>
        </div>
    </transition>
</template>



<style lang="scss" scoped>
$greywhite: rgb(220, 220, 220);
$textstroke: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;

.dialog-parent {
    position: absolute;
    width: 100%;
    height: 100%;
    text-shadow: $textstroke;
    display: flex;
    justify-content: center;
    align-items: center;

    .dialogue-header {
        position: absolute;
        top: 3%;
        left: 3%;
        font-size: 3vw;
        font-variant: small-caps;
        transform: skewY(-1deg);
        border-left: .1vw solid white;
        padding: .45vw .65vw;

        div {
            &:nth-child(1) {
                color: white;
                font-size: 1.8vw;
                line-height: 2vw;
            }

            &:nth-child(2) {
                color: lightgreen;
                font-weight: bold;
                line-height: 2vw;
            }
        }
    }

    .dialogue-main {
        position: absolute;
        bottom: 25%;
        right: 15%;
        width: 30%;
        transform: skewY(-1deg);

        .ped-talk {
            border-left: .2vw solid rgb(200, 200, 200);
            padding: .45vw .65vw;
            background: linear-gradient(90deg, rgba(25, 25, 25, .45) 0%, transparent 100%);
            color: orange;
            line-height: 2vw;
            font-size: .9vw;
            font-weight: bold;
            white-space: pre-line;
        }

        // .ped-talk {
        //     position: relative;
        //     font-size: .9vw;
        //     color: white;
        //     background: rgba(44, 44, 44, 0.6);
        //     border-radius: .25vw;
        //     padding: .35vw .65vw;
        //     text-align: center;
        //     font-weight: bold;
        // }

        .talk-br {
            position: relative;
            background: linear-gradient(90deg, transparent 0%, rgb(225, 225, 225) 50%, transparent 100%);
            width: 100%;
            height: .25vw;
            margin: .5vw 0;
        }

        .answer-entry {
            position: relative;
            margin: .25vw;
            width: 45%;
            background: rgba(37, 37, 37, 0.35);
            display: flex;
            justify-content: center;
            align-items: center;
            color: rgb(225, 225, 225);
            font-size: .9vw;
            border: .1vw solid rgb(200, 200, 200);
            border-radius: .15vw;
            padding: .5vw 0;
            transition: ease;
            transition-duration: .15s;

            &:hover {
                color: white;
                border: .1vw solid rgb(255, 255, 255);
                animation: pulse 1s ease infinite;
            }
        }
    }
}
</style>