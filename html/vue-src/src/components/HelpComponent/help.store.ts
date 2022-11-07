import eventhandler from '@/plugins/eventhandler';
import { defineStore } from 'pinia';
import { ref } from 'vue';

type IHelp = {
    uid: string;
    msg: string;
    key?: string;
    image?: string;
    icon?: string;
}

interface DataState {
    helps: Array<IHelp>;
}

export const useHelpStore = defineStore("HelpStore", () => {
    const store = ref<DataState>({
        helps: [
            // { msg: "Put away bucket", uid: "putaway", key: "X" },
            // { msg: "You are near water!", uid: "near-water", image: "enter.png" }
        ]
    });

    function addHelp({ uid, key, msg, image, icon }: IHelp) {
        if (store.value.helps.findIndex(a => a.uid == uid) >= 0) return;

        store.value.helps.push({
            uid,
            key,
            msg,
            image,
            icon
        });
    }

    function removeHelp(uid: string) {
        const idx = store.value.helps.findIndex(a => a.uid == uid);
        if (idx >= 0) {
            store.value.helps.splice(idx, 1);
        }
    }

    function updateHelp({ uid, key, msg, image, icon }: IHelp) {
        const idx = store.value.helps.findIndex(a => a.uid == uid);
        if (idx >= 0) {
            store.value.helps[idx].msg = msg;
            store.value.helps[idx].key = key;
            store.value.helps[idx].image = image;
            store.value.helps[idx].icon = icon;
        }
    }

    return { store, addHelp, removeHelp, updateHelp }
});

eventhandler.on("Help-Remove", ({ uid }) => {
    const { removeHelp } = useHelpStore();
    removeHelp(uid);
});

eventhandler.on("Help-Add", ({ key, message, uid, image, icon }) => {
    const { addHelp } = useHelpStore();
    addHelp({
        key: key,
        msg: message,
        uid: uid,
        image: image,
        icon: icon
    });
});

eventhandler.on("Help-Update", ({ key, message, uid, image, icon }) => {
    const { updateHelp } = useHelpStore();
    updateHelp({
        key: key,
        msg: message,
        uid: uid,
        image: image,
        icon: icon
    })
});