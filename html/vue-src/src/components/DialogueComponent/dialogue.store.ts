import { declineSound, selectSound } from '@/plugins/audioPlugin';
import eventhandler from '@/plugins/eventhandler';
import { defineStore } from 'pinia';
import { ref, watch } from 'vue';

export interface IPlayerSay {
    Text: string;
    Event?: string;
    EventArgs?: string;
    CancelOnExecute?: boolean;
    Next?: IDialogue;
}

export interface IDialogue {
    PedSays: string;
    PlayerSays: IPlayerSay[];
}

interface DataState {
    opened: boolean;
    dialoguesData: {
        Header: string;
        Entries: IDialogue | null;
    };
}

export const useDialogueStore = defineStore("DialogueStore", () => {
    const store = ref<DataState>({
        opened: false,
        dialoguesData: {
            Header: "",
            Entries: null
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
            eventhandler.TriggerClient("DialogueClosed", null);
        }

        eventhandler.FocusNui(newState);
    });

    function PlayerSelectAnswer(answer: IPlayerSay) {
        if(answer.Event) {
            eventhandler.TriggerServer(answer.Event, answer.EventArgs);
        }

        if(answer.Next) {
            store.value.dialoguesData.Entries = answer.Next;
        }

        if(answer.CancelOnExecute) {
            store.value.opened = false;
        }

        selectSound();
    }

    return { store, PlayerSelectAnswer }
});

eventhandler.on("StartDialogue", ({ dialoguesData }) => {
    const { store } = useDialogueStore();
    store.dialoguesData = dialoguesData;
    store.opened = true;
});