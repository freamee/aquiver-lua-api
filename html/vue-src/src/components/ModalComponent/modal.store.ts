import { declineSound, selectSound } from '@/plugins/audioPlugin';
import eventhandler from '@/plugins/eventhandler';
import { defineStore } from 'pinia';
import { ref, watch } from 'vue';

interface ModalDataInterface {
    question: string;
    icon?: string;
    buttons: { name: string; event: string; args: any }[];
    inputs: { id: string; placeholder: string; value?: string }[];
}

interface DataState {
    opened: boolean;
    modalData: ModalDataInterface;
}

export const useModalStore = defineStore("ModalStore", () => {
    const store = ref<DataState>({
        opened: false,
        modalData: {
            question: "Test question.",
            icon: "fa-solid fa-question-circle",
            buttons: [
                { name: "Sell", args: null, event: "" },
                { name: "Sell", args: null, event: "" },
            ],
            inputs: [
                { id: "test", placeholder: "Source ID" },
                { id: "test", placeholder: "Amount" },
            ]
        }
    });

    function keyupHandler(e: KeyboardEvent) {
        if (e.key != "Escape") return;

        if (store.value.opened) {
            store.value.opened = false;
        }
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


    return { store }
});

eventhandler.on("ModalMenu-Open", ({ modalData }) => {
    const { store } = useModalStore();
    store.modalData = modalData;
    store.opened = true;
});