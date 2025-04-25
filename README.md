# Kotha Vada - Room Finder App

Kotha Vada is a comprehensive room finder mobile application that facilitates users in finding available rooms for rent and allows users to list their own rooms. The app is built with Flutter for the frontend and Supabase for the backend, with integration of OpenStreetMap for displaying room locations and providing navigation.

## Features

- **User Authentication**: Secure user registration and login using Supabase authentication.
- **Room Listing and Management**: Add, edit, and delete room listings with details like price, amenities, and location.
- **Map-Based Search**: Find rooms on an interactive map with filtering options.
- **Room Details**: View comprehensive details of rooms including images, amenities, and contact information.
- **Notification System**: Receive notifications about room interests and new listings.
- **Profile Management**: Update user profile information.

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Supabase
- **State Management**: Bloc/Cubit
- **Dependency Injection**: GetIt
- **Maps**: OpenStreetMap via flutter_map
- **Location Services**: Geolocator and Geocoding

## Getting Started

### Prerequisites

- Flutter SDK (version 3.7.2 or higher)
- Dart SDK (version 3.0.0 or higher)
- A Supabase account

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/kothavada.git
   cd kothavada
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Supabase:
   - Follow the instructions in the `SUPABASE_SETUP.md` file to create and configure your Supabase project.
   - Create a `.env` file in the project root with your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── di/
│   ├── errors/
│   ├── network/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── cubits/
└── main.dart
```

## Database Schema

The app uses the following Supabase tables:

- **users**: Stores user profile information
- **rooms**: Stores room listings with details
- **notifications**: Stores user notifications

For detailed schema information, refer to the `supabase_tables_setup.sql` file.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Supabase](https://supabase.io/)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [flutter_map](https://pub.dev/packages/flutter_map)
- [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [get_it](https://pub.dev/packages/get_it)
