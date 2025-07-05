# Map Items Integration Todo List

## Overview
This document outlines the steps to implement the display of multiple categorized items (destinations, OCOP products, local specialties, festivals) on HERE Maps, with proper categorization, filtering, and interaction.

## 1. API Integration

### Backend API Development
- [ ] Design consistent base API response structure
- [ ] Create map-items bulk loading endpoint (`/api/map-items`) with filtering options
- [ ] Implement type-specific endpoints with appropriate fields:
  - [ ] Destinations API (`/api/destinations`)
  - [ ] OCOP Products API (`/api/ocop-products`)
  - [ ] Local Specialties API (`/api/local-specialties`) 
  - [ ] Festivals/Events API (`/api/events`)
- [ ] Create marker type endpoint (`/api/marker-types`)
- [ ] Implement proper pagination for all endpoints
- [ ] Add caching headers for better performance

### JSON Structure Standardization
- [ ] Ensure all APIs return location data in a consistent format
- [ ] Standardize naming conventions across all item types
- [ ] Add marker_id field to all map item types
- [ ] Include essential metadata for map display (name, image, type)

## 2. Model Enhancements

### Create Unified Map Item Model
- [ ] Create `MapItem` model class in `lib/models/map/map_item.dart`
- [ ] Update existing models to include location data:
  - [ ] Add latitude/longitude to `Destination` model
  - [ ] Add latitude/longitude to `OcopProduct` model
  - [ ] Add latitude/longitude to `LocalSpecialty` model
  - [ ] Add latitude/longitude to `EventFestival` model
- [ ] Add marker type association to all models
- [ ] Implement proper JSON serialization/deserialization

## 3. Provider Implementation

### Create Map Item Provider
- [ ] Create `MapItemProvider` class in `lib/providers/map/map_item_provider.dart`
- [ ] Implement data loading and caching functionality
- [ ] Add type filtering capabilities
- [ ] Create methods to retrieve items by type
- [ ] Add appropriate logging (following 'ocop_' prefix convention)

### Update Map Provider
- [ ] Enhance `MapProvider` to handle map items display
- [ ] Implement marker creation and management
- [ ] Add map marker tap handling
- [ ] Implement proper marker image loading from assets
- [ ] Add map item filtering functionality

### Update Existing Providers
- [ ] Modify `OcopProductProvider` for map integration
- [ ] Update other providers with location data handling
- [ ] Ensure all providers load data efficiently in splash screen

## 4. HERE Map Integration

### Map Marker Creation
- [ ] Implement function to create HERE map markers from map items
- [ ] Set proper anchor points for map markers (bottom center)
- [ ] Add metadata to markers for tap handling
- [ ] Implement draw order for marker layering

### Map Interaction
- [ ] Set up tap gesture handler for map markers
- [ ] Implement item selection functionality
- [ ] Create navigation from map to detail screens
- [ ] Add map viewport management (zoom to fit items)

### Map Optimization
- [ ] Implement marker clustering for large datasets
- [ ] Add map caching for better performance
- [ ] Optimize map frame rate settings
- [ ] Consider using simplified map style

## 5. UI Components

### Map Filter UI
- [ ] Create `MapCategoryFilter` widget with filter chips
- [ ] Implement type visibility toggling
- [ ] Add visual indicators for selected/unselected filters
- [ ] Style filter UI to match app design

### Map Screen Updates
- [ ] Update map screen to initialize and display map items
- [ ] Add loading indicators
- [ ] Implement error handling and fallbacks
- [ ] Ensure map responsiveness on different screen sizes

### Map Item Detail UI
- [ ] Create or update detail screens for each item type
- [ ] Ensure consistent navigation between map and detail views
- [ ] Add "Show on map" functionality on detail screens

## 6. Splash Screen & Data Loading

- [ ] Update splash screen to load all required data
- [ ] Implement parallel data loading for efficiency
- [ ] Add proper error handling
- [ ] Set appropriate loading timeouts

## 7. Testing & Optimization

- [ ] Test with various data set sizes
- [ ] Verify performance on different devices
- [ ] Optimize marker image loading
- [ ] Test offline behavior
- [ ] Verify memory usage with large data sets

## 8. Documentation

- [ ] Document code with proper comments
- [ ] Update project documentation to include map feature
- [ ] Add usage examples
- [ ] Document marker image requirements 