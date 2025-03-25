<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute } from 'vitepress'
import VPNavBarMenuGroup from 'vitepress/dist/client/theme-default/components/VPNavBarMenuGroup.vue'
import VPNavScreenMenuGroup from 'vitepress/dist/client/theme-default/components/VPNavScreenMenuGroup.vue'

const props = defineProps<{
  screenMenu?: boolean
}>()

const route = useRoute()

const versions = ref([]);
const currentVersion = ref('Versions');

const waitForGlobalDocumenterVars = () => {
    return new Promise((resolve) => {
    const checkInterval = setInterval(() => {
        if (window.DOC_VERSIONS && window.DOCUMENTER_CURRENT_VERSION) {
        clearInterval(checkInterval);
        resolve({
            versions: window.DOC_VERSIONS,
            currentVersion: window.DOCUMENTER_CURRENT_VERSION
        });
        }
    }, 100); // Check every 100ms
    });
};

onMounted(async () => {
    const globalvars = await waitForGlobalDocumenterVars();
    versions.value = globalvars.versions.map((v) => {
        return {text: v, link: `${window.location.origin}/${v}/`}
    });
    currentVersion.value = globalvars.currentVersion;
});

</script>

<template>
  <VPNavBarMenuGroup
    v-if="!screenMenu"
    :item="{ text: currentVersion, items: versions }"
    class="VPVersionPicker"
  />
  <VPNavScreenMenuGroup
    v-else
    :text="currentVersion"
    :items="versions"
    class="VPVersionPicker"
  />
</template>

<style scoped>
.VPVersionPicker :deep(button .text) {
  color: var(--vp-c-text-1) !important;
}

.VPVersionPicker:hover :deep(button .text) {
  color: var(--vp-c-text-2) !important;
}
</style>