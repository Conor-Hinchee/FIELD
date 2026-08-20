// FIELD color system: monochrome grayscale on true black.
// A single accent color is reserved for alert / abnormal states only.
module Palette {
    const BG        = 0x121212; // near-black with a faint gray lift
    const PRIMARY   = 0xF0F0F0; // time-support numbers, current temp, steps
    const SECONDARY = 0xB0B0B0; // heart rate, date, battery
    const TERTIARY  = 0x666666; // labels, hi/lo, sunrise/sunset, fine ticks
    const ACCENT    = 0xFF3B30; // reserved: low battery / HR alert / goal met
    const HOUR      = 0xC0C0C0; // silver hour-baton face
    const HOUR_EDGE = 0x4A4A4A; // dark beveled rim on hour batons
    const HOUR_HI   = 0xFFFFFF; // bright shiny white core down the baton
}
