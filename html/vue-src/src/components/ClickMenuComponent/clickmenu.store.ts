import { declineSound, selectSound } from '@/plugins/audioPlugin';
import eventhandler from '@/plugins/eventhandler';
import { defineStore } from 'pinia';
import { ref, watch } from 'vue';

type IMenu = {
    name: string;
    icon: string;
    eventName?: string;
    eventArgs: any;
}

interface DataState {
    opened: boolean;
    menuHeader: string;
    menuData: Array<IMenu>;
}

export const useClickMenuStore = defineStore("ClickMenuStore", () => {
    const store = ref<DataState>({
        opened: false,
        menuHeader: "",
        menuData: []
    });

    function keyupHandler(e: KeyboardEvent) {
        if (e.key != "Escape") return;

        if (store.value.opened) {
            store.value.opened = false;
        }
    }

    function executeClick({ eventArgs, eventName }: IMenu) {
        if (eventName) {
            eventhandler.TriggerServer(eventName, eventArgs);
        }
        store.value.opened = false;
    }

    watch(() => store.value.opened, (newState) => {
        if (newState) {
            window.addEventListener("keyup", keyupHandler);
            selectSound();
        }
        else {
            window.removeEventListener("keyup", keyupHandler);
            declineSound();
        }

        eventhandler.FocusNui(newState);
    });

    return { store, executeClick }
});

eventhandler.on("ClickMenu-Open", ({ menuData, menuHeader }) => {
    const { store } = useClickMenuStore();
    store.menuData = menuData;
    store.menuHeader = menuHeader;
    store.opened = true;

    // nextTick(() => {
    //     const a = document.getElementById("clickmenuID");
    //     if (a) {
    //         a.style.top = d.cursorY + 30 + "px";
    //         a.style.left = d.cursorX + "px";
    //     }
    // });
});

eventhandler.on("ClickMenu-Close", () => {
    const { store } = useClickMenuStore();
    store.opened = false;
});