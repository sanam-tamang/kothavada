Develop a comprehensive room finder mobile application named "Kotha Vada". The application should facilitate users in finding available rooms for rent and also allow users to list their own rooms. The core technologies to be used are Flutter for the frontend and Supabase for the backend. A key requirement is the integration of a free map API (alternative to Google Maps) for displaying room locations and providing navigation.

Here is a detailed breakdown of the requirements:

**Project Name:** Kotha Vada

**Technology Stack:**
* **Frontend:** Flutter (targeting both Android and iOS)
* **Backend:** Supabase (for database, authentication, and potentially real-time features for notifications)
* **Mapping:** A free and open-source map API (e.g., OpenStreetMap via a suitable Flutter library) that supports displaying markers and providing navigation capabilities. **Absolutely no paid map APIs like Google Maps.**

**Core Features:**
IMPORTANT:
user cubit state management and proper folder structure mcv user getit for dependency injection 

1.  **User Authentication (Supabase):**
    * Implement secure user registration (e.g., email/password, potentially social logins if Supabase supports them easily).
    * Implement user login and logout functionality.
    * Manage user sessions.

2.  **Room Listing and Management:**
    * **Add New Room:** Authenticated users should be able to add details of a room they want to list. This includes:
        * Room Title/Description
        * Address
        * Rental Price
        * Number of Bedrooms/Bathrooms
        * Amenities (e.g., Wi-Fi, parking, furniture - could be a simple text field or checkboxes)
        * Contact Information (phone number, email)
        * **Location:** Allow users to specify the location of the room. This can be done by:
            * Dragging a pin on a map interface (using the free map API).
            * Entering an address that gets geocoded to coordinates (requires a free geocoding service compatible with the chosen map API). Storing latitude and longitude is essential.
        * Upload Images of the room.
    * **View My Listings:** Users should be able to see a list of the rooms they have added.
    * **Edit/Delete Room:** Users should be able to modify or remove their listed rooms.

3.  **Room Discovery (Map-Based Search):**
    * **Interactive Map:** Display a map interface (using the free map API) that shows the user's current location (with permission) and markers representing the available rooms in the visible map area.
    * **Display Room Information on Map:** Tapping on a room marker should display a brief overview of the room (e.g., title, price). A further tap should lead to a detailed room view.
    * **Search/Filter (Optional but Recommended):** Allow users to search for rooms based on criteria like location (city, neighborhood), price range, number of bedrooms, etc. The map view should update based on the search results.
    * **Navigation:** Provide an option to get directions from the user's current location to the selected room's location using the free map API or a compatible navigation service.

4.  **Room Details View:**
    * Display comprehensive details of a selected room, including all information entered by the lister.
    * Show a gallery of room images.
    * Include a button or option to contact the lister (e.g., via phone or email).
    * Display the room's location on a small map snippet.

5.  **Notification System (Supabase):**
    * Implement a basic notification system. Examples:
        * Notify room listers when someone shows interest (e.g., views their listing multiple times, though this might require more complex tracking).
        * Notify users about new room listings in areas they have previously searched or shown interest in.
        * Supabase's real-time features or functions could be used to trigger and manage these notifications. Consider how notifications will be delivered (in-app, push notifications - push notifications might require additional setup beyond basic Supabase). Focus initially on in-app notifications if push is complex with the free tools.

**Technical Considerations:**

* **Free Map API Integration:** Research and select a suitable free map library/API for Flutter (e.g., `flutter_map` with OpenStreetMap). Ensure it supports:
    * Displaying map tiles.
    * Adding custom markers with location coordinates.
    * Getting the user's current location.
    * Generating routes/providing navigation links.
    * Geocoding (converting addresses to coordinates) and Reverse Geocoding (converting coordinates to addresses) if needed for the "Add Room" feature. Find a free service compatible with the chosen map API.
* **Supabase Integration:**
    * Set up Supabase tables for users and rooms. The rooms table must include columns for latitude and longitude.
    * Implement row level security in Supabase to protect user data and room listings.
    * Utilize Supabase Authentication for user management.
    * Use Supabase client library for Flutter to interact with the backend.
    * Explore Supabase Functions or Realtime for implementing the notification logic.
* **Location Permissions:** Handle requesting and managing location permissions from the user.
* **Image Storage:** Use Supabase Storage to store room images.

**Deliverables:**

* Well-structured Flutter project code.
* Clear instructions on setting up the Supabase backend (table schemas, authentication configuration, any functions/realtime setup).
* Code for integrating the chosen free map API.
* Code implementing all the core features listed above.
* Basic documentation on how to run the application.

**Constraint Checklist:**

* Use Flutter for frontend? Yes.
* Use Supabase for backend? Yes.
* Implement User Authentication? Yes.
* Implement Room Listing/Adding? Yes.
* Rooms include Location (coordinates)? Yes.
* Use a FREE map API? Yes (Specify which one was chosen).
* Display Rooms on a Map? Yes.
* Allow Navigation to Rooms? Yes (Using the free map API/service).
* Implement a Notification System? Yes (Using Supabase capabilities).
* Avoid using Google Maps API? Yes.

Ensure the code is clean, modular, and follows good programming practices. Prioritize functionality and the use of the specified free technologies.

