import { playAudio } from '@/plugins/audioPlugin';
import eventhandler from '@/plugins/eventhandler';
import { defineStore } from 'pinia';
import { ref } from 'vue';

type INotification = {
    message: string;
    icon: string;
    color: string;
    unique: number;
}

interface DataState {
    Notifications: Array<INotification>;
}

export const useNotifications = defineStore("NotificationStore", () => {
    const store = ref<DataState>({
        Notifications: []
    });

    function sendNotification(type: "error" | "success" | "info" | "warning", message: string) {
        let icon: string, color: string;

        switch (type) {
            case "error": {
                icon = "fa-solid fa-times-circle";
                color = "red";
                playAudio(require("@/assets/sfx/e.mp3"));
                break;
            }
            case "info": {
                icon = "fa-solid fa-info-circle";
                color = "lightblue";
                playAudio(require("@/assets/sfx/i.mp3"));
                break;
            }
            case "success": {
                icon = "fa-solid fa-circle-check";
                color = "lightgreen";
                playAudio(require("@/assets/sfx/s.mp3"));
                break;
            }
            case "warning": {
                icon = "fa-solid fa-exclamation-circle";
                color = "yellow";
                playAudio(require("@/assets/sfx/w.mp3"));
                break;
            }
        }

        /** Probably not neccessary, and there are better solutions, but y. */
        const unique = Math.floor(Math.random() * 10000);

        store.value.Notifications.push({
            message,
            icon,
            color,
            unique
        })

        setTimeout(() => {
            const idx = store.value.Notifications.findIndex((a) => a.unique == unique);
            if (store.value.Notifications[idx]) {
                store.value.Notifications.splice(idx, 1);
            }
        }, 5000);
    }

    return { store, sendNotification }
});

eventhandler.on("Send-Notification", ({type, message}) => {
    const { sendNotification } = useNotifications();
    sendNotification(type, message);
});