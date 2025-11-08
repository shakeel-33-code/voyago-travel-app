const functions = require("firebase-functions");

// Import the Google Cloud Translate client
const { Translate } = require("@google-cloud/translate").v2;
const translate = new Translate();

/**
 * Mock AI Itinerary Generator
 * 
 * This Cloud Function simulates an AI-powered itinerary generator.
 * In production, this would integrate with real AI services like OpenAI, Gemini, etc.
 * For now, it returns pre-defined mock itineraries based on destination keywords.
 */
exports.generateItinerary = functions.https.onCall((data, context) => {
  // Check if the user is authenticated (security best practice)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to generate an itinerary."
    );
  }

  const prompt = (data.prompt || "").toLowerCase().trim();
  
  if (!prompt || prompt.length < 5) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Please provide a valid prompt (at least 5 characters)."
    );
  }

  console.log(`Generating itinerary for prompt: ${prompt}`);

  // Create base date for the itinerary (tomorrow)
  const baseDate = new Date();
  baseDate.setDate(baseDate.getDate() + 1);
  baseDate.setHours(9, 0, 0, 0); // Start at 9 AM

  let mockItinerary = [];

  // Mock AI logic based on destination keywords
  if (prompt.includes("goa")) {
    mockItinerary = generateGoaItinerary(baseDate);
  } else if (prompt.includes("kerala")) {
    mockItinerary = generateKeralaItinerary(baseDate);
  } else if (prompt.includes("mumbai")) {
    mockItinerary = generateMumbaiItinerary(baseDate);
  } else if (prompt.includes("rajasthan") || prompt.includes("jaipur")) {
    mockItinerary = generateRajasthanItinerary(baseDate);
  } else if (prompt.includes("himachal") || prompt.includes("manali") || prompt.includes("shimla")) {
    mockItinerary = generateHimachalItinerary(baseDate);
  } else if (prompt.includes("bangalore") || prompt.includes("bengaluru")) {
    mockItinerary = generateBangaloreItinerary(baseDate);
  } else {
    // Default generic itinerary
    mockItinerary = generateGenericItinerary(baseDate, prompt);
  }

  console.log(`Generated ${mockItinerary.length} itinerary items`);

  return { itinerary: mockItinerary };
});

/**
 * Generates a Goa-specific itinerary
 */
function generateGoaItinerary(baseDate) {
  return [
    {
      title: "Arrive in Goa & Check-in",
      type: "transport",
      location: "Goa Airport (GOI)",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours
      description: "Airport pickup and hotel check-in",
      notes: "Pre-book airport transfer for convenience"
    },
    {
      title: "Lunch at Britto's",
      type: "dining",
      location: "Baga Beach, North Goa",
      startTime: new Date(baseDate.getTime() + 4 * 60 * 60 * 1000).toISOString(), // 1 PM
      endTime: new Date(baseDate.getTime() + 5 * 60 * 60 * 1000).toISOString(),
      description: "Famous beachside restaurant with fresh seafood",
      notes: "Try the seafood platter and king fish curry"
    },
    {
      title: "Relax at Baga Beach",
      type: "activity",
      location: "Baga Beach, North Goa",
      startTime: new Date(baseDate.getTime() + 6 * 60 * 60 * 1000).toISOString(), // 3 PM
      endTime: new Date(baseDate.getTime() + 9 * 60 * 60 * 1000).toISOString(),
      description: "Beach relaxation and water sports",
      notes: "Perfect time for parasailing and jet skiing"
    },
    {
      title: "Sunset at Anjuna Beach",
      type: "sightseeing",
      location: "Anjuna Beach, North Goa",
      startTime: new Date(baseDate.getTime() + 10 * 60 * 60 * 1000).toISOString(), // 7 PM
      endTime: new Date(baseDate.getTime() + 11 * 60 * 60 * 1000).toISOString(),
      description: "Famous sunset point with hippie culture",
      notes: "Don't miss the Wednesday flea market if visiting on Wednesday"
    }
  ];
}

/**
 * Generates a Kerala-specific itinerary
 */
