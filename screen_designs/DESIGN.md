---
name: Fleet Utility
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#42474f'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#727780'
  outline-variant: '#c2c7d1'
  surface-tint: '#2d6197'
  primary: '#00355f'
  on-primary: '#ffffff'
  primary-container: '#0f4c81'
  on-primary-container: '#8ebdf9'
  inverse-primary: '#a0c9ff'
  secondary: '#565f6d'
  on-secondary: '#ffffff'
  secondary-container: '#dae3f4'
  on-secondary-container: '#5c6573'
  tertiary: '#002f79'
  on-tertiary: '#ffffff'
  tertiary-container: '#0044a7'
  on-tertiary-container: '#9fb9ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4ff'
  primary-fixed-dim: '#a0c9ff'
  on-primary-fixed: '#001c37'
  on-primary-fixed-variant: '#07497d'
  secondary-fixed: '#dae3f4'
  secondary-fixed-dim: '#bec7d7'
  on-secondary-fixed: '#131c28'
  on-secondary-fixed-variant: '#3e4755'
  tertiary-fixed: '#dae2ff'
  tertiary-fixed-dim: '#b1c5ff'
  on-tertiary-fixed: '#001847'
  on-tertiary-fixed-variant: '#0040a0'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  title-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is engineered specifically for bus fleet supervisors, maintenance managers, and depot engineers operating in high-tempo, industrial environments. The tone is deliberate, disciplined, and utilitarian: clean data presentation takes priority over decorative flair. 

Visual principles:
- **Data-First Density:** Information hierarchy is calibrated for rapid triage—inspection logs, tyre pressures, spare part inventory, and service downtime counters must be legible at an arm's reach under harsh garage lighting.
- **Precision Engineering Aesthetic:** Grounded in a modern industrial tool ethos, relying on structural 1px divider lines, crisp alignment, clear state delineation, and unadorned surfaces rather than skeuomorphic gloss or heavy drop shadows.
- **Enterprise Calm:** The interface avoids noisy, high-saturation fills. High-priority statuses (breakdowns, warnings, schedule clears) stand out through deliberate functional color accents against a neutral slate foundation.

## Colors

The palette establishes an authoritative, calm operational surface with strict semantic status mappings:

- **Primary (`#0F4C81`) & On-Primary (`#FFFFFF`):** Deep oceanic corporate blue used for major interactive elements, active navigation items, primary actions, and key table headers.
- **Surface Roles:**
  - `background`: `#F6F7F9` (app-wide structural canvas).
  - `surface`: `#FFFFFF` (card containers, sheet modals, and input fields).
  - `surfaceMuted`: `#EEF0F3` (inactive tabs, table headers, and structural tracks).
- **Text Hierarchy:**
  - `textPrimary`: `#111827` (high-contrast neutral for numerical readings, vehicle numbers, and primary labels).
  - `textSecondary`: `#5B6472` (metadata, helper text, timestamps, and secondary captions).
- **Structural Lines:**
  - `border`: `#E2E5EA` (used uniformly across card outlines, segment partitions, and input borders).
- **Operational Semantics:**
  - `success`: `#157347` (service completed, operational vehicle, passed inspection).
  - `warning`: `#B26A00` (service due, low consumable level, pending audit).
  - `danger`: `#B42318` (breakdown, failed safety check, critical defect).
  - `info`: `#175CD3` (in-transit updates, planned schedules, standard notices).

Every badge and banner must employ a 10% opacity tint of the respective semantic color for its background with the solid semantic tone for text and border.

## Typography

Typography prioritizes fast numerical legibility and scanning speed:

- **Hanken Grotesk** serves as the primary system typeface across all headlines, body copy, and UI controls. Its geometric clarity and sturdy terminals maintain legibility at compact body sizes.
- **JetBrains Mono** is strictly reserved for quantitative and tracking data: vehicle license plates, chassis/VIN identifiers, part numbers, odometer/hour-meter readings, and Indian Rupee (`₹`) currency formats.
- **INR Currency Rules:** All currency amounts must render using `JetBrains Mono` and conform to the Indian numbering system formatting (e.g., `₹12,48,500.00` or `₹4,250`), with a non-breaking space following the currency sign.
- **Tabular Figures:** For tabular data lists and telemetry readouts, numeric glyphs must utilize tabular alignment (`font-variant-numeric: tabular-nums`) to prevent shifting layouts across live metric updates.

## Layout & Spacing

A strict **4pt base grid** governs all spatial relationships across this mobile-first enterprise system:

- **Canvas Metrics:** Default mobile viewport margin is set to `16px` (`margin: 1rem`) with an internal column gutter of `12px` (`gutter: 0.75rem`).
- **Dense Stacking Rhythm:**
  - Component-internal padding adheres to increments of 4px: `4px` (`space-xs`), `8px` (`space-sm`), `12px` (`space-md`), `16px` (`space-lg`), and `24px` (`space-xl`).
  - Form field stacks and list rows standardly utilize `8px` or `12px` vertical gaps to maximize single-screen information density.
- **Breakpoints & Adaptability:**
  - `Compact (Mobile: < 600px)`: Single column fluid view, fixed bottom app bar / action bar, card layouts span full width between margins.
  - `Medium (Tablet / Depot Terminal: 600px - 1024px)`: 2-column grid for split inspection sheets and vehicle status summaries; outer margin expands to `24px`.

## Elevation & Depth

This design system explicitly departs from stacked ambient drop shadows. Depth and hierarchy are achieved entirely through **low-contrast outlines** and **tonal layering**:

- **Zero Shadows:** Elevation `0px` is the standard across all base cards, modals, and list rows. No fuzzy blurs or multi-stop drop shadows are permitted.
- **1px Structural Borders:** Containers, inputs, and modular sections are delineated by a crisp `1px solid #E2E5EA` border.
- **Tonal Stepping:**
  - Base level: `#F6F7F9` (canvas).
  - Raised component: `#FFFFFF` (resting cards, dialogs, bottom sheets).
  - Recessed/Muted segment: `#EEF0F3` (column headings, input resting states, filter tracks).
- **Floating Modals & Sheets:** When a sheet or menu overlays the interface, use a solid `1px solid #E2E5EA` enclosure coupled with a backdrop scrim of `#111827` at 30% opacity, maintaining sharp perimeter borders instead of drop-shadow halos.

## Shapes

The shape hierarchy balances compact utility with tactile touch targets:

- **Cards & Primary Modules:** Strict `12px` corner radius.
- **Inputs, Buttons, & Interactive Selectors:** Strict `10px` corner radius.
- **Pills & Status Badges:** Fully rounded (`9999px`) or `6px` radius depending on density context (use `6px` for inline data grid tags; pills for primary status banners).
- **Dividers & Outlines:** 1px width, continuous, non-dashed, using `#E2E5EA`.

## Components

### Buttons
- **Primary:** Background `#0F4C81`, text `#FFFFFF`, height `44px`, border-radius `10px`, typography `Hanken Grotesk 14px semi-bold`. Active state deepens to `#0B3860`.
- **Secondary / Outlined:** Background `#FFFFFF`, text `#0F4C81`, border `1px solid #0F4C81`, height `44px`, border-radius `10px`.
- **Destructive:** Background `#B42318`, text `#FFFFFF`, height `44px`, border-radius `10px`.

### Input Fields
- Height `40px` (dense) to `44px` (standard), border-radius `10px`, background `#FFFFFF`, border `1px solid #E2E5EA`.
- Focused state: border `1.5px solid #0F4C81`, no outline ring or outer blur glow.
- Embedded mono labels for numeric metrics (e.g., Odometer, Litres, INR).

### Cards & Fleet Work Orders
- Background `#FFFFFF`, border-radius `12px`, border `1px solid #E2E5EA`, padding `12px` to `16px`.
- Header section contains Bus Registration Number in `JetBrains Mono 14px` alongside a right-aligned semantic status chip.
- Content body separates key metric pairs (e.g., Driver, Route, Depot, Bay) via clean `8px` grid rows.

### Chips & Badges
- Height `22px` to `26px`, border-radius `6px`, padding `2px 8px`.
- Semantic application:
  - **Operational:** Background `#E8F5E9`, text `#157347`, border `1px solid #A3D9A5`.
  - **Service Due:** Background `#FFF4E5`, text `#B26A00`, border `1px solid #FFD599`.
  - **Critical Breakdown:** Background `#FEECEB`, text `#B42318`, border `1px solid #FECDCA`.

### Lists & Inspection Rows
- Background `#FFFFFF`, divided by `1px solid #E2E5EA` lines without full outer borders when nested in cards.
- Min touch target `48px`, content inset `12px`.
- Checkboxes: `18px x 18px`, border `1.5px solid #5B6472`, checked fill `#0F4C81` with white checkmark, radius `4px`.

### Metric Counter Banners
- Dedicated depot stats tile: `#EEF0F3` muted container, radius `10px`, padding `10px 12px`.
- Displays total counts (e.g., Active Buses, Scheduled PMs) with values set in `JetBrains Mono` and descriptors in `Hanken Grotesk`.
