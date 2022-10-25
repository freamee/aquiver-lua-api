<template>
    <div id="app" class="kozeprehuz">
        <NotificationComponent />
        <ProgressComponent />
    </div>
</template>
  
<script lang="ts">

import { defineComponent } from "vue"
import ProgressComponent from "@/components/ProgressComponent/index.vue";
import NotificationComponent from "@/components/NotificationComponent/index.vue";

export default defineComponent({
    components: {
        ProgressComponent,
        NotificationComponent
    }

});

</script>