function generateKeralaItinerary(baseDate) {
  return [
    {
      title: "Backwater Cruise",
      type: "activity",
      location: "Alleppey Backwaters",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 4 * 60 * 60 * 1000).toISOString(),
      description: "Traditional houseboat experience",
      notes: "Book overnight houseboat for full experience"
    },
    {
      title: "Kerala Traditional Lunch",
      type: "dining",
      location: "Local Village Restaurant",
      startTime: new Date(baseDate.getTime() + 5 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 6 * 60 * 60 * 1000).toISOString(),
      description: "Authentic Kerala meal on banana leaf",
      notes: "Try the fish curry and appam"
    },
    {
      title: "Spice Plantation Tour",
      type: "sightseeing",
      location: "Thekkady Spice Gardens",
      startTime: new Date(baseDate.getTime() + 7 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 10 * 60 * 60 * 1000).toISOString(),
      description: "Learn about spice cultivation",
      notes: "Buy fresh spices and tea directly from farmers"
    }
  ];
}

/**
 * Generates a Mumbai-specific itinerary
 */
function generateMumbaiItinerary(baseDate) {
  return [
    {
      title: "Visit Gateway of India",
      type: "sightseeing",
      location: "Colaba, Mumbai",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 2 * 60 * 60 * 1000).toISOString(),
      description: "Iconic Mumbai landmark",
      notes: "Take a boat ride to Elephanta Caves from here"
    },
    {
      title: "Business Lunch Meeting",
      type: "business",
      location: "Nariman Point Business District",
      startTime: new Date(baseDate.getTime() + 4 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 6 * 60 * 60 * 1000).toISOString(),
      description: "Professional meeting at business district",
      notes: "Book conference room in advance"
    },
    {
      title: "Marine Drive Evening Walk",
      type: "activity",
      location: "Marine Drive, Mumbai",
      startTime: new Date(baseDate.getTime() + 8 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 10 * 60 * 60 * 1000).toISOString(),
      description: "Stroll along the Queen's Necklace",
      notes: "Perfect for sunset views and street food"
    }
  ];
}

/**
 * Generates a Rajasthan-specific itinerary
 */
function generateRajasthanItinerary(baseDate) {
  return [
    {
      title: "Amber Fort Visit",
      type: "sightseeing",
      location: "Amber Fort, Jaipur",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 3 * 60 * 60 * 1000).toISOString(),
      description: "Magnificent Rajput fort architecture",
      notes: "Take elephant ride or jeep to reach the fort"
    },
    {
      title: "Royal Rajasthani Lunch",
      type: "dining",
      location: "City Palace Restaurant, Jaipur",
      startTime: new Date(baseDate.getTime() + 4 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 5.5 * 60 * 60 * 1000).toISOString(),
      description: "Traditional Rajasthani thali",
      notes: "Try dal baati churma and gatte ki sabzi"
    },
    {
      title: "Hawa Mahal Photography",
      type: "sightseeing",
      location: "Hawa Mahal, Jaipur",
      startTime: new Date(baseDate.getTime() + 6 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 7.5 * 60 * 60 * 1000).toISOString(),
      description: "Palace of Winds photo session",
      notes: "Best views from the opposite coffee shop"
    },
    {
      title: "Johari Bazaar Shopping",
      type: "shopping",
      location: "Johari Bazaar, Jaipur",
      startTime: new Date(baseDate.getTime() + 8 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 10 * 60 * 60 * 1000).toISOString(),
      description: "Shop for jewelry, textiles, and handicrafts",
      notes: "Bargain for best prices and check gem certificates"
    }
  ];
}

/**
 * Generates a Himachal-specific itinerary
 */
function generateHimachalItinerary(baseDate) {
  return [
    {
      title: "Trek to Triund",
      type: "activity",
      location: "McLeod Ganj, Himachal Pradesh",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 6 * 60 * 60 * 1000).toISOString(),
      description: "Popular trekking destination with mountain views",
      notes: "Carry warm clothes and water. Trek difficulty: Easy to moderate"
    },
    {
      title: "Mountain Cafe Lunch",
      type: "dining",
      location: "Dharamkot Village",
      startTime: new Date(baseDate.getTime() + 7 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 8 * 60 * 60 * 1000).toISOString(),
      description: "Cafe with panoramic mountain views",
      notes: "Try momos and thukpa for authentic mountain food"
    },
    {
      title: "Visit Dalai Lama Temple",
      type: "sightseeing",
      location: "McLeod Ganj, Himachal Pradesh",
      startTime: new Date(baseDate.getTime() + 9 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 10.5 * 60 * 60 * 1000).toISOString(),
      description: "Peaceful Buddhist temple complex",
      notes: "Respect local customs and maintain silence"
    }
  ];
}

