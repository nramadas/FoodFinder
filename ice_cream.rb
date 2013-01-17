#!/usr/bin/env ruby

# w2d4
# Jordan and Niranjan

require 'rest-client'
require 'json'
require 'nokogiri'
require 'addressable/uri'

class FoodFinder

  KEY = "AIzaSyDU__izP4Dh1VGqwni7ZRNIN51_Ruhe7xE"

  def run_program
    start_point = get_location
    restaurants = get_restaurants(start_point)
    sort_restaurants(restaurants)
    print_restaurants(restaurants)
    end_point = get_choice(restaurants)
    directions = get_directions(start_point,end_point)
    print_directions(directions)
  end

  #gets directions based on current loc and
  #loc of restaurant
  def get_directions(start_point, end_point)
    user_direc = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "/maps/api/directions/json",
      :query_values => {:origin => "#{start_point}",
                        :destination => "#{end_point}",
                        :sensor => "false",
                        :mode => "walking"}
    )
    directions_json = RestClient.get(user_direc.to_s)
    JSON.parse(directions_json)
  end

  def print_directions(directions)
    steps = directions["routes"][0]["legs"][0]["steps"]
    steps.each do |step|
      t = Nokogiri::HTML(step["html_instructions"]).text
      t = t.gsub("Destination","\nDestination") if t.include?("Destination")
      puts t
    end
  end

  #gets a list of restaurants that fit within the user's criteria
  def get_restaurants(location)
    latitude, longitude = convert_location(location)

    food_query = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "/maps/api/place/nearbysearch/json",
      :query_values => {:location => "#{latitude},#{longitude}",
                        :radius => "#{get_distance}",
                        :types => "food",
                        :key => "#{KEY}",
                        :sensor => "false",
                        :keyword => "#{get_food_kind}"}
    )
    food_query_json = RestClient.get(food_query.to_s)
    JSON.parse(food_query_json)["results"]
  end

  #sorts restaurants by rating
  def sort_restaurants(restaurants)
    restaurants.sort_by! do |restaurant|
      restaurant["rating"] = 0.0 if restaurant["rating"].nil?
      restaurant["rating"]
    end
    restaurants.reverse!
  end

  def print_restaurants(restaurants)
    restaurants.each_with_index do |result, i|
      puts "#{i + 1}: rating: #{result["rating"]} | #{result["name"]}"
    end
    restaurants
  end

  def get_choice(restaurants)
    puts "Which one do you want to go to?"
    print "> "
    restaurants[gets.chomp.to_i-1]["vicinity"].gsub(' ', '+')
  end

  def get_location
    puts "Where are you searching from?"
    print "> "
    gets.chomp.gsub(' ', '+')
  end

  def get_distance
    puts "How far can you walk? (in meters)"
    print "> "
    gets.chomp
  end

  def get_food_kind
    puts "What kind of food are you looking for?"
    print "> "
    gets.chomp.gsub(' ', '+')
  end

  #converts a street address to lat/long
  def convert_location(address)
    loc_query = Addressable::URI.new(
      :scheme => "http",
      :host => "maps.googleapis.com",
      :path => "/maps/api/geocode/json",
      :query_values => {:address => "#{address}",
                        :sensor => "false"}
    )

    geolocation_json = RestClient.get(loc_query.to_s)
    location = JSON.parse(geolocation_json)

    latitude = location["results"][0]["geometry"]["location"]["lat"]
    longitude = location["results"][0]["geometry"]["location"]["lng"]

    [latitude, longitude]
  end

end

#script to run program
if __FILE__ == $PROGRAM_NAME
  FoodFinder.new.run_program
end