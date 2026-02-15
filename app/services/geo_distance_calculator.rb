# frozen_string_literal: true

# GeoDistanceCalculator - Calculates distances between Earth coordinates
# following the curvature of the Earth using the Vincenty formula.
#
# The Vincenty formula is highly accurate for calculating geodesic distances
# on an ellipsoid model of the Earth (WGS-84).
#
# Usage:
#   calculator = GeoDistanceCalculator.new(
#     point1: { latitude: 40.7128, longitude: -74.0060, altitude: 0 },
#     point2: { latitude: 51.5074, longitude: -0.1278, altitude: 0 }
#   )
#   result = calculator.calculate
#
class GeoDistanceCalculator
  # WGS-84 ellipsoid parameters (meters)
  SEMI_MAJOR_AXIS = 6_378_137.0          # Equatorial radius (a)
  SEMI_MINOR_AXIS = 6_356_752.314245     # Polar radius (b)
  FLATTENING = 1 / 298.257223563         # Flattening (f)

  # Convergence threshold for iterative calculation
  CONVERGENCE_THRESHOLD = 1e-12
  MAX_ITERATIONS = 200

  attr_reader :point1, :point2, :errors

  # Initialize with two geographic coordinates
  #
  # @param point1 [Hash] First coordinate with :latitude, :longitude, :altitude (optional)
  # @param point2 [Hash] Second coordinate with :latitude, :longitude, :altitude (optional)
  #
  # Latitude: -90 to 90 degrees (positive = North, negative = South)
  # Longitude: -180 to 180 degrees (positive = East, negative = West)
  # Altitude: meters above mean sea level (default: 0)
  #
  def initialize(point1:, point2:)
    @point1 = normalize_point(point1)
    @point2 = normalize_point(point2)
    @errors = []
    validate_coordinates!
  end

  # Calculate the distance between the two points
  #
  # @return [Hash] Result containing:
  #   - surface_distance: Distance along Earth's surface (meters)
  #   - straight_line_distance: Direct distance through Earth (meters)
  #   - total_distance: Distance accounting for altitude changes (meters)
  #   - initial_bearing: Initial bearing from point1 to point2 (degrees)
  #   - final_bearing: Final bearing at point2 (degrees)
  #   - altitude_difference: Difference in altitude (meters)
  #
  def calculate
    return { success: false, errors: @errors } if @errors.any?

    vincenty_result = vincenty_inverse

    return vincenty_result if vincenty_result[:success] == false

    altitude_diff = @point2[:altitude] - @point1[:altitude]
    
    # Total distance accounting for altitude difference
    # Uses Pythagorean theorem with surface distance and altitude difference
    total_distance = Math.sqrt(vincenty_result[:surface_distance]**2 + altitude_diff**2)

    {
      success: true,
      surface_distance: vincenty_result[:surface_distance],
      surface_distance_km: vincenty_result[:surface_distance] / 1000.0,
      surface_distance_miles: vincenty_result[:surface_distance] / 1609.344,
      surface_distance_nautical_miles: vincenty_result[:surface_distance] / 1852.0,
      total_distance: total_distance,
      total_distance_km: total_distance / 1000.0,
      total_distance_miles: total_distance / 1609.344,
      altitude_difference: altitude_diff,
      initial_bearing: vincenty_result[:initial_bearing],
      final_bearing: vincenty_result[:final_bearing],
      point1: @point1,
      point2: @point2
    }
  end

  # Check if calculation is valid
  def valid?
    @errors.empty?
  end

  private

  # Normalize point data with defaults
  def normalize_point(point)
    {
      latitude: point[:latitude].to_f,
      longitude: point[:longitude].to_f,
      altitude: (point[:altitude] || point[:height] || 0).to_f
    }
  end

  # Validate coordinate ranges
  def validate_coordinates!
    validate_point(@point1, "Point 1")
    validate_point(@point2, "Point 2")
  end

  def validate_point(point, name)
    lat = point[:latitude]
    lon = point[:longitude]
    alt = point[:altitude]

    if lat < -90 || lat > 90
      @errors << "#{name} latitude must be between -90 and 90 degrees (got #{lat})"
    end

    if lon < -180 || lon > 180
      @errors << "#{name} longitude must be between -180 and 180 degrees (got #{lon})"
    end

    if alt < -500 # Below Dead Sea level
      @errors << "#{name} altitude seems too low: #{alt} meters"
    end

    if alt > 100_000 # Above Karman line
      @errors << "#{name} altitude exceeds Earth-based limits: #{alt} meters"
    end
  end

  # Convert degrees to radians
  def to_radians(degrees)
    degrees * Math::PI / 180.0
  end

  # Convert radians to degrees
  def to_degrees(radians)
    radians * 180.0 / Math::PI
  end

  # Vincenty inverse formula for calculating geodesic distance
  # between two points on an ellipsoid
  #
  # @return [Hash] Distance and bearing information
  #
  def vincenty_inverse
    lat1 = to_radians(@point1[:latitude])
    lon1 = to_radians(@point1[:longitude])
    lat2 = to_radians(@point2[:latitude])
    lon2 = to_radians(@point2[:longitude])

    # Check for coincident points
    if (lat1 - lat2).abs < 1e-12 && (lon1 - lon2).abs < 1e-12
      return {
        success: true,
        surface_distance: 0.0,
        initial_bearing: 0.0,
        final_bearing: 0.0
      }
    end

    # Reduced latitudes (latitude on the auxiliary sphere)
    u1 = Math.atan((1 - FLATTENING) * Math.tan(lat1))
    u2 = Math.atan((1 - FLATTENING) * Math.tan(lat2))

    sin_u1 = Math.sin(u1)
    cos_u1 = Math.cos(u1)
    sin_u2 = Math.sin(u2)
    cos_u2 = Math.cos(u2)

    # Difference in longitude
    lon_diff = lon2 - lon1
    lambda_prev = lon_diff
    lambda_curr = lon_diff

    # Iterative calculation
    iteration = 0
    converged = false

    sin_sigma = cos_sigma = sigma = sin_alpha = cos_sq_alpha = cos_2sigma_m = nil

    while iteration < MAX_ITERATIONS
      sin_lambda = Math.sin(lambda_curr)
      cos_lambda = Math.cos(lambda_curr)

      sin_sigma = Math.sqrt(
        (cos_u2 * sin_lambda)**2 +
        (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lambda)**2
      )

      # Check for antipodal points
      if sin_sigma.abs < 1e-12
        return {
          success: true,
          surface_distance: 0.0,
          initial_bearing: 0.0,
          final_bearing: 0.0
        }
      end

      cos_sigma = sin_u1 * sin_u2 + cos_u1 * cos_u2 * cos_lambda
      sigma = Math.atan2(sin_sigma, cos_sigma)

      sin_alpha = cos_u1 * cos_u2 * sin_lambda / sin_sigma
      cos_sq_alpha = 1 - sin_alpha**2

      # Equatorial line case
      if cos_sq_alpha.abs < 1e-12
        cos_2sigma_m = 0
      else
        cos_2sigma_m = cos_sigma - 2 * sin_u1 * sin_u2 / cos_sq_alpha
      end

      c = FLATTENING / 16 * cos_sq_alpha * (4 + FLATTENING * (4 - 3 * cos_sq_alpha))

      lambda_prev = lambda_curr
      lambda_curr = lon_diff + (1 - c) * FLATTENING * sin_alpha * (
        sigma + c * sin_sigma * (
          cos_2sigma_m + c * cos_sigma * (-1 + 2 * cos_2sigma_m**2)
        )
      )

      # Check for convergence
      if (lambda_curr - lambda_prev).abs < CONVERGENCE_THRESHOLD
        converged = true
        break
      end

      iteration += 1
    end

    unless converged
      # Fall back to haversine for near-antipodal points
      return haversine_fallback
    end

    # Calculate distance
    u_sq = cos_sq_alpha * (SEMI_MAJOR_AXIS**2 - SEMI_MINOR_AXIS**2) / SEMI_MINOR_AXIS**2

    a_coeff = 1 + u_sq / 16384 * (4096 + u_sq * (-768 + u_sq * (320 - 175 * u_sq)))
    b_coeff = u_sq / 1024 * (256 + u_sq * (-128 + u_sq * (74 - 47 * u_sq)))

    delta_sigma = b_coeff * sin_sigma * (
      cos_2sigma_m + b_coeff / 4 * (
        cos_sigma * (-1 + 2 * cos_2sigma_m**2) -
        b_coeff / 6 * cos_2sigma_m * (-3 + 4 * sin_sigma**2) * (-3 + 4 * cos_2sigma_m**2)
      )
    )

    distance = SEMI_MINOR_AXIS * a_coeff * (sigma - delta_sigma)

    # Calculate bearings
    initial_bearing = calculate_bearing(
      cos_u2, Math.sin(lambda_curr),
      cos_u1 * sin_u2 - sin_u1 * cos_u2 * Math.cos(lambda_curr)
    )

    final_bearing = calculate_bearing(
      cos_u1, -Math.sin(lambda_curr),
      sin_u1 * cos_u2 - cos_u1 * sin_u2 * Math.cos(lambda_curr)
    )

    {
      success: true,
      surface_distance: distance,
      initial_bearing: initial_bearing,
      final_bearing: final_bearing
    }
  end

  # Calculate bearing from components
  def calculate_bearing(cos_term, sin_lambda, diff_term)
    bearing = to_degrees(Math.atan2(cos_term * sin_lambda, diff_term))
    (bearing + 360) % 360
  end

  # Haversine formula fallback for edge cases
  def haversine_fallback
    lat1 = to_radians(@point1[:latitude])
    lon1 = to_radians(@point1[:longitude])
    lat2 = to_radians(@point2[:latitude])
    lon2 = to_radians(@point2[:longitude])

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = Math.sin(dlat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    # Use mean radius for haversine
    mean_radius = 6_371_008.8
    distance = mean_radius * c

    # Calculate initial bearing
    y = Math.sin(dlon) * Math.cos(lat2)
    x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dlon)
    initial_bearing = (to_degrees(Math.atan2(y, x)) + 360) % 360

    {
      success: true,
      surface_distance: distance,
      initial_bearing: initial_bearing,
      final_bearing: (initial_bearing + 180) % 360,
      method: :haversine_fallback
    }
  end
end
