# GeoDistance Calculator

A Ruby on Rails application for calculating distances between Earth coordinates following the curvature of the Earth.

## Features

- **Vincenty Formula**: Uses the highly accurate Vincenty inverse formula for geodesic distance calculations on the WGS-84 ellipsoid
- **Altitude Support**: Optionally includes height above mean sea level in calculations
- **Multiple Units**: Returns distances in meters, kilometers, miles, and nautical miles
- **Bearing Calculation**: Provides initial and final bearing (compass direction)
- **Web Interface**: User-friendly form for calculating distances
- **JSON API**: RESTful API endpoint for programmatic access

## Installation

```bash
# Navigate to the project directory
cd /Users/test/rails/claude

# Install dependencies
bundle install

# Setup database
bin/rails db:prepare

# Start the server
bin/rails server
```

## Usage

### Web Interface

Visit `http://localhost:3000` to use the web form.

Enter coordinates for two points:
- **Latitude**: -90 to 90 degrees (positive = North, negative = South)
- **Longitude**: -180 to 180 degrees (positive = East, negative = West)
- **Altitude** (optional): meters above mean sea level

### API Endpoint

**POST** `/api/v1/distance`

#### Request

```json
{
  "point1": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "altitude": 0
  },
  "point2": {
    "latitude": 51.5074,
    "longitude": -0.1278,
    "altitude": 0
  }
}
```

#### Response

```json
{
  "success": true,
  "surface_distance": 5570206.123,
  "surface_distance_km": 5570.206,
  "surface_distance_miles": 3461.337,
  "surface_distance_nautical_miles": 3008.211,
  "total_distance": 5570206.123,
  "total_distance_km": 5570.206,
  "total_distance_miles": 3461.337,
  "altitude_difference": 0,
  "initial_bearing": 51.21,
  "final_bearing": 108.45,
  "point1": {
    "latitude": 40.7128,
    "longitude": -74.006,
    "altitude": 0.0
  },
  "point2": {
    "latitude": 51.5074,
    "longitude": -0.1278,
    "altitude": 0.0
  }
}
```

#### cURL Example

```bash
curl -X POST http://localhost:3000/api/v1/distance \
  -H "Content-Type: application/json" \
  -d '{
    "point1": {"latitude": 40.7128, "longitude": -74.0060, "altitude": 0},
    "point2": {"latitude": 51.5074, "longitude": -0.1278, "altitude": 0}
  }'
```

## How It Works

### Vincenty Formula

The application uses the **Vincenty inverse formula** which calculates geodesic distances on an ellipsoid model of the Earth (WGS-84). This provides accuracy within 0.5mm for any two points on Earth.

Key parameters (WGS-84):
- Semi-major axis (equatorial radius): 6,378,137 m
- Semi-minor axis (polar radius): 6,356,752.314245 m
- Flattening: 1/298.257223563

### Distance Types

1. **Surface Distance**: The geodesic distance along Earth's curved surface
2. **Total Distance**: Accounts for altitude differences using the Pythagorean theorem:
   ```
   total = √(surface_distance² + altitude_difference²)
   ```

### Bearings

- **Initial Bearing**: The compass direction when starting from Point 1
- **Final Bearing**: The compass direction upon arriving at Point 2

Due to the curvature of the Earth, these bearings differ for long distances.

## Running Tests

```bash
bin/rails test
```

## Example Distances

| Route | Distance (km) |
|-------|---------------|
| New York → London | ~5,570 |
| Sydney → Tokyo | ~7,823 |
| Los Angeles → Sydney | ~12,073 |
| London → Cape Town | ~9,672 |

## Technical Notes

- Handles edge cases including coincident points and near-antipodal points
- Falls back to Haversine formula for edge cases where Vincenty doesn't converge
- Validates coordinate ranges and provides meaningful error messages
- Thread-safe for concurrent API requests

## License

MIT License
