# QWI365 Documentation Index

**Project**: QWI365 - Real-Time Agricultural Sensor & Irrigation Management System  
**Version**: 1.0.0+1  
**Date**: February 22, 2026  

---

## 📚 Documentation Map

### 🎯 Primary Documentation

#### 1. **README.md** - Complete Project Overview
**Location**: `/README.md` (936 lines)  
**Audience**: All stakeholders  
**Contains**:
- Project overview and features
- Architecture and technology stack
- All 9 API endpoints reference
- 12 device types and sensor mappings
- Installation and setup guide
- Project structure
- Troubleshooting guide

**Quick Access**:
```
Section                          | Location
─────────────────────────────────────────────
Features                         | Line 23-82
Architecture Overview            | Line 94-106
Device Integration & Sensor API  | Line 116-203
API Endpoints Reference          | Line 215-330
Device Types & Sensor Mappings   | Line 342-405
Installation & Setup             | Line 417-471
Project Structure                | Line 483-525
Key Components                   | Line 537-662
Usage Guide                       | Line 674-765
Data Models                       | Line 777-835
Troubleshooting                  | Line 847-920
Contributing                     | Line 932-960
```

---

### 🔌 API Documentation

#### 2. **SENSOR_API_INTEGRATION.md** - Sensor Data Submission Guide
**Location**: `/SENSOR_API_INTEGRATION.md` (New)  
**Audience**: IoT engineers, firmware developers, sensor integrators  
**Contains**:
- Sensor data submission API endpoint
- Complete parameter specifications
- 6 usage examples (cURL, Python, Node.js, Arduino, etc.)
- Response format (success & error)
- Data flow diagrams
- Security considerations
- Recommended submission intervals
- Data interpretation tables
- Troubleshooting checklist
- Integration checklist

**Use Cases**:
- ✅ Integrating new sensor hardware
- ✅ Testing API endpoints
- ✅ Understanding data flow
- ✅ Debugging sensor issues
- ✅ Firmware development

---

#### 3. **API Endpoints Reference** (in README.md)
**Endpoints Documented**: 9 SOAP endpoints
- Site Screen API
- Sites List API
- Device Details API
- Available Water API
- Recipes API
- Historical Recipe API
- Historical Graph API
- User Login API
- Forgot Password API

---

### 🔧 Implementation Documentation

#### 4. **GRAPHS_IMPLEMENTATION.md** - Graphs Screen Implementation
**Location**: `/GRAPHS_IMPLEMENTATION.md`  
**Audience**: Flutter developers  
**Contains**:
- Complete graphs screen implementation
- HistoricalDataModel updates
- GraphProvider implementation
- Device type mapping
- Data organization strategy

---

#### 5. **UNIFIED_SITE_SELECTOR.md** - Site Selector Design
**Location**: `/UNIFIED_SITE_SELECTOR.md`  
**Audience**: UI/UX designers, Flutter developers  
**Contains**:
- Site selector component design
- Unified implementation across screens
- Design specifications and styling
- Button layouts and states

---

### 📋 Supporting Documents

#### 6. **README_UPDATE_SUMMARY.md** - What Was Added
**Location**: `/README_UPDATE_SUMMARY.md` (New)  
**Audience**: Project managers, documentation maintainers  
**Contains**:
- Summary of all README updates
- Content statistics
- Key highlights
- What's now available

---

## 📖 Navigation by Role

### 👤 For **Mobile App Users**
1. Start with: **README.md** → Features section
2. Then read: → Usage Guide section
3. Reference: → Troubleshooting section

### 👨‍💻 For **Flutter Developers**
1. Start with: **README.md** → Project Structure
2. Study: **GRAPHS_IMPLEMENTATION.md**
3. Study: **UNIFIED_SITE_SELECTOR.md**
4. Reference: **README.md** → Key Components section

### 🔌 For **IoT/Firmware Engineers**
1. Start with: **SENSOR_API_INTEGRATION.md**
2. Reference: **README.md** → Device Integration section
3. Debug: → Troubleshooting Checklist in SENSOR_API_INTEGRATION.md

### 🗄️ For **Backend/API Developers**
1. Study: **README.md** → API Endpoints Reference (9 endpoints)
2. Review: **SENSOR_API_INTEGRATION.md** → Data Flow
3. Reference: **README.md** → Data Models section

