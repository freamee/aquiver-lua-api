const RegisteredEvents: Record<string, (...args: any) => void> = {}

export default {

    TriggerClient(eventName: string, eventArgs: any) {
        // @ts-ignore
        if (typeof GetParentResourceName === 'function') {
            // @ts-ignore
            fetch(`https://${GetParentResourceName()}/trigger_client`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({ event: eventName, args: eventArgs }),
            });
        }
    },

    TriggerServer(eventName: string, eventArgs: any){
        // @ts-ignore
        if (typeof GetParentResourceName === 'function') {
            // @ts-ignore
            fetch(`https://${GetParentResourceName()}/trigger_server`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({ event: eventName, args: eventArgs }),
            });
        }
    },

    FocusNui(state: boolean) {
        this.TriggerClient("focusNUI", state);
    },

    on(eventName:string, cb: (...args:any) => void) {
        if(typeof RegisteredEvents[eventName] === "function") return;

        RegisteredEvents[eventName] = cb;
    }
}

window.addEventListener("message", (e) => {
    const d = e.data;

    if(typeof RegisteredEvents[d.event] === "function") {
        RegisteredEvents[d.event](d);
    }
});
