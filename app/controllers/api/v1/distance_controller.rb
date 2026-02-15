# frozen_string_literal: true

module Api
  module V1
    class DistanceController < ApplicationController
      skip_before_action :verify_authenticity_token

      # POST /api/v1/distance
      #
      # Request body:
      # {
      #   "point1": {
      #     "latitude": 40.7128,
      #     "longitude": -74.0060,
      #     "altitude": 0
      #   },
      #   "point2": {
      #     "latitude": 51.5074,
      #     "longitude": -0.1278,
      #     "altitude": 0
      #   }
      # }
      #
      # Response:
      # {
      #   "success": true,
      #   "surface_distance": 5570222.123,
      #   "surface_distance_km": 5570.222,
      #   "surface_distance_miles": 3461.347,
      #   "surface_distance_nautical_miles": 3008.219,
      #   "total_distance": 5570222.123,
      #   "total_distance_km": 5570.222,
      #   "total_distance_miles": 3461.347,
      #   "altitude_difference": 0,
      #   "initial_bearing": 51.2,
      #   "final_bearing": 108.5,
      #   "point1": {...},
      #   "point2": {...}
      # }
      #
      def calculate
        point1 = extract_point(:point1)
        point2 = extract_point(:point2)

        if point1.nil? || point2.nil?
          return render json: {
            success: false,
            errors: ["Both point1 and point2 are required with latitude and longitude"]
          }, status: :bad_request
        end

        calculator = GeoDistanceCalculator.new(point1: point1, point2: point2)
        result = calculator.calculate

        if result[:success]
          render json: result
        else
          render json: result, status: :unprocessable_entity
        end
      end

      private

      def extract_point(key)
        point_params = params[key]
        return nil if point_params.blank?

        {
          latitude: point_params[:latitude],
          longitude: point_params[:longitude],
          altitude: point_params[:altitude] || point_params[:height] || 0
        }
      end
    end
  end
end
