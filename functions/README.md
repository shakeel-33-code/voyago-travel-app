# VoyaGo Cloud Functions

This directory contains the Firebase Cloud Functions for the VoyaGo travel app.

## Functions

### `generateItinerary`
- **Type**: HTTP Callable
- **Purpose**: Generates mock AI-powered itinerary suggestions
- **Authentication**: Required
- **Input**: 
  ```javascript
  {
    prompt: "3 days in Goa, beach activities"
  }
  ```
- **Output**:
  ```javascript
  {
    itinerary: [
      {
        title: "Activity Title",
        type: "activity|dining|transport|sightseeing|etc",
        location: "Location Name",
        startTime: "2024-01-01T09:00:00.000Z",
        endTime: "2024-01-01T11:00:00.000Z",
        description: "Activity description",
        notes: "Additional notes"
      }
    ]
  }
  ```

## Supported Destinations

The mock AI currently has specialized itineraries for:
- **Goa**: Beach activities, seafood, water sports
- **Kerala**: Backwaters, spice plantations, traditional cuisine
- **Mumbai**: Business trips, iconic landmarks, city experiences
- **Rajasthan/Jaipur**: Heritage tours, forts, traditional culture
- **Himachal Pradesh**: Mountain treks, Buddhist temples, adventure
- **Bangalore**: Tech city culture, parks, microbreweries
- **Generic**: Falls back to general activities for any destination

## Setup Instructions

1. **Install Dependencies**:
   ```bash
   cd functions
   npm install
   ```

2. **Deploy Functions**:
   ```bash
   firebase deploy --only functions
   ```

3. **Local Development**:
   ```bash
   npm run serve
   ```

4. **View Logs**:
   ```bash
   npm run logs
   ```

## Development Notes

- This is a **mock AI implementation** for demonstration purposes
- In production, replace with real AI services (OpenAI, Google Gemini, etc.)
- All dates are returned in ISO 8601 format for easy parsing
- Function includes authentication checks for security
- Error handling follows Firebase Functions best practices

## Future Enhancements

- [ ] Integrate with real AI services
- [ ] Add budget-based filtering
- [ ] Include weather-based suggestions
- [ ] Add hotel and flight booking integration
- [ ] Implement user preference learning