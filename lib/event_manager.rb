require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.gsub(/[^\d]/, "")
  len = phone_number.length
  if len < 10
    phone_number = ""
  elsif len == 11
    if phone_number[0] == "1"
      phone_number = phone_number[1..10]
    else
      phone_number = ""
    end
  elsif len > 11
    phone_number = ""
  else
    phone_number
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

# Works for both hour and weekday!
def most_popular_time(sign_up_times)
  hash = sign_up_times.each_with_object(Hash.new(0)) do |time, new_hash|
    new_hash[time] += 1
  end

  hash.max_by{|key, value| value}[0]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

days = {0 => "Sunday",
  1 => "Monday", 
  2 => "Tuesday",
  3 => "Wednesday",
  4 => "Thursday",
  5 => "Friday",
  6 => "Saturday"}

file = "event_attendees.csv"

contents = CSV.open(
  "event_attendees.csv", 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

sign_up_hours = []
sign_up_days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  sign_up_hours << Time.strptime(row[:regdate], "%m/%d/%y %H:%M").strftime("%H")
  sign_up_days << Date.strptime(row[:regdate], "%m/%d/%y %H:%M").wday
  save_thank_you_letter(id, form_letter)
end

puts "Most popular registration time: #{most_popular_time(sign_up_hours)}:00"
puts "Most popular registration day: #{days[most_popular_time(sign_up_days)]}"