### 🏗️ For **System Architects**
1. Start with: **README.md** → Architecture Overview
2. Study: **README.md** → Project Structure
3. Review: **SENSOR_API_INTEGRATION.md** → Data Flow

### 📊 For **Project Managers**
1. Start with: **README.md** → Features (overview)
2. Reference: **README_UPDATE_SUMMARY.md** (progress)
3. Review: → Version History

---

## 🎯 Quick Reference Tables

### All Documented Endpoints

```
API Endpoint              Method  Type    Parameters
────────────────────────────────────────────────────────
SiteScreen               SOAP    Get All Sites with Devices
Sites                    SOAP    List Unique Sites
DeviceDetails            SOAP    Get Devices for Site
AvailableWater           SOAP    Water Availability
Recipes                  SOAP    Get Recipes
HistoricalRecipe         SOAP    Recipe History
HistoricalGraph          SOAP    Historical Data
UserLogin                SOAP    Authentication
ForgotPassword           SOAP    Password Recovery
PostData                 REST    POST Sensor Readings ← NEW!
```

### All Supported Device Types

```
Device Type     Bus1              Bus2          Bus3            Bus4
─────────────────────────────────────────────────────────────────────
10HS            Moisture          -             -               -
GS1             Moisture          -             -               -
5TM             Moisture          Temp          -               -
GS3             Moisture          Temp          EC              -
5TE             Moisture          Temp          EC              -
EnviroScan      Moisture          Temp          EC              -
PYR             Solar             -             -               -
VP4             Temp              Humidity      Pressure        -
ECRN50          Rainfall          -             -               -
ECRN100         Rainfall          -             -               -
PH              pH                -             -               -
EC              EC                -             -               -
```

### Parameter Specifications

```
Bus Number  Field Name              Range           Unit    Alert
────────────────────────────────────────────────────────────────────
Bus1        Soil Moisture           0.0-1.0         Frac    <0.15, >0.75
Bus2        Soil Temperature        -40 to 60       °C      <0, >50
Bus3        Electrical Conductivity 0.0-100+        dS/m    >4.0
Bus4        pH / Battery            3.0-10.0        pH      <5.5, >8.5
```

---

## 🗂️ File Organization

```
QWI365_Flutter/
├── README.md                          ← Main documentation (936 lines)
├── SENSOR_API_INTEGRATION.md          ← Sensor API guide (NEW)
├── GRAPHS_IMPLEMENTATION.md           ← Graphs implementation details
├── UNIFIED_SITE_SELECTOR.md          ← Site selector design
├── README_UPDATE_SUMMARY.md           ← Update summary (NEW)
├── DOCUMENTATION_INDEX.md             ← This file
│
├── lib/
│   ├── models/
│   │   ├── device_model.dart
│   │   ├── site_model.dart
│   │   ├── recipe_model.dart
│   │   ├── water_model.dart
│   │   └── historical_data_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── site_provider.dart
│   │   ├── recipe_provider.dart
│   │   └── graph_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── sites_screen.dart
│   │   ├── recipes_screen.dart
│   │   ├── graphs_screen.dart
│   │   ├── login_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── settings_screen.dart
│   │   └── splash_screen.dart
│   ├── services/
│   │   └── network_api_service.dart
│   ├── widgets/
│   │   └── custom_drawer.dart
│   └── utils/
│       ├── api_urls.dart
│       ├── app_colors.dart
│       └── app_routes.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── android/
└── ios/
```

---

## 🔍 How to Find Information

### Looking for **API Documentation**?
→ **SENSOR_API_INTEGRATION.md** (sensor submission)  
→ **README.md** section "API Endpoints Reference" (all 9 SOAP APIs)

### Looking for **Device Information**?
→ **README.md** section "Device Types & Sensor Mappings"  
→ **README.md** section "Device Integration & Sensor Data API"

### Looking for **Setup Instructions**?
→ **README.md** section "Installation & Setup"

### Looking for **Code Structure**?
→ **README.md** section "Project Structure"  
→ **README.md** section "Key Components"

### Looking for **Graphs Implementation**?
→ **GRAPHS_IMPLEMENTATION.md**

### Looking for **UI Design Specifications**?
→ **UNIFIED_SITE_SELECTOR.md**

### Looking for **Troubleshooting**?
→ **README.md** section "Troubleshooting"  
→ **SENSOR_API_INTEGRATION.md** section "Troubleshooting Checklist"

