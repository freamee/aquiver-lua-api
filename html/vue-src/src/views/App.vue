<template>
    <div id="app" class="kozeprehuz">
        <NotificationComponent />
        <ProgressComponent />
        <ClickMenuComponent />
        <DialogueComponent />
        <HelpComponent />
        <ModalComponent />
    </div>
</template>
  
<script lang="ts">

import { defineComponent } from "vue"
import ProgressComponent from "@/components/ProgressComponent/index.vue";
import NotificationComponent from "@/components/NotificationComponent/index.vue";
import ClickMenuComponent from "@/components/ClickMenuComponent/index.vue";
import DialogueComponent from "@/components/DialogueComponent/index.vue";
import HelpComponent from "@/components/HelpComponent/index.vue";
import ModalComponent from "@/components/ModalComponent/index.vue";

export default defineComponent({
    components: {
        ProgressComponent,
        NotificationComponent,
        ClickMenuComponent,
        DialogueComponent,
        HelpComponent,
        ModalComponent
    }

});

</script>