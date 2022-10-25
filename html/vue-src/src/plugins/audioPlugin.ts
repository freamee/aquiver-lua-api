export function playAudio(path: string, volume: number = 0.025) {
    const d = new Audio(path);
    d.volume = volume;
    d.play();
}

export function hoverSound(volume: number = 0.1) {
    // playAudio(require("@/assets/sfx/hover.mp3"), volume);
    playAudio(require("@/assets/sfx/gtahover.wav"), volume);
}

export function selectSound(volume: number = 0.1) {
    // playAudio(require("@/assets/sfx/select.mp3"), volume);
    playAudio(require("@/assets/sfx/gtaselect.mp3"), volume);
}

export function declineSound(volume: number = 0.1) {
    playAudio(require("@/assets/sfx/gtadecline.wav"), volume);
}