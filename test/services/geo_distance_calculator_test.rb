# frozen_string_literal: true

require "test_helper"

class GeoDistanceCalculatorTest < ActiveSupport::TestCase
  # Test case 1: New York to London
  # Known distance: approximately 5,570 km
  test "calculates distance from New York to London" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 40.7128, longitude: -74.0060 },
      point2: { latitude: 51.5074, longitude: -0.1278 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_in_delta 5570, result[:surface_distance_km], 10 # Within 10 km
  end

  # Test case 2: Sydney to Tokyo
  # Known distance: approximately 7,823 km
  test "calculates distance from Sydney to Tokyo" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: -33.8688, longitude: 151.2093 },
      point2: { latitude: 35.6762, longitude: 139.6503 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_in_delta 7823, result[:surface_distance_km], 15
  end

  # Test case 3: Same point (zero distance)
  test "returns zero for same coordinates" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 40.7128, longitude: -74.0060 },
      point2: { latitude: 40.7128, longitude: -74.0060 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_equal 0.0, result[:surface_distance]
  end

  # Test case 4: Antipodal points
  test "handles antipodal points" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 0, longitude: 0 },
      point2: { latitude: 0, longitude: 180 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    # Half Earth circumference ≈ 20,000 km
    assert_in_delta 20000, result[:surface_distance_km], 100
  end

  # Test case 5: Altitude difference
  test "calculates total distance with altitude" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 40.7128, longitude: -74.0060, altitude: 0 },
      point2: { latitude: 40.7128, longitude: -74.0060, altitude: 1000 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_equal 1000, result[:altitude_difference]
    assert_in_delta 1000, result[:total_distance], 1
  end

  # Test case 6: Invalid latitude
  test "rejects invalid latitude" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 100, longitude: -74.0060 },
      point2: { latitude: 51.5074, longitude: -0.1278 }
    )
    
    result = calculator.calculate
    
    assert_equal false, result[:success]
    assert_includes result[:errors].first, "latitude"
  end

  # Test case 7: Invalid longitude
  test "rejects invalid longitude" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 40.7128, longitude: -200 },
      point2: { latitude: 51.5074, longitude: -0.1278 }
    )
    
    result = calculator.calculate
    
    assert_equal false, result[:success]
    assert_includes result[:errors].first, "longitude"
  end

  # Test case 8: Bearing calculation
  test "calculates correct bearing" do
    # North Pole to Equator on prime meridian
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 90, longitude: 0 },
      point2: { latitude: 0, longitude: 0 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    # Bearing from North Pole going south should be 180°
    assert_in_delta 180, result[:initial_bearing], 1
  end

  # Test case 9: Short distance (local)
  test "calculates short distances accurately" do
    # Approximately 1 km apart
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 51.5074, longitude: -0.1278 },
      point2: { latitude: 51.5164, longitude: -0.1278 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_in_delta 1, result[:surface_distance_km], 0.1
  end

  # Test case 10: Returns all expected fields
  test "returns all expected result fields" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 40.7128, longitude: -74.0060, altitude: 100 },
      point2: { latitude: 51.5074, longitude: -0.1278, altitude: 200 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert result.key?(:surface_distance)
    assert result.key?(:surface_distance_km)
    assert result.key?(:surface_distance_miles)
    assert result.key?(:surface_distance_nautical_miles)
    assert result.key?(:total_distance)
    assert result.key?(:total_distance_km)
    assert result.key?(:total_distance_miles)
    assert result.key?(:altitude_difference)
    assert result.key?(:initial_bearing)
    assert result.key?(:final_bearing)
    assert result.key?(:point1)
    assert result.key?(:point2)
  end

  # Test case 11: Mt. Everest to Dead Sea (extreme altitudes)
  test "handles extreme altitude differences" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 27.9881, longitude: 86.9250, altitude: 8848 },   # Mt. Everest
      point2: { latitude: 31.5000, longitude: 35.5000, altitude: -430 }   # Dead Sea
    )
    
    result = calculator.calculate
    
    assert result[:success]
    assert_equal 9278, result[:altitude_difference].round  # 8848 - (-430)
  end

  # Test case 12: Cross-equator calculation
  test "calculates distance crossing equator" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 10, longitude: 0 },
      point2: { latitude: -10, longitude: 0 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    # 20 degrees of latitude ≈ 2,222 km
    assert_in_delta 2222, result[:surface_distance_km], 10
  end

  # Test case 13: Conversion accuracy
  test "unit conversions are accurate" do
    calculator = GeoDistanceCalculator.new(
      point1: { latitude: 0, longitude: 0 },
      point2: { latitude: 0, longitude: 1 }
    )
    
    result = calculator.calculate
    
    assert result[:success]
    
    # Verify conversions
    expected_miles = result[:surface_distance] / 1609.344
    expected_nm = result[:surface_distance] / 1852.0
    
    assert_in_delta expected_miles, result[:surface_distance_miles], 0.001
    assert_in_delta expected_nm, result[:surface_distance_nautical_miles], 0.001
  end
end