/**
 * Generates a Bangalore-specific itinerary
 */
function generateBangaloreItinerary(baseDate) {
  return [
    {
      title: "Cubbon Park Morning Walk",
      type: "activity",
      location: "Cubbon Park, Bangalore",
      startTime: new Date(baseDate).toISOString(),
      endTime: new Date(baseDate.getTime() + 2 * 60 * 60 * 1000).toISOString(),
      description: "Green oasis in the heart of the city",
      notes: "Perfect for jogging and photography"
    },
    {
      title: "South Indian Breakfast",
      type: "dining",
      location: "MTR Restaurant, Bangalore",
      startTime: new Date(baseDate.getTime() + 2.5 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 3.5 * 60 * 60 * 1000).toISOString(),
      description: "Authentic South Indian breakfast",
      notes: "Try masala dosa and filter coffee"
    },
    {
      title: "Bangalore Palace Tour",
      type: "sightseeing",
      location: "Bangalore Palace",
      startTime: new Date(baseDate.getTime() + 5 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 7 * 60 * 60 * 1000).toISOString(),
      description: "Tudor-style architecture palace",
      notes: "Audio guide available for detailed history"
    },
    {
      title: "Microbrewery Dinner",
      type: "dining",
      location: "Koramangala, Bangalore",
      startTime: new Date(baseDate.getTime() + 10 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(baseDate.getTime() + 12 * 60 * 60 * 1000).toISOString(),
      description: "Experience Bangalore's famous brewery culture",
      notes: "Try local craft beers and Continental food"
    }
  ];
}

/**
 * Generates a generic itinerary based on prompt
 */
function generateGenericItinerary(baseDate, prompt) {
  const activities = [
    {
      title: "Explore Local Attractions",
      type: "sightseeing",
      location: "City Center",
      description: "Visit popular landmarks and tourist spots",
      notes: "Research local history and book guided tours"
    },
    {
      title: "Local Cuisine Experience",
      type: "dining",
      location: "Traditional Restaurant",
      description: "Taste authentic local dishes",
      notes: "Ask locals for recommendations"
    },
    {
      title: "Cultural Activity",
      type: "activity",
      location: "Cultural Center",
      description: "Immerse in local culture and traditions",
      notes: "Respect local customs and dress codes"
    },
    {
      title: "Shopping for Souvenirs",
      type: "shopping",
      location: "Local Market",
      description: "Buy unique local handicrafts and souvenirs",
      notes: "Bargain respectfully and check authenticity"
    }
  ];

  // Determine number of days from prompt
  let numDays = 1;
  if (prompt.includes("2 day") || prompt.includes("2-day")) numDays = 2;
  else if (prompt.includes("3 day") || prompt.includes("3-day")) numDays = 3;
  else if (prompt.includes("4 day") || prompt.includes("4-day")) numDays = 4;
  else if (prompt.includes("5 day") || prompt.includes("5-day")) numDays = 5;
  else if (prompt.includes("week")) numDays = 7;

  const itinerary = [];
  for (let day = 0; day < numDays; day++) {
    for (let i = 0; i < Math.min(activities.length, 3); i++) {
      const activity = activities[i];
      const startTime = new Date(baseDate.getTime() + (day * 24 * 60 * 60 * 1000) + (i * 3 * 60 * 60 * 1000));
      const endTime = new Date(startTime.getTime() + 2 * 60 * 60 * 1000);

      itinerary.push({
        title: `Day ${day + 1}: ${activity.title}`,
        type: activity.type,
        location: activity.location,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        description: activity.description,
        notes: activity.notes
      });
    }
  }

  return itinerary;
}

/**
 * Dialogflow Webhook for VoyaGo Chatbot
 * 
 * This function handles webhook requests from Dialogflow for intents that require
 * external processing, particularly translation requests.
 */
exports.dialogflowWebhook = functions.https.onRequest(async (request, response) => {
  try {
    // Set CORS headers
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'GET, POST');
    response.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight OPTIONS request
    if (request.method === 'OPTIONS') {
      response.status(204).send('');
      return;
    }

    console.log('Dialogflow webhook called:', JSON.stringify(request.body, null, 2));

    const intent = request.body.queryResult?.intent?.displayName;
    
    if (intent === "Translate") {
      // Get parameters from Dialogflow
      const text = request.body.queryResult?.parameters?.text;
      const targetLanguage = request.body.queryResult?.parameters?.language;

      console.log(`Translation request: "${text}" to ${targetLanguage}`);

      if (!text || !targetLanguage) {
        response.json({
          fulfillmentText: "Sorry, I need both text to translate and a target language.",
        });
        return;
      }

      // Map language name (e.g., "Spanish") to code (e.g., "es")
      const langCodeMap = {
        "spanish": "es",
        "french": "fr",
        "german": "de",
        "hindi": "hi",
        "italian": "it",
        "portuguese": "pt",
        "russian": "ru",
        "japanese": "ja",
        "korean": "ko",
        "chinese": "zh",
        "arabic": "ar",
        "dutch": "nl",
        "swedish": "sv",
        "norwegian": "no",
        "danish": "da",
        "finnish": "fi",
        "turkish": "tr",
        "thai": "th",
        "vietnamese": "vi",
        "polish": "pl",
        "czech": "cs",
        "hungarian": "hu",
        "greek": "el",
        "hebrew": "he"
      };

      const langCode = langCodeMap[targetLanguage.toLowerCase()] || "en";

      try {
        // Call the Google Translate API
        const [translations] = await translate.translate(text, langCode);
        const translation = Array.isArray(translations) ? translations[0] : translations;

        console.log(`Translation result: "${translation}"`);

        // Send the translation back to Dialogflow
        response.json({
          fulfillmentText: `"${text}" in ${targetLanguage} is: "${translation}"`,
        });
      } catch (error) {
        console.error("TRANSLATION_ERROR:", error);
        response.json({
          fulfillmentText: "Sorry, I couldn't translate that right now. Please try again later.",
        });
      }
    } else if (intent === "Help") {
      // Handle help requests
      response.json({
        fulfillmentText: "I can help you with travel planning, expense tracking, and translating phrases. I can also answer questions about using VoyaGo. What would you like help with?",
      });
    } else {
      // Handle other intents or default
      console.log(`Unhandled intent: ${intent}`);
      response.json({
        fulfillmentText: "I'm here to help with your travel needs! You can ask me for help or ask me to translate phrases to different languages.",
      });
    }
  } catch (error) {
    console.error("Webhook error:", error);
    response.status(500).json({
      fulfillmentText: "Sorry, I encountered an error processing your request.",
    });
  }
});

