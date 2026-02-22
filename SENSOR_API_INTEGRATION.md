# Sensor Data API Integration Guide

**Document Type**: API Reference Guide  
**Last Updated**: February 22, 2026  
**API Version**: 1.0  
**Status**: Production

---

## 📡 Sensor Data Submission API

### Overview

The QWI365 system integrates with agricultural sensors through a RESTful GET endpoint that accepts real-time sensor readings and stores them in the backend database. Once submitted, data automatically becomes available in the mobile app within 60 seconds.

### Base Endpoint

```
https://pani.expert365.com.au/PostData.aspx
```

---

## 📋 Request Format

### Method
```
GET
```

### Parameters

All parameters are passed as URL query parameters. Example:

```
https://pani.expert365.com.au/PostData.aspx?IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&Bus4=6.45
```

### Parameter Specifications

| Parameter | Type | Required | Range | Unit | Example | Description |
|-----------|------|----------|-------|------|---------|-------------|
| **IMEI** | String | ✅ Yes | N/A | N/A | `QWI365-0028_1_1` | Unique device identifier (Device_SiteID_BusID format) |
| **Bus1** | Float | ✅ Yes | 0.0 - 1.0 | Fraction | `0.43` | Soil Moisture (Volumetric Water Content) |
| **Bus2** | Float | ✅ Yes | -40 to 60 | °C | `7.2` | Soil Temperature |
| **Bus3** | Float | ✅ Yes | 0.0 - 100+ | dS/m | `2.29` | Electrical Conductivity (Salinity) |
| **Bus4** | Float | ✅ Yes | 3.0 - 10.0 | pH | `6.45` | pH Value / Battery Voltage |

### Parameter Details

#### IMEI (Device ID)
- **Format**: `Device_SiteID_BusID` (e.g., `QWI365-0028_1_1`)
- **Length**: Max 100 characters
- **Requirements**: Must be unique per sensor/device
- **Case Sensitive**: Yes

#### Bus1 - Soil Moisture
- **Range**: 0.0 to 1.0 (fractional)
- **Interpretation**: Multiply by 100 for percentage
  - 0.43 = 43% soil moisture
- **Typical Range**: 0.15 (dry) to 0.75 (wet)
- **Sensor Type**: Volumetric Water Content (VWC)
- **Units in App**: Percentage (%)

#### Bus2 - Soil Temperature
- **Range**: -40°C to 60°C
- **Typical Range**: 5°C to 35°C (field conditions)
- **Resolution**: 0.1°C
- **Sensor Type**: DS18B20 or similar
- **Units in App**: °Celsius

#### Bus3 - Electrical Conductivity (EC)
- **Range**: 0.0 to 100+ dS/m
- **Typical Range**: 0.5 to 3.0 dS/m (normal soil)
- **Alert Threshold**: > 4.0 dS/m (salt stress)
- **Sensor Type**: EC probe / Conductivity sensor
- **Units in App**: dS/m or mS/cm (1 dS/m = 10 mS/cm)

#### Bus4 - pH / Battery Voltage
- **Range**: 3.0 to 10.0 (pH) or mV (battery)
- **Typical Range**: 6.0 to 7.5 (neutral soil)
- **Alert Threshold**: < 5.5 (acidic) or > 8.5 (alkaline)
- **Sensor Type**: pH probe or battery voltage reference
- **Units in App**: pH units or V representation

---

## 🔧 Usage Examples

### Example 1: Basic Sensor Reading

**Request:**
```
https://pani.expert365.com.au/PostData.aspx?IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&Bus4=6.45
```

**Breakdown:**
- Device: QWI365-0028_1_1
- Moisture: 43% (0.43)
- Temperature: 7.2°C
- EC: 2.29 dS/m
- pH: 6.45

### Example 2: Using cURL

```bash
curl "https://pani.expert365.com.au/PostData.aspx?IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&Bus4=6.45"
```

### Example 3: Using Postman

1. **Method**: GET
2. **URL**: `https://pani.expert365.com.au/PostData.aspx`
3. **Params**:
   ```
   IMEI   = QWI365-0028_1_1
   Bus1   = 0.43
   Bus2   = 7.2
   Bus3   = 2.29
   Bus4   = 6.45
   ```

### Example 4: Using Python

```python
import requests

url = "https://pani.expert365.com.au/PostData.aspx"
params = {
    'IMEI': 'QWI365-0028_1_1',
    'Bus1': '0.43',
    'Bus2': '7.2',
    'Bus3': '2.29',
    'Bus4': '6.45'
}

response = requests.get(url, params=params)
print(response.status_code)
print(response.json())
```

### Example 5: Using Node.js

```javascript
const axios = require('axios');

const params = {
    IMEI: 'QWI365-0028_1_1',
    Bus1: '0.43',
    Bus2: '7.2',
    Bus3: '2.29',
    Bus4: '6.45'
};

axios.get('https://pani.expert365.com.au/PostData.aspx', { params })
    .then(response => console.log(response.data))
    .catch(error => console.log(error));
```

