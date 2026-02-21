# Complete Graphs Screen Implementation

## Overview
This document outlines the complete implementation of the Graphs screen in Flutter, matching the Java Android version's functionality.

## Files Modified

### 1. **HistoricalDataModel** (`lib/models/historical_data_model.dart`)
Updated to support all three bus readings from the sensor data:

```dart
class HistoricalDataModel {
  final double bus1Reading;
  final double? bus2Reading;
  final double? bus3Reading;
  final String dateTime;
  final String deviceName;
  final double? refillPoint;
}
```

**Key Features:**
- Supports multi-sensor devices with up to 3 bus readings
- Improved refill point parsing to handle multiple data types
- Proper null safety for optional readings

### 2. **GraphProvider** (`lib/providers/graph_provider.dart`)
Implements the Java `parseGraphData()` logic:

```dart
fetchHistoricalGraph(
  String siteName,
  String fromDate,
  String toDate,
  String username,
  Map<String, String> deviceTypeMap,
)
```

**Device Type Mapping:**
- **10HS/GS1**: Moisture (bus1) + refill point
- **5TM**: Moisture (bus1) + Temperature (bus2) with refill point
- **GS3/5TE/EnviroScan**: Moisture (bus1) + Temperature (bus2) + EC (bus3) with refill point
- **PYR**: Solar Radiation (bus1)
- **VP4**: Temperature (bus1) + Humidity (bus2) + Pressure (bus3)
- **ECRN50/ECRN100**: Rainfall (bus1)
- **PH**: pH (bus1)
- **EC**: Electrical Conductivity (bus1)

**Data Organization:**
- Parses raw JSON response from API
- Organizes data into 8 categories: Moisture, Temperature, EC, Solar, Humidity, Pressure, PH, Rainfall
- Handles multi-device scenarios with proper grouping

### 3. **GraphsScreen** (`lib/screens/graphs_screen.dart`)
Complete screen implementation with all Java features:

#### Features Implemented:

**1. Site Navigation**
- Left/Right arrow buttons for site navigation with proper enabled/disabled states
- Buttons appear grayed out (darker background, lighter icon) when at boundaries
- Left button disabled when on first site
- Right button disabled when on last site
- Dropdown selector for site selection
- Map view showing selected site location
- Initial map centered on Australia

**2. Date Selection**
- From and To date pickers
- Default to current date
- Triggers graph refresh on date change
- Format: dd/MM/yyyy

**3. Multiple Graphs**
- Separate chart for each data type (8 total)
- Conditional visibility (only shows if data exists)
- Color-coded by device
- Smooth curve rendering with Bezier interpolation

**4. Graph Features**
- Multi-line support for multiple devices
- Interactive touch points
- Real-time value display on tap
- Refill line for moisture data
- Formatted axes (time on X, values on Y)
- Grid with proper styling

**5. Value Display**
- Selected value shown above each graph
- Format: `value unit @ timestamp` or `prefix value`
- Updates on chart tap
- Default: "N/A" when no data selected

**6. Legend**
- Color-coded device names
- Displayed below each chart
- Shows refill indicator (blue) for moisture

**7. Data Handling**
- "No data found" message when empty
- Proper error handling
- Loading indicator during fetch
- Refresh capability from app bar

## Color Palette

8 distinct colors for device differentiation:
```dart
FF6B6B, 4ECDC4, 45B7D1, FFA07A, 98D8C8, F7DC6F, BB8FCE, 85C1E9
```

## API Integration

Data flows as follows:
1. User selects site, date range
2. GraphProvider calls API with device type map
3. API returns JSON array of readings
4. Provider parses data and organizes by type
5. Screen displays organized data in charts

## Responsive Design

- Adapts to various screen sizes
- Proper spacing and padding
- Scrollable content for long lists
- Touch-optimized interactive elements

## Data Format Expected

Example API response:
```json
{
  "Device_Name": "QWI365-0028_1_1",
  "bus_1_Reading": 0.43,
  "bus_2_Reading": 7.2,
  "bus_3_Reading": 2.29,
  "bus_4_Reading": 6.45,
  "Insertion_Date": "04/02/2026 17:33:55",
  "REfill_point": 20
}
```

## Units and Formatting

- **Moisture Content**: % (decimal 1)
- **Temperature**: ℃ (decimal 1)
- **EC**: dS/m (decimal 1)
- **Solar**: W/m² (decimal 0)
- **Humidity**: % (decimal 0)
- **Pressure**: hPa (decimal 0)
- **pH**: pH (decimal 1)
- **Rainfall**: mm (decimal 0)

## State Management

- Uses Provider pattern for state management
- Real-time updates using notifyListeners()
- Proper separation of concerns (Model, Provider, View)

## Dependencies

- `fl_chart`: Chart rendering
- `google_maps_flutter`: Map display
- `provider`: State management
- `intl`: Date/time formatting