/**
 * Mock Booking Search Engine
 * 
 * This function simulates a booking search engine for flights, hotels, and buses.
 * In production, this would integrate with real booking APIs like Amadeus, Booking.com, etc.
 */
exports.searchBookings = functions.https.onCall((data, context) => {
  // Check if the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to search bookings."
    );
  }

  const type = data.type; // "flight", "hotel", "bus"
  const query = data.query; // e.g., "Delhi to Goa"

  console.log(`Booking search request: ${type} - ${query}`);

  if (!type || !query) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Both type and query are required for booking search."
    );
  }

  let mockResults = [];

  if (type === "flight") {
    mockResults = [
      {
        id: "FL-101",
        title: "IndiGo 6E-204",
        from: "Delhi (DEL)",
        to: "Goa (GOI)",
        price: 4500.0,
        currency: "INR",
        departureTime: new Date(Date.now() + 86400000 * 2).toISOString(), // 2 days from now
        arrivalTime: new Date(Date.now() + 86400000 * 2 + 7200000).toISOString(), // 2 hours later
        duration: "2h 15m",
        airline: "IndiGo",
        aircraft: "Airbus A320",
        bookingClass: "Economy",
      },
      {
        id: "FL-102",
        title: "Vistara UK-847",
        from: "Delhi (DEL)",
        to: "Goa (GOI)",
        price: 5200.0,
        currency: "INR",
        departureTime: new Date(Date.now() + 86400000 * 2 + 3600000).toISOString(), // 2 days + 1 hour
        arrivalTime: new Date(Date.now() + 86400000 * 2 + 10800000).toISOString(), // 3 hours later
        duration: "2h 30m",
        airline: "Vistara",
        aircraft: "Boeing 737",
        bookingClass: "Premium Economy",
      },
      {
        id: "FL-103",
        title: "SpiceJet SG-8456",
        from: "Delhi (DEL)",
        to: "Goa (GOI)",
        price: 3800.0,
        currency: "INR",
        departureTime: new Date(Date.now() + 86400000 * 3).toISOString(), // 3 days from now
        arrivalTime: new Date(Date.now() + 86400000 * 3 + 8100000).toISOString(), // 2h 15m later
        duration: "2h 15m",
        airline: "SpiceJet",
        aircraft: "Boeing 737",
        bookingClass: "Economy",
      },
    ];
  } else if (type === "hotel") {
    mockResults = [
      {
        id: "HO-101",
        title: "Taj Exotica Resort & Spa",
        location: "Benaulim, Goa",
        pricePerNight: 15000.0,
        currency: "INR",
        checkInDate: new Date(Date.now() + 86400000 * 2).toISOString(),
        checkOutDate: new Date(Date.now() + 86400000 * 5).toISOString(),
        rating: 4.8,
        amenities: ["Wi-Fi", "Pool", "Spa", "Beach Access", "Restaurant"],
        roomType: "Deluxe Sea View Room",
        description: "Luxury beachfront resort with world-class amenities",
      },
      {
        id: "HO-102",
        title: "Grand Hyatt Goa",
        location: "Bambolim, Goa",
        pricePerNight: 12000.0,
        currency: "INR",
        checkInDate: new Date(Date.now() + 86400000 * 2).toISOString(),
        checkOutDate: new Date(Date.now() + 86400000 * 5).toISOString(),
        rating: 4.6,
        amenities: ["Wi-Fi", "Pool", "Gym", "Spa", "Business Center"],
        roomType: "King Room",
        description: "Modern luxury hotel with excellent facilities",
      },
      {
        id: "HO-103",
        title: "The Leela Goa",
        location: "Cavelossim, Goa",
        pricePerNight: 18000.0,
        currency: "INR",
        checkInDate: new Date(Date.now() + 86400000 * 2).toISOString(),
        checkOutDate: new Date(Date.now() + 86400000 * 5).toISOString(),
        rating: 4.9,
        amenities: ["Wi-Fi", "Pool", "Spa", "Golf Course", "Beach Access", "Fine Dining"],
        roomType: "Premier Room",
        description: "Ultra-luxury resort with pristine beach and premium services",
      },
    ];
  } else if (type === "bus") {
    mockResults = [
      {
        id: "BU-101",
        title: "Volvo A/C Sleeper",
        from: "Delhi",
        to: "Goa",
        price: 1200.0,
        currency: "INR",
        departureTime: new Date(Date.now() + 86400000 * 1).toISOString(), // 1 day from now
        arrivalTime: new Date(Date.now() + 86400000 * 1 + 43200000).toISOString(), // 12 hours later
        duration: "12h 30m",
        operator: "RedBus",
        busType: "A/C Sleeper",
        amenities: ["Wi-Fi", "Charging Point", "Entertainment", "Blanket"],
      },
      {
        id: "BU-102",
        title: "Mercedes Multi-Axle",
        from: "Delhi",
        to: "Goa",
        price: 1500.0,
        currency: "INR",
        departureTime: new Date(Date.now() + 86400000 * 1 + 3600000).toISOString(), // 1 day + 1 hour
        arrivalTime: new Date(Date.now() + 86400000 * 1 + 39600000).toISOString(), // 11 hours later
        duration: "11h 45m",
        operator: "Travels India",
        busType: "A/C Semi-Sleeper",
        amenities: ["Wi-Fi", "Charging Point", "Water Bottle", "Snacks"],
      },
    ];
  } else {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid booking type. Supported types: flight, hotel, bus"
    );
  }

  console.log(`Returning ${mockResults.length} results for ${type} search`);

  return { 
    results: mockResults,
    searchQuery: query,
    searchType: type,
    timestamp: new Date().toISOString()
  };
});