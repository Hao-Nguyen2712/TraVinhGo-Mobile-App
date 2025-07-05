# OCOP Product Global Data Handling Plan

## Goal
Fetch OCOP product data once at app startup (in the splash screen) and make it globally available for the OCOP product screen to avoid redundant API calls and ensure data consistency. (Map integration will be considered in the future.)

---

## Steps

### 1. Create an `OcopProductProvider`
- Implements `ChangeNotifier`.
- Holds a list of OCOP products and exposes methods to fetch and access them.
- Notifies listeners when data is loaded.

### 2. Register the Provider Globally
- Add `OcopProductProvider` to the list of providers in `main.dart` (or your app's entry point).
- Example:
  ```dart
  MultiProvider(
    providers: [
      // ... other providers ...
      ChangeNotifierProvider(create: (_) => OcopProductProvider()),
    ],
    child: MyApp(),
  )
  ```

### 3. Fetch OCOP Data in Splash Screen
- In the splash screen's `_loadData()` (or equivalent), trigger the provider's fetch method:
  ```dart
  await Provider.of<OcopProductProvider>(context, listen: false).fetchOcopProducts();
  ```
- This ensures OCOP data is loaded before the user reaches the OCOP product screen.

### 4. Use Provider Data in OCOP Product Screen
- Refactor `OcopProductScreen` to use the provider's data instead of calling the API directly.
- Listen to provider changes for loading state and data.

### 5. Documentation
- Document this data flow and usage in this markdown file for future reference and onboarding.

---

## Benefits
- **No duplicate API calls**: Data is fetched once and reused in the OCOP product screen.
- **Consistency**: The OCOP product screen uses a single data source.
- **Performance**: Reduces network usage and improves app responsiveness.
- **Scalability**: Easy to refresh or update OCOP data globally if needed.

---

## Follow-up
- Ensure the OCOP product screen uses the provider for OCOP data.
- Remove any direct API calls to `OcopProductService().getOcopProduct()` outside the provider.
- Optionally, add error handling and refresh logic to the provider.
- (Map integration can be added in the future as needed.) 