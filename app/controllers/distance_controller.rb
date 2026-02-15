# frozen_string_literal: true

class DistanceController < ApplicationController
  # GET /distance - Show the input form
  def index
    @result = nil
  end

  # POST /distance/calculate - Calculate and display results
  def calculate
    point1 = extract_point(params, :point1)
    point2 = extract_point(params, :point2)

    calculator = GeoDistanceCalculator.new(point1: point1, point2: point2)
    @result = calculator.calculate

    render :index
  end

  private

  def extract_point(params, key)
    point_params = params[key] || {}
    {
      latitude: point_params[:latitude],
      longitude: point_params[:longitude],
      altitude: point_params[:altitude].presence || 0
    }
  end
end
