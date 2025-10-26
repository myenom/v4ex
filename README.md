# V2EX iOS Client

A native iOS client for V2EX forum built with SwiftUI, featuring a modern design and comprehensive functionality.

## Features

### Core Functionality
- **Authentication** - Secure token-based authentication using V2EX Personal Access Tokens
- **Home Feed** - Browse latest and hot topics with pull-to-refresh
- **Topic Details** - View full topic content with replies
- **Node Browsing** - Explore all V2EX nodes with search capability
- **Notifications** - Real-time notification management with swipe-to-delete
- **User Profile** - View member profiles and manage account

### Data Persistence
- **Favorites** - Save and manage favorite topics (stored in Supabase)
- **Reading History** - Track read topics automatically (stored in Supabase)
- **Node Subscriptions** - Subscribe to favorite nodes (stored in Supabase)
- **Theme Preferences** - Save theme settings (stored locally)

### User Experience
- **Dark Mode** - Full dark mode support with system theme option
- **Smooth Animations** - Native iOS animations and transitions
- **Skeleton Loading** - Beautiful loading states for all content
- **Error Handling** - Graceful error recovery with retry options
- **Sharing** - Share topics via native iOS share sheet
- **Responsive Design** - Optimized for all iOS devices

## Architecture

### Project Structure
```
V2EX/
├── V2EXApp.swift           # App entry point
├── Models/
│   ├── AppState.swift      # Global app state management
│   └── V2EXModels.swift    # Data models for API responses
├── Services/
│   ├── V2EXAPIService.swift    # V2EX API client
│   └── SupabaseService.swift   # Supabase data persistence
├── Views/
│   ├── AuthenticationView.swift    # Login screen
│   ├── MainTabView.swift           # Tab bar navigation
│   ├── HomeView.swift              # Home feed
│   ├── TopicDetailView.swift      # Topic details
│   ├── NodesView.swift             # Node browsing
│   ├── NodeDetailView.swift       # Node topics
│   ├── NotificationsView.swift    # Notifications
│   ├── ProfileView.swift          # User profile
│   └── SettingsView.swift         # App settings
└── Utilities/
    └── KeychainHelper.swift    # Secure token storage
```

### Technologies Used
- **SwiftUI** - Modern declarative UI framework
- **Async/Await** - Modern Swift concurrency
- **URLSession** - Native HTTP networking
- **Keychain** - Secure credential storage
- **Supabase** - Backend database for user data
- **Combine** - Reactive state management

## Setup Instructions

### Prerequisites
1. Xcode 15.0 or later
2. iOS 16.0 or later
3. V2EX account with Personal Access Token
4. Supabase project (already configured)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd project
   ```

2. **Open in Xcode**
   ```bash
   open V2EX.xcodeproj
   ```

3. **Get V2EX Access Token**
   - Visit https://v2ex.com/settings/tokens
   - Create a new token with appropriate scope
   - Save the token securely

4. **Configure Supabase** (Already done)
   - Database schema is already created
   - Connection details are in `.env` file

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### First Time Usage

1. Launch the app
2. Enter your V2EX Personal Access Token
3. Tap "Sign In"
4. Start browsing topics and nodes

## V2EX API Integration

This app uses both V2EX API versions:

### API v1 (Public endpoints)
- Latest topics
- Hot topics
- All nodes list

### API v2 (Authenticated endpoints)
- User profile
- Notifications
- Node details
- Topic details and replies

### Rate Limits
- V2EX API v1: No authentication required
- V2EX API v2: 120 requests per hour with authentication

## Database Schema

### Supabase Tables

**user_preferences**
- Stores theme and app settings
- Fields: user_id, theme_mode

**favorites**
- Stores favorited topics
- Fields: user_id, topic_id, topic_title, topic_url, node_name

**reading_history**
- Tracks read topics
- Fields: user_id, topic_id, topic_title, last_read_at

**node_subscriptions**
- Stores subscribed nodes
- Fields: user_id, node_id, node_name, node_title

All tables have Row Level Security (RLS) enabled for data protection.

## Key Features Implementation

### Authentication Flow
1. User enters V2EX Personal Access Token
2. Token validated by fetching user profile
3. Token stored securely in iOS Keychain
4. Auto-login on subsequent launches

### Data Synchronization
- Favorites synced to Supabase on add/remove
- Reading history tracked automatically on topic view
- Node subscriptions persist across devices
- Theme preferences saved locally for instant load

### Offline Support
- Token stored locally for offline authentication
- Cached images for better performance
- Graceful degradation when network unavailable

## Design Principles

### UI/UX
- Native iOS design patterns
- Consistent spacing and typography
- Smooth animations and transitions
- Contextual actions (swipe gestures)
- Pull-to-refresh on all lists

### Performance
- Lazy loading for long lists
- Image caching with AsyncImage
- Pagination for large data sets
- Efficient state management

### Security
- Secure token storage in Keychain
- HTTPS for all API calls
- RLS policies on all database tables
- No hardcoded credentials

## Future Enhancements

- [ ] Topic posting and reply composition
- [ ] Rich text editor for content
- [ ] Image upload support
- [ ] Push notifications
- [ ] Widget support
- [ ] iPad optimization
- [ ] Localization (Chinese/English)
- [ ] Deep linking
- [ ] Search functionality
- [ ] User blocking/muting

## API Reference

### V2EX API Documentation
- Official API: https://v2ex.com/help/api
- Base URL: https://www.v2ex.com/api/v2

### Supabase Integration
- Connection configured via environment variables
- REST API for data operations
- Row Level Security for data protection

## Contributing

Contributions are welcome! Please ensure:
- Code follows Swift best practices
- UI matches iOS design guidelines
- All features are tested on multiple devices
- Documentation is updated

## License

This project is created for educational purposes and is not affiliated with V2EX.

## Credits

- V2EX API by V2EX.com
- Reference implementation: react-native-v2ex
- Icons: SF Symbols
- Backend: Supabase

## Support

For issues or questions:
1. Check V2EX API documentation
2. Review Supabase setup
3. Verify token validity at https://v2ex.com/settings/tokens

---

Built with SwiftUI for iOS 16+