### Example 6: Arduino/IoT Device

```cpp
#include <WiFi.h>
#include <HTTPClient.h>

void sendSensorData() {
    HTTPClient http;
    
    String imei = "QWI365-0028_1_1";
    float moisture = 0.43;
    float temperature = 7.2;
    float ec = 2.29;
    float ph = 6.45;
    
    String url = "https://pani.expert365.com.au/PostData.aspx?IMEI=" + imei 
                + "&Bus1=" + String(moisture) 
                + "&Bus2=" + String(temperature)
                + "&Bus3=" + String(ec)
                + "&Bus4=" + String(ph);
    
    http.begin(url);
    int httpCode = http.GET();
    
    if (httpCode == 200) {
        String payload = http.getString();
        Serial.println("Success: " + payload);
    } else {
        Serial.println("Error: " + String(httpCode));
    }
    
    http.end();
}
```

---

## 📥 Response Format

### Success Response (HTTP 200)

```json
{
  "Device_Name": "QWI365-0028_1_1",
  "bus_1_Reading": 0.43,
  "bus_2_Reading": 7.2,
  "bus_3_Reading": 2.29,
  "bus_4_Reading": 6.45,
  "Insertion_Date": "22/02/2026 14:30:55",
  "REfill_point": 20,
  "Status": "OK"
}
```

### Error Response (HTTP 400)

```json
{
  "Status": "ERROR",
  "Message": "Invalid IMEI format",
  "Code": 400
}
```

### Response Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| **Device_Name** | String | Echo of submitted IMEI |
| **bus_1_Reading** | Float | Confirmed moisture reading |
| **bus_2_Reading** | Float | Confirmed temperature reading |
| **bus_3_Reading** | Float | Confirmed EC reading |
| **bus_4_Reading** | Float | Confirmed pH/battery reading |
| **Insertion_Date** | String | Server timestamp (dd/MM/yyyy HH:mm:ss) |
| **REfill_point** | Integer | Irrigation threshold % (for this device) |
| **Status** | String | "OK" or "ERROR" |

---

## 🔄 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Sensor Device (Arduino, IoT, Modbus, etc.)                      │
│ Reads: Moisture, Temperature, EC, pH every N minutes            │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│ Sensor Device Makes GET Request to PostData.aspx                │
│ Example: https://pani.expert365.com.au/PostData.aspx?           │
│          IMEI=QWI365-0028_1_1&Bus1=0.43&Bus2=7.2&Bus3=2.29&... │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│ Server (pani.expert365.com.au)                                  │
│ - Validates parameters                                          │
│ - Stores in database                                            │
│ - Returns confirmation JSON                                     │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│ Mobile App (QWI365 Flutter)                                     │
│ - Auto-refreshes every 60 seconds                               │
│ - Calls SiteScreen & DeviceDetails APIs                         │
│ - Fetches latest sensor data                                    │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│ User Interface                                                  │
│ - Map markers update with real-time data                        │
│ - Device readings refreshed                                     │
│ - Graphs updated with historical data                           │
│ - Status indicators (🟢 🟡 🔴) reflect device state            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Considerations

### HTTPS Only
- All requests MUST use HTTPS
- HTTP requests will be rejected
- SSL/TLS 1.2 or higher required

### Authentication
- Currently uses IMEI as device identifier
- No API key or token required for POST endpoint
- Future versions may implement API keys

### Rate Limiting
- Recommended: 1 request every 15-30 minutes per device
- Maximum: 1 request per minute (bursts allowed)
- Excessive requests will be throttled

### Data Validation
- All parameters must be numeric (except IMEI)
- Invalid ranges are rejected
- Malformed requests return HTTP 400

---

## ⏱️ Frequency & Intervals

### Recommended Submission Intervals

| Device Type | Interval | Reason |
|-------------|----------|--------|
| **Soil Moisture** | 15-30 min | Slow changes in soil conditions |
| **Temperature** | 30-60 min | Relatively stable diurnal cycle |
| **EC (Salinity)** | 1-2 hours | Minimal short-term variation |
| **pH** | Daily | Very stable parameter |
| **Battery Status** | Hourly | Monitor device health |

### Mobile App Refresh
- **Automatic**: Every 60 seconds on home screen
- **Manual**: User can pull-to-refresh
- **Incremental**: Only new data is fetched

---

## ⚠️ Common Issues & Solutions

### Issue 1: Invalid IMEI Format
**Error**: `Invalid IMEI format`
**Solution**: Ensure IMEI matches pattern `DeviceName_SiteID_BusID`

### Issue 2: Out of Range Values
**Error**: `Bus1 value out of range (0.0-1.0)`
**Solution**: 
- Check moisture sensor calibration
- Ensure values are fractional (0.43 not 43)
- Verify sensor wiring

