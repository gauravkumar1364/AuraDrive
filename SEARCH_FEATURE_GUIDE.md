# 🔍 Route Search Feature - User Guide

## Overview

The dashboard now includes a powerful **address search** feature that allows you to easily set source and destination locations by typing addresses instead of manually tapping on the map!

## 🆕 What's New

### Search Button in App Bar
- **Location**: Top-right corner (🔍 icon)
- **Function**: Opens the Route Search dialog
- **Quick Access**: One tap to search for any location worldwide

## 📱 How to Use the Search Feature

### Opening the Search Dialog

1. Tap the **🔍 Search icon** in the app bar
2. The Route Search dialog will open

### Setting Source Location

**Option 1: Search by Address**
1. Type an address in the "Source Location" field
   - Examples: 
     - "1600 Amphitheatre Parkway, Mountain View, CA"
     - "Eiffel Tower, Paris"
     - "Times Square, New York"
2. Tap the **Search button** (🔍) or press Enter
3. Wait for the location to be found
4. Green confirmation will appear when successful

**Option 2: Use Current Location**
1. Tap the **"Use Current Location"** button
2. Your GPS position is automatically set as source

### Setting Destination Location

1. Type an address in the "Destination Location" field
2. Tap the **Search button** (🔍) or press Enter
3. Wait for the location to be found
4. Red confirmation will appear when successful

### Applying the Route

1. Once both source and destination are set (or either one):
   - The **"Set Route"** button becomes active
2. Tap **"Set Route"** to apply
3. Dialog closes and route appears on map
4. Tap **"Cancel"** to discard changes

## 🎯 Features

### Smart Address Recognition

The search feature uses **geocoding** to understand various address formats:

✅ **Full addresses**: "123 Main St, Springfield, IL 62701"
✅ **Landmarks**: "Statue of Liberty, New York"
✅ **Places**: "Central Park, NYC"
✅ **Businesses**: "Apple Park, Cupertino"
✅ **Partial addresses**: "Paris, France"
✅ **Coordinates**: Works with lat/long too

### Visual Feedback

- **🟢 Green confirmation**: Source successfully set
- **🔴 Red confirmation**: Destination successfully set
- **⚠️ Error messages**: Clear feedback if location not found
- **⏳ Loading indicator**: Shows when searching

### Coordinate Display

When a location is found, you see:
```
Source set: 37.4220, -122.0841
Destination set: 48.8584, 2.2945
```

## 🌍 Search Tips (Built-in Guide)

The dialog includes helpful tips:

1. **Use full addresses** for better results
2. **Include city and country** when possible
3. **Famous landmarks** work well
4. **Example formats**:
   - "Eiffel Tower, Paris"
   - "Golden Gate Bridge, San Francisco"
   - "Big Ben, London"

## 🔄 Complete Workflow

### Example: Planning a Route

1. **Open Search**: Tap 🔍 in app bar
2. **Set Source**: 
   - Type "Times Square, New York"
   - Tap Search
   - ✅ Confirmed
3. **Set Destination**:
   - Type "Central Park, New York"
   - Tap Search
   - ✅ Confirmed
4. **Apply Route**: Tap "Set Route"
5. **View on Map**:
   - Green pin at Times Square
   - Red flag at Central Park
   - Blue route line connecting them
   - Distance and ETA displayed

## 🎨 UI Components

### Dialog Layout

```
┌─────────────────────────────────────┐
│ 🔍 Search Route               ✕     │ ← Header
├─────────────────────────────────────┤
│ Source Location                     │
│ [Enter address...] 🔍               │
│ [Use Current Location]              │
│ ✅ Source set: 37.42, -122.08       │
│                                     │
│ Destination Location                │
│ [Enter address...] 🔍               │
│ ✅ Destination set: 48.85, 2.29     │
│                                     │
│ 💡 Search Tips:                     │
│ • Use full addresses                │
│ • Include city and country          │
│ • Famous landmarks work well        │
├─────────────────────────────────────┤
│           [Cancel]  [Set Route]     │ ← Actions
└─────────────────────────────────────┘
```

