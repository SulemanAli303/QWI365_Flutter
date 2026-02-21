# Unified Site Selector Design

## Overview
The site selector component (navigation buttons + dropdown) is now standardized across all screens for a consistent user experience.

## Screens Updated

### 1. **SitesScreen** (Original Reference)
- Location: `lib/screens/sites_screen.dart`
- Implementation: `_buildSiteSelector()` & `_buildRoundButton()`

### 2. **GraphsScreen** (Updated)
- Location: `lib/screens/graphs_screen.dart`
- Implementation: `_buildSiteSelector()` & `_buildRoundButton()`

### 3. **RecipesScreen - History Tab** (Updated)
- Location: `lib/screens/recipes_screen.dart`
- Implementation: `_buildSiteSelector()` & `_buildRoundButton()`

## Design Specifications

### Container Styling
```dart
padding: const EdgeInsets.all(10),
color: Colors.black,
```

### Navigation Buttons (Left/Right)
**Dimensions:**
- Width: 40px
- Height: 35px
- Border Radius: 5px

**Enabled State:**
- Background: `Colors.white`
- Icon Color: `Colors.black`

**Disabled State:**
- Background: `Colors.grey[700]`
- Icon Color: `Colors.grey[400]`

### Dropdown Container
**Dimensions:**
- Height: 35px
- Padding: Symmetric horizontal 10px

**Styling:**
- Background: `Colors.white`
- Border Radius: 5px
- Icon: `Icons.arrow_drop_down` (black)
- Text Color: Black

### Spacing
- Between left button and dropdown: 10px
- Between dropdown and right button: 10px

## Button Behavior

### Left Button
- **Enabled:** When NOT on first site (currentIndex > 0)
- **Action:** Navigate to previous site
- **Disabled:** When on first site

### Right Button
- **Enabled:** When NOT on last site (currentIndex < siteNames.length - 1)
- **Action:** Navigate to next site
- **Disabled:** When on last site

### Dropdown
- Always functional when sites available
- Updates selected site
- Triggers data refresh

## Implementation Pattern

All three screens follow the same pattern:

```dart
Widget _buildSiteSelector(List<String> siteNames) {
  final currentIndex = _selectedSite != null
      ? siteNames.indexOf(_selectedSite!)
      : 0;
  final isLeftEnabled = currentIndex > 0;
  final isRightEnabled = currentIndex < siteNames.length - 1;

  return Container(
    padding: const EdgeInsets.all(10),
    color: Colors.black,
    child: Row(
      children: [
        _buildRoundButton(...),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButtonHideUnderline(...)
          ),
        ),
        const SizedBox(width: 10),
        _buildRoundButton(...),
      ],
    ),
  );
}

Widget _buildRoundButton({
  required IconData icon,
  required VoidCallback? onTap,
  required bool enabled,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 35,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[700],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(
        icon,
        color: enabled ? Colors.black : Colors.grey[400],
      ),
    ),
  );
}
```

## Visual Consistency

All screens now display:
- Same button size and shape
- Same dropdown styling
- Same color scheme (black background, white buttons)
- Same enabled/disabled state indication
- Same spacing and padding

## Benefits

1. **Consistency:** Users see familiar navigation across all screens
2. **Predictability:** Button behavior is identical everywhere
3. **Maintainability:** Changes to one implementation benefit all screens
4. **Professional Look:** Polished, unified UI/UX

## Future Updates

If the design needs modification, update the `_buildRoundButton()` widget in:
1. `sites_screen.dart`
2. `graphs_screen.dart`
3. `recipes_screen.dart`

All three will automatically reflect the changes.

