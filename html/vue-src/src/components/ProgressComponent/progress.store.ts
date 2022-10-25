import { defineStore } from 'pinia';
import { ref } from 'vue';

interface DataState {
    opened: boolean;
    startingTime: number | null;
    time: number | null;
    text: string;
    interval: number | null;
    percent: number;
}

export const useProgressStore = defineStore("playerProgress", () => {
    const store = ref<DataState>({
        opened: false,

        startingTime: null,
        time: null,
        text: "",
        interval: null,
        percent: 0
    });

    function StartProgress(text: string, time: number) {
        if (store.value.interval) {
            clearInterval(store.value.interval);
            store.value.interval = null;
        }

        store.value.time = time;
        store.value.startingTime = time;
        store.value.text = text;
        store.value.opened = true;

        store.value.interval = setInterval(() => {
            if (store.value.time != null && store.value.startingTime != null) {
                store.value.time -= 500;

                store.value.percent = ((store.value.time / store.value.startingTime) * 100) - 100;

                if (store.value.time < 1) {
                    store.value.opened = false;

                    if (store.value.interval) {
                        clearInterval(store.value.interval);
                        store.value.interval = null;
                    }
                }
            }
        }, 500);
    }

    return { store, StartProgress }
});


window.addEventListener("message", (e) => {
    const d = e.data;

    if (d.event == "Progress-Start") {
        const { StartProgress } = useProgressStore();

        StartProgress(d.text, d.time);
    }
});