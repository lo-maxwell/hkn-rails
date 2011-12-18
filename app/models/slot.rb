class Slot < ActiveRecord::Base

  # === List of columns ===
  #   id         : integer 
  #   room       : integer 
  #   created_at : datetime 
  #   updated_at : datetime 
  #   hour       : integer 
  #   wday       : integer 
  # =======================

  # This is a tutoring office hours slot

  has_and_belongs_to_many :tutors, :before_add => :check_tutor
  has_many :slot_changes

  ROOMS = {cory: 0, soda: 1}

  validate :valid_room
  validate :valid_hour
  validates :room, :presence => true
  validates :wday, :presence => true, :inclusion => {:in => 1..5}
  validates :hour, :presence => true, :uniqueness => {:scope => [:wday, :room]}

  HOUR_RANGE_ERROR = "hour must be within tutoring hours"
  ROOM_ERROR = "room needs to be 0 (Cory) or 1 (Soda)"

  def to_s
    "Slot #{room_name} #{day_name} #{hour}"
  end

  def inspect
    "<#Slot #{room_name} #{day_name} #{hour}>"
  end

  def room_name
    if room == ROOMS[:cory] then
      "Cory"
    elsif room == ROOMS[:soda] then
      "Soda"
    end
  end

  def day_name
    day_to_wday = {"Monday"=>1, "Tuesday"=>2, "Wednesday"=>3, "Thursday"=>4, "Friday"=>5}
    day_to_wday.key(wday)
  end

  def valid_room
    if !room.blank?
      errors[:room] << ROOM_ERROR unless (room == 0 or room == 1)
    end
  end

  def valid_hour
    unless (Property.tutoring_start..Property.tutoring_end).include? hour
      errors[:hour] << HOUR_RANGE_ERROR
    end
  end

  def check_tutor(tutor)
    flip_room = room == 0 ? 1 : 0
    otherslot = Slot.find_by_wday_and_hour_and_room(wday, hour, flip_room)
    unless otherslot.nil?
      other_tutors = otherslot.tutors
      other_tutors.each do |other_tutor|
        if tutor == other_tutor
          raise "Same tutor in different offices at same time!"
        end
      end
    end
  end

  def availabilities
    return Availability.where(:hour => hour, :wday => wday)
  end

  def adjacent_to(other_slot)
    other_slot.wday == wday and (other_slot.hour - hour).abs == 1
  end
end