### Issue 3: Network Timeout
**Error**: Connection timeout or "500 Internal Server Error"
**Solution**:
- Check internet connectivity
- Verify endpoint URL is correct
- Retry with exponential backoff (2s, 4s, 8s, 16s)

### Issue 4: No Data Appearing in App
**Cause**: Data submitted but not visible in mobile app
**Solution**:
- Wait 60 seconds for auto-refresh
- Force refresh in app (pull-to-refresh)
- Verify device IMEI matches site devices
- Check app is logged in with correct account

### Issue 5: Data Drift Over Time
**Cause**: Sensor readings consistently offset from expected values
**Solution**:
- Recalibrate sensor (follow manufacturer instructions)
- Verify sensor type in app (should match Device_Type in system)
- Check for soil saturation or environmental factors

---

## 📊 Data Interpretation

### Moisture Levels (Bus1)

```
Value     Level        Status      Action
─────────────────────────────────────────
< 0.15    Very Dry     ⚠️ ALERT     Irrigate immediately
0.15-0.25 Dry          🟡 WARNING   Schedule irrigation
0.25-0.45 Optimal      🟢 GOOD      No action needed
0.45-0.60 Moist        🟢 GOOD      No action needed
0.60-0.75 Wet          🟡 WARNING   Reduce irrigation
> 0.75    Very Wet     ⚠️ ALERT     Drainage required
```

### Temperature Ranges (Bus2)

```
Value     Range         Status      Note
──────────────────────────────────────────
< 0°C     Freezing      ⚠️ ALERT     Risk of crop damage
0-5°C     Cold          🟡 WARNING   Slow growth
5-35°C    Optimal       🟢 GOOD      Normal operations
35-50°C   Hot           🟡 WARNING   Stress conditions
> 50°C    Very Hot      ⚠️ ALERT     Critical conditions
```

### EC/Salinity Levels (Bus3)

```
Value (dS/m) Level        Status      Crop Impact
────────────────────────────────────────────────
0.0-0.5      Very Low      ⚠️ Low      Nutrient deficiency
0.5-1.5      Low           🟡 Caution   Most crops ok
1.5-3.0      Optimal       🟢 GOOD      Good for most crops
3.0-4.0      High          🟡 WARNING   Salt-sensitive crop stress
> 4.0        Very High     ⚠️ ALERT     Crop damage likely
```

### pH Levels (Bus4)

```
Value     Range         Soil Type      Status
──────────────────────────────────────────────
< 5.5     Very Acidic   Acidic soil    🟡 Caution
5.5-6.0   Acidic        Acidic         🟢 Good
6.0-7.5   Neutral       Optimal        🟢 BEST
7.5-8.5   Alkaline      Alkaline       🟡 Caution
> 8.5     Very Alkaline Highly alkaline ⚠️ Alert
```

---

## 🛠️ Troubleshooting Checklist

Before submitting data, verify:

- [ ] Device has internet connectivity
- [ ] Using HTTPS (not HTTP)
- [ ] IMEI is exactly matching device in system
- [ ] Bus1 is between 0.0 and 1.0
- [ ] Bus2 is reasonable temperature (-40 to 60°C)
- [ ] Bus3 is positive EC value
- [ ] Bus4 is valid pH value (3.0-10.0)
- [ ] No URL encoding issues with special characters
- [ ] Request completes within 30 seconds
- [ ] Response status is 200 OK

---

## 📈 Integration Checklist

For new sensor integration:

### Hardware Setup
- [ ] Sensor installed in field
- [ ] Sensor calibrated per manufacturer spec
- [ ] Device has power supply and connectivity
- [ ] Sensor readings tested manually

### Software Setup
- [ ] Device registered in QWI365 system
- [ ] IMEI obtained and noted
- [ ] API endpoint URL verified
- [ ] Submission interval determined
- [ ] Error handling implemented

### Testing
- [ ] Manual POST test with cURL succeeds
- [ ] Response is valid JSON with status "OK"
- [ ] Data appears in app within 2 minutes
- [ ] Multiple readings submitted successfully
- [ ] Device offline detection works (no 200 response)

### Monitoring
- [ ] Set up device health monitoring
- [ ] Configure alert thresholds for values
- [ ] Log all API responses (success/error)
- [ ] Implement retry logic for failures
- [ ] Monitor battery voltage regularly

---

## 🔗 Related Documentation

- **Main README**: `/README.md` - Complete app documentation
- **API Endpoints**: See API Endpoints Reference section in README
- **Device Types**: Device Types & Sensor Mappings in README
- **Graphs Implementation**: `/GRAPHS_IMPLEMENTATION.md`

---

## 📞 Support & Questions

**Technical Issues**:
- Email: support@expert365.com.au
- Website: https://www.expert365.com.au
- Documentation: See README.md

**Sensor Calibration**:
- Consult manufacturer documentation
- Contact sensor support team
- Test with known reference materials

---

**Version**: 1.0  
**Last Updated**: February 22, 2026  
**Status**: Production Ready