### Looking for **Usage Instructions**?
→ **README.md** section "Usage Guide"

### Looking for **Contributing Guidelines**?
→ **README.md** section "Contributing"

---

## 📊 Documentation Statistics

| Metric | Count |
|--------|-------|
| **Total Documentation Files** | 5 |
| **Total Lines of Documentation** | ~2000+ |
| **API Endpoints Documented** | 9 SOAP + 1 REST |
| **Device Types Documented** | 12 |
| **Code Examples** | 15+ |
| **Troubleshooting Issues** | 6+ |
| **Tables & Reference Charts** | 20+ |
| **Diagrams & Flows** | 5+ |

---

## 🆕 What's New in This Update

### Added Files
✅ **SENSOR_API_INTEGRATION.md** - Complete sensor API integration guide  
✅ **README_UPDATE_SUMMARY.md** - Summary of README updates  
✅ **DOCUMENTATION_INDEX.md** - This file

### Enhanced Files
✅ **README.md** - Expanded from 18 to 936 lines with:
- Complete feature documentation
- Full API reference
- Device type mappings
- Sensor reading validation
- Complete troubleshooting guide

---

## 📝 Document Maintenance

### Version Control
- **Version**: 1.0.0+1
- **Last Updated**: February 22, 2026
- **Status**: Production Ready

### Update Schedule
- **README.md**: Updated with each major release
- **SENSOR_API_INTEGRATION.md**: Updated when API changes
- **GRAPHS_IMPLEMENTATION.md**: Updated with graphs features
- **UNIFIED_SITE_SELECTOR.md**: Updated with UI changes

### How to Contribute Docs
1. Update relevant .md file
2. Include version number and date
3. Update this index if adding new files
4. Submit with feature pull request

---

## 🔗 External References

### Official Links
- **Website**: https://www.expert365.com.au
- **Support Email**: support@expert365.com.au
- **API Base URL**: https://pani.expert365.com.au

### Framework Documentation
- **Flutter**: https://flutter.dev
- **Dart**: https://dart.dev
- **Provider Package**: https://pub.dev/packages/provider
- **Google Maps Flutter**: https://pub.dev/packages/google_maps_flutter

---

## ✅ Documentation Completeness Checklist

- [x] Features documented
- [x] Architecture documented
- [x] API endpoints documented (9 SOAP + 1 REST)
- [x] Device types documented
- [x] Sensor parameters documented
- [x] Installation guide provided
- [x] Usage guide provided
- [x] Troubleshooting guide provided
- [x] Code examples provided
- [x] Data models documented
- [x] Project structure documented
- [x] Contributing guidelines provided
- [x] Sensor API integration guide provided
- [x] Implementation details documented

---

## 🎓 Learning Path

### Beginner (Mobile App User)
1. **README.md** → Features section (5 min)
2. **README.md** → Usage Guide (10 min)
3. Done! Ready to use the app

### Intermediate (Flutter Developer)
1. **README.md** → Architecture Overview (5 min)
2. **README.md** → Project Structure (10 min)
3. **README.md** → Key Components (15 min)
4. **GRAPHS_IMPLEMENTATION.md** (20 min)
5. **UNIFIED_SITE_SELECTOR.md** (10 min)
6. Ready to contribute features

### Advanced (System Architect)
1. **README.md** → Complete read (60 min)
2. **SENSOR_API_INTEGRATION.md** (30 min)
3. **GRAPHS_IMPLEMENTATION.md** (20 min)
4. **UNIFIED_SITE_SELECTOR.md** (15 min)
5. Review all code in `lib/` directory
6. Ready to design new features

### Integration (IoT Engineer)
1. **SENSOR_API_INTEGRATION.md** (30 min)
2. **README.md** → Device Types section (10 min)
3. **README.md** → API Endpoints Reference (15 min)
4. Test API with examples
5. Ready to integrate hardware

---

## 🎯 Success Metrics

All objectives achieved:
- ✅ Complete device checks documented
- ✅ Status indicators explained
- ✅ Sites management documented
- ✅ Recipes system explained
- ✅ All APIs documented (9 SOAP + 1 REST)
- ✅ API structure explained with push flow
- ✅ Sensor integration guide created

---

**Status**: ✅ Complete & Production Ready  
**Audience**: All stakeholders  
**Maintenance**: Active

