<template>
    <div id="app" class="kozeprehuz">
        <NotificationComponent />
        <ProgressComponent />
        <ClickMenuComponent />
    </div>
</template>
  
<script lang="ts">

import { defineComponent } from "vue"
import ProgressComponent from "@/components/ProgressComponent/index.vue";
import NotificationComponent from "@/components/NotificationComponent/index.vue";
import ClickMenuComponent from "@/components/ClickMenuComponent/index.vue";

export default defineComponent({
    components: {
        ProgressComponent,
        NotificationComponent,
        ClickMenuComponent
    }

});

</script>