### Color Coding

- **Blue Header**: Primary brand color
- **Green Accents**: Source location
- **Red Accents**: Destination location
- **Light Blue Box**: Tips section

## 🔧 Technical Details

### Geocoding Service

- **Package**: `geocoding ^3.0.0`
- **Provider**: Platform-native geocoding
- **Coverage**: Worldwide
- **Accuracy**: Address-level precision

### Search Process

```dart
1. User enters address
2. Geocoding service called
3. Address → Coordinates conversion
4. LatLng object created
5. Marker placed on map
6. Route drawn if both points set
```

### Error Handling

**Common Issues & Solutions**:

| Issue | Solution |
|-------|----------|
| "Location not found" | Try more specific address |
| No results | Include city/country |
| Slow search | Check internet connection |
| Generic location | Add more details to search |

## 🚀 Advanced Usage

### Quick Combinations

**Test Nearby Routes**:
1. Use Current Location as source
2. Search for nearby landmark
3. Start navigation immediately

**Multi-Point Planning**:
1. Set initial route
2. Clear and set new destination
3. Keep source for different paths

**Landmark Navigation**:
```
Source: "Statue of Liberty"
Destination: "Times Square"
Result: Tourist route through NYC
```

## 🔄 Integration with Existing Features

The search feature works seamlessly with:

### Manual Selection (Still Available)
- Tap green/red buttons on map
- Tap map to set location
- Mix search + manual selection

### Route Information
- Distance calculated automatically
- ETA updates based on speed
- Real-time position tracking

### Collision Detection
- Alerts work with searched routes
- Risk assessment continues
- Warnings shown during navigation

## 📊 Comparison: Search vs. Manual

| Feature | Search (New) | Manual Tap |
|---------|--------------|------------|
| Precision | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Speed | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Ease of Use | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Known Places | ⭐⭐⭐⭐⭐ | ⭐ |
| Custom Points | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 🎯 Best Practices

### For Accurate Results

1. **Be Specific**: "123 Main St, City, State" > "Main St"
2. **Use Commas**: Helps separate address components
3. **Include Landmarks**: "Near Eiffel Tower" works
4. **Test Variations**: Try different formats if first fails

### For Quick Setup

1. **Current Location Button**: Fastest source setup
2. **Common Destinations**: Save in notes for reuse
3. **Recent Addresses**: Keep a list handy
4. **Voice Input**: Use device keyboard dictation

## 🌟 Example Searches

### Urban Navigation
```
Source: "Penn Station, New York"
Destination: "Brooklyn Bridge"
```

### Campus Routes
```
Source: "Stanford University"
Destination: "Hoover Tower"
```

### Tourist Spots
```
Source: "Louvre Museum, Paris"
Destination: "Arc de Triomphe"
```

### Business Locations
```
Source: "Apple Park, Cupertino"
Destination: "Googleplex, Mountain View"
```

## 🔮 Future Enhancements

Planned improvements:
- [ ] Recent searches history
- [ ] Saved favorite locations
- [ ] Auto-complete suggestions
- [ ] Offline geocoding database
- [ ] Multiple result selection
- [ ] Voice search integration
- [ ] Share routes via VANET

## ❓ FAQ

**Q: Do I need internet for search?**
A: Yes, geocoding requires internet connection.

**Q: Can I search without setting both points?**
A: Yes! Set only source or only destination.

**Q: What if my address isn't found?**
A: Try adding more details or use manual tap as fallback.

**Q: Can I search in different languages?**
A: Yes, geocoding supports international addresses.

**Q: Is there a limit on searches?**
A: No artificial limits, but respect platform usage policies.

---

**Now you can search for any location worldwide and plan routes effortlessly! 🗺️✨**
