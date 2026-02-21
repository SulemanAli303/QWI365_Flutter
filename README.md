# QWI365 - Real-Time Agricultural Sensor & Irrigation Management System

A comprehensive Flutter mobile application for monitoring agricultural soil conditions, managing irrigation recipes, and analyzing historical data through real-time sensor integration.

**Current Status:** v1.0.0+1  
**Platform Support:** iOS, Android, macOS, Linux, Windows, Web

---

## 📋 Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Device Integration & Sensor Data API](#device-integration--sensor-data-api)
- [API Endpoints Reference](#api-endpoints-reference)
- [Device Types & Sensor Mappings](#device-types--sensor-mappings)
- [Installation & Setup](#installation--setup)
- [Project Structure](#project-structure)
- [Key Components](#key-components)
- [Usage Guide](#usage-guide)
- [Data Models](#data-models)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## 🎯 Features

### 1. **Real-Time Sensor Monitoring**
- Live soil moisture, temperature, pH, and electrical conductivity readings
- Multi-sensor device support (up to 3 bus readings per device)
- Automatic data refresh every 60 seconds
- Device status indicators (online/offline)

### 2. **Interactive Map View**
- Google Maps integration with real-time marker updates
- Color-coded markers for device status:
  - 🟢 **Green**: Device healthy (all readings normal)
  - 🟡 **Yellow**: Warning (moisture/EC levels elevated)
  - 🔴 **Red**: Critical (device offline or error)
  - 🔵 **Blue**: Informational (data available)
- Custom info windows with device details
- Support for satellite and normal map views

### 3. **Site Management**
- Browse and manage multiple irrigation sites
- View site location, coordinates, and device inventory
- Unified site selector with previous/next navigation
- Device list with real-time readings
- Available water calculation (irrigation potential)

### 4. **Irrigation Recipes**
- Pre-calculated irrigation schedules based on:
  - Soil moisture content
  - Temperature variations
  - Rainfall data
  - Evapotranspiration (ET) values
- Historical recipe analysis with date-based filtering
- Visual status indicators (Completed, Pending, Skipped)
- Irrigation amount and timing recommendations

### 5. **Historical Data Analysis**
- Interactive graphs for all sensor parameters:
  - **Moisture Content (MC)** - percentage
  - **Temperature (TEMP)** - °C
  - **Electrical Conductivity (EC)** - dS/m (mS/cm)
  - **Solar Radiation** - W/m²
  - **Humidity** - %
  - **Pressure** - hPa
  - **pH** - units
  - **Rainfall** - mm
- Date range filtering
- Multi-device comparison on single graph
- Refill point tracking
- Data point selection with formatted values

### 6. **User Management**
- Secure login system
- Password recovery via email
- User session management
- Persistent authentication (SharedPreferences)

### 7. **Settings & Preferences**
- Map layer selection (Satellite/Normal)
- Default site configuration
- User account management

---

## 🏗️ Architecture Overview

### Technology Stack
```
Frontend: Flutter 3.11+
State Management: Provider (v6.1.5+1)
Maps: Google Maps Flutter (v2.14.2)
Data Persistence: SharedPreferences (v2.5.4)
Networking: SOAP/HTTP with xml parsing
Charting: FL Chart (v1.1.1)
UI Framework: Material Design 3
```

### Design Pattern
- **MVC with Providers**: Clean separation of concerns
- **Provider Pattern**: Reactive state management
- **SOAP-based APIs**: Legacy system integration
- **Real-time Updates**: Periodic refresh mechanism

---

## 🔌 Device Integration & Sensor Data API

### Sensor Data Submission Endpoint

**Base URL:** `https://pani.expert365.com.au/PostData.aspx`

#### Recipe: Using the Soil Sensor API

**Ingredients (API Details):**

```
Endpoint: https://pani.expert365.com.au/PostData.aspx

Example Request:
https://pani.expert365.com.au/PostData.aspx?IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&Bus4=6.45
```

**Parameters:**

| Parameter | Field Name | Range | Unit | Example | Description |
|-----------|-----------|-------|------|---------|-------------|
| IMEI | Device ID | String | N/A | `QWI365-0028_1_1` | Unique sensor/device identifier (format: Device_SiteID_BusID) |
| Bus1 | Soil Moisture | 0.0 - 1.0 | Fraction | `0.43` | Volumetric water content (multiply by 100 for %) |
| Bus2 | Soil Temperature | -40 to 60 | °C | `7.2` | Soil temperature reading |
| Bus3 | Electrical Conductivity | 0.0 - 100+ | dS/m | `2.29` | Soil salinity measurement (alert if >4 mS/cm) |
| Bus4 | pH | 3.0 - 10.0 | pH units | `6.45` | Soil acidity/alkalinity (V representation) |

#### Steps to Cook (Implementation Guide)

**Step 1: Mix - Prepare the Request**
```
Send a GET request with all sensor parameters to PostData.aspx endpoint
```

**Step 2: Check - Parse Response**
```
Server responds with JSON confirmation:
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

**Step 3: Serve - Use in App**
```
- Moisture: 0.43 × 100 = 43% soil moisture
- Temperature: 7.2°C soil temperature
- EC (Salinity): 2.29 dS/m (⚠️ Alert if >4)
- pH: 6.45 (neutral to slightly acidic)
- Refill Point: 20% (irrigation threshold)
```

#### Chef's Notes

- **Moisture (Bus1)**: Always a fraction (0-1). Multiply by 100 for percentage display.
- **Real-World Conditions**: All values reflect actual field sensor readings with natural variation.
- **Auto-Integration**: Once sensors post data via GET request, it automatically appears in the app within 60 seconds.
- **Battery Monitoring**: Monitor Bus4/pH readings for low voltage indicators.
- **Data Refresh**: App checks for new readings every 60 seconds automatically.

#### Example cURL Request
```bash
curl "https://pani.expert365.com.au/PostData.aspx?IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&Bus4=6.45"
```

#### Data Flow Diagram
```
Sensor Device
    ↓ (GET request with sensor readings)
PostData.aspx API
    ↓ (parses parameters & stores in database)
Server Database
    ↓ (triggered by app's periodic fetch)
SiteScreen / DeviceDetails API calls
    ↓ (returns latest readings)
Flutter App Display
    ↓ (shows on map, home screen, and graphs)
User sees real-time data
```

---

## 🔗 API Endpoints Reference

All APIs use **SOAP protocol** with the following base configuration:

| Property | Value |
|----------|-------|
| Base URL | `https://pani.expert365.com.au/Expert365.asmx` |
| Namespace | `http://tempuri.org/` |
| Protocol | SOAP 1.1 with .NET compatibility |
| Authentication | Username parameter (HTTP parameter) |

### Endpoint Details

#### 1. **Site Screen** - Get All Sites with Devices
```
Action: http://tempuri.org/SiteScreen
Method: SiteScreen
URL: https://pani.expert365.com.au/Expert365.asmx?op=SiteScreen
Parameters: 
  - UserName (String): Authenticated username

Response: Array of SiteModel objects
{
  "Site_Name": "Farm A",
  "latitude": "-28.8295",
  "longitude": "132.4331",
  "Device_Type": "5TM",
  "Device_Name": "QWI365-0028_1_1",
  "Device_Id": "12345",
  "last_Update": "04/02/2026 17:33:55",
  "bus_1_reading": 0.43,
  "bus_2_reading": 7.2,
  "bus_3_reading": 2.29,
  "bus_4_Reading": 6.45,
  "REfill_Point": 20
}
```

#### 2. **Sites** - List All Unique Sites
```
Action: http://tempuri.org/Sites
Method: Sites
URL: https://pani.expert365.com.au/Expert365.asmx?op=Sites
Parameters:
  - UserName (String): Authenticated username

Response: Array of site names (unique)
```

#### 3. **Device Details** - Get Devices for Specific Site
```
Action: http://tempuri.org/DeviceDetails
Method: DeviceDetails
URL: https://pani.expert365.com.au/Expert365.asmx?op=DeviceDetails
Parameters:
  - UserName (String): Authenticated username
  - SiteName (String): Target site name

Response: Array of DeviceModel objects with latest readings
{
  "Device_Name": "QWI365-0028_1_1",
  "Device_Type": "5TM",
  "Device_Id": "12345",
  "Insertion_Date": "04/02/2026 17:33:55",
  "bus_1_Reading": 0.43,
  "bus_2_Reading": 7.2,
  "bus_3_reading": 2.29,
  "bus_4_Reading": 6.45,
  "REfill_Point": 20
}
```

#### 4. **Available Water / Horticulture** - Water Availability
```
Action: http://tempuri.org/AvailableWaterHorticulture
Method: AvailableWaterHorticulture
URL: https://pani.expert365.com.au/Expert365.asmx?op=AvailableWaterHorticulture
Parameters:
  - SiteName (String): Target site name

Response: WaterModel object
{
  "Plant_Available_Water": 45.5,
  "Total_Available_Water": 150.0,
  "Unit": "mm",
  "Last_Updated": "04/02/2026 17:33:55"
}
```

#### 5. **Recipes** - Get Current Irrigation Recipes
```
Action: http://tempuri.org/Recipes
Method: Recipes
URL: https://pani.expert365.com.au/Expert365.asmx?op=Recipes
Parameters:
  - UserName (String): Authenticated username
  - SiteName (String): Target site name

Response: Array of RecipeModel objects
{
  "Site_Name": "Farm A",
  "REfill_Point": 20,
  "Bus_1_Reading": 0.43,
  "Insertion_Date": "04/02/2026 17:33:55",
  "Evapotranspiration": 3.5,
  "Temprature": 7.2,
  "rainfall": 0.5,
  "irrigation_amount": 15.0,
  "irrigation_time": "06:00:00",
  "status": "Completed"
}
```

#### 6. **Historical Recipe** - Recipe History with Date Range
```
Action: http://tempuri.org/HistoricalRecipe
Method: HistoricalRecipe
URL: https://pani.expert365.com.au/Expert365.asmx?op=HistoricalRecipe
Parameters:
  - UserName (String): Authenticated username
  - SiteName (String): Target site name
  - FromDate (String): Format: dd/MM/yyyy
  - ToDate (String): Format: dd/MM/yyyy

Response: Array of RecipeModel objects with date filtering
```

#### 7. **Historical Graph** - Multi-device Historical Data
```
Action: http://tempuri.org/HistoricalGraph
Method: HistoricalGraph
URL: https://pani.expert365.com.au/Expert365.asmx?op=HistoricalGraph
Parameters:
  - UserName (String): Authenticated username
  - SiteName (String): Target site name
  - FromDate (String): Format: dd/MM/yyyy
  - ToDate (String): Format: dd/MM/yyyy

Response: Array of HistoricalDataModel objects
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

#### 8. **User Login** - Authentication
```
Action: http://tempuri.org/UserLogin
Method: UserLogin
URL: https://pani.expert365.com.au/Expert365.asmx?op=UserLogin
Parameters:
  - UserName (String): Email/username
  - Password (String): User password

Response:
{
  "status": "success",
  "message": "Login successful",
  "userId": "12345"
}
or
{
  "status": "error",
  "message": "Invalid credentials"
}
```

#### 9. **Forgot Password** - Password Recovery
```
Action: http://tempuri.org/ForgotPassword
Method: ForgotPassword
URL: https://pani.expert365.com.au/Expert365.asmx?op=ForgotPassword
Parameters:
  - UserName (String): Email address

Response:
{
  "status": "success",
  "message": "Password reset link sent to email"
}
```

---

## 📱 Device Types & Sensor Mappings

The system supports various agricultural sensors. Each device type has specific bus readings:

### Device Type Mapping Chart

| Device Type | Bus 1 | Bus 2 | Bus 3 | Bus 4 | App Display | Graph Support |
|------------|-------|-------|-------|-------|------------|---------------|
| **10HS** | Moisture (%) | - | - | - | Moisture % | MC Chart |
| **GS1** | Moisture (%) | - | - | - | Moisture % | MC Chart |
| **5TM** | Moisture (%) | Temp (°C) | - | - | MC, Temp | MC, Temp Charts |
| **GS3** | Moisture (%) | Temp (°C) | EC (dS/m) | - | MC, Temp, EC | MC, Temp, EC Charts |
| **5TE** | Moisture (%) | Temp (°C) | EC (dS/m) | - | MC, Temp, EC | MC, Temp, EC Charts |
| **EnviroScan** | Moisture (%) | Temp (°C) | EC (dS/m) | - | MC, Temp, EC | MC, Temp, EC Charts |
| **PYR** | Solar (W/m²) | - | - | - | Solar | Solar Chart |
| **VP4** | Temp (°C) | Humidity (%) | Pressure (hPa) | - | Temp, RH, Press | Temp, RH, Press Charts |
| **ECRN50** | Rainfall (mm) | - | - | - | Rainfall | Rainfall Chart |
| **ECRN100** | Rainfall (mm) | - | - | - | Rainfall | Rainfall Chart |
| **PH** | pH (units) | - | - | - | pH Value | pH Chart |
| **EC** | EC (dS/m) | - | - | - | EC Value | EC Chart |

### Device Status Indicators

**Dashboard Status Checks:**

```
✅ ONLINE - Device transmitting data within last 2 hours
⚠️ WARNING - Moisture >50% OR EC >4 mS/cm OR Offline for 2-24 hours
❌ OFFLINE - No data for >24 hours
🔧 ERROR - Invalid readings or connection issues
```

### Sensor Reading Validation

| Parameter | Min | Max | Safe Range | Alert Threshold |
|-----------|-----|-----|-----------|-----------------|
| **Moisture (Bus1)** | 0.0 | 1.0 | 0.25-0.60 | <0.15 (dry) or >0.75 (wet) |
| **Temperature (Bus2)** | -40°C | 60°C | 5-35°C | <0°C or >50°C |
| **EC (Bus3)** | 0.0 | 100+ | 0.5-3.0 dS/m | >4.0 dS/m (salt stress) |
| **pH (Bus4)** | 3.0 | 10.0 | 6.0-7.5 | <5.5 or >8.5 |
| **Rainfall (Bus1)** | 0.0 | 500+ | Varies | Monitor trends |
| **Solar (Bus1)** | 0 | 1500+ | 0-1000+ W/m² | Monitor patterns |
| **Humidity (Bus2)** | 0% | 100% | 40-80% | <20% or >95% |
| **Pressure (Bus3)** | 800 | 1100 | 900-1050 hPa | Extreme variations |

---

## 🚀 Installation & Setup

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart 3.11.0 or higher
- iOS 12.0+ / Android 8.0+ / macOS 10.15+
- Google Maps API key (for native platforms)
- Active internet connection

### Step 1: Clone Repository
```bash
git clone <repository-url>
cd QWI365_Flutter
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Google Maps

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>com.apple.developer.maps</key>
<true/>
<key>GoogleMapsApiKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

### Step 4: Build & Run

**Debug:**
```bash
flutter run
```

**Release (Android):**
```bash
flutter build apk --release
flutter build appbundle --release
```

**Release (iOS):**
```bash
flutter build ios --release
```

### Step 5: First Time Setup
1. Launch app
2. Navigate to login screen
3. Enter credentials
4. Select default site in settings
5. Grant location permissions for map functionality

---

## 📁 Project Structure

```
QWI365_Flutter/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── device_model.dart              # Device data structure
│   │   ├── site_model.dart                # Site data structure
│   │   ├── recipe_model.dart              # Recipe data structure
│   │   ├── water_model.dart               # Water availability data
│   │   └── historical_data_model.dart     # Historical graph data
│   ├── providers/
│   │   ├── auth_provider.dart             # Authentication state
│   │   ├── site_provider.dart             # Site & device state
│   │   ├── recipe_provider.dart           # Recipe state
│   │   └── graph_provider.dart            # Historical graph state
│   ├── services/
│   │   ├── network_api_service.dart       # SOAP API calls
│   │   └── [other services]
│   ├── screens/
│   │   ├── splash_screen.dart             # Splash/loading screen
│   │   ├── login_screen.dart              # User authentication
│   │   ├── forgot_password_screen.dart    # Password recovery
│   │   ├── home_screen.dart               # Map view with markers
│   │   ├── sites_screen.dart              # Site details & devices
│   │   ├── recipes_screen.dart            # Irrigation recipes
│   │   ├── graphs_screen.dart             # Historical data charts
│   │   └── settings_screen.dart           # User preferences
│   ├── widgets/
│   │   ├── custom_drawer.dart             # Navigation drawer
│   │   └── [other widgets]
│   └── utils/
│       ├── api_urls.dart                  # API endpoint constants
│       ├── app_colors.dart                # Theme colors
│       └── app_routes.dart                # Navigation routes
├── assets/
│   └── [marker icons, images]
├── android/
│   └── [Android native configuration]
├── ios/
│   └── [iOS native configuration]
├── pubspec.yaml                           # Dependencies
├── analysis_options.yaml                  # Lint rules
├── README.md                              # This file
├── GRAPHS_IMPLEMENTATION.md               # Graphs implementation details
└── UNIFIED_SITE_SELECTOR.md              # Site selector design
```

---

## 🎨 Key Components

### 1. **Providers (State Management)**

#### AuthProvider
- User authentication state
- Login/logout logic
- Session management via SharedPreferences
- Username & token storage

#### SiteProvider
- Manages site and device lists
- Deduplicates sites when multiple devices per site exist
- Filters devices by selected site
- Tracks selected site
- Manages water availability data

#### RecipeProvider
- Irrigation recipe data
- Historical recipe filtering
- Recipe status management

#### GraphProvider
- Historical data fetching
- Graph data organization by device type
- Multi-sensor data alignment
- Date-based filtering

### 2. **Models**

#### SiteModel
```dart
class SiteModel {
  final String siteName;          // Unique site identifier
  final double latitude;          // Map coordinate
  final double longitude;         // Map coordinate
  final String? deviceType;       // Type of sensor (5TM, GS3, etc.)
  final String? deviceName;       // Device identifier
  final String? lastUpdate;       // Last reading timestamp
  final double? bus1Reading;      // Sensor reading 1
  final double? bus2Reading;      // Sensor reading 2
  final double? bus3Reading;      // Sensor reading 3
  final double? bus4Reading;      // Sensor reading 4
  final double? refillPoint;      // Irrigation threshold
}
```

#### DeviceModel
```dart
class DeviceModel {
  final String deviceName;        // Device ID
  final double bus1Reading;       // Latest reading 1
  final double bus2Reading;       // Latest reading 2
  final double bus3Reading;       // Latest reading 3
  final double bus4Reading;       // Latest reading 4
  final double refillPoint;       // Irrigation threshold
  final String insertionDate;     // Timestamp
  final String deviceId;          // Unique device ID
  final String deviceType;        // Sensor type
}
```

#### RecipeModel
```dart
class RecipeModel {
  final String siteName;
  final double refillPoint;
  final double moistureContent;
  final String insertionDate;
  final double evapotranspiration;
  final double temperature;
  final double rainFall;
  final double irrigationAmount;
  final String irrigationTime;
  final String status;            // "Completed", "Pending", "Skipped"
}
```

#### HistoricalDataModel
```dart
class HistoricalDataModel {
  final double bus1Reading;       // Primary measurement
  final double? bus2Reading;      // Secondary measurement
  final double? bus3Reading;      // Tertiary measurement
  final String dateTime;          // Data point timestamp
  final String deviceName;        // Source device
  final double? refillPoint;      // Irrigation reference
}
```

### 3. **Screens**

#### Home Screen
- Google Maps with real-time markers
- Color-coded device status
- Custom info windows
- Periodic data refresh (60s)
- Satellite/Normal map toggle

#### Sites Screen
- Unified site selector
- Device list with readings
- Map view with location
- Available water calculation
- Date-based filtering

#### Recipes Screen
- Current irrigation recommendations
- Historical recipe search
- Status tracking
- Irrigation schedule details
- Unified site selector

#### Graphs Screen
- Multi-parameter historical charts
- Device comparison (same graph)
- Date range selection
- Data point inspection
- Refill point visualization
- Unified site selector

#### Settings Screen
- Map layer preferences
- Default site selection
- User account management
- Logout functionality

---

## 📊 Usage Guide

### Getting Started

1. **Login**
   - Enter email and password
   - App stores credentials securely
   - Redirects to home screen on success

2. **Explore Home Screen**
   - View all sites on interactive map
   - Tap markers for device details
   - Use map controls for navigation
   - Refresh to get latest data

3. **Select a Site**
   - Use dropdown in Sites, Recipes, or Graphs screen
   - Use Previous/Next buttons for navigation
   - View all devices at selected site
   - Monitor real-time readings

4. **View Device Status**
   - Green: All readings normal
   - Yellow: Warning conditions detected
   - Red: Device offline or error
   - Blue: Data available

5. **Check Irrigation Recipes**
   - Navigate to Recipes screen
   - Current tab shows active recipes
   - History tab shows past recipes
   - Filter by date range
   - View recommended irrigation amounts

6. **Analyze Historical Data**
   - Open Graphs screen
   - Select date range
   - Choose device(s) to compare
   - Inspect individual data points
   - Export or share charts

7. **Configure Settings**
   - Set preferred map view
   - Select default site
   - Manage account
   - Review app information

### Data Refresh Mechanics

```
User launches app
  ↓
Home Screen fetches sites & recipes
  ↓ (every 60 seconds)
Auto-refresh timer triggered
  ↓
New data fetched from API
  ↓
Markers updated on map
  ↓
Device readings refreshed
  ↓ (user stays on home screen)
Cycle repeats
```

### Device Status Determination

```
Get last_Update timestamp from API
  ↓
Calculate time difference with current time
  ↓
IF (< 2 hours) → ONLINE (🟢 Green)
ELSE IF (< 24 hours) → WARNING (🟡 Yellow)
ELSE IF (≥ 24 hours) → OFFLINE (🔴 Red)
```

---

## 🔄 Data Models

### API Response Parsing

All API responses are parsed from SOAP XML format. Example transformation:

```xml
<!-- Raw SOAP Response -->
<SiteScreenResult>
  <Site_Name>Farm A</Site_Name>
  <Device_Name>QWI365-0028_1_1</Device_Name>
  <latitude>-28.8295</latitude>
  <longitude>132.4331</longitude>
  <bus_1_Reading>0.43</bus_1_Reading>
  <bus_2_Reading>7.2</bus_2_Reading>
  <bus_3_Reading>2.29</bus_3_Reading>
  <bus_4_Reading>6.45</bus_4_Reading>
  <Insertion_Date>04/02/2026 17:33:55</Insertion_Date>
  <REfill_Point>20</REfill_Point>
</SiteScreenResult>
```

```dart
// Converted to Dart Model
SiteModel(
  siteName: "Farm A",
  deviceName: "QWI365-0028_1_1",
  latitude: -28.8295,
  longitude: 132.4331,
  bus1Reading: 0.43,     // Moisture 43%
  bus2Reading: 7.2,      // Temperature 7.2°C
  bus3Reading: 2.29,     // EC 2.29 dS/m
  bus4Reading: 6.45,     // pH 6.45
  lastUpdate: "04/02/2026 17:33:55",
  refillPoint: 20,       // Refill at 20%
)
```

### Deduplication Logic

When API returns multiple devices per site:

```
API Response: [
  { Site_Name: "Farm A", Device_Name: "Device_1", ... },
  { Site_Name: "Farm A", Device_Name: "Device_2", ... },  ← Duplicate site
  { Site_Name: "Farm B", Device_Name: "Device_3", ... }
]

After Deduplication:
SiteProvider._sites = [
  { Site_Name: "Farm A", Device_Name: "Device_1", ... },  ← First kept
  { Site_Name: "Farm B", Device_Name: "Device_3", ... }
]

SiteProvider.devices (when "Farm A" selected) = [
  { Device_Name: "Device_1", ... },
  { Device_Name: "Device_2", ... }                         ← All devices shown
]
```

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. **Dropdown Error: "There should be exactly one item with [DropdownButton]'s value"**
- **Cause**: Multiple sites with same name in dropdown
- **Solution**: Ensure `SiteProvider.fetchSites()` deduplicates site names
- **Check**: Use unique site names or verify deduplication logic

#### 2. **Maps Not Showing**
- **Cause**: Missing Google Maps API key
- **Solution**: Configure API key in AndroidManifest.xml and Info.plist
- **Check**: Verify location permissions are granted

#### 3. **No Data Appearing**
- **Cause**: API timeout or network connectivity
- **Solution**: Check internet connection, verify API endpoint is accessible
- **Check**: Use device logs to debug SOAP response

#### 4. **Sensors Not Transmitting**
- **Cause**: Sensor offline, low battery, or no connectivity
- **Solution**: Check device status in app, verify sensor configuration
- **Check**: Device should show offline (red marker) if not transmitting

#### 5. **Historical Graphs Empty**
- **Cause**: No data for selected date range
- **Solution**: Verify devices were active during selected dates
- **Check**: Expand date range to include more data

#### 6. **Login Failed**
- **Cause**: Incorrect credentials or server unreachable
- **Solution**: Verify username/password, check network connection
- **Check**: Use Forgot Password if credentials lost

### Debug Logging

Enable verbose logging in network service:

```dart
// In lib/services/network_api_service.dart
print('[API] Request: $soapAction');
print('[API] Response: $response');
print('[API] Parsed: $parsedData');
```

### Performance Optimization

- **Disable map animations** if maps lag: Remove `.animateCamera()` calls
- **Reduce refresh interval**: Modify `_startRefreshTimer()` duration
- **Cache responses**: Implement local storage for frequently accessed data
- **Lazy load graphs**: Build charts only when screen is visible

---

## 👥 Contributing

### Guidelines

1. **Code Style**: Follow Dart conventions
2. **Documentation**: Document all public methods
3. **Testing**: Write unit tests for business logic
4. **Git Workflow**: Use feature branches
5. **Commit Messages**: Use clear, descriptive messages

### Reporting Issues

Include:
- Device type and OS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs if applicable
- API responses if related to data

### Feature Requests

Suggest improvements:
- Mobile-first design considerations
- Offline data support
- Advanced analytics
- Real-time alerts
- Integration with weather APIs

---

## 📄 License

This project is proprietary. Unauthorized copying or distribution is prohibited.

---

## 📞 Support

For technical support or questions:
- **Email**: support@expert365.com.au
- **Website**: https://www.expert365.com.au
- **Documentation**: See GRAPHS_IMPLEMENTATION.md and UNIFIED_SITE_SELECTOR.md

---

## 📈 Version History

### v1.0.0+1 (Current)
- Initial release
- Complete site management
- Real-time device monitoring
- Irrigation recipes
- Historical data analysis
- Multi-device support
- Google Maps integration
- Unified site selector

---

**Last Updated**: February 22, 2026  
**Maintained By**: Expert365 Development Team  
**Project Status**: Active Development
