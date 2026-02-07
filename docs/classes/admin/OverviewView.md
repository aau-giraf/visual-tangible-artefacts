# Overview View Documentation

**File:** `Frontend/admin-dashboard/src/views/OverviewView.vue`

## Overview
The dashboard landing page providing a high-level summary of the system status and key metrics.

## Features
- **Header:** Welcomes the user and shows system status ("Systemet kører normalt").
- **KPI Grid:** Displays 4 key performance indicator cards:
    - Active Students (currently hardcoded/placeholder data).
    - Statistic 2 (Placeholder "Tekst").
    - Statistic 3 (Placeholder "Tekst").
    - New Notifications (Placeholder "8").
- **Activity Chart:** A placeholder area for an activity graph (ApexCharts).

## Tech Stack
- Typescript (setup script).
- Tailwind CSS for styling.
- Lucide Icons (dynamically loaded via `<component :is="...">`).
