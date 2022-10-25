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

    FocusNui(state: boolean) {
        this.TriggerClient("focusNUI", state);
    }
}
