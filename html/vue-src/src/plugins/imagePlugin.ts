import { ComponentOptions } from "vue"

/**
 * 
 * @param URI "@/assets/img/{IMAGE_NAME}"
 */
export function getImage(URI: string) {
    try {
        return { img: require('@/assets/img/' + URI), success: true }
    }
    catch (err) {
        return { img: require("@/assets/notfound.svg"), success: false }
    }
}