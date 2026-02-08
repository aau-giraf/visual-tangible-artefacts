# Pairings View Documentation

**File:** `Frontend/admin-dashboard/src/views/PairingsView.vue`

## Overview
A management screen for defining relationships between Caregivers and Children.

## Features
- **Create Pairing:**
    - Dropdowns to select a Caregiver and a Child.
    - "Create Pairing" button (disabled until selections are made).
- **List Pairings:**
    - Displays a table of existing pairings.
    - Shows Caregiver name/username, Child name/username, and creation date.
- **Delete Pairing:**
    - Action button to remove an existing relationship.

## Data Integration
- Fetches data on mount:
    - `getCaregivers()`
    - `getChildren()`
    - `getPairings()`
- Calls API methods `createPairing` and `deletePairing` for actions.

## State
- Manages lists (`caregivers`, `children`, `pairings`) and selection state (`selectedCaregiverId`, `selectedChildId`) using Vue `ref`.
