# Mock API

Local JSON server providing event data for the LocalEventsExplorer app.

## Setup

```bash
npm install
```

## Usage

```bash
# Generate seed data
node seed.js

# Start the server on port 3001
npm start
```

## Endpoints

- `GET /events` - List all events
- `GET /events/:id` - Get a single event by ID

## Data Shape

Each event object:

```json
{
  "id": "1",
  "title": "Jazz Night at The Aeolian",
  "description": "Live quartet, doors at 7pm.",
  "venueName": "Aeolian Hall",
  "latitude": 42.9849,
  "longitude": -81.2453,
  "startTime": "2026-03-15T19:00:00Z",
  "imageUrl": "https://picsum.photos/seed/1/600/400"
}